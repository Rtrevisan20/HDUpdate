(*
***********************************************************************
HDUpdate v0.0.1
***********************
Por Renato Trevisan
***********************
Proposta: Fazer atualizações automatizadas usando a API do GitHub.
***********************************************************************
MIT License

Copyright (c) 2024 Renato Trevisan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*)
unit HDUpdate.Core.Updater;

interface

uses
  HDUpdate.Core.Commons,
  HDUpdate.Core.Interfaces,
  HDUpdate.Internet.Interfaces,
  HDUpdate.Language.Interfaces,
  HDUpdate.Core.Types,
  System.Classes,
  System.Generics.Collections,
  System.IniFiles,
  System.SyncObjs,
  WinApi.Windows,
  System.SysUtils,
  System.Zip;

type
  TUpdater = class(TInterfacedPersistent, IUpdateModel)
  private
    FLaunchUpdateApp: TFileName; // Adicionado por renato trevisan dia 10/06/2024 16:42:20
    FUpdateURL      : string;
    FExtractNames   : TStringArray;
    FIsAbort        : Boolean;
    FRootPath       : string;
    FUpdateFile     : string;
    // Item 9.5: nome real do asset baixado (Samples.exe / Client.zip)
    FUpdateFileName : string;
    FInternet       : IModelInternet;
    FUseReleases      : Boolean;
    FReleaseAssetName : string;
    FVersionAtual     : TFileVersion;
    FRolledBackFiles: TStringList;  // lista de arquivos renomeados para .old (rollback)
    FVerifyExtracted  : Boolean;    // validar hash dos arquivos extraidos via manifest.json
    FAssetType        : TAssetType; // atZip, atExe, atAuto
    FKillTaskApp      : TFileName;
    FRestartApp       : Boolean;
    FIsExe            : Boolean; // True se for um .exe False se for .zip
    FRequireAssetHash : Boolean;
    FExpectedAssetSHA256 : string;
  protected
    FView   : IUpdateView;
    FConsts : IFactoryConsts;
    // Internal routlines
    procedure SyncView(Proc: TThreadProcedure);          // perfect
    procedure SyncShowView;                              // perfect
    procedure SyncCloseView;                             // perfect
    function  SyncErrorMessage(Text: string): Boolean;   // perfect
    procedure SyncMessageError(Text: string);            // perfect
    function  GetUpdateFileName: string;                 // perfect
    function  ExtractAll(AStrins: TStringArray): Boolean;
    // ... routlines
    function  DoUpdate        : TUpdateResult; virtual;  // perfect
    function  GetDownloadInfo : Boolean; virtual;        // perfect
    function  Download        : Boolean; virtual;        // perfect
    function  Unpacking       : Boolean; virtual;        // perfect
    procedure DeleteFiles;                               // perfect
    procedure Done; virtual;                             // perfect
    procedure CleanOldFiles;                             // Item 9: limpeza de .old
    function  RunInstaller(const AFileName: string): Boolean; // Item 10: roda instalador .exe
    { IUpdateModel }
    procedure Cancel; virtual;                           // perfect
  public
    constructor Create(View: IUpdateView; UpdateInfo: TUpdateInfo); virtual;
    destructor  Destroy; override;
    procedure   Update;
    procedure   UpdateFromFile(FileName: string);
    property    AssetType: TAssetType read FAssetType write FAssetType;
    property    RestartApp: Boolean read FRestartApp;
  end;

implementation

uses
  HDUpdate.Internet.Factory,
  HDUpdate.Language.Consts.Factory,
  HDUpdate.Core.Utils,
  System.Hash,
  System.JSON,
  System.IOUtils,
  WinApi.ShellAPI;

{$HINTS OFF}
function FileToOld(FileName: string): Boolean;
const
  Suffics = '.old';
begin
  if FileExists(FileName + Suffics) then
    if not System.SysUtils.DeleteFile(FileName + Suffics) then
      Exit(False);

  if FileExists(FileName) then
    if not RenameFile(FileName, FileName + Suffics) then
      Exit(False);

  Result := True;
end;
{$HINTS ON}

procedure TUpdater.Cancel;
begin
  FIsAbort := True;
end;

