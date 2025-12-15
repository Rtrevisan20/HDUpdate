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
unit HDUpdateCore.Language.Interfaces;

interface

type
  IMessageConsts = interface
    ['{696CF212-668F-45F1-A92B-968DFF536C89}']
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

  IFactoryConsts = interface
    ['{1603CA30-E7C8-4997-A627-7A87CBFA7E51}']
    function Consts: IMessageConsts;
  end;

implementation

end.
