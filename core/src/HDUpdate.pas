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
unit HDUpdate;

interface

uses
  HDUpdate.Core.Interfaces,
  HDUpdate.Core.Types,
  HDUpdate.Language.Interfaces,
  HDMessageDlg.Interfaces,
  HDMessageDlg,
  System.SysUtils;

type
  IHDUpdate = interface
    ['{FDBCC0E2-D4BA-49CF-86AE-1FBB55341C1D}']
    function ActualVersion        (aActualVersion : string)           : IHDUpdate;
    function GitAuth              (aGitAuth       : Boolean = False)  : IHDUpdate;
    function IniKeyName           (aIniKeyName    : String)           : IHDUpdate;
    function GitToken             (aGitToken      : String)           : IHDUpdate;
    function GitRepo              (aGitRepo       : String)           : IHDUpdate;
    function GitUserName          (aGitUserName   : String)           : IHDUpdate;
    function GitIni               (aGitIni        : String)           : IHDUpdate;
    function RootPath             (aRootPath      : String)           : IHDUpdate;
    function Titulo               (aTitulo        : String = '')      : IHDUpdate;
    function PngResource          (aPngResource   : String)           : IHDUpdate;
    function ExeUpdateApp         (aValue         : string = 'Update.exe'): IHDUpdate;
    function ExtractNames         (aExtractNames  : TStringArray)     : IHDUpdate;
    function KillTaskApp          (aKillApp       : TFileName)        : IHDUpdate;
    function UseReleases          (aValue         : Boolean = False)  : IHDUpdate;
    function RequireAssetHash     (aValue         : Boolean = False)  : IHDUpdate;
    function ReleaseAssetName     (aName          : string)           : IHDUpdate;
    function Language             (const ALanguage: string)           : IHDUpdate;
    function VerifyExtractedFiles (aValue         : Boolean = False)  : IHDUpdate;
    function AssetType            (aValue : TAssetType = TAssetType.atAuto): IHDUpdate;

    (*================================================================================*)
    function GetVersionUpdate                                 : string;
    function GetUpdate                                        : boolean;
    procedure ThreadUpdate;
    procedure Standalone;
    procedure UpdateNow;
  end;

  THDUpdate = class(TInterfacedObject, IHDUpdate)
  private
    FIniKeyName           : String;
    FGitToken             : String;
    FGitRepo              : String;
    FGitUserName          : String;
    FGitPath              : String;
    FRootPath             : String;
    FTitulo               : String;
    FPngRes               : String;
    FGitAuth              : Boolean;
    FExtractNames         : TStringArray;
    FActualVersion        : string;
    FKillApp              : TFileName;
    FExeUpdateApp         : string;
    FUseReleases          : Boolean;
    FRequireAssetHash     : Boolean;
    FReleaseAssetName     : string;
    FAssetType            : TAssetType;
    FLanguage             : string;
    FVerifyExtractedFiles : Boolean;
    FModelCheck           : IModelCheck;
    FFactoryConsts        : IFactoryConsts;
    FMessages             : IMessageConsts;
    MSG                   : iHDMessageDlg;
    procedure UpdateProc(UpdateAviable: Boolean; Version: TFileVersion);
    procedure CheckStandalone(UpdateAviable: Boolean; Version: TFileVersion);
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IHDUpdate;
    function ActualVersion        (aActualVersion : string)           : IHDUpdate;
    function GitAuth              (aGitAuth       : Boolean = False)  : IHDUpdate;
    function IniKeyName           (aIniKeyName    : String)           : IHDUpdate;
    function GitToken             (aGitToken      : String)           : IHDUpdate;
    function GitRepo              (aGitRepo       : String)           : IHDUpdate;
    function GitUserName          (aGitUserName   : String)           : IHDUpdate;
    function GitIni               (aGitIni        : String)           : IHDUpdate;
    function RootPath             (aRootPath      : String)           : IHDUpdate;
    function Titulo               (aTitulo        : String = '')      : IHDUpdate;
    function PngResource          (aPngResource   : String)           : IHDUpdate;
    function ExeUpdateApp         (aValue         : string = 'Update.exe'): IHDUpdate;
    function ExtractNames         (aExtractNames  : TStringArray)     : IHDUpdate;
    function KillTaskApp          (aKillApp       : TFileName)        : IHDUpdate;
    function UseReleases          (aValue         : Boolean = False)  : IHDUpdate;
    function RequireAssetHash     (aValue         : Boolean = False)  : IHDUpdate;
    function ReleaseAssetName     (aName          : string)           : IHDUpdate;
    function Language             (const ALanguage: string)           : IHDUpdate;
    function VerifyExtractedFiles (aValue         : Boolean = False)  : IHDUpdate;
    function AssetType            (aValue : TAssetType = TAssetType.atAuto): IHDUpdate;


    function GetVersionUpdate                                         : string;
    function GetUpdate                                                : boolean;
    procedure UpdateNow;
    procedure ThreadUpdate;
    procedure Standalone;
  end;