procedure TUpdater.SyncCloseView;
begin
  SyncView(
    procedure
    begin
      FView.Close;
    end);
end;

constructor TUpdater.Create(View: IUpdateView; UpdateInfo: TUpdateInfo);
begin
  FExpectedAssetSHA256 := '';
  FLaunchUpdateApp      := UpdateInfo.ExeUpdateApp; //adicionado por renato trevisan dia 10/06/2024 16:30:00

  FInternet             := TModelIternetFactory.New.Internet;
  FInternet.IniKeyName  := UpdateInfo.IniKeyName;
  FInternet.GitToken    := UpdateInfo.GitToken;
  FInternet.GitRepo     := UpdateInfo.GitRepo;
  FInternet.GitUserName := UpdateInfo.GitUserName;
  FInternet.GitIni      := UpdateInfo.GitIni;
  FInternet.GitAuth     := UpdateInfo.GitAuth;

  FExtractNames         := UpdateInfo.ExtractNames + [ExtractFileName(ParamStr(0))];
  FConsts               := TFactoryConsts.Global;
  FRolledBackFiles      := TStringList.Create;
  FVerifyExtracted      := UpdateInfo.VerifyExtractedFiles;
  FRequireAssetHash     := UpdateInfo.RequireAssetHash;
  FAssetType            := UpdateInfo.AssetType;
  FReleaseAssetName     := UpdateInfo.ReleaseAssetName;
  FKillTaskApp          := UpdateInfo.KillTaskApp;
  FRestartApp           := False;
  FUseReleases          := UpdateInfo.UseReleases;
  FVersionAtual         := UpdateInfo.ActualVersion;

  if UpdateInfo.RootPath.IsEmpty then
    FRootPath := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)))
  else
    FRootPath := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)) + PathDelim + UpdateInfo.RootPath);

  // set View
  Self.FView := View;
  SyncView(
    procedure
    begin
      // set Model
      View.Model := Self;
      // Item 9.16: textos estaticos do form (.fmx) chumbados em pt-BR agora saem das consts
      View.CancelText  := FConsts.Consts.CancelButton;
      View.WaitingText := FConsts.Consts.WaitingMessage;
      // State
      View.State := TUpdateState.Waiting;
      // Description
      if UpdateInfo.Titulo <> '' then
        View.Titulo := UpdateInfo.Titulo
      else
        View.Titulo := FConsts.Consts.MsgTitle;
      // PngResource
      if UpdateInfo.PngResource <> '' then
        View.PngResource := UpdateInfo.PngResource;
      // Progress
      View.Progress(0, 1);
      // Status
      View.Status := FConsts.Consts.WaitingStatus;
      // Version (Item 9.16: fix de 'Versão: ' chumbado - usa a const localizada)
      View.Version := Format(FConsts.Consts.Version, [UpdateInfo.VersionUpdate]);
      // Descricao padrao localizada (o .fmx traz 'Estamos preparando...' chumbado em pt-BR)
      View.UpdateLog := FConsts.Consts.PreparingUpdate;
      // Item 8: em modo Releases nao existe ini para ler (evita request inutil e AV)
      if not FUseReleases then
        if FInternet.UpdateLog <> '' then
          View.UpdateLog := FInternet.UpdateLog;
    end
  );
end;

procedure TUpdater.DeleteFiles;
var
  LUpdateFile: string;
begin
  LUpdateFile := GetUpdateFileName;
  if FileExists(LUpdateFile) then
    System.SysUtils.DeleteFile(LUpdateFile);
end;

destructor TUpdater.Destroy;
begin
  FreeAndNil(FRolledBackFiles);
  FView.Model := nil;
  inherited;
end;

procedure TUpdater.Done;
begin
  // 1. Encerra a instancia antiga ANTES de abrir a nova.
  //    Se KillTaskApp for o proprio executavel, o encerramento acontece pela
  //    auto-terminacao do processo (FRestartApp), pois Killtask por nome
  //    derrubaria tambem a instancia recem-lancada.
  if (FKillTaskApp <> '') and
     (not SameText(ExtractFileName(FKillTaskApp), ExtractFileName(FLaunchUpdateApp))) then
    HDUpdate.Core.Utils.Killtask(FKillTaskApp);

  // 2. Depois lanca a nova instancia
  SyncView(
    procedure
    begin
      FView.State := TUpdateState.Done;
      FView.Status := FConsts.Consts.DoneStatus;
      FView.ShowMessage(FConsts.Consts.DoneMessage);
      HDUpdate.Core.Utils.LaunchUpdateApp(FLaunchUpdateApp, True);
    end);

  FRestartApp := True;
  // Limpa arquivos .old apos sucesso
  CleanOldFiles;
