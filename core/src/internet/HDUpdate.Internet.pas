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
unit HDUpdate.Internet;

interface

uses
  HDUpdate.Core.Commons,
  HDUpdate.Internet.Interfaces,
  HDUpdate.Core.Types,
  System.Classes,
  System.IniFiles,
  System.Net.HttpClient,
  System.Net.UrlClient,
  System.SysUtils,
  System.JSON;

type
  TModelInternet = class(TInterfacedObject, IModelInternet)
  private
    FIniKeyName   : String;
    FGitAuth      : Boolean;
    FGitToken     : String;
    FGitRepo      : String;
    FGitUserName  : String;
    FGitIni       : String;
    FIni          : TMemIniFile;
    FVersionAtual : string;
    function GetIniFile : TMemIniFile; overload;
    function GetStream  : TMemoryStream; overload;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IModelInternet;

    function GetVersionUpdate(out AVersion: TFileVersion): boolean;
    function GetUpdateURL: string;
    function DowloadFile(aDownURL, APath: string; ADownloadProgress: TReceiveDataEventRef): Boolean;

    function  UpdateLog                  : string;
    procedure SetGitAuth    (aAuth       : Boolean = False);
    procedure SetIniKeyName (aKeyName    : String);
    procedure SetGitToken   (aToken      : String);
    procedure SetGitRepo    (aRepository : String);
    procedure SetGitUserName(aUserName   : String);
    procedure SetGitIni     (aGitIni       : String);
    procedure SetVersion    (aVersion    : String);

    end;

var
  ProxySettings: TProxySettings;

implementation

uses
  HDUpdate.Internet.HttpClientHook,
  HDUpdate.Core.Utils;

constructor TModelInternet.Create;
begin

end;

destructor TModelInternet.Destroy;
begin
  if Assigned(FIni) then
    FIni.Free;
  inherited;
end;

{$HINTS OFF}
function TModelInternet.DowloadFile(aDownURL, APath: string; ADownloadProgress: TReceiveDataEventRef): Boolean;
var
  FHttp     : THttpClient;
  FStream   : TStream;
  FHook     : IHttpClientHook;
  FResponse : IHTTPResponse;
  FTime     : Cardinal;
begin
  Result  := False;
  FTime   := 0;
  FHook   := THttpClientHook.New;
  FHook.ResiveDataProc(
   procedure(ALength, AProgress: Int64; var AAbort: Boolean)
    begin
      if (FTime < TThread.GetTickCount) or (ALength = AProgress) then
      begin
        ADownloadProgress(ALength, AProgress, AAbort);
        FTime := TThread.GetTickCount + 1000 div 30; // 30 per second
      end;
    end);
  FStream := TFileStream.Create(APath, fmCreate);
    try
      FHttp := THttpClient.Create;
      FHttp.ProxySettings := ProxySettings;
      if FGitAuth then
        FHttp.CustHeaders.Add('Authorization', 'Bearer ' + FGitToken);
      FHttp.OnReceiveData := FHook.ResiveDataProc;
        try
          try
            FResponse := FHttp.Get(aDownURL, FStream);
            Result := (FResponse.StatusCode <= 299) and (FResponse.ContentLength = FStream.Size);
          except
            on ENetHTTPException do
              Result := False;
          end;
        finally
          FHttp.Free;
        end;
    finally
      FStream.Free;
    end;
end;
{$HINTS ON}

function TModelInternet.GetStream: TMemoryStream;
var
  FHttp   : THttpClient;
  FStream : TMemoryStream;
  FUrl    : string;
  FReader : TStreamReader;
  FJson   : TJSONObject;
  FRes    : IHTTPResponse;
begin
  Result  := nil;
  FJson   := nil;
  FStream := TMemoryStream.Create;
  try
    FUrl  := cBASEURL+FGitUserName+'/'+FGitRepo+cCONTENTS+FGitIni;
    FHttp := THttpClient.Create;
    FReader := TStreamReader.Create(FStream);
    try
      if FGitAuth then // Se for repositorio privado precisa do token
        FHttp.CustHeaders.Add('Authorization', 'Bearer ' + FGitToken);

      FHttp.ProxySettings := ProxySettings;
      FRes := FHttp.Get(FUrl, FStream);
      case FRes.StatusCode of
        200:
         begin
          FJson   := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(FReader.ReadToEnd), 0) as TJSONObject;
          if FJson = nil then Exit;
          if FHttp.Get(FJson.GetValue<string>(cDOWNLOAD_URL), FStream).StatusCode <> 200 then
            FreeAndNil(FStream);

          Result := FStream;
         end;
       else
        raise Exception.Create('Não foi possivel conectar ao servidor!');
      end;
    finally
      FHttp.Free;
      FReader.Free;
      FJson.Free;
    end;
  except
    FreeAndNil(FStream);
  end;
end;

function TModelInternet.GetUpdateURL: string;
var
  FPathDownload : string;
  FHttp   : THttpClient;
  FStream : TMemoryStream;
  FUrl    : string;
  FReader : TStreamReader;
  FJson   : TJSONObject;
  FRes    : IHTTPResponse;
begin
  FJson := nil;

  if not Assigned(FIni) then
    FIni := GetIniFile;

  FPathDownload := FIni.ReadString(FIniKeyName, 'Download', '');
  FUrl          := cBASEURL+FGitUserName+'/'+FGitRepo+cCONTENTS+FPathDownload;
  FHttp         := THttpClient.Create;
  FStream       := TMemoryStream.Create;
  FReader       := TStreamReader.Create(FStream);
  try
    if FGitAuth then // Se for repositorio privado precisa do token
      FHttp.CustHeaders.Add('Authorization', 'Bearer ' + FGitToken);

    FHttp.ProxySettings := ProxySettings;
    FRes := FHttp.Get(FUrl, FStream);
    case FRes.StatusCode of
      200:
       begin
        FJson  := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(FReader.ReadToEnd), 0) as TJSONObject;
        if FJson = nil then Exit;
        Result := FJson.GetValue<string>(cDOWNLOAD_URL);
       end;
    end;
  finally
    FHttp.Free;
    FReader.Free;
    FStream.Free;
    FJson.Free;
  end;
end;

function TModelInternet.GetVersionUpdate(out AVersion: TFileVersion) : boolean;
begin
  Result  := False;
  if not Assigned(FIni) then
    FIni := GetIniFile;

  if FIni <> nil then
  begin
    AVersion := TFileVersion.Create(FIni.ReadString(FIniKeyName, 'Version', ''));
    if FVersionAtual < AVersion.ToString then
      Result   := True else
      Result   := False;
  end else
    AVersion := TFileVersion.Create('0.0.0.0');
end;

function TModelInternet.GetIniFile: TMemIniFile;
var
  FStream: TMemoryStream;
  FStrings: TStringList;
begin
  Result    := nil;
  FStream   := GetStream;
  if FStream = nil then Exit;
  try
    FStrings := TStringList.Create;
    try
      FStrings.LoadFromStream(FStream, TEncoding.UTF8);
      Result := TMemIniFile.Create('');
      Result.SetStrings(FStrings);
    finally
      FStrings.Free;
    end;
  finally
    FStream.Free;
  end;
end;

class function TModelInternet.New: IModelInternet;
begin
  Result := Self.Create;
end;

procedure TModelInternet.SetGitAuth(aAuth: Boolean = False);
begin
  FGitAuth := aAuth;
end;

procedure TModelInternet.SetIniKeyName(aKeyName: String);
begin
  FIniKeyName := aKeyName;
end;

procedure TModelInternet.SetVersion(aVersion: String);
begin
  FVersionAtual := aVersion;
end;

function TModelInternet.UpdateLog: string;
begin
  if not Assigned(FIni) then
    FIni := GetIniFile;

  Result := FIni.ReadString(FIniKeyName, 'Log', '');
end;

procedure TModelInternet.SetGitIni(aGitIni: String);
begin
  FGitIni := aGitIni;
end;

procedure TModelInternet.SetGitRepo(aRepository: String);
begin
  FGitRepo := aRepository;
end;

procedure TModelInternet.SetGitToken(aToken: String);
begin
  FGitToken := aToken;
end;

procedure TModelInternet.SetGitUserName(aUserName: String);
begin
  FGitUserName := aUserName;
end;

end.
