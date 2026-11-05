# TurboUpdate

HDUpdate foi projetado para ser uma forma simples e elegante de fazer atualizações usando a API Rest do Github. Inspirado no [TurboUpdate](https://github.com/errorcalc/TurboUpdate) com algumas melhorias para atender a minha necessidade.

## 🚀 Instalação

### Para instalar em seu projeto usando [boss](https://github.com/HashLoad/boss):

```sh
boss install github.com/Rtrevisan20/HDUpdate
```

### ⚙️ Instalação Manual

- Adicione as seguintes pastas ao seu projeto, em _Project > Options > Delphi Compiler > Search path_

```
../core/src/core
../core/src/internet
../core/src/language
../core/src/view
```

## 🤝 Dependências

- [HDmessageDlg](https://github.com/Rtrevisan20/HDMessageDlg)

## Todos Parâmetros disponíveis

- Se for usar um repositório privado, será necessário criar um [Token no Github](https://github.com/settings/tokens) para que o HDUpdate consiga obter as informações corretamente.

```delphi
begin
  GlobalUpdate
    .GitAuth(True)                  // True = Requer autenticação; False = Não requer autenticação
    .GitToken('Seu Token Github opcional caso não tenha autenticação')
    .GitRepo('Updates')             // Repositorio com updates.ini / releases (ex.: usado nos samples)
    .GitUserName('Rtrevisan20')     // Usuario dono do repositorio
    .GitIni('updates.ini')          // Arquivo INI para ler as opções de atualizações (updates.ini)
    .IniKeyName('HDUpdate.Samples') // Secao do arquivo INI (ex.: HDUpdate.Samples, HDUpdate.Console)
    .ActualVersion('1.0.0')         // Versão atual do seu app
    .ExtractNames(['&ALL'])         // &ALL extrai tudo, ou especifique um arquivo ex: Samples.exe
    .Titulo('Título que vai aparecer na tela de atualização. Default: ficará em branco')
    .RootPath('Nome da pasta onde deseja descompactar o executável atualizado. Default: Pasta Raiz do sistema')
    .PngResource('Resource identifier')
    .KillTaskApp(ExtractFileName(ParamStr(0)))  // Nome do exe que será fechado para executar o update
    .ExeUpdateApp('Samples.exe')    // Nome do exe que vai executar o update ex: Samples.exe, Update.exe
    .UseReleases(True)              // True = Usa GitHub Releases API; False = Usa branch/master (padrão: False)
    .RequireAssetHash(True)         // True = Exige hash SHA256 no asset (padrão: False)
    .ReleaseAssetName('Samples.zip') // Nome específico do asset; OBRIGATÓRIO se a release tiver 2+ assets da mesma extensão (requisitos acima)
    .AssetType(TAssetType.atAuto)   // atZip, atExe, atAuto (padrão: atAuto - prefere .zip, fallback .exe)
    .VerifyExtractedFiles(True)     // True = Valida hash dos arquivos extraídos via manifest.json (padrão: False)
    .Language('pt-BR');             // Idioma: 'pt-BR', 'en-US' (padrão: pt-BR)
end;
```

## Parâmetros Obrigatórios

- Para usar o parâmetro PngResource é necessário adicionar o recurso em: _Project > Resources and Images_, e passar o nome do recurso como parâmetro.

```delphi
begin
  GlobalUpdate
    .GitAuth(True)                  // True = Requer autenticação; False = Não requer autenticação
    .GitToken('Seu Token Github')
    .GitRepo('Updates')
    .GitUserName('Rtrevisan20')
    .GitIni('updates.ini')
    .IniKeyName('HDUpdate.Samples')
    .ActualVersion('1.0.0')
    .ExtractNames(['&ALL']);
end;
```

## Requisitos por Caso de Uso

> A partir da revisão de defaults (2026-11-04), o modo **Clássico é o padrão** do componente
> (`UseReleases` nasce `False`), assim como sem autenticação (`GitAuth` nasce `False`).
> As validações (`RequireAssetHash`, `VerifyExtractedFiles`) também nascem desligadas.

### Modo Clássico — updates.ini no branch/master (padrão)

**Obrigatórios (código):**

```delphi
GlobalUpdate
  .GitRepo('Updates')
  .GitUserName('Rtrevisan20')
  .GitIni('updates.ini')
  .IniKeyName('HDUpdate.Samples')           // secao do arquivo INI; ex: 'HDUpdate.Samples', 'HDUpdate.Console'
  .ActualVersion('1.0.0');
```

**Obrigatórios (updates.ini):** chaves `Version` (x.y.z.w) e `Download` (caminho do zip
dentro do repositório) na seção apontada por `IniKeyName` (`Log` é opcional).

- Repositório **privado**: `.GitAuth(True)` + `.GitToken('<token>')`.

### Modo GitHub Releases — .UseReleases(True)

**Obrigatórios (código):**

```delphi
GlobalUpdate
  .GitRepo('Updates')
  .GitUserName('Rtrevisan20')
  .ActualVersion('1.0.0')
  .UseReleases(True);
```

**Repositório privado: `.GitAuth(True)` + `.GitToken('<token>')` são OBRIGATÓRIOS** — sem
token a API do GitHub negra o acesso à release e ao download dos assets.

**`.ReleaseAssetName(...)`: OBRIGATÓRIO quando a release tiver MAIS DE UM asset da mesma
extensão.** Sem o nome, o componente pega o **primeiro asset na ordem da API** com a
extensão preferida (`atAuto` = prefere `.zip`, fallback `.exe`); se nenhum casar, usa o
primeiro asset de qualquer tipo. A ordem dos assets no GitHub **não é contrato** (varia por
upload/ordem alfabética) — em repositórios com assets de vários apps (ex.: `Samples.zip` e
`Console.zip` na mesma release), a escolha sem `ReleaseAssetName` pode baixar o asset do
app errado.

**`.AssetType(TAssetType.atAuto)`** (opcional, padrão `atAuto`): `atZip` = prefere `.zip`,
`atExe` = prefere `.exe` (instalador), `atAuto` = `.zip` com fallback `.exe`.

**`.RequireAssetHash(True)`** (opcional): compara o SHA-256 do arquivo baixado com o
`digest` informado pela API do GitHub (disponível para assets recentes; asset sem `digest`
tem a validação pulada).

**`.VerifyExtractedFiles(True)`** (opcional): valida o SHA-256 dos arquivos extraídos
contra o `manifest.json` + raiz do zip (pode ser gerado com `tools\GenerateManifest.exe`
`App.zip`, que injeta o manifest dentro do zip). Zip sem manifest passa sem validação.

## Parâmetros Opcionais

- Para usar o parâmetro PngResource é necessário adicionar o recurso em: _Project > Resources and Images_, e passar o nome do recurso (Resource identifier) como parâmetro.

```delphi
begin
   GlobalUpdate
    .Titulo('Título que vai aparecer na tela de atualização. Default: ficará em branco')
    .RootPath('Nome da pasta onde deseja descompactar o executável atualizado. Default: Pasta Raiz do sistema')
    .PngResource('Resource identifier')
    .KillTaskApp(ExtractFileName(ParamStr(0)))  // Nome do exe que será fechado
    .ExeUpdateApp('Update.exe')                 // Nome do exe que executa o update
    // GitHub Releases (Item 8)
    .UseReleases(True)              // Usa API de Releases do GitHub
    .RequireAssetHash(True)         // Exige hash SHA256 do asset
    .ReleaseAssetName('Samples.zip') // Nome específico do asset; OBRIGATÓRIO se a release tiver 2+ assets da mesma extensão
    .AssetType(TAssetType.atAuto)   // atZip, atExe, atAuto
    .VerifyExtractedFiles(True)     // Valida hash dos arquivos extraídos
    .Language('pt-BR');             // Idioma: pt-BR, en-US
end;
```

## Procedures e Functions

```delphi
begin
  GlobalUpdate
    .GetVersionUpdate       // Retorna uma string com a versão disponível no Github
    .GetUpdate              // Retorna verdadeiro ou falso para atualização
    .UpdateNow              // Atualiza o sistema
    .ThreadUpdate           // Atualiza o sistema em sistemas console
    .Standalone;            // Chama um atualizador externo e fecha o sistema aberto
end;
```

## ☕ Exemplos de uso

- Veja alguns exemplos na [samples](https://github.com/Rtrevisan20/HDUpdate/Samples)
- Uses necessárias para a maioria dos usos

```delphi
uses
  HDUpdate,
  HDUpdate.Core.Types; // Para TAssetType
```

- Nos samples, o token do GitHub é lido de um arquivo `.env` (chave `KEY`) pelo helper
  `EnvConfig.pas` e passado com `.GitToken(GetGitToken)`. É só uma convenção dos exemplos —
  no seu app você pode obter o token de onde preferir.
- Exemplos disponíveis: `samples\Samples.Main.pas` (app FMX) e `samples\Console.dpr` (console),
  ambos apontando para o repositório `Rtrevisan20/Updates` com as seções de ini
  `HDUpdate.Samples` e `HDUpdate.Console`.

- Para usar o HDUpdate é necessário um arquivo .ini dentro da raiz do seu repositório. Segue a estrutura de como o arquivo ini deve estar para que o componente faça a leitura corretamente:

### Modo Tradicional (branch/master) - updates.ini

```ini
[HDUpdate.Samples]
Download=Samples/Samples.zip
Version=1.0.1
Log=Um novo jeito de fazer atualização.

[HDUpdate.Console]
Download=Console/Console.zip
Version=1.0.1
Log=Um novo jeito de fazer atualização.
```

### Modo GitHub Releases (UseReleases=True)

- Neste modo o componente **NÃO lê o `updates.ini`** — todo o estado vem da API de Releases
  (`/releases/latest`): a versão é o `tag_name` da release e o download vem do asset
  selecionado por `ReleaseAssetName`/`AssetType`. Veja a seção "Requisitos por Caso de Uso"
  acima: `ReleaseAssetName` é obrigatório quando a release tem mais de um asset da mesma
  extensão (sem ele o componente pega o primeiro asset do tipo preferido).

### Explicação do arquivo updates.ini (modo tradicional)

- **`[HDUpdate.Samples]`** — seção do INI; o nome deve ser o mesmo passado no parâmetro `IniKeyName` (ex.: `HDUpdate.Samples`, `HDUpdate.Console`).
- **`Download=`** — onde vai estar o arquivo zipado responsável pela atualização (modo tradicional apenas).
  - ex: `Samples.zip` => você pode colocar o atualizador na raiz do seu repositório e especificar apenas o nome do arquivo.
  - ex: `Samples/Samples.zip` => `Samples` é uma pasta, seguida de `/` e o nome do arquivo.
- **`Version=`** — ex: `1.0.0.12` — aqui você coloca a nova versão do seu sistema.
- **`Log=`** — descrição breve do que a atualização está corrigindo ou agregando ao seu sistema/aplicativo. Se não quiser, deixe vazio.

> As opções de Releases (`ReleaseAssetName`, `AssetType`, `RequireAssetHash`,
> `VerifyExtractedFiles` e o hash esperado do asset) são configuradas **somente pela API
> fluente** (`.ReleaseAssetName(...)`, `.AssetType(...)`, `.RequireAssetHash(True)` etc.) —
> o componente lê do INI apenas `Download`, `Version` e `Log`.

## 📝 Licença

Esse projeto está sob licença. Veja o arquivo [LICENÇA](LICENSE.md) para mais detalhes.
