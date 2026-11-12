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
unit HDUpdate.Core.Utils;

interface

uses
  System.SysUtils,
  WinApi.ShellAPI,
  WinApi.Windows,
  Winapi.TlHelp32;

  function LaunchUpdateApp   (FileName: TFileName = 'Update.exe'; RunAsAdministrator: Boolean = True): Boolean;
  function  Killtask          (ExeFileName: TFileName): Integer;
  function  NormalizeFileName (FileName: string): string;
  /// Extrai o nome do arquivo de uma URL, removendo query string (?token=...),
  /// fragmento (#...) e qualquer diretorio. Retorna '' se nao for possivel.
  function  ExtractFileNameFromUrl(const AUrl: string): string;

implementation

function ExtractFileNameFromUrl(const AUrl: string): string;
const
  CInvalidChars: TSysCharSet = ['<', '>', ':', '"', '|', '?', '*', '/'];
var
  LUrl  : string;
  LPos  : Integer;
  LChar : Char;
begin
  Result := '';
  LUrl   := AUrl.Trim;

  // Remove fragmento e query string
  LPos := LUrl.IndexOf('#');
  if LPos >= 0 then
    LUrl := LUrl.Substring(0, LPos);
  LPos := LUrl.IndexOf('?');
  if LPos >= 0 then
    LUrl := LUrl.Substring(0, LPos);

  if LUrl = '' then
    Exit;

  // Pega o trecho depois do ultimo '/' ou '\'
  LPos := LUrl.LastIndexOf('/');
  if LPos < 0 then
    LPos := LUrl.LastIndexOf('\');
  if LPos >= 0 then
    LUrl := LUrl.Substring(LPos + 1);

  // Nao aceita nome com caractere invalido (ex.: resto de path ou query)
  for LChar in LUrl do
    if CharInSet(LChar, CInvalidChars) or (LChar < #32) then
      Exit;

  Result := LUrl;
end;

function NormalizeFileName(FileName: string): string;
begin
  Result := FileName.Replace('/', PathDelim);
end;

function Killtask(ExeFileName: TFileName): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
   begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
   end;

  CloseHandle(FSnapshotHandle);
end;

function LaunchUpdateApp(FileName: TFileName; RunAsAdministrator: Boolean): Boolean;
var
  Info: TShellExecuteInfo;
begin
  if IsRelativePath(FileName) then
    FileName := ExtractFilePath(ParamStr(0)) + PathDelim + FileName;
  ZeroMemory(@Info, SizeOf(Info));
  Info.cbSize := SizeOf(Info);
  Info.Wnd := 0;
  if RunAsAdministrator then
    Info.lpVerb := 'runas';
  Info.lpFile := PChar(FileName);
  Info.lpParameters := '';
  Info.lpDirectory := PChar(ExtractFilePath(FileName));
  Info.nShow := SW_NORMAL;
  Result := ShellExecuteEx(@Info);
end;

end.
