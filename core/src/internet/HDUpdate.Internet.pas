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
  HDUpdate.Core.Types,
  HDUpdate.Internet.Interfaces,
  System.Classes,
  System.DateUtils,
  System.Hash,
  System.IniFiles,
  System.JSON,
  System.Net.HttpClient,
  System.Net.UrlClient,
  System.SysUtils;

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

    function GetURLUpdateINI: string;
    function DowloadFile(aDownURL, APath: string; ADownloadProgress: TReceiveDataEventRef): Boolean;

    function  UpdateLog                  : string;
    procedure SetGitAuth    (aAuth       : Boolean = False);
    procedure SetIniKeyName (aKeyName    : String);
    procedure SetGitToken   (aToken      : String);
    procedure SetGitRepo    (aRepository : String);
    procedure SetGitUserName(aUserName   : String);
    procedure SetGitIni     (aGitIni       : String);
    procedure SetVersion    (aVersion    : String);
    // Releases (Item 8)
    function GetLatestRelease(out ARelease: TGitHubRelease): Boolean;
    function GetReleaseAssetUrl(const ARelease: TGitHubRelease; const AAssetName: string;
                                out AUrl: string; out ADigest: string;
                                const AType: TAssetType = TAssetType.atAuto): Boolean;

    end;

var
  ProxySettings: TProxySettings;

implementation

uses
  HDUpdate.Core.Utils,
  HDUpdate.Internet.HttpClientHook,
  System.Generics.Collections;

// Retorna o JSON apenas quando o conteudo for um objeto (evita EInvalidCast em arrays)
function ParseJSONObjectSafe(const AJsonText: string): TJSONObject;
var
  LVal: TJSONValue;
begin
  Result := nil;
  LVal := TJSONObject.ParseJSONValue(AJsonText);
  try
    if LVal is TJSONObject then
      Result := TJSONObject(LVal)
    else
      LVal.Free;
  except
    LVal.Free;
  end;
end;

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
      // Item 9.4: o endpoint de asset da API exige Accept: application/octet-stream
      if aDownURL.Contains('/releases/assets/') then
        FHttp.CustHeaders.Add('Accept', 'application/octet-stream');
      FHttp.OnReceiveData := FHook.ResiveDataProc;
        try
          try
            FResponse := FHttp.Get(aDownURL, FStream);
            Result := Assigned(FResponse) and (FResponse.StatusCode >= 200) and (FResponse.StatusCode <= 299) and (FStream.Size > 0);
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

  // Item 9.4: nao deixa arquivo parcial (ex.: pagina HTML de 404) com extensao de asset
  if not Result and FileExists(APath) then
    DeleteFile(APath);
end;
{$HINTS ON}

function TModelInternet.GetStream: TMemoryStream;
var
  FHttp        : THttpClient;
  FIniStream   : TMemoryStream;
  FDownload    : TMemoryStream;
  FUrl         : string;
  FReader      : TStreamReader;
  FJson        : TJSONObject;
  FRes         : IHTTPResponse;
  LJsonText    : string;
  LDownloadUrl : string;
begin
  Result     := nil;
  FJson      := nil;
  FIniStream := TMemoryStream.Create;
  try
    try
      FUrl  := cBASEURL+FGitUserName+'/'+FGitRepo+cCONTENTS+FGitIni;
      FHttp := THttpClient.Create;
      try
        if FGitAuth then // Se for repositorio privado precisa do token
          FHttp.CustHeaders.Add('Authorization', 'Bearer ' + FGitToken);

        FHttp.ProxySettings := ProxySettings;
        FRes := FHttp.Get(FUrl, FIniStream);
        if (FRes.StatusCode < 200) or (FRes.StatusCode > 299) then
          raise Exception.Create('Não foi possível conectar ao servidor!');

        FIniStream.Position := 0;
        FReader := TStreamReader.Create(FIniStream, TEncoding.UTF8, True);
        try
          LJsonText := FReader.ReadToEnd;
        finally
          FReader.Free;
        end;

        FJson := ParseJSONObjectSafe(LJsonText);
        if FJson = nil then Exit;

        LDownloadUrl := FJson.GetValue<string>(cDOWNLOAD_URL);
        if LDownloadUrl = '' then Exit;

        FDownload := TMemoryStream.Create;
        try
          FRes := FHttp.Get(LDownloadUrl, FDownload);
          if (FRes.StatusCode >= 200) and (FRes.StatusCode <= 299) and (FDownload.Size > 0) then
          begin
            FDownload.Position := 0;
            Result    := FDownload;
            FDownload := nil; // ownership passa para Result
          end;
        finally
          FDownload.Free;
        end;
      finally
        FHttp.Free;
      end;
    except
      FreeAndNil(Result);
    end;
  finally
    FreeAndNil(FIniStream);
    FreeAndNil(FJson);
  end;
end;

function TModelInternet.GetURLUpdateINI: string;
var
  FPathDownload : string;
  FHttp         : THttpClient;
  FStream       : TMemoryStream;
  FUrl          : string;
  FReader       : TStreamReader;
  FJson         : TJSONObject;
  FRes          : IHTTPResponse;
begin
  Result := '';
  FJson  := nil;

  if not Assigned(FIni) then
    FIni := GetIniFile;

  if FIni = nil then
    Exit;

  FPathDownload := FIni.ReadString(FIniKeyName, 'Download', '');
  FUrl          := cBASEURL+FGitUserName+'/'+FGitRepo+cCONTENTS+FPathDownload;
  FHttp         := THttpClient.Create;
  FStream       := TMemoryStream.Create;
  try
    if FGitAuth then // Se for repositorio privado precisa do token
      FHttp.CustHeaders.Add('Authorization', 'Bearer ' + FGitToken);

    FHttp.ProxySettings := ProxySettings;
    FRes := FHttp.Get(FUrl, FStream);
    if (FRes.StatusCode >= 200) and (FRes.StatusCode <= 299) and (FStream.Size > 0) then
    begin
      FStream.Position := 0;
      FReader := TStreamReader.Create(FStream, TEncoding.UTF8, True);
      try
        FJson := ParseJSONObjectSafe(FReader.ReadToEnd);
      finally
        FReader.Free;
      end;
      if FJson <> nil then
        Result := FJson.GetValue<string>(cDOWNLOAD_URL);
    end;
  finally
    FHttp.Free;
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
      FStream.Position := 0;
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

  if FIni = nil then
    Exit('');

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


{ GitHub Releases (Item 8) }

const
  cRELEASES_API = '/releases/latest';

function TModelInternet.GetLatestRelease(out ARelease: TGitHubRelease): Boolean;
var
  FHttp   : THttpClient;
  FStream : TMemoryStream;
  FUrl    : string;
  FReader : TStreamReader;
  FJson   : TJSONObject;
  FRes    : IHTTPResponse;
  LAssets : TJSONArray;
  LAsset  : TJSONValue;
  i       : Integer;
begin
  Result := False;
  ARelease := Default(TGitHubRelease);
  FJson  := nil;

  FUrl := cBASEURL + FGitUserName + '/' + FGitRepo + cRELEASES_API;
  FHttp := THttpClient.Create;
  FStream := TMemoryStream.Create;
  try
    if FGitAuth then
      FHttp.CustHeaders.Add('Authorization', 'Bearer ' + FGitToken);

    FHttp.ProxySettings := ProxySettings;
    FRes := FHttp.Get(FUrl, FStream);
    if (FRes.StatusCode >= 200) and (FRes.StatusCode <= 299) and (FStream.Size > 0) then
    begin
      FStream.Position := 0;
      FReader := TStreamReader.Create(FStream, TEncoding.UTF8, True);
      try
        FJson := ParseJSONObjectSafe(FReader.ReadToEnd);
      finally
        FReader.Free;
      end;
      if FJson <> nil then
      begin
        ARelease.TagName     := FJson.GetValue<string>('tag_name', '');
        ARelease.Name        := FJson.GetValue<string>('name', '');
        ARelease.Body        := FJson.GetValue<string>('body', '');
        ARelease.Prerelease  := FJson.GetValue<Boolean>('prerelease', False);
        ARelease.Draft       := FJson.GetValue<Boolean>('draft', False);
        ARelease.PublishedAt := ISO8601ToDate(FJson.GetValue<string>('published_at', ''));

        LAssets := FJson.GetValue<TJSONArray>('assets');
        if LAssets <> nil then
        begin
          SetLength(ARelease.Assets, LAssets.Count);
          for i := 0 to LAssets.Count - 1 do
          begin
            LAsset := LAssets.Items[i];
            if LAsset is TJSONObject then
            begin
              ARelease.Assets[i].Name               := TJSONObject(LAsset).GetValue<string>('name', '');
              ARelease.Assets[i].BrowserDownloadUrl := TJSONObject(LAsset).GetValue<string>('browser_download_url', '');
              ARelease.Assets[i].DigestSHA256       := TJSONObject(LAsset).GetValue<string>('digest', '');
              ARelease.Assets[i].Size               := TJSONObject(LAsset).GetValue<Int64>('size', 0);
              // Item 9.4: repositorio privado nao aceita browser_download_url com token (404).
              // O endpoint da API com Accept: application/octet-stream responde 200.
              ARelease.Assets[i].Id := TJSONObject(LAsset).GetValue<Int64>('id', 0);
              if ARelease.Assets[i].Id > 0 then
                ARelease.Assets[i].ApiAssetUrl := Format(
                  'https://api.github.com/repos/%s/%s/releases/assets/%d',
                  [FGitUserName, FGitRepo, ARelease.Assets[i].Id]);
            end;
          end;
        end;
        Result := True;
      end;
    end;
  finally
    FHttp.Free;
    FStream.Free;
    FJson.Free;
  end;
end;

function TModelInternet.GetReleaseAssetUrl(const ARelease: TGitHubRelease; const AAssetName: string;
                                           out AUrl: string; out ADigest: string;
                                           const AType: TAssetType): Boolean;
var
  LAsset: TGitHubAsset;
begin
  Result := False;
  AUrl   := '';
  ADigest := '';

  LAsset := ARelease.FindAsset(AAssetName, AType);
  if not LAsset.IsEmpty then
  begin
    // Item 9.4: prefere o endpoint da API (token) e usa a URL web apenas como fallback
    if LAsset.ApiAssetUrl <> '' then
      AUrl := LAsset.ApiAssetUrl
    else
      AUrl := LAsset.BrowserDownloadUrl;
    ADigest  := LAsset.DigestSHA256;
    Result   := AUrl <> '';
  end;
end;

end.