end;

procedure TUpdater.CleanOldFiles;
var
  LSearch: TSearchRec;
  LOldPath: string;
  LFindHandle: Integer;
begin
  LOldPath := FRootPath + '*.old';
  LFindHandle := FindFirst(LOldPath, faAnyFile, LSearch);
  try
    while LFindHandle = 0 do
    begin
      if (LSearch.Name <> '.') and (LSearch.Name <> '..') then
       System.SysUtils.DeleteFile(FRootPath + LSearch.Name);
       LFindHandle := FindNext(LSearch);
    end;
  finally
    FindClose(LSearch);
  end;
end;

function TUpdater.Download: Boolean;
var
  LFileName, LAssetHash, LExpected: string;
begin
  // View
  SyncView(
    procedure
    begin
      FView.State   := TUpdateState.Downloading;
      FView.Status  := FConsts.Consts.DownloadingStatus;
    end);

  try
    LFileName := GetUpdateFileName;
    // Item 9.5: garante a subpasta (Updates) quando o nome do asset coincide com o exe atual
    ForceDirectories(ExtractFileDir(LFileName));
    Result :=
      FInternet
       .DowloadFile(
        FUpdateURL,
        LFileName,
        procedure(Length, Progress: Int64; var Abort: Boolean)
        begin
          Abort := FIsAbort;
          // View
          SyncView(
            procedure
            begin
              FView.Progress(Progress, Length);
            end);
        end);

   if Result and FRequireAssetHash and (FExpectedAssetSHA256 <> '') then
      begin
        LAssetHash := THashSHA2.GetHashStringFromFile(LFileName).ToLower;
        LExpected := FExpectedAssetSHA256;
        if LExpected.StartsWith('sha256:') then
          LExpected := LExpected.Substring(7);
        if not SameText(LAssetHash, LExpected) then
        begin
          try
            DeleteFile(LFileName);                                // nao deixa zip corrompido para tras
          except
          end;
          SyncMessageError(FConsts.Consts.HashInvalid + LAssetHash);
          Result := False;
        end;
      end;
  except
    Result := False;
  end;
end;

function TUpdater.ExtractAll(AStrins: TStringArray): Boolean;
const
  CExtractParameter = '&ALL';
var
  LStringList: TStringList;
  LFindIndex: integer;
begin
  LStringList := TStringList.Create;
  try
    LStringList.AddStrings(AStrins);
    Result := LStringList.Find(CExtractParameter, LFindIndex);
  finally
    FreeAndNil(LStringList);
  end;
end;

function TUpdater.GetDownloadInfo: Boolean;
var
  FileVersion: TFileVersion;
  LRelease: TGitHubRelease;
  LAsset: TGitHubAsset;
  LAssetType: TAssetType;
  LUrl: string;
begin
  // View
  SyncView(
    procedure
    begin
      FView.State   := TUpdateState.Waiting;
      FView.Status  := FConsts.Consts.WaitingStatus;
    end);

  FUpdateFileName := '';

  if FUseReleases then
  begin
    if FInternet.GetLatestRelease(LRelease) then
    begin
      FileVersion := LRelease.GetVersion;
      SyncView(
        procedure
        begin
          FView.Version := Format(FConsts.Consts.Version, [FileVersion.ToString]);
        end);
      if FileVersion > FVersionAtual then
      begin
        LAssetType := FAssetType;
        if FInternet.GetReleaseAssetUrl(LRelease, FReleaseAssetName, LUrl, FExpectedAssetSHA256, LAssetType) then
        begin
          FUpdateURL := LUrl;
          // Item 9.5: usa o nome real do asset como nome do arquivo local
          LAsset := LRelease.FindAsset(FReleaseAssetName, LAssetType);
          if not LAsset.IsEmpty then
            FUpdateFileName := LAsset.Name;
          Result := True;
        end else
          Result := False;
      end else
        Result := False;
    end else
      Result := False;
  end else
  begin
    // Modo Classico usando o arquivo INI
    if FInternet.GetVersionUpdate(FileVersion) then
      SyncView(
        procedure
        begin
          FView.Version := Format(FConsts.Consts.Version, [FileVersion.ToString]);
        end);

    FUpdateURL := FInternet.GetURLUpdateINI;
    Result     := FUpdateURL <> '';
    if Result then
      // Item 9.7: nome do arquivo a partir da URL, sem query string (?token=...)
      FUpdateFileName := ExtractFileNameFromUrl(FUpdateURL);
  end;
