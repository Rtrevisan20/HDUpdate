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
unit HDUpdate.Language.US;

interface

uses
  HDUpdate.Language.Interfaces,
  System.Classes,
  System.IniFiles,
  System.SysUtils;

type
  TMessageConstsUS = class(TInterfacedObject, IMessageConsts)
  private
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IMessageConsts;
    function WaitingStatus: string;
    function DownloadingStatus: string;
    function RenamingFilesStatus: string;
    function UnpackingStatus: string;
    function DoneStatus: string;
    function ConnectionError: string;
    function DownloadError: string;
    function CorruptedFilesError: string;
    function DoneMessage: string;
    function DoneMessageRestart : string;
    function Version: string;
    function MsgTitle: string;
    function MsgQuestion: string;
    function MsgBodyLastVersion: string;
    function MsgBodyUpdateVersion : string;
  end;

implementation

function TMessageConstsUS.ConnectionError: string;
begin
  Result := 'Connection Error, Please Check Your Internet Connection, Try Again?';
end;

function TMessageConstsUS.CorruptedFilesError: string;
begin
  Result := 'Corrupted Files, Try Again?';
end;

constructor TMessageConstsUS.Create;
begin
end;

destructor TMessageConstsUS.Destroy;
begin
  inherited;
end;

function TMessageConstsUS.DoneMessage: string;
begin
  Result := 'Successful! Please Restart Application';
end;

function TMessageConstsUS.DoneMessageRestart: string;
begin
  Result := 'Successful! The app will be restarted';
end;

function TMessageConstsUS.DoneStatus: string;
begin
  Result := 'Done!';
end;

function TMessageConstsUS.DownloadError: string;
begin
  Result := 'Download Error, Try Again?';
end;

function TMessageConstsUS.DownloadingStatus: string;
begin
  Result := 'Downloading...';
end;

function TMessageConstsUS.MsgBodyLastVersion: string;
begin
  Result := 'System is in the latest version. ';
end;

function TMessageConstsUS.MsgBodyUpdateVersion: string;
begin
  Result := 'Update available. ';
end;

function TMessageConstsUS.MsgQuestion: string;
begin
  Result := 'Do you want to update?'
end;

function TMessageConstsUS.MsgTitle: string;
begin
  Result := 'System update';
end;

class function TMessageConstsUS.New: IMessageConsts;
begin
  Result := Self.Create;
end;

function TMessageConstsUS.RenamingFilesStatus: string;
begin
  Result := 'Renaming Files...';
end;

function TMessageConstsUS.UnpackingStatus: string;
begin
  Result := 'Unpacking...';
end;

function TMessageConstsUS.Version: string;
begin
  Result := 'Version %s';
end;

function TMessageConstsUS.WaitingStatus: string;
begin
  Result := 'Waiting...';
end;

end.
