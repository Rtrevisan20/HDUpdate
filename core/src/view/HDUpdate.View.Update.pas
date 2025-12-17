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
unit HDUpdate.View.Update;

interface

uses
  HDMessageDlg,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Types,
  HDMessageDlg.Interfaces,
  HDUpdate.Core.Interfaces,
  HDUpdate.Language.Interfaces,
  HDUpdate.Core.Types,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants;

type
  TViewUpdate = class(TForm, IUpdateView)
    LayoutForm          : TLayout;
    LayoutFotter        : TLayout;
    ButtonCancel        : TButton;
    LabelTurboUpdate    : TLabel;
    LayoutMain          : TLayout;
    LayoutImage         : TLayout;
    Image               : TImage;
    LayoutInfo          : TLayout;
    LabelState          : TLabel;
    LabelVersion        : TLabel;
    LabelTitulo         : TLabel;
    LineFotterSeparator : TLine;
    LayoutProgress      : TLayout;
    ProgressBar         : TProgressBar;
    LabelWaiting        : TLabel;
    lydescription       : TLayout;
    lyLog               : TLayout;
    lyBottom            : TLayout;
    lyState             : TLayout;
    lyVersion           : TLayout;
    txtLog              : TText;
    lineTopSeparator: TLine;
    LyTopSeparator: TLayout;
    StyleBook: TStyleBook;
    procedure FormClose        (Sender: TObject; var Action: TCloseAction);
    procedure ButtonCancelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
  private
    Model   : IUpdateModel;
    Msg     : iHDMessageDlg;
    FConsts : IMessageConsts;
  public
    procedure SetVersion      (const Value: string);
    procedure SetTitulo       (const Value: string);
    procedure SetStatus       (const Value: string);
    procedure SetPngResource  (const Value: string);
    procedure SetModel        (Model: IUpdateModel);
    procedure SetUpdateState  (Value: TUpdateState);
    procedure SetUpdateLog    (aLog: string);
    procedure ShowMessage     (Message: string);
    function  ShowErrorMessage(Message: string): Boolean;
    procedure Progress        (Progress, Length: Integer);
    procedure IUpdateView.Close = ViewClose;
    procedure IUpdateView.Show  = ViewShow;
    procedure ViewClose;
    procedure ViewShow;
  end;


implementation

uses
  HDUpdate.Language.Consts.Factory;

{$R *.fmx}

procedure TViewUpdate.ButtonCancelClick(Sender: TObject);
begin
  Model.Cancel;
end;

procedure TViewUpdate.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caNone;
  Model.Cancel;
end;

procedure TViewUpdate.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkEscape  then
    Model.Cancel;
end;

procedure TViewUpdate.Progress(Progress, Length: Integer);
begin
  ProgressBar.Max   := Length;
  ProgressBar.Value := Progress;
end;

procedure TViewUpdate.SetTitulo(const Value: string);
begin
  LabelTitulo.Text := Value;
end;

procedure TViewUpdate.SetUpdateLog(aLog: string);
begin
  txtLog.Text := aLog;
end;

procedure TViewUpdate.SetModel(Model: IUpdateModel);
begin
  Self.Model := Model;
end;

procedure TViewUpdate.SetPngResource(const Value: string);
var
  Stream: TResourceStream;
begin
  Stream := TResourceStream.Create(HInstance, Value, RT_RCDATA);
  try
    Image.Bitmap.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TViewUpdate.SetStatus(const Value: string);
begin
  LabelState.Text := Value;
end;

procedure TViewUpdate.SetUpdateState(Value: TUpdateState);
begin
  case Value of
    TUpdateState.Waiting:
      begin
        LabelWaiting.Visible := True;
        ButtonCancel.Enabled := False;
      end;
    TUpdateState.Downloading:
      begin
        LabelWaiting.Visible := False;
        ButtonCancel.Enabled := True;
      end;
    TUpdateState.Unpacking:
      begin
        LabelWaiting.Visible := False;
        ButtonCancel.Enabled := False;
      end;
    TUpdateState.Done:
      begin
        LabelWaiting.Visible := False;
      end;
  end;
end;

procedure TViewUpdate.SetVersion(const Value: string);
begin
  LabelVersion.Text := Value;
end;

function TViewUpdate.ShowErrorMessage(Message: string): Boolean;
begin
  FConsts := TFactoryConsts.New.Consts;
  Msg     := THDMessageDlg.New;
  Result  := Msg
              .MsgTitle(FConsts.MsgTitle)
              .MsgQuestion('')
              .MsgBody(Message)
              .MsgIcon(TiError)
              .MsgType(TyQuestion)
              .DisplayQuestion;
end;

procedure TViewUpdate.ShowMessage(Message: string);
begin
  FConsts := TFactoryConsts.New.Consts;
  Msg := THDMessageDlg.New;
  Msg
    .MsgTitle(FConsts.MsgTitle)
    .MsgQuestion('')
    .MsgBody(Message)
    .MsgIcon(TiMessage)
    .MsgType(TyOK)
    .DisplayMessage;
end;

procedure TViewUpdate.ViewClose;
begin
  OnClose := nil;
  inherited Close;
end;

procedure TViewUpdate.ViewShow;
begin
  Self.Position := TFormPosition.MainFormCenter; // Add by Renato Trevisan
  inherited Show;
end;

end.
