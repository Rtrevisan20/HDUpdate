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
unit HDUpdateCore.Utils;

interface

uses
  System.SysUtils,
  WinApi.ShellAPI,
  WinApi.Windows,
  Winapi.TlHelp32;

  procedure LaunchUpdateApp(FileName: TFileName = 'Update.exe'; RunAsAdministrator: Boolean = True);
  function  Killtask(       ExeFileName: TFileName): Integer;
  function  NormalizeFileName(FileName: string): string;

implementation

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

procedure LaunchUpdateApp(FileName: TFileName; RunAsAdministrator: Boolean);
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
  ShellExecuteEx(@Info);
end;

end.
