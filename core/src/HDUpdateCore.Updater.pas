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
unit HDUpdateCore.Updater;

interface

uses
  HDUpdateCore.Commons,
  HDUpdateCore.Interfaces,
  HDUpdateCore.Internet.Interfaces,
  HDUpdateCore.Language.Interfaces,
  HDUpdateCore.Types,
  System.Classes,
  System.Generics.Collections,
  System.IniFiles,
  System.SyncObjs,
  System.SysUtils,
  System.Zip;

type
  TUpdater = class(TInterfacedPersistent, IUpdateModel)
  protected

  private
    FLaunchUpdateApp: TFileName; // Adicionado por renato trevisan dia 10/06/2024 16:42:20
    FUpdateURL      : string;
    FExtractNames   : TStringArray;
    FIsAbort        : Boolean;
    FRootPath       : string;
    FUpdateFile     : string;
    FInternet       : IModelInternet;
  protected
    FView   : IUpdateView;
    FConsts : IFactoryConsts;
    // Internal routlines
    procedure SyncView(Proc: TThreadProcedure);          // perfect
    procedure SyncShowView;                              // perfect
    procedure SyncCloseView;                             // perfect
    function  SyncErrorMessage(Text: string): Boolean;   // perfect
    function  GetUpdateFileName: string;                 // perfect
    function  ExtractAll(AStrins: TStringArray): Boolean;
    // ... routlines
    function  DoUpdate        : TUpdateResult; virtual;  // perfect
    function  GetDownloadInfo : Boolean; virtual;        // perfect
    function  Download        : Boolean; virtual;        // perfect
    function  Unpacking       : Boolean; virtual;        // perfect
    procedure DeleteFiles;                               // perfect
    procedure Done; virtual;                             // perfect
    { IUpdateModel }
    procedure Cancel; virtual;                           // perfect
  public
    constructor Create(View: IUpdateView; UpdateInfo: TUpdateInfo); virtual;
    destructor  Destroy; override;
    procedure   Update;
    procedure   UpdateFromFile(FileName: string);
  end;

implementation

uses
  HDUpdateCore.Internet.Factory,
  HDUpdateCore.Language.Consts.Factory,
  HDUpdateCore.Utils;

{$HINTS OFF}
function FileToOld(FileName: string): Boolean;
const
  Suffics = '.old';
begin
  if FileExists(FileName + Suffics) then
    if not DeleteFile(FileName + Suffics) then
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
  FLaunchUpdateApp      := ExtractFileName(ParamStr(0)); //adicionado por renato trevisan dia 10/06/2024 16:30:00

  FInternet             := TModelIternetFactory.New.Internet;
  FInternet.IniKeyName  := UpdateInfo.IniKeyName;
  FInternet.GitToken    := UpdateInfo.GitToken;
  FInternet.GitRepo     := UpdateInfo.GitRepo;
  FInternet.GitUserName := UpdateInfo.GitUserName;
  FInternet.GitPath     := UpdateInfo.GitPath;
  FInternet.GitAuth     := UpdateInfo.GitAuth;

  FExtractNames         := UpdateInfo.ExtractNames + [ExtractFileName(ParamStr(0))];
  FConsts               := TFactoryConsts.New;

  if UpdateInfo.RootPath.IsEmpty then //adicionado por renato trevisan dia 11/06/2024
    FRootPath := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)) + PathDelim + UpdateInfo.RootPath) else
    FRootPath := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)) + PathDelim);

  // set View
  Self.FView := View;
  SyncView(
    procedure
      begin
        // set Model
        View.Model := Self;
        // State
        View.State := TUpdateState.Waiting;
        // Description
        if UpdateInfo.Titulo <> '' then
          View.Titulo := UpdateInfo.Titulo else
          View.Titulo := 'Atualizando seu sistema!';
        // PngRes
        if UpdateInfo.PngRes <> '' then
          View.PngRes := UpdateInfo.PngRes;
        // Progress
        View.Progress(0, 1);
        // Status
        View.Status := FConsts.Consts.WaitingStatus;
        // Version
        View.Version := '';
        View.Log := FInternet.UpdateLog;
      end
  );
end;

procedure TUpdater.DeleteFiles;
begin
  if FileExists(GetUpdateFileName) then
    DeleteFile(GetUpdateFileName);
end;

destructor TUpdater.Destroy;
begin
  FView.Model := nil;
  inherited;
end;

procedure TUpdater.Done;
begin
  // View
  SyncView(
   procedure
    begin
      FView.State := TUpdateState.Done;
      FView.Status := FConsts.Consts.DoneStatus;
      FView.ShowMessage(FConsts.Consts.DoneMessage);
      HDUpdateCore.Utils.LaunchUpdateApp(FLaunchUpdateApp, True);
      HDUpdateCore.Utils.Killtask(FLaunchUpdateApp);
    end);
end;

function TUpdater.Download: Boolean;
begin
  // View
  SyncView(
    procedure
     begin
      FView.State   := TUpdateState.Downloading;
      FView.Status  := FConsts.Consts.DownloadingStatus;
     end);

     try
      Result :=
        FInternet
         .DowloadFile(
          FUpdateURL,
          GetUpdateFileName,
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
begin
  // View
  SyncView(
    procedure
     begin
      FView.State := TUpdateState.Waiting;
      FView.Status := FConsts.Consts.WaitingStatus;
     end);

  if FInternet.GetVersionUpdate(FileVersion) then
    SyncView(
     procedure
       begin
        FView.Version := Format(FConsts.Consts.Version, [FileVersion.ToString]);
       end);

  FUpdateURL := FInternet.GetUpdateUrl;
  Result     := FUpdateURL <> '';
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

function TUpdater.Unpacking: Boolean;
var
  LZipFile: TZipFile;
  LForIndex: Integer;
  LFullFileName: string;
  LFileName: string;
  LExeName: string;
begin
  Result := True;
  // View
  SyncView(
    procedure
     begin
      FView.State  := TUpdateState.Unpacking;
      FView.Status := FConsts.Consts.UnpackingStatus;
     end);
  // Unpacking
  LZipFile := TZipFile.Create;
  try
    try
     LZipFile.Open(GetUpdateFileName, TZipMode.zmRead);
      {Verifica se vai extratir tudo ou não}
      if not ExtractAll(FExtractNames) then begin
        for LForIndex := 0 to LZipFile.FileCount - 1 do begin
          for LExeName in FExtractNames do begin
           LFileName := ExtractFileName(NormalizeFileName(LZipFile.FileName[LforIndex]));
            if LExeName.ToUpper = LFileName.ToUpper then begin
              LFullFileName := FRootPath + NormalizeFileName(LZipFile.FileName[LforIndex]);
              if not FileToOld(LFullFileName) then
                Exit(False);

              LZipFile.Extract(LFileName, FRootPath);
              Break;
            end;
          end;
          // View
          SyncView(
            procedure
             begin
              FView.Progress(LforIndex, LZipFile.FileCount - 1);
             end);
        end;
      end
    else
      begin
        for LForIndex := 0 to LZipFile.FileCount - 1 do begin
          LFullFileName := FRootPath + NormalizeFileName(LZipFile.FileName[LforIndex]);

          if not FileToOld(LFullFileName) then Exit(False);
          // View
          SyncView(
            procedure
             begin
               FView.Progress(LforIndex, LZipFile.FileCount - 1);
             end);
        end;
       LZipFile.ExtractAll(FRootPath);
      end;
    except
      on EZipException do Exit(False);
      on EFOpenError   do Exit(False);
    end;
  finally
    LZipFile.Free;
  end;
end;

function TUpdater.DoUpdate: TUpdateResult;
begin
  // Obter informações
  if not GetDownloadInfo then
    if FIsAbort then
      Exit(TUpdateResult.Abort) else
    if SyncErrorMessage(FConsts.Consts.ConnectionError) then
      Exit(TUpdateResult.TryAgain) else
      Exit(TUpdateResult.Fail);

  // Download
  if not Download then
    if FIsAbort then
      Exit(TUpdateResult.Abort) else
    if SyncErrorMessage(FConsts.Consts.DownloadError) then
      Exit(TUpdateResult.TryAgain) else
      Exit(TUpdateResult.Fail);

  //Unpacking
  if not Unpacking then
    if SyncErrorMessage(FConsts.Consts.CorruptedFilesError) then
      Exit(TUpdateResult.TryAgain) else
      Exit(TUpdateResult.Fail);

  // Deleta arquivo .ZIP de atualização
  DeleteFiles;
  Done;
  Result := TUpdateResult.Success;
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
  ArchiveName = 'Update.zip';
begin
  if FUpdateFile = '' then
    Result := ExtractFileDir(ParamStr(0)) + PathDelim + ArchiveName else
    Result := FUpdateFile;
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
          Done else
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
