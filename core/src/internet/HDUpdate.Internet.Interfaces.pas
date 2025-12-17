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
unit HDUpdate.Internet.Interfaces;

interface

uses
  IdComponent,
  HDUpdate.Core.Commons,
  HDUpdate.Core.Types,
  System.Net.HttpClient;

type

  IModelInternet = interface
    ['{F2E48258-75D8-494C-8987-8D9E65538030}']
    function GetVersionUpdate(out AVersion: TFileVersion): boolean;
    function GetUpdateURL: string;

    function DowloadFile(aDownURL, APath: string; ADownloadProgress: TReceiveDataEventRef): Boolean;

    function UpdateLog : string;
    procedure SetGitAuth    (aAuth    : Boolean = False);
    procedure SetIniKeyName (aKeyName : String);
    procedure SetGitToken   (aToken   : String);
    procedure SetGitRepo    (aRepository : String);
    procedure SetGitUserName(aUserName   : String);
    procedure SetGitIni     (aGitIni     : String);
    procedure SetVersion    (aVersion    : String);

    property  VersionAtual: string  write SetVersion;
    property  GitAuth     : Boolean  write SetGitAuth;
    property  IniKeyName  : String   write SetIniKeyName;
    property  GitToken    : String   write SetGitToken;
    property  GitRepo     : String   write SetGitRepo;
    property  GitUserName : String   write SetGitUserName;
    property  GitIni      : String   write SetGitIni;
  end;

  IModelIternetFactory = interface
    ['{94A9D5A9-2D3F-4F4C-8E10-928F97DBA0E2}']
    function Internet : IModelInternet;
  end;

  IHttpClientHook = interface
    ['{BE41CA65-9E48-4726-9F79-5E488D3ACA68}']
    function ResiveDataProc: TReceiveDataEvent; overload;
    function ResiveDataProc(OnResiveData: TReceiveDataEventRef): IHttpClientHook; overload;
    function ResiveWorkEventId: TWorkEvent; overload;
    function ResiveWorkEventId(OnResiveData: TReceiveDataEventRef): IHttpClientHook; overload;
    function IsAbort(AAbort : boolean): IHttpClientHook;
  end;

implementation

end.