var
  GlobalUpdate : IHDUpdate;

implementation

uses
  HDUpdate.Core.Check,
  HDUpdate.Core.Utils,
  HDUpdate.Language.Consts.Factory,
  HDUpdate.View.Utils;

function THDUpdate.ActualVersion(aActualVersion: string): IHDUpdate;
begin
  Result := Self;
  FActualVersion := aActualVersion;
  FModelCheck.ActualVersion(TFileVersion.Create(aActualVersion));
end;

procedure THDUpdate.UpdateProc(UpdateAviable: Boolean; Version: TFileVersion);
begin
  MSG     := THDMessageDlg.New;
  FMessages := FFactoryConsts.Consts;

  if UpdateAviable then
   begin
    if
     MSG.MsgTitle(FMessages.MsgTitle)
      .MsgQuestion(FMessages.MsgQuestion)
      .MsgBody(Format(FMessages.MsgBodyUpdateVersion + FMessages.Version, [Version.ToString]))
      .MsgIcon(TiQuestion)
      .MsgType(TyQuestion)
      .DisplayQuestion then
         HDUpdate.View.Utils.FMXUpdate(FModelCheck.UpdateInfo);
   end else
    MSG.MsgTitle(FMessages.MsgTitle)
     .MsgQuestion('')
     .MsgBody(Format(FMessages.MsgBodyLastVersion + FMessages.Version, [Version.ToString]))
     .MsgIcon(TiMessage)
     .MsgType(TyOK)
     .DisplayMessage;
end;

procedure THDUpdate.CheckStandalone(UpdateAviable: Boolean; Version: TFileVersion);
begin
  MSG     := THDMessageDlg.New;
  FMessages := FFactoryConsts.Consts;

  if UpdateAviable then
  begin
  if
   MSG.MsgTitle(FMessages.MsgTitle)
    .MsgQuestion(FMessages.MsgQuestion)
    .MsgBody(Format(FMessages.MsgBodyUpdateVersion + FMessages.Version, [Version.ToString]))
    .MsgIcon(TiQuestion)
    .MsgType(TyQuestion)
    .DisplayQuestion
  then
  begin
   LaunchUpdateApp(FExeUpdateApp);
   if not SameText(ExtractFileName(FKillApp), ExtractFileName(FExeUpdateApp)) then
     Killtask(FKillApp);
  end;
  end else
  MSG.MsgTitle(FMessages.MsgTitle)
   .MsgQuestion('')
   .MsgBody(Format(FMessages.MsgBodyLastVersion + FMessages.Version, [Version.ToString]))
   .MsgIcon(TiMessage)
   .MsgType(TyOK)
   .DisplayMessage;
end;

constructor THDUpdate.Create;
begin
  FModelCheck := TModelCheck.Create;
  FFactoryConsts := TFactoryConsts.Global;   // instancia compartilhada: o .Language() vale para view/updater
end;

destructor THDUpdate.Destroy;
begin

  inherited;
end;

function THDUpdate.ExeUpdateApp(aValue: string): IHDUpdate;
begin
  Result        := Self;
  FExeUpdateApp := aValue;
  FModelCheck.ExeUpdateApp(aValue);
end;

function THDUpdate.ExtractNames(aExtractNames: TStringArray): IHDUpdate;
begin
  Result := Self;
  FExtractNames := aExtractNames;
  FModelCheck.ExtractNames(aExtractNames);
end;

function THDUpdate.GetUpdate: boolean;
begin
  Result := FModelCheck.CheckUpdate;
end;

function THDUpdate.GetVersionUpdate: string;
begin
  Result := FModelCheck.GetVersionUpdate.ToString;