end;

function TUpdater.SyncErrorMessage(Text: string): Boolean;
var
  R: Boolean;
begin
  SyncView(
    procedure
    begin
      R := FView.ShowErrorMessage(Text);
    end);

  Result := R;
end;

procedure TUpdater.SyncMessageError(Text: string);
begin
  SyncView(
    procedure
    begin
      FView.ShowMessageError(Text);
    end);
end;

procedure TUpdater.SyncShowView;
begin
  SyncView(
    procedure
    begin
      FView.Show;
    end);
end;

procedure TUpdater.SyncView(Proc: TThreadProcedure);
begin
  if FView <> nil then
    TThread.Synchronize(nil, Proc);
end;

// Item 10: detecta executavel pela extensao e, como fallback, pela assinatura PE ('MZ')
function IsExecutableFile(const AFileName: string): Boolean;
const
  CMagicMZ = $5A4D;
var
  LStream: TFileStream;
  LMagic : Word;
begin
  Result := False;
  if not FileExists(AFileName) then Exit;
  if SameText(ExtractFileExt(AFileName), '.exe') then Exit(True);

  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if LStream.Size >= SizeOf(LMagic) then
    begin
      LStream.ReadBuffer(LMagic, SizeOf(LMagic));
      Result := LMagic = CMagicMZ;
    end;
  finally
    LStream.Free;
  end;
end;

function TUpdater.RunInstaller(const AFileName: string): Boolean;
var
  LExecInfo: TShellExecuteInfo;
begin
  Result := False;
  FillChar(LExecInfo, SizeOf(LExecInfo), 0);
  LExecInfo.cbSize := SizeOf(TShellExecuteInfo);
  LExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  LExecInfo.Wnd := 0;
  LExecInfo.lpVerb := 'open';
  LExecInfo.lpFile := PWideChar(UnicodeString(AFileName));
  // Executa normalmente (visivel) para o usuario acompanhar a instalacao
  LExecInfo.lpParameters := '';
  LExecInfo.nShow := SW_SHOW;
  if ShellExecuteEx(@LExecInfo) then
  begin
    // Aguarda o instalador terminar
    if LExecInfo.hProcess <> 0 then
    begin
      WaitForSingleObject(LExecInfo.hProcess, INFINITE);
      CloseHandle(LExecInfo.hProcess);
    end;
    Result := True;
  end;
end;

function TUpdater.Unpacking: Boolean;
var
  LZipFile: TZipFile;
  LForIndex: Integer;
  LFullFileName: string;
  LFileName: string;
  LExeName: string;
  LManifestJson: string;
  LManifestObj: TJSONObject;
  LFilesObj: TJSONObject;
  LFileHash: string;
  LExpectedHash: string;
  LPair: TJSONPair;
  LStream: TStream;          // fix: leitura do manifest em memoria (sem arquivo temp)
  LZipHeader: TZipHeader;    // fix
  LManifestBytes: TBytes;    // fix
  LExtractedFile: string;
  LOldFile: string;
  LFile: string;
  LExec: string;
