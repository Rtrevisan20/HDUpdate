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
unit HDUpdate.Core.Check;

interface

uses
  HDUpdate.Core.Commons,
  HDUpdate.Core.Interfaces,
  HDUpdate.Internet.Interfaces,
  HDUpdate.Core.Types,
  System.SysUtils;

type
  TModelCheck = class(TInterfacedObject, IModelCheck)
  private
    FGitAuth          : Boolean;
    FIniKeyName       : String;
    FGitToken         : String;
    FGitRepo          : String;
    FGitUserName      : String;
    FGitPath          : String;
    FPngRes           : String;
    FRootPath         : String;
    FTitulo           : String;
    FExeUpdateApp     : string;
    FKillTaskApp      : TFileName;
    FModelInternet    : IModelInternet;
    FVersionAtual     : TFileVersion;
    FExtractNames     : TStringArray;
    FUseReleases      : Boolean;
    FRequireAssetHash : Boolean;
    FReleaseAssetName : string;
    FAssetType        : TAssetType;
    FUpdateInfo       : TUpdateInfo;
    FVerifyExtractedFiles  : Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IModelCheck;
    (*=================================================================*)
    procedure UpdateCheckProc(aVersion: TFileVersion;
                              aUpdateCheckProc: TUpdateCheckResultProc);
    function  GetVersionUpdate  : TFileVersion;
    function  CheckUpdate       : boolean;
    (*=================================================================*)
    function ActualVersion        (aActualVersion : TFileVersion)     : IModelCheck;
    function GitAuth              (aGitAuth       : Boolean = False)  : IModelCheck;
    function IniKeyName           (aIniKeyName    : String)           : IModelCheck;
    function GitToken             (aGitToken      : String)           : IModelCheck;
    function GitRepo              (aGitRepo       : String)           : IModelCheck;
    function GitUserName          (aGitUserName   : String)           : IModelCheck;
    function GitIni               (aGitIni        : String)           : IModelCheck;
    function RootPath             (aRootPath      : String)           : IModelCheck;
    function Titulo               (aTitulo        : String = '')      : IModelCheck;
    function PngResource          (aPngResource   : String)           : IModelCheck;
    function ExtractNames         (aExtractNames  : TStringArray)     : IModelCheck;
    function ExeUpdateApp         (aExeUpdateApp  : string= 'Update.exe'): IModelCheck;
    function KillTaskApp          (aKillTaskApp   : TFileName)        : IModelCheck;
    function UseReleases          (aValue         : Boolean = False)  : IModelCheck;
    function RequireAssetHash     (aValue         : Boolean = False)  : IModelCheck;
    function ReleaseAssetName     (aName          : string)           : IModelCheck;
    function VerifyExtractedFiles (aValue         : Boolean = False)  : IModelCheck;
    function AssetType            (aValue         : TAssetType = TAssetType.atAuto): IModelCheck;

    function UpdateInfo : TUpdateInfo;
  end;

var
  FIsChecking: Boolean = False;

implementation

uses
  HDUpdate.Internet.Factory,
  System.Classes;

function TModelCheck.CheckUpdate: boolean;
var
  LVersion: TFileVersion;
  LRelease: TGitHubRelease;
  LUrl, LDigest: string;
begin
  if FIsChecking then Exit(False);
  FIsChecking := True;
   try
    if FUseReleases then
    begin
      if FModelInternet.GetLatestRelease(LRelease) then
      begin
        LVersion := LRelease.GetVersion;
        FUpdateInfo.VersionUpdate := LVersion.ToString;
        if LVersion > FVersionAtual then
        begin
          if FModelInternet.GetReleaseAssetUrl(LRelease, FUpdateInfo.ReleaseAssetName, LUrl, LDigest, FUpdateInfo.AssetType) then
          begin
            FUpdateInfo.DownloadUrl     := LUrl;
            FUpdateInfo.ExpectedSHA256  := LDigest;
            Result := True;
          end
          else
            Result := False;
        end
        else
          Result := False;
      end
      else
        Result := False;
    end
    else
    begin
      if FModelInternet.GetVersionUpdate(LVersion) then
       Result := LVersion > FVersionAtual else
       Result := False;
    end;
   finally
     FIsChecking := False;
   end;
end;

constructor TModelCheck.Create;
begin
  FModelInternet                    := TModelIternetFactory.New.Internet;
  FUpdateInfo                       := Default(TUpdateInfo);
  FUpdateInfo.GitAuth               := False;
  FUpdateInfo.ExeUpdateApp          := 'Update.exe';
  FUpdateInfo.UseReleases           := False;
  FUpdateInfo.RequireAssetHash      := False;
  FUpdateInfo.VerifyExtractedFiles  := False;
  FUpdateInfo.AssetType             := TAssetType.atAuto;
  FVerifyExtractedFiles             := False;
end;

destructor TModelCheck.Destroy;
begin
  inherited;
end;

function TModelCheck.ExeUpdateApp(aExeUpdateApp: string= 'Update.exe'): IModelCheck;
begin
  Result                    := Self;
  FExeUpdateApp             := aExeUpdateApp;
  FUpdateInfo.ExeUpdateApp  := aExeUpdateApp;
end;

function TModelCheck.ExtractNames(aExtractNames: TStringArray): IModelCheck;
begin
  Result                    := Self;
  FExtractNames             := aExtractNames;
  FUpdateInfo.ExtractNames  := aExtractNames;
end;

function TModelCheck.GetVersionUpdate: TFileVersion;
var
  LRelease: TGitHubRelease;
begin
  if FUpdateInfo.UseReleases then
  begin
    if FModelInternet.GetLatestRelease(LRelease) then
      Result := LRelease.GetVersion
    else
      Result := TFileVersion.Create('0.0.0.0');
  end
  else
    FModelInternet.GetVersionUpdate(Result);
  FUpdateInfo.VersionUpdate := Result.ToString;
end;

function TModelCheck.GitAuth(aGitAuth: Boolean = False): IModelCheck;
begin
  Result                  := Self;
  FGitAuth                := aGitAuth;
  FModelInternet.GitAuth  := aGitAuth;
  FUpdateInfo.GitAuth     := aGitAuth;
end;

function TModelCheck.GitIni(aGitIni: String): IModelCheck;
begin
  Result                  := Self;
  FGitPath                := aGitIni;
  FModelInternet.GitIni  := aGitIni;
  FUpdateInfo.GitIni     := aGitIni;
end;

function TModelCheck.GitRepo(aGitRepo: String): IModelCheck;
begin
  Result                  := Self;
  FGitRepo                := aGitRepo;
  FModelInternet.GitRepo  := aGitRepo;
  FUpdateInfo.GitRepo     := aGitRepo;
end;

function TModelCheck.GitToken(aGitToken: String): IModelCheck;
begin
  Result                  := Self;
  FGitToken               := aGitToken;
  FModelInternet.GitToken := aGitToken;
  FUpdateInfo.GitToken    := aGitToken;
end;

function TModelCheck.GitUserName(aGitUserName: String): IModelCheck;
begin
  Result                      := Self;
  FGitUserName                := aGitUserName;
  FModelInternet.GitUserName  := aGitUserName;
  FUpdateInfo.GitUserName     := aGitUserName;
end;

function TModelCheck.IniKeyName(aIniKeyName: String): IModelCheck;
begin
  Result                    := Self;
  FIniKeyName               := aIniKeyName;
  FModelInternet.IniKeyName := aIniKeyName;
  FUpdateInfo.IniKeyName    := aIniKeyName;
end;

function TModelCheck.KillTaskApp(aKillTaskApp: TFileName): IModelCheck;
begin
  Result                  := Self;
  FKillTaskApp            := aKillTaskApp;
  FUpdateInfo.KillTaskApp := aKillTaskApp;
end;

class function TModelCheck.New: IModelCheck;
begin
  Result := Self.Create;
end;

