unit EnvConfig;

interface

/// Le uma chave de um arquivo .env.
/// Procura em: diretorio atual, pasta do executavel e ..\..\ (padrao Win32\Debug).
function EnvValue(const AKey: string; const ADefault: string = ''): string;

/// Retorna o token do GitHub lido da chave KEY do .env.
function GetGitToken: string;

implementation

uses
  System.IOUtils,
  System.SysUtils;

function EnvFilePath: string;
var
  LCandidates: TArray<string>;
  LCandidate : string;
begin
  LCandidates := [
    TPath.Combine(GetCurrentDir, '.env'),
    TPath.Combine(ExtractFilePath(ParamStr(0)), '.env'),
    TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\.env')
  ];

  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(TPath.GetFullPath(LCandidate));

  Result := EmptyStr;
end;

function EnvValue(const AKey: string; const ADefault: string = ''): string;
var
  LRawLine : string;
  LLine    : string;
  LName    : string;
  LValue   : string;
  LPos     : Integer;
begin
  Result := ADefault;

  if EnvFilePath = EmptyStr then
    Exit;

  for LRawLine in TFile.ReadAllLines(EnvFilePath) do
  begin
    LLine := LRawLine.Trim;

    if (LLine = EmptyStr) or LLine.StartsWith('#') then
      Continue;

    LPos := LLine.IndexOf('=');
    if LPos <= 0 then
      Continue;

    LName  := LLine.Substring(0, LPos).Trim;
    LValue := LLine.Substring(LPos + 1).Trim;

    if not SameText(LName, AKey) then
      Continue;

    // aceita KEY=valor, KEY = valor; e KEY = valor entre aspas
    if LValue.EndsWith(';') then
      LValue := LValue.Substring(0, LValue.Length - 1).Trim;

    if (LValue.Length >= 2) and
       (((LValue[1] = #39) and (LValue[LValue.Length] = #39)) or
        ((LValue[1] = #34) and (LValue[LValue.Length] = #34))) then
      LValue := LValue.Substring(1, LValue.Length - 2);

    Exit(LValue);
  end;
end;

function GetGitToken: string;
begin
  Result := EnvValue('KEY', EmptyStr);
  if Result = EmptyStr then
    raise Exception.Create(
      'Token do GitHub nao encontrado no arquivo .env.' + sLineBreak +
      'Crie um .env na pasta do projeto com a linha:' + sLineBreak +
      'KEY=seu_token_aqui');
end;

end.