begin
  Result := True;
  FRolledBackFiles.Clear;
  // View
  SyncView(
    procedure
    begin
      FView.State  := TUpdateState.Unpacking;
      FView.Status := FConsts.Consts.UnpackingStatus;
    end);

  LExec := GetUpdateFileName;
  FIsExe := IsExecutableFile(LExec);

  if FIsExe then
  begin
    // View
    SyncView(
      procedure
      begin
        FView.Status := FConsts.Consts.PreparingInstaller;
      end);
   FLaunchUpdateApp := LExec;
   Exit(True);
  end else
  begin
    // Unpacking ZIP (lógica existente)
    LZipFile := TZipFile.Create;
    try
      try
        LZipFile.Open(GetUpdateFileName, TZipMode.zmRead);
        {Verifica se vai extratir tudo ou nao}
        if not ExtractAll(FExtractNames) then
        begin
          for LForIndex := 0 to LZipFile.FileCount - 1 do
          begin
            for LExeName in FExtractNames do
            begin
              LFileName := ExtractFileName(NormalizeFileName(LZipFile.FileName[LforIndex]));
              if LExeName.ToUpper = LFileName.ToUpper then
              begin
                LFullFileName := FRootPath + NormalizeFileName(LZipFile.FileName[LforIndex]);
                if not FileToOld(LFullFileName) then
                  Exit(False);
                FRolledBackFiles.Add(LFullFileName);

                LZipFile.Extract(LFileName, FRootPath);
                Break;
              end;
            end;
            // View
            SyncView(
              procedure
              begin
                FView.Progress(LForIndex, LZipFile.FileCount - 1);
              end);
          end;
        end else
        begin
          // Se vai extrair tudo, primeiro verifica se tem manifest.json para validacao
          LManifestJson := '';
          if FVerifyExtracted then
          begin
            try
              // Le o manifest.json direto em memoria via TZipFile.Read.
              // Antes: GetTempFileName + Extract + ReadAllText(LTempFile) lia o
              // tmpXXXX.tmp VAZIO (0 bytes) -> LManifestJson = '' e a validacao
              // de hash era pulada silenciosamente (prova: probe 04/11/2026).
              for LForIndex := 0 to LZipFile.FileCount - 1 do
              begin
                if SameText(ExtractFileName(LZipFile.FileName[LForIndex]), 'manifest.json') then
                begin
                  LZipFile.Read(LForIndex, LStream, LZipHeader);
                  try
                    LStream.Position := 0;
                    SetLength(LManifestBytes, LStream.Size);
                    if LStream.Size > 0 then
                      LStream.ReadBuffer(LManifestBytes, Length(LManifestBytes));
                    LManifestJson := TEncoding.UTF8.GetString(LManifestBytes);
                    // Remove BOM, se houver (JSON gravado por WriteAllText(UTF8) traz BOM)
                    if LManifestJson.StartsWith(Chr($FEFF)) then
                      LManifestJson := LManifestJson.Substring(1);
                  finally
                    LStream.Free;
                  end;
                  Break;
                end;
              end;
            except
              LManifestJson := '';
            end;
          end;

          for LForIndex := 0 to LZipFile.FileCount - 1 do
          begin
            LFullFileName := FRootPath + NormalizeFileName(LZipFile.FileName[LforIndex]);

            if not FileToOld(LFullFileName) then
              Exit(False);
            FRolledBackFiles.Add(LFullFileName);
            // View
            SyncView(
              procedure
              begin
                FView.Progress(LForIndex, LZipFile.FileCount - 1);
              end);
          end;
          LZipFile.ExtractAll(FRootPath);

          // Validacao de hash dos arquivos extraidos (se manifest.json existe)
          if FVerifyExtracted and (LManifestJson <> '') then
          begin
            LManifestObj := TJSONObject.ParseJSONValue(LManifestJson) as TJSONObject;
            try
              if LManifestObj <> nil then
              begin
                LFilesObj := LManifestObj.GetValue<TJSONObject>('files');
                if LFilesObj <> nil then
                begin
                  for LPair in LFilesObj do
                  begin
                    LExpectedHash := LPair.JsonValue.Value;
                    LExtractedFile := FRootPath + LPair.JsonString.Value;
                    if FileExists(LExtractedFile) then
                    begin
                      LFileHash := THashSHA2.GetHashStringFromFile(LExtractedFile).ToLower;
                      // Remove prefixo "sha256:" se houver
                      if LExpectedHash.StartsWith('sha256:') then
                        LExpectedHash := LExpectedHash.Substring(7);
                      if not SameText(LFileHash, LExpectedHash) then
                      begin
                        SyncMessageError(FConsts.Consts.HashInvalid + LFileHash);
                        Exit(False);
                      end;
                    end;
                  end;
                end;
              end;
            finally
              LManifestObj.Free;
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          // Rollback: restaurar todos os arquivos .old
          for LFile in FRolledBackFiles do
          begin
            LOldFile := LFile + '.old';
            if FileExists(LOldFile) then
            begin
              if FileExists(LFile) then
                System.SysUtils.DeleteFile(LFile);
              RenameFile(LOldFile, LFile);
            end;
          end;
          if (E is EZipException) or (E is EFOpenError) then
          begin
            // Item 9.7: descarta o arquivo baixado invalido (nao apaga arquivo informado pelo usuario)
            if FUpdateFile = '' then
              DeleteFiles;
            Exit(False);
          end
          else
            raise;
        end;
      end;
    finally
      LZipFile.Free;
    end;
  end;
