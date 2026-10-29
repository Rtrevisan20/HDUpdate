program Console;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Vcl.Forms,
  System.SysUtils,
  HDUpdate.Core.Check in '..\core\src\core\HDUpdate.Core.Check.pas',
  HDUpdate.Core.Commons in '..\core\src\core\HDUpdate.Core.Commons.pas',
  HDUpdate.Core.Interfaces in '..\core\src\core\HDUpdate.Core.Interfaces.pas',
  HDUpdate.Core.Types in '..\core\src\core\HDUpdate.Core.Types.pas',
  HDUpdate.Core.Update.Thread in '..\core\src\core\HDUpdate.Core.Update.Thread.pas',
  HDUpdate.Core.Updater in '..\core\src\core\HDUpdate.Core.Updater.pas',
  HDUpdate.Core.Utils in '..\core\src\core\HDUpdate.Core.Utils.pas',
  HDUpdate.Internet.Factory in '..\core\src\internet\HDUpdate.Internet.Factory.pas',
  HDUpdate.Internet.HttpClientHook in '..\core\src\internet\HDUpdate.Internet.HttpClientHook.pas',
  HDUpdate.Internet.Interfaces in '..\core\src\internet\HDUpdate.Internet.Interfaces.pas',
  HDUpdate.Internet in '..\core\src\internet\HDUpdate.Internet.pas',
  HDUpdate.Language.Consts.Factory in '..\core\src\language\HDUpdate.Language.Consts.Factory.pas',
  HDUpdate.Language.Interfaces in '..\core\src\language\HDUpdate.Language.Interfaces.pas',
  HDUpdate.Language.PTbr in '..\core\src\language\HDUpdate.Language.PTbr.pas',
  HDUpdate.Language.US in '..\core\src\language\HDUpdate.Language.US.pas',
  HDUpdate.View.Update in '..\core\src\view\HDUpdate.View.Update.pas' {ViewUpdate},
  HDUpdate.View.Update.Thread in '..\core\src\view\HDUpdate.View.Update.Thread.pas',
  HDUpdate.View.Utils in '..\core\src\view\HDUpdate.View.Utils.pas',
  HDUpdate in '..\core\src\HDUpdate.pas';

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;

  GlobalUpdate
    .GitAuth(       True)
    .GitToken(      '')
    .GitRepo(       'HDUpdate')
    .GitUserName(   'Rtrevisan20')
    .GitIni(        'updates.ini')
    .IniKeyName(    'AmbiSoft.Client')
    .ActualVersion( '1.0.0.1')
    .Titulo(        'Aqui o título foi mudado!!!')
    .ExtractNames([ '&ALL'])
    .ThreadUpdate;

  Application.Run;

end.
