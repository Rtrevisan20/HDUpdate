unit Samples.Main;

interface

uses
  HDMessageDlg,
  HDMessageDlg.Interfaces,
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
  HDUpdate,
  HDUpdate.Core.Types;

type
  TForm1 = class(TForm)
    btnCheckVersion: TButton;
    lblVersion      : TLabel;
    btnUpdateNow: TButton;
    btnUpdateStandalone: TButton;
    btnUpdateReleases: TButton;
    btnUpdateWithHash: TButton;
    btnUpdateExeAsset: TButton;
    btnUpdateZipAsset: TButton;
    btnLanguagePT: TButton;
    btnLanguageEN: TButton;
    btnUpdateHashConsole: TButton;
    btnUpdateHashSamples: TButton;
    btnGetVersion: TButton;
    procedure btnCheckVersionClick(Sender: TObject);
    procedure btnUpdateNowClick(Sender: TObject);
    procedure btnUpdateStandaloneClick(Sender: TObject);
    procedure btnUpdateReleasesClick(Sender: TObject);
    procedure btnUpdateWithHashClick(Sender: TObject);
    procedure btnUpdateExeAssetClick(Sender: TObject);
    procedure btnUpdateZipAssetClick(Sender: TObject);
    procedure btnLanguagePTClick(Sender: TObject);
    procedure btnLanguageENClick(Sender: TObject);
    procedure btnUpdateHashConsoleClick(Sender: TObject);
    procedure btnUpdateHashSamplesClick(Sender: TObject);
    procedure btnGetVersionClick(Sender: TObject);
  private
    procedure ConfigureUpdateCommon;
    procedure ShowResult(const ATitle, AMsg: string);
  public
  end;

var
  Form1: TForm1;

implementation

uses
  EnvConfig;

{$R *.fmx}

procedure TForm1.ConfigureUpdateCommon;
begin
  GlobalUpdate
    .GitAuth(True)
    .GitToken(GetGitToken)
    .GitRepo('Updates')
    .KillTaskApp(ExtractFileName(ParamStr(0)))
    .GitUserName('Rtrevisan20')
    .ActualVersion('1.0.0')
    .ExtractNames(['&ALL']);
end;

procedure TForm1.ShowResult(const ATitle, AMsg: string);
begin
  THDMessageDlg.New
    .MsgTitle(ATitle)
    .MsgBody(AMsg)
    .MsgIcon(TiMessage)
    .MsgType(TyOK)
    .DisplayMessage;
end;

procedure TForm1.btnCheckVersionClick(Sender: TObject);
var
  LVersion: string;
begin
  ConfigureUpdateCommon;
  LVersion :=
    GlobalUpdate
      .GitIni('updates.ini')
      .IniKeyName('HDUpdate.Samples')
      .Language('en-US')
      .GetVersionUpdate;

  if LVersion <> '' then
    ShowResult('Versao Disponivel', 'Nova versao: ' + LVersion)
  else
    ShowResult('Sem Atualizacao', 'Sistema ja esta na ultima versao.');
end;

procedure TForm1.btnUpdateNowClick(Sender: TObject);
begin
  // Modo clássico (branch master + updates.ini)
  ConfigureUpdateCommon;
  GlobalUpdate
    .GitIni('updates.ini')
    .ExeUpdateApp('Samples.exe')
    .IniKeyName('HDUpdate.Samples');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Atualizacao Disponivel', 'Versao: ' + GlobalUpdate.GetVersionUpdate);
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Sem Atualizacao', 'Sistema ja esta na ultima versao.');
end;

procedure TForm1.btnUpdateReleasesClick(Sender: TObject);
begin
  // Modo Releases (GitHub Releases API) - Item 8
  ConfigureUpdateCommon;
  GlobalUpdate
    .UseReleases(True)              // Item 8: usa /releases/latest
    .RequireAssetHash(True)         // Item 8: valida SHA-256 do asset
//    .ReleaseAssetName('Samples.zip') // Item 8: asset especifico
    .Language('pt-BR');             // Item 9: i18n runtime

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Release Encontrada', 'Versao: ' + GlobalUpdate.GetVersionUpdate + #13#10 + 'Download URL configurado.');
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Sem Release Nova', 'Nenhuma release nova disponivel.');
end;

procedure TForm1.btnUpdateWithHashClick(Sender: TObject);
begin
  // Com verificação de hash dos arquivos extraídos - Item 9
  ConfigureUpdateCommon;
  GlobalUpdate
    .UseReleases(True)
    .RequireAssetHash(True)
    .VerifyExtractedFiles(True)    // Item 9: valida manifest.json
    .Language('en-US');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Atualizacao com Hash', 'Validacao de hash dos arquivos ativada (manifest.json).');
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Falha', 'Nenhuma atualizacao ou falha na validacao de hash.');
end;

procedure TForm1.btnUpdateExeAssetClick(Sender: TObject);
begin
  // Exemplo 4: Usando AssetType para preferir .exe (instalador) - Item 10
  ConfigureUpdateCommon;
  GlobalUpdate
    .UseReleases(True)
    .AssetType(TAssetType.atExe)      // Item 10: prefere instalador .exe
    .RequireAssetHash(True)           // Exige hash SHA-256
    .ExeUpdateApp('Samples.exe')
    .ReleaseAssetName('Samples.exe')
//    .VerifyExtractedFiles(True)       // Valida manifest.json se for .zip
    .KillTaskApp(ExtractFileName(ParamStr(0)))
    .Language('pt-BR');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Asset .exe Encontrado',
      'Instalador .exe detectado.' + #13#10 + 
      'O instalador sera executado...');
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Sem Instalador .exe', 'Nenhum instalador .exe encontrado na release.');
end;

procedure TForm1.btnUpdateHashConsoleClick(Sender: TObject);
begin
  // Com verificação de hash dos arquivos extraídos - Item 9
  ConfigureUpdateCommon;
  GlobalUpdate
    .UseReleases(False)
    .IniKeyName('HDUpdate.Console')
    .GitIni('updates.ini')
    .ExeUpdateApp('Console.exe')
    .RequireAssetHash(True)
    .VerifyExtractedFiles(True)    // Item 9: valida manifest.json
    .Language('pt-BR');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Atualizacao com Hash', 'Validacao de hash dos arquivos ativada (manifest.json).');
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Falha', 'Nenhuma atualizacao ou falha na validacao de hash.');
end;

procedure TForm1.btnUpdateHashSamplesClick(Sender: TObject);
begin
  // Com verificação de hash dos arquivos extraídos - Item 9
  ConfigureUpdateCommon;
  GlobalUpdate
    .UseReleases(False)
    .IniKeyName('HDUpdate.Samples')
    .GitIni('updates.ini')
    .ExeUpdateApp('Samples.exe')
    .RequireAssetHash(True)
    .VerifyExtractedFiles(True)    // Item 9: valida manifest.json
    .Language('pt-BR');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Atualizacao com Hash', 'Validacao de hash dos arquivos ativada (manifest.json).');
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Falha', 'Nenhuma atualizacao ou falha na validacao de hash.');
end;

procedure TForm1.btnUpdateZipAssetClick(Sender: TObject);
begin
  // Exemplo: Usando AssetType para forçar .zip - Item 10
  ConfigureUpdateCommon;
  GlobalUpdate
    .UseReleases(True)
    .AssetType(TAssetType.atZip)      // Item 10: força apenas .zip
    .RequireAssetHash(True)           // Exige hash SHA-256
    .VerifyExtractedFiles(True)       // Valida manifest.json
    .KillTaskApp(ExtractFileName(ParamStr(0)))
    .Language('pt-BR');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Asset .zip Encontrado', 
      'Arquivo .zip detectado na release.' + #13#10 +
      'Sera extraido automaticamente.');
    GlobalUpdate.UpdateNow;
  end
  else
    ShowResult('Sem Arquivo .zip', 'Nenhum arquivo .zip encontrado na release.');
end;

procedure TForm1.btnUpdateStandaloneClick(Sender: TObject);
begin
  ConfigureUpdateCommon;
  GlobalUpdate
    .GitIni('updates.ini')
    .IniKeyName('HDUpdate.Samples')
    .Titulo('Atualizacao Standalone')
    .KillTaskApp(ExtractFileName(ParamStr(0)))
    .ExeUpdateApp('Samples.exe');

  if GlobalUpdate.GetUpdate then
  begin
    ShowResult('Atualizacao Standalone', 'Versao: ' + GlobalUpdate.GetVersionUpdate);
    GlobalUpdate.Standalone;
  end
  else
    ShowResult('Sem Atualizacao', 'Sistema ja esta na ultima versao.');
end;

procedure TForm1.btnLanguagePTClick(Sender: TObject);
begin
  GlobalUpdate.Language('pt-BR');
  ShowResult('Idioma', 'Idioma alterado para Portugues (pt-BR)');
end;

procedure TForm1.btnGetVersionClick(Sender: TObject);
begin
  // Modo Releases (GitHub Releases API) - Item 8
  ConfigureUpdateCommon;
  var LVersion := GlobalUpdate
    .UseReleases(True)              // Item 8: usa /releases/latest
    .RequireAssetHash(True)         // Item 8: valida SHA-256 do asset
//    .ReleaseAssetName('Samples.zip') // Item 8: asset especifico
    .Language('pt-BR')             // Item 9: i18n runtime
    .GetVersionUpdate;

  ShowResult('Release Encontrada', 'Versao: ' + LVersion);
end;

procedure TForm1.btnLanguageENClick(Sender: TObject);
begin
  GlobalUpdate.Language('en-US');
  ShowResult('Language', 'Language changed to English (en-US)');
end;

end.