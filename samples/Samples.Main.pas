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
  HDMessageDlg.Interfaces,
  HDUpdateCore.Check,
  HDUpdateCore.Interfaces,
  HDUpdateCore.Language.Interfaces,
  HDUpdateCore.Types,
  HDUpdateCore.View.Utils,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants;

type
  TForm1 = class(TForm)
    Button1: TButton;
    lblVersion: TLabel;
    lblPathDownload: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FConsts   : IMessageConsts;
    FCheck    : IModelCheck;
    MSG       : iHDMessageDlg;
    procedure Check(UpdateAviable: Boolean; Version: TFileVersion);
  public
  end;

var
  Form1: TForm1;

implementation

uses
  HDUpdateCore.Language.Consts.Factory;

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if FCheck
      .GitAuth(True)
      .GitToken(      '***REMOVED_GITHUB_TOKEN***')
      .GitRepo(       'HDUpdate')
      .GitUserName(   'Rtrevisan20')
      .GitPath(       'updates.ini')
      .IniKeyName(    'AmbiSoft.Client')
      .ActualVersion( TFileVersion.Create('1.0.0.1'))
      .Titulo(        'Atualização de sistema...')
      .ExtractNames([ '&ALL'])
      .CheckUpdate then
    FCheck.UpdateCheckProc(TFileVersion.Create('1.0.0.1'), Check);
end;

procedure TForm1.Check(UpdateAviable: Boolean; Version: TFileVersion);
begin
  MSG     := THDMessageDlg.New;
  FConsts := TFactoryConsts.New.Consts;
 if UpdateAviable then
  begin
   if
    MSG.MsgTitle(FConsts.MsgTitle)
     .MsgQuestion(FConsts.MsgQuestion)
     .MsgBody(Format(FConsts.MsgBodyUpdateVersion + FConsts.Version, [Version.ToString]))
     .MsgIcon(TiQuestion)
     .MsgType(TyQuestion)
     .DisplayQuestion then

    HDUpdateCore.View.Utils.FMXUpdate(FCheck.UpdateInfo);
  end else
   MSG.MsgTitle(FConsts.MsgTitle)
    .MsgQuestion('')
    .MsgBody(Format(FConsts.MsgBodyLastVersion + FConsts.Version, [Version.ToString]))
    .MsgIcon(TiMessage)
    .MsgType(TyOK)
    .DisplayMessage;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FCheck := TModelCheck.New;
  lblVersion.Text :=
   FCheck
    .GitAuth(True)
    .GitToken('***REMOVED_GITHUB_TOKEN***')
    .GitRepo('HDUpdate')
    .GitUserName('Rtrevisan20')
    .GitPath('updates.ini')
    .IniKeyName('AmbiSoft.Client')
    .ActualVersion(TFileVersion.Create('1.0.0.0'))
    .Titulo('Atualização de sistema...')
    .ExtractNames(['&ALL'])
    .GetFileVersion.ToString;
end;

end.