end;

function TUpdater.DoUpdate: TUpdateResult;
begin
  // Obter informações se vai ser release ou classico com .ini
  if not GetDownloadInfo then
     if FIsAbort then
      Exit(TUpdateResult.Abort)
    else if SyncErrorMessage(FConsts.Consts.ConnectionError) then
      Exit(TUpdateResult.TryAgain)
    else
      Exit(TUpdateResult.Fail);

  // Download
  if not Download then
    if FIsAbort then
      Exit(TUpdateResult.Abort)
    else if SyncErrorMessage(FConsts.Consts.DownloadError) then
      Exit(TUpdateResult.TryAgain)
    else
      Exit(TUpdateResult.Fail);

  //Unpacking
  if not Unpacking then
    if SyncErrorMessage(FConsts.Consts.CorruptedFilesError) then
      Exit(TUpdateResult.TryAgain)
    else
      Exit(TUpdateResult.Fail);

  // Deleta arquivo de atualização (.zip)
  if not FIsExe then
    DeleteFiles;

  Done;
  Exit(TUpdateResult.Success);
end;

procedure TUpdater.Update;
var
  FResult: TUpdateResult;
begin
  FIsAbort := False;
  SyncShowView;
  try
    repeat
      FResult := DoUpdate;
    until FResult <> TUpdateResult.TryAgain;
  finally
    SyncCloseView;
  end;
end;

function TUpdater.GetUpdateFileName: string;
const
  ArchiveName   = 'Update';
  CUpdatesFolder = 'Updates';
var
  LExt, LName, LDir: string;
begin
  if FUpdateFile <> '' then
    Exit(FUpdateFile);

  // Item 9.7: o nome vem sanitizado de FUpdateFileName (asset do release ou URL sem query).
  // Nunca aceita diretorio nem URL crua: ExtractFileNameFromUrl devolve '' nesses casos.
  LName := ExtractFileNameFromUrl(FUpdateFileName);

  // Item 10: preserva a extensao (.exe ou .zip) para permitir a deteccao posterior
  if SameText(ExtractFileExt(LName), '.exe') then
    LExt := '.exe'
  else
  begin
    LExt := '.zip';
    if not SameText(ExtractFileExt(LName), LExt) then
      LName := ArchiveName + LExt;
  end;

  LDir   := ExtractFileDir(ParamStr(0)) + PathDelim;
  Result := LDir + LName;

  // O proprio executavel em execucao esta bloqueado para escrita:
  // nesse caso o download vai para a subpasta Updates.
  if SameText(Result, ExpandFileName(ParamStr(0))) then
    Result := LDir + CUpdatesFolder + PathDelim + LName;
end;

procedure TUpdater.UpdateFromFile(FileName: string);
var
  TryAgain: Boolean;
begin
  FUpdateFile := FileName;
  try
    SyncShowView;
    try
      TryAgain := False;
      repeat
        // Unpacking
        if Unpacking then
          Done
        else
          TryAgain := SyncErrorMessage(FConsts.Consts.CorruptedFilesError);
      until not TryAgain;
    finally
      SyncCloseView;
    end;
  finally
    FUpdateFile := '';
  end;
end;

end.