program Console;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  EnvConfig,
  HDUpdate in '..\core\src\HDUpdate.pas',
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
  HDUpdate.View.Utils in '..\core\src\view\HDUpdate.View.Utils.pas';

begin
  try
    ReportMemoryLeaksOnShutdown := True;

    Writeln('=== HDUpdate Sample - Console ===');
    Writeln('Testando novas funcionalidades (Releases + i18n + Hash)');
    Writeln('');

    // Exemplo 1: Modo clássico (via updates.ini no branch padrão)
    Writeln('--- Exemplo 1: Modo clássico (branch master) ---');
    GlobalUpdate
      .GitAuth(True)
      .GitToken(GetGitToken)
      .GitRepo('Updates')
      .GitUserName('Rtrevisan20')
      .GitIni('updates.ini')
      .IniKeyName('HDUpdate.Console')
      .ActualVersion('1.0.0')
      .ExtractNames(['&ALL'])
      .Language('pt-BR');  // Item 9: i18n runtime

    if GlobalUpdate.GetUpdate then
    begin
      Writeln('Atualizacao disponivel: ', GlobalUpdate.GetVersionUpdate);
      Writeln('Log: ', GlobalUpdate.GetVersionUpdate);
    end
    else
      Writeln('Sistema ja esta na ultima versao.');

    Writeln('');

    // Exemplo 2: Modo Releases (GitHub Releases API) - Item 8
    Writeln('--- Exemplo 2: Modo Releases (GitHub Releases API) ---');
    GlobalUpdate
      .GitAuth(True)
      .GitToken(GetGitToken)
      .GitRepo('Updates')
      .GitUserName('Rtrevisan20')
      .ActualVersion('1.0.0')
      .ExtractNames(['&ALL'])
      .UseReleases(True)             // Item 8: usa /releases/latest
      .RequireAssetHash(True)        // Item 8: valida SHA-256 do asset
      .ReleaseAssetName('Console.zip') // Item 8: asset especifico (opcional)
      .Language('pt-BR');

    if GlobalUpdate.GetUpdate then
    begin
      Writeln('Release encontrada: ', GlobalUpdate.GetVersionUpdate);
      Writeln('Download URL: ', GlobalUpdate.GetVersionUpdate);
    end
    else
      Writeln('Nenhuma release nova disponivel.');

    Writeln('');

    // Exemplo 3: Com verificação de hash dos arquivos extraídos - Item 9
    Writeln('--- Exemplo 3: Verificacao de hash dos arquivos extraidos ---');
    Writeln('(Requer manifest.json no zip com hashes SHA-256)');
    GlobalUpdate
      .GitAuth(True)
      .GitToken(GetGitToken)
      .GitRepo('Updates')
      .GitUserName('Rtrevisan20')
      .ActualVersion('1.0.0')
      .ExtractNames(['&ALL'])
      .UseReleases(True)
      .RequireAssetHash(True)
      .VerifyExtractedFiles(True)    // Item 9: valida manifest.json
      .Language('en-US');

    if GlobalUpdate.GetUpdate then
    begin
      Writeln('Atualizacao com verificacao de hash disponivel.');
    end
    else
      Writeln('Nenhuma atualizacao ou falha na validacao.');

    Writeln('');

    // Exemplo 4: Usando AssetType para preferir .exe (instalador) - Item 10
    Writeln('--- Exemplo 4: AssetType atExe (instalador) ---');
    Writeln('(Prefere instalador .exe na release e executa de forma visivel)');
    GlobalUpdate
      .GitAuth(True)
      .GitToken(GetGitToken)
      .GitRepo('Updates')
      .GitUserName('Rtrevisan20')
      .ActualVersion('1.0.0')
      .ExtractNames(['&ALL'])
      .UseReleases(True)
      .AssetType(TAssetType.atExe)      // Item 10: prefere instalador .exe
      .RequireAssetHash(True)           // Exige hash SHA-256
      .VerifyExtractedFiles(True)       // Valida manifest.json se for .zip
      .Language('pt-BR');

    if GlobalUpdate.GetUpdate then
    begin
      Writeln('Instalador .exe encontrado na release.');
      Writeln('Executara o instalador de forma visivel para o usuario.');
    end
    else
      Writeln('Nenhum instalador .exe encontrado na release.');

    Writeln('');

    // Exemplo 5: AssetType atAuto (padrão - prefere .zip, fallback .exe) - Item 10
    Writeln('--- Exemplo 5: AssetType atAuto (padrão) ---');
    Writeln('(Prefere .zip, faz fallback para .exe se não encontrar .zip)');
    GlobalUpdate
      .GitAuth(True)
      .GitToken(GetGitToken)
      .GitRepo('Updates')
      .GitUserName('Rtrevisan20')
      .ActualVersion('1.0.0')
      .ExtractNames(['&ALL'])
      .UseReleases(True)
      .AssetType(TAssetType.atAuto)     // Item 10: padrão - prefere .zip, fallback .exe
      .RequireAssetHash(True)
      .Language('pt-BR');

    if GlobalUpdate.GetUpdate then
    begin
      Writeln('Asset encontrado (preferencia: .zip -> .exe).');
    end
    else
      Writeln('Nenhum asset compativel encontrado.');

    Writeln('');

    // Exemplo 6: AssetType atZip (força apenas .zip) - Item 10
    Writeln('--- Exemplo 6: AssetType atZip (apenas .zip) ---');
    Writeln('(Força download apenas do asset .zip)');
    GlobalUpdate
      .GitAuth(True)
      .GitToken(GetGitToken)
      .GitRepo('Updates')
      .GitUserName('Rtrevisan20')
      .ActualVersion('1.0.0')
      .ExtractNames(['&ALL'])
      .UseReleases(True)
      .AssetType(TAssetType.atZip)      // Item 10: apenas .zip
      .RequireAssetHash(True)
      .Language('pt-BR');

    if GlobalUpdate.GetUpdate then
    begin
      Writeln('Asset .zip encontrado na release.');
    end
    else
      Writeln('Nenhum asset .zip encontrado na release.');

    Writeln('');
    Writeln('Pressione ENTER para sair...');
    Readln;

  except
    on E: Exception do
    begin
      Writeln('ERRO: ', E.Message);
      Readln;
    end;
  end;
end.