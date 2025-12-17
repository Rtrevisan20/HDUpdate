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
    FGitAuth      : Boolean;
    FIniKeyName   : String;
    FGitToken     : String;
    FGitRepo      : String;
    FGitUserName  : String;
    FGitPath      : String;
    FPngRes       : String;
    FRootPath     : String;
    FTitulo       : String;
    FModelInternet: IModelInternet;
    FVersionAtual : TFileVersion;
    FExtractNames : TStringArray;
    FUpdateInfo   : TUpdateInfo;
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
    function ActualVersion(aActualVersion : TFileVersion): IModelCheck;
    function IniKeyName   (aIniKeyName    : String): IModelCheck;
    function GitUserName  (aGitUserName   : String): IModelCheck;
    function GitRepo      (aGitRepo       : String): IModelCheck;
    function GitIni       (aGitIni        : String): IModelCheck;
    function GitAuth      (aGitAuth       : Boolean = False): IModelCheck;
    function GitToken     (aGitToken      : String): IModelCheck;
    function RootPath     (aRootPath      : String): IModelCheck;
    function Titulo       (aTitulo        : String = ''): IModelCheck;
    function PngResource  (aPngResource   : String): IModelCheck;
    function ExtractNames (aExtractNames  : TStringArray): IModelCheck;

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
begin
  if FIsChecking then Exit(False);
  FIsChecking := True;
   try
    FModelInternet.GetVersionUpdate(FVersionAtual);
    if FVersionAtual < LVersion then
     Result := True else
     Result := False;
   finally
     FIsChecking := False;
   end;
end;

constructor TModelCheck.Create;
begin
  FModelInternet := TModelIternetFactory.New.Internet;
  FUpdateInfo    := Default(TUpdateInfo);
end;

destructor TModelCheck.Destroy;
begin
  inherited;
end;

function TModelCheck.ExtractNames(aExtractNames: TStringArray): IModelCheck;
begin
  Result                    := Self;
  FExtractNames             := aExtractNames;
  FUpdateInfo.ExtractNames  := aExtractNames;
end;

function TModelCheck.GetVersionUpdate: TFileVersion;
begin
  FModelInternet.GetVersionUpdate(Result);
end;

function TModelCheck.GitAuth(aGitAuth: Boolean): IModelCheck;
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

function TModelCheck.Titulo(aTitulo: String): IModelCheck;
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
    begin
     FIsChecking := True;
      try
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

end.
