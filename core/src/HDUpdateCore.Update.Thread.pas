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
unit HDUpdateCore.Update.Thread;

interface

uses
  HDUpdateCore.Interfaces,
  HDUpdateCore.Types,
  HDUpdateCore.Updater,

  System.Classes,
  System.SysUtils;

type
  TUpdateThread = class(TThread)
  class var IsUpdating: Boolean;
  private
    class function IsDone: Boolean; static;
  protected
    UpdateInfo      : TUpdateInfo;
    IsUpdateFromFile: Boolean;
    FileName        : string;
    procedure Execute; override;
    procedure Work; virtual; abstract;
    function  CreateModel(View: IUpdateView): TUpdater; virtual;
    procedure Sync(Proc: TThreadProcedure);
    procedure Prepare; virtual;
    procedure Start;
  public
    constructor Create(UpdateInfo: TUpdateInfo);
    procedure   Update;
    procedure   UpdateFromFile(FileName: string);
  end;

implementation

constructor TUpdateThread.Create(UpdateInfo: TUpdateInfo);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  Self.UpdateInfo := UpdateInfo;
end;

function TUpdateThread.CreateModel(View: IUpdateView): TUpdater;
begin
  Result := TUpdater.Create(View, UpdateInfo);
end;

procedure TUpdateThread.Execute;
begin
  inherited;
  if IsUpdating then Exit;
  IsUpdating := True;
   try
    Work;
   finally
    IsUpdating := False;
   end;
end;

class function TUpdateThread.IsDone: Boolean;
begin
  Result := not IsUpdating;
end;

procedure TUpdateThread.Prepare;
begin
  // Create view and others
end;

procedure TUpdateThread.Start;
begin
  Prepare;
  inherited Start;
end;

procedure TUpdateThread.Sync(Proc: TThreadProcedure);
begin
  TThread.Synchronize(nil, Proc);
end;

procedure TUpdateThread.Update;
begin
  Start;
end;

procedure TUpdateThread.UpdateFromFile(FileName: string);
begin
  IsUpdateFromFile := True;
  Self.FileName := FileName;
  Start;
end;

initialization
  AddTerminateProc(TUpdateThread.IsDone);

finalization

end.
