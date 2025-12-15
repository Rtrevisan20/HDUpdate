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
unit HDUpdateCore.Types;

{$SCOPEDENUMS ON}
interface

uses
  System.Classes,
  System.SysUtils;

type
  TUpdateState = (Waiting, Downloading, Unpacking, Done);
  TStringArray = array of string;
  TFileVersion = record
  public
    Major   : Word;
    Minor   : Word;
    Release : Word;
    Build   : Word;
    class operator Equal(             L, R: TFileVersion): Boolean; // =
    class operator NotEqual(          L, R: TFileVersion): Boolean; // <>
    class operator GreaterThan(       L, R: TFileVersion): Boolean; // >
    class operator GreaterThanOrEqual(L, R: TFileVersion): Boolean; // >=
    class operator LessThan(          L, R: TFileVersion): Boolean; // <
    class operator LessThanOrEqual(   L, R: TFileVersion): Boolean; // <=
    constructor Create(VersionStr: string);
{$IFDEF MSWINDOWS}
    constructor CreateForFile(FileName: TFileName);
{$ENDIF}
    function ToString: string;
  end;

  TUpdateInfo = record
    // Main
    ExtractNames  : TStringArray; //Nome do exexutavel a ser extraido, ou parametro &ALL para extrair tudo..
    IniKeyName    : string;
    GitUserName   : string;
    GitRepo       : string;
    GitPath       : string;
    GitAuth       : boolean;
    GitToken      : string;
    ActualVersion : TFileVersion;
    // Optional
    RootPath      : string;
    Titulo        : string;
    PngRes        : string;
  end;

{$IFDEF MSWINDOWS}
function GetFileVersion(FileName: string; out Version: TFileVersion): Boolean;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses WinApi.Windows;
{$ENDIF}


{$IFDEF MSWINDOWS}
function GetFileVersion(FileName: string; out Version: TFileVersion): Boolean;
var
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  FI: PVSFixedFileInfo;
  VerSize: DWORD;
begin
  Result := False;
  UniqueString(FileName);
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
        begin
          Version.Major   := HiWord(FI.dwFileVersionMS);
          Version.Minor   := LoWord(FI.dwFileVersionMS);
          Version.Release := HiWord(FI.dwFileVersionLS);
          Version.Build   := LoWord(FI.dwFileVersionLS);
          Result          := True;
        end;
    finally
      FreeMem(VerBuf);
    end;
  end;
end;
{$ENDIF}

{ TFileVersion }

constructor TFileVersion.Create(VersionStr: string);
var
  A: TArray<string>;
begin
  Major   := 0;
  Minor   := 0;
  Release := 0;
  Build   := 0;
  A := VersionStr.Split(['.']);
  try
    if High(A) >= 0 then Major   := A[0].Trim.ToInteger;
    if High(A) >= 1 then Minor   := A[1].Trim.ToInteger;
    if High(A) >= 2 then Release := A[2].Trim.ToInteger;
    if High(A) >= 3 then Build   := A[3].Trim.ToInteger;
  except
    on EConvertError do;
  end;
end;

{$IFDEF MSWINDOWS}
constructor TFileVersion.CreateForFile(FileName: TFileName);
begin
  Self := Default (TFileVersion);
  GetFileVersion(FileName, Self);
end;
{$ENDIF}

class operator TFileVersion.Equal(L, R: TFileVersion): Boolean;
begin
  Result :=
    (L.Major    = R.Major)   and
    (L.Minor    = R.Minor)   and
    (L.Release  = R.Release) and
    (L.Build    = R.Build);
end;

class operator TFileVersion.GreaterThan(L, R: TFileVersion): Boolean;
begin
  Result := R < L;
end;

class operator TFileVersion.GreaterThanOrEqual(L, R: TFileVersion): Boolean;
begin
  Result := R <= L;
end;

class operator TFileVersion.LessThan(L, R: TFileVersion): Boolean;
begin
  Result := False;
  // Major
  if L.Major > R.Major then Exit(False);
  if L.Major < R.Major then Exit(True);
  // Minor
  if L.Minor > R.Minor then Exit(False);
  if L.Minor < R.Minor then Exit(True);
  // Release
  if L.Release > R.Release then Exit(False);
  if L.Release < R.Release then Exit(True);
  // Build
  if L.Build > R.Build then Exit(False);
  if L.Build < R.Build then Exit(True);
end;

class operator TFileVersion.LessThanOrEqual(L, R: TFileVersion): Boolean;
begin
  Result := (L < R) or (L = R);
end;

class operator TFileVersion.NotEqual(L, R: TFileVersion): Boolean;
begin
  Result := not(L = R);
end;

function TFileVersion.ToString: string;
begin
  Result := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
end;

end.
