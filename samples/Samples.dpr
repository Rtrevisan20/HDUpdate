program Samples;

uses
  System.StartUpCopy,
  FMX.Forms,
  Samples.Main in 'Samples.Main.pas' {Form1},
  HDUpdateCore.Check in '..\core\src\HDUpdateCore.Check.pas',
  HDUpdateCore.Commons in '..\core\src\HDUpdateCore.Commons.pas',
  HDUpdateCore.Interfaces in '..\core\src\HDUpdateCore.Interfaces.pas',
  HDUpdateCore.Types in '..\core\src\HDUpdateCore.Types.pas',
  HDUpdateCore.Update.Thread in '..\core\src\HDUpdateCore.Update.Thread.pas',
  HDUpdateCore.Updater in '..\core\src\HDUpdateCore.Updater.pas',
  HDUpdateCore.Utils in '..\core\src\HDUpdateCore.Utils.pas',
  HDUpdateCore.Internet.Factory in '..\core\src\internet\HDUpdateCore.Internet.Factory.pas',
  HDUpdateCore.Internet.HttpClientHook in '..\core\src\internet\HDUpdateCore.Internet.HttpClientHook.pas',
  HDUpdateCore.Internet.Interfaces in '..\core\src\internet\HDUpdateCore.Internet.Interfaces.pas',
  HDUpdateCore.Internet in '..\core\src\internet\HDUpdateCore.Internet.pas',
  HDUpdateCore.Language.Consts.Factory in '..\core\src\language\HDUpdateCore.Language.Consts.Factory.pas',
  HDUpdateCore.Language.Interfaces in '..\core\src\language\HDUpdateCore.Language.Interfaces.pas',
  HDUpdateCore.Language.PTbr in '..\core\src\language\HDUpdateCore.Language.PTbr.pas',
  HDUpdateCore.Language.US in '..\core\src\language\HDUpdateCore.Language.US.pas',
  HDUpdateCore.View.Update in '..\core\src\view\HDUpdateCore.View.Update.pas' {ViewUpdate},
  HDUpdateCore.View.Update.Thread in '..\core\src\view\HDUpdateCore.View.Update.Thread.pas',
  HDUpdateCore.View.Utils in '..\core\src\view\HDUpdateCore.View.Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
