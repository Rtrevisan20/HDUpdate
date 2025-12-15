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
unit HDUpdateCore.Interfaces;

interface

uses
  IdComponent,
  HDUpdateCore.Commons,
  HDUpdateCore.Types,
  System.Net.HttpClient;

type

  IUpdateModel = interface
    ['{6C6B4485-4762-4E1E-9F49-C9F903691346}']
    procedure Cancel;
  end;

  IUpdateView = interface
    ['{D04D4A90-A5A5-49F7-A260-312F76938EAA}']
    procedure SetVersion      (const Value: string);
    procedure SetTitulo       (const Value: string);
    procedure SetStatus       (const Value: string);
    procedure SetPngRes       (const Value: string);
    procedure SetModel        (Model: IUpdateModel);
    procedure SetUpdateState  (Value: TUpdateState);
    procedure SetLog          (aLog: string);

    procedure ShowMessage     (Message: string);
    function  ShowErrorMessage(Message: string): Boolean;
    procedure Progress        (Progress, Length: Integer);
    procedure Close;
    procedure Show;
    // properties

    property Log:         string write SetLog;
    property Version:     string write SetVersion;
    property Status:      string write SetStatus;
    property Titulo:      string write SetTitulo;
    property PngRes:      string write SetPngRes;
    property Model: IUpdateModel write SetModel;
    property State: TUpdateState write SetUpdateState;
  end;

  IModelCheck = interface
    ['{83B7058C-A3CF-4B69-A82B-D45A6B04D3BA}']
    (*=================================================================*)
    procedure UpdateCheckProc(aVersion: TFileVersion; aUpdateCheckProc: TUpdateCheckResultProc);
    function  GetFileVersion       : TFileVersion;
    function  CheckUpdate          : boolean;
    (*=================================================================*)

    function ActualVersion(aActualVersion : TFileVersion): IModelCheck;
    function GitAuth      (aGitAuth       : Boolean = False): IModelCheck;
    function IniKeyName   (aIniKeyName    : String): IModelCheck;
    function GitToken     (aGitToken      : String): IModelCheck;
    function GitRepo      (aGitRepo       : String): IModelCheck;
    function GitUserName  (aGitUserName   : String): IModelCheck;
    function GitPath      (aGitPath       : String): IModelCheck;
    function RootPath     (aRootPath      : String): IModelCheck;
    function Titulo       (aTitulo        : String): IModelCheck;
    function PngRes       (aPngRes        : String): IModelCheck;
    function ExtractNames (aExtractNames  : TStringArray): IModelCheck;

    function UpdateInfo : TUpdateInfo;
  end;

implementation

end.