function TModelCheck.PngResource(aPngResource : String): IModelCheck;
begin
  Result                  := Self;
  FPngRes                 := aPngResource;
  FUpdateInfo.PngResource := aPngResource;
end;

function TModelCheck.RootPath(aRootPath: String): IModelCheck;
begin
  Result                := Self;
  FRootPath             := aRootPath;
  FUpdateInfo.RootPath  := aRootPath;
end;

function TModelCheck.Titulo(aTitulo: String = ''): IModelCheck;
begin
  Result              := Self;
  FTitulo             := aTitulo;
  FUpdateInfo.Titulo  := aTitulo;
end;

procedure TModelCheck.UpdateCheckProc(aVersion: TFileVersion; aUpdateCheckProc: TUpdateCheckResultProc);
begin
  if FIsChecking then Exit;
  TThread.CreateAnonymousThread(
    procedure
     var
      LVersion: TFileVersion;
      LRelease: TGitHubRelease;
      LUrl, LDigest: string;
    begin
     LVersion := aVersion;
     FIsChecking := True;
       try
        if FUseReleases then
        begin
          if FModelInternet.GetLatestRelease(LRelease) then
          begin
            LVersion := LRelease.GetVersion;
            FUpdateInfo.VersionUpdate := LVersion.ToString;
            if LVersion > aVersion then
            begin
              if FModelInternet.GetReleaseAssetUrl(LRelease, FUpdateInfo.ReleaseAssetName, LUrl, LDigest, FUpdateInfo.AssetType) then
              begin
                FUpdateInfo.DownloadUrl     := LUrl;
                FUpdateInfo.ExpectedSHA256  := LDigest;
                TThread.Synchronize(nil,
                 procedure
                  begin
                    aUpdateCheckProc(True, LVersion);
                  end);
              end
              else
                TThread.Synchronize(nil, procedure begin aUpdateCheckProc(False, LVersion); end);
            end
            else
              TThread.Synchronize(nil, procedure begin aUpdateCheckProc(False, LVersion); end);
          end
          else
            TThread.Synchronize(nil, procedure begin aUpdateCheckProc(False, LVersion); end);
        end
        else
        begin
          if FModelInternet.GetVersionUpdate(LVersion) then
            begin
              TThread.Synchronize(nil,
               procedure
                begin
                  if LVersion > aVersion then
                    aUpdateCheckProc(True, LVersion) else
                    aUpdateCheckProc(False, LVersion);
                end);
            end;
        end;
       finally
         FIsChecking := False;
       end;
     end).Start;
end;
function TModelCheck.UpdateInfo: TUpdateInfo;
begin
  Result := FUpdateInfo;
end;

function TModelCheck.ActualVersion(aActualVersion : TFileVersion): IModelCheck;
begin
  Result                    := Self;
  FVersionAtual             := aActualVersion;
  FUpdateInfo.ActualVersion := aActualVersion;
end;


function TModelCheck.UseReleases(aValue: Boolean = False): IModelCheck;
begin
  Result := Self;
  FUseReleases := aValue;
  FUpdateInfo.UseReleases := aValue;
end;

function TModelCheck.RequireAssetHash(aValue: Boolean = False): IModelCheck;
begin
  Result := Self;
  FRequireAssetHash := aValue;
  FUpdateInfo.RequireAssetHash := aValue;
end;

function TModelCheck.ReleaseAssetName(aName: string): IModelCheck;
begin
  Result := Self;
  FReleaseAssetName := aName;
  FUpdateInfo.ReleaseAssetName := aName;
end;

function TModelCheck.VerifyExtractedFiles(aValue: Boolean = False): IModelCheck;
begin
  Result := Self;
  FVerifyExtractedFiles := aValue;
  FUpdateInfo.VerifyExtractedFiles := aValue;
end;

function TModelCheck.AssetType(aValue: TAssetType = TAssetType.atAuto): IModelCheck;
begin
  Result := Self;
  FAssetType := aValue;
  FUpdateInfo.AssetType := aValue;
end;

end.
