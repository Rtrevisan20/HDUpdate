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
unit HDUpdate.Internet.HttpClientHook;

interface

uses
  IdComponent,
  HDUpdate.Core.Commons,
  HDUpdate.Internet.Interfaces,
  System.Net.HttpClient,
  System.SysUtils;

type
  THttpClientHook = class(TInterfacedObject, IHttpClientHook)
  private
    FOnResiveData : TReceiveDataEventRef;
    FIsAbort      : boolean;
    procedure ReceiveDataProc(const Sender: TObject;
                              aContentLength: Int64;
                              aReadCount: Int64;
                              var aAbort: Boolean);
    procedure ReceiveWorkEventID(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IHttpClientHook;
    function ResiveDataProc   : TReceiveDataEvent; overload;
    function ResiveWorkEventId: TWorkEvent; overload;
    function ResiveDataProc   (OnResiveData: TReceiveDataEventRef): IHttpClientHook; overload;
    function ResiveWorkEventId(OnResiveData: TReceiveDataEventRef): IHttpClientHook; overload;
    function IsAbort          (AAbort : boolean): IHttpClientHook;
  end;

implementation

constructor THttpClientHook.Create;
begin
end;

destructor THttpClientHook.Destroy;
begin
  inherited;
end;

function THttpClientHook.IsAbort(AAbort: boolean): IHttpClientHook;
begin
  Result   := Self;
  FIsAbort := AAbort;
end;

class function THttpClientHook.New: IHttpClientHook;
begin
  Result := Self.Create;
end;

procedure THttpClientHook.ReceiveDataProc(const Sender: TObject; AContentLength,
  AReadCount: Int64; var AAbort: Boolean);
begin
  if Assigned(FOnResiveData) then
    FOnResiveData(AContentLength, AReadCount, AAbort);
end;

procedure THttpClientHook.ReceiveWorkEventID(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
  if Assigned(FOnResiveData) then
    FOnResiveData(AWorkCount, AWorkCount, FIsAbort);
end;

function THttpClientHook.ResiveDataProc(OnResiveData: TReceiveDataEventRef): IHttpClientHook;
begin
  Result        := Self;
  FOnResiveData := OnResiveData;
end;

function THttpClientHook.ResiveWorkEventId(OnResiveData: TReceiveDataEventRef): IHttpClientHook;
begin
  Result        := Self;
  FOnResiveData := OnResiveData;
end;

function THttpClientHook.ResiveWorkEventId: TWorkEvent;
begin
  Result := ReceiveWorkEventID;
end;

function THttpClientHook.ResiveDataProc: TReceiveDataEvent;
begin
  Result := ReceiveDataProc;
end;

end.
