unit Samples.Main;

interface

uses
  HDMessageDlg,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.Types,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants,
  HDUpdate;

type
  TForm1 = class(TForm)
    btnCheckVersion: TButton;
    lblVersion      : TLabel;
    btnUpdateNow: TButton;
    btnUpdateStandalone: TButton;
    btnUpdateResource: TButton;
    procedure btnCheckVersionClick(Sender: TObject);
    procedure btnUpdateNowClick(Sender: TObject);
    procedure btnUpdateStandaloneClick(Sender: TObject);
    procedure btnUpdateResourceClick(Sender: TObject);
  private

  public
  end;

var
  Form1: TForm1;

implementation

uses
  EnvConfig;

{$R *.fmx}

procedure TForm1.btnCheckVersionClick(Sender: TObject);
begin
  lblVersion.Text :=
   lblVersion.Text +
    GlobalUpdate
      .GitAuth(       True)
      .GitToken(      GetGitToken)
      .GitRepo(       'Updates')
      .GitUserName(   'Rtrevisan20')
      .GitIni(        'updates.ini')
      .IniKeyName(    'AmbiSoft.Client')
      .ActualVersion( '1.0.0.1')
      .ExtractNames([ '&ALL'])
      .GetVersionUpdate;
end;

procedure TForm1.btnUpdateNowClick(Sender: TObject);
begin
  if GlobalUpdate
      .GitAuth(       True)
      .GitToken(      GetGitToken)
      .GitRepo(       'Updates')
      .GitUserName(   'Rtrevisan20')
      .GitIni(        'updates.ini')
      .IniKeyName(    'AmbiSoft.Client')
      .ActualVersion( '1.0.0.1')
      .Titulo(        'Aqui o título foi mudado!!!')
      .ExtractNames([ '&ALL'])
      .GetUpdate then
     GlobalUpdate.UpdateNow;
end;

procedure TForm1.btnUpdateResourceClick(Sender: TObject);
begin
  if GlobalUpdate
      .GitAuth(       True)
      .GitToken(      GetGitToken)
      .GitRepo(       'Updates')
      .GitUserName(   'Rtrevisan20')
      .GitIni(        'updates.ini')
      .IniKeyName(    'AmbiSoft.Client')
      .ActualVersion( '1.0.0.1')
      .ExtractNames([ '&ALL'])
      .PngResource('updateResource')
      .GetUpdate then
     GlobalUpdate.UpdateNow;
end;

procedure TForm1.btnUpdateStandaloneClick(Sender: TObject);
begin
  if GlobalUpdate
      .GitAuth(       True)
      .GitToken(      GetGitToken)
      .GitRepo(       'Updates')
      .GitUserName(   'Rtrevisan20')
      .GitIni(        'updates.ini')
      .IniKeyName(    'AmbiSoft.Client')
      .ActualVersion( '1.0.0.1')
      .ExtractNames([ '&ALL'])
      .KillTaskApp(ExtractFileName(ParamStr(0)))
      .ExeUpdateApp('Updates.exe')
      .GetUpdate then
     GlobalUpdate.Standalone;
end;

end.
