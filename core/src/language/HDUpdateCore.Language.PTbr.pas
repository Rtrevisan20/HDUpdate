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
unit HDUpdateCore.Language.PTbr;

interface

uses
  HDUpdateCore.Language.Interfaces,
  System.Classes,
  System.IniFiles,
  System.SysUtils;

type
  TMessageConstsPTbr = class(TInterfacedObject, IMessageConsts)
  private
  public
    constructor Create;
    destructor Destroy; override;
    class function New            : IMessageConsts;
    function WaitingStatus        : string;
    function DownloadingStatus    : string;
    function RenamingFilesStatus  : string;
    function UnpackingStatus      : string;
    function DoneStatus           : string;
    function ConnectionError      : string;
    function DownloadError        : string;
    function CorruptedFilesError  : string;
    function DoneMessage          : string;
    function DoneMessageRestart   : string;
    function Version              : string;
    function MsgTitle             : string;
    function MsgQuestion          : string;
    function MsgBodyLastVersion   : string;
    function MsgBodyUpdateVersion : string;
  end;

implementation

function TMessageConstsPTbr.ConnectionError: string;
begin
  Result := 'Erro na conexão, cheque a sua conexão com a internet. Tentar novamente?';
end;

function TMessageConstsPTbr.CorruptedFilesError: string;
begin
  Result := 'Arquivos corrompidos. Tentar novamente?';
end;

constructor TMessageConstsPTbr.Create;
begin
end;

destructor TMessageConstsPTbr.Destroy;
begin
  inherited;
end;

function TMessageConstsPTbr.DoneMessage: string;
begin
  Result := 'Atualização bem-sucedida! Por favor, reinicie o aplicativo.';
end;

function TMessageConstsPTbr.DoneMessageRestart: string;
begin
  Result := 'Atualização bem-sucedida! O aplicativo será reiniciado.';
end;

function TMessageConstsPTbr.DoneStatus: string;
begin
  Result := 'Feito!';
end;

function TMessageConstsPTbr.DownloadError: string;
begin
  Result := 'Erro no Download. Tentar novamente?';
end;

function TMessageConstsPTbr.DownloadingStatus: string;
begin
  Result := 'Downloading...';
end;

function TMessageConstsPTbr.MsgBodyLastVersion: string;
begin
  Result := 'Sistema está na ultima versão. ';
end;

function TMessageConstsPTbr.MsgBodyUpdateVersion: string;
begin
  Result := 'Atualização disponível. ';
end;

function TMessageConstsPTbr.MsgQuestion: string;
begin
  Result := 'Deseja atualizar?'
end;

function TMessageConstsPTbr.MsgTitle: string;
begin
  Result := 'Atualização do sistema';
end;

class function TMessageConstsPTbr.New: IMessageConsts;
begin
  Result := Self.Create;
end;

function TMessageConstsPTbr.RenamingFilesStatus: string;
begin
  Result := 'Renomeando arquivos...';
end;

function TMessageConstsPTbr.UnpackingStatus: string;
begin
  Result := 'Desempacotando...';
end;

function TMessageConstsPTbr.Version: string;
begin
  Result := 'Versão %s';
end;

function TMessageConstsPTbr.WaitingStatus: string;
begin
  Result := 'Aguardando...';
end;

end.
