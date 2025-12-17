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
unit HDUpdate.View.Update.Thread;

interface

uses
  FMX.Forms,
  HDUpdate.Core.Update.Thread;

type
  TFmxUpdateThread = class(TUpdateThread)
  protected
    function CreateView: TCustomForm; virtual;
    procedure Work; override;
  end;

implementation

uses
  HDUpdate.Core.Interfaces,
  HDUpdate.View.Update,
  HDUpdate.Core.Updater;

function TFmxUpdateThread.CreateView: TCustomForm;
begin
  Result := TViewUpdate.Create(Application);
end;

procedure TFmxUpdateThread.Work;
var
  FModel: TUpdater;
  FView : TCustomForm;
begin
  // É necessário aguardar o início do loop principal
  while ApplicationState = TApplicationState.None do Sleep(0);
  Sync(
    procedure
     begin
      FView := CreateView;
     end);

  if Application.MainForm = nil then
    Application.MainForm := FView;
  FModel := nil;
  try
    FModel := CreateModel(FView as IUpdateView);
    if IsUpdateFromFile then
      FModel.UpdateFromFile(FileName) else
      FModel.Update;
  finally
    FModel.Free;
    if FView <> Application.MainForm then
      Sync(procedure
       begin
        FView.Free;
       end)
    else
     begin
      IsUpdating := False;
      Sync(
       procedure
        begin
         FView.Close;
        end);
     end;
  end;
end;

end.