end;

function THDUpdate.GitAuth(aGitAuth: Boolean = False): IHDUpdate;
begin
  Result    := Self;
  FGitAuth  := aGitAuth;
  FModelCheck.GitAuth(aGitAuth);
end;

function THDUpdate.GitIni(aGitIni : String) : IHDUpdate;
begin
  Result    := Self;
  FGitPath  := aGitIni;
  FModelCheck.GitIni(aGitIni);
end;

function THDUpdate.GitRepo(aGitRepo: String): IHDUpdate;
begin
  Result    := Self;
  FGitRepo  := aGitRepo;
  FModelCheck.GitRepo(aGitRepo);
end;

function THDUpdate.GitToken(aGitToken: String): IHDUpdate;
begin
  Result    := Self;
  FGitToken := aGitToken;
  FModelCheck.GitToken(aGitToken);
end;

function THDUpdate.GitUserName(aGitUserName: String): IHDUpdate;
begin
  Result        := Self;
  FGitUserName  := aGitUserName;
  FModelCheck.GitUserName(aGitUserName);
end;

function THDUpdate.IniKeyName(aIniKeyName: String): IHDUpdate;
begin
  Result      := Self;
  FIniKeyName := aIniKeyName;
  FModelCheck.IniKeyName(aIniKeyName);
end;

function THDUpdate.KillTaskApp(aKillApp: TFileName): IHDUpdate;
begin
  Result := Self;
  FKillApp := aKillApp;
  FModelCheck.KillTaskApp(aKillApp);
end;

class function THDUpdate.New: IHDUpdate;
begin
  Result := Self.Create;
end;

function THDUpdate.PngResource(aPngResource: String): IHDUpdate;
begin
  Result  := Self;
  FPngRes := aPngResource;
  FModelCheck.PngResource(aPngResource);
end;

function THDUpdate.RootPath(aRootPath: String): IHDUpdate;
begin
  Result    := Self;
  FRootPath := aRootPath;
  FModelCheck.RootPath(aRootPath);
end;

procedure THDUpdate.Standalone;
begin
  FModelCheck.UpdateCheckProc(TFileVersion.Create(FActualVersion), CheckStandalone);
end;

procedure THDUpdate.ThreadUpdate;
begin
  HDUpdate.View.Utils.FMXUpdate(FModelCheck.UpdateInfo);
end;

function THDUpdate.Titulo(aTitulo: String = ''): IHDUpdate;
begin
  Result  := Self;
  FTitulo := aTitulo;
  FModelCheck.Titulo(aTitulo);
end;

procedure THDUpdate.UpdateNow;
begin
  FModelCheck.UpdateCheckProc(TFileVersion.Create(FActualVersion), UpdateProc);
end;

function THDUpdate.UseReleases(aValue: Boolean = False): IHDUpdate;
begin
  Result := Self;
  FUseReleases := aValue;
  FModelCheck.UseReleases(aValue);
end;

function THDUpdate.RequireAssetHash(aValue: Boolean = False): IHDUpdate;
begin
  Result := Self;
  FRequireAssetHash := aValue;
  FModelCheck.RequireAssetHash(aValue);
end;

function THDUpdate.ReleaseAssetName(aName: string): IHDUpdate;
begin
  Result := Self;
  FReleaseAssetName := aName;
  FModelCheck.ReleaseAssetName(aName);
end;

function THDUpdate.AssetType(aValue: TAssetType = TAssetType.atAuto): IHDUpdate;
begin
  Result := Self;
  FAssetType := aValue;
  FModelCheck.AssetType(aValue);
end;

function THDUpdate.Language(const ALanguage: string): IHDUpdate;
begin
  Result := Self;
  FLanguage := ALanguage;
  if not Assigned(FFactoryConsts) then
    FFactoryConsts := TFactoryConsts.Global;

  if Assigned(FFactoryConsts) then
    FFactoryConsts.SetLanguage(ALanguage);
end;

function THDUpdate.VerifyExtractedFiles(aValue: Boolean = False): IHDUpdate;
begin
  Result := Self;
  FVerifyExtractedFiles := aValue;
  FModelCheck.VerifyExtractedFiles(aValue);
end;

initialization
  GlobalUpdate := THDUpdate.New;

end.