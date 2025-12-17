# TurboUpdate

HDUpdate foi projetado para ser uma forma simples e elegante de fazer atualizações usando a API Rest do Github. Inspirado no [TurboUpdate](https://github.com/errorcalc/TurboUpdate) com algumas melhorias para atender a minha necessidade.

## 🚀 Instalação

### Para instalar em seu projeto usando [boss](https://github.com/HashLoad/boss):
```sh
boss install github.com/Rtrevisan20/HDUpdate
```
### ⚙️ Instalação Manual
  * Adicione as seguintes pastas ao seu projeto, em *Project > Options > Delphi Compiler > Search path*
```
../core/src/core
../core/src/internet
../core/src/language
../core/src/view
```
## 🤝 Dependências
* [HDmessageDlg](https://github.com/Rtrevisan20/HDMessageDlg)

## Todos Parâmetros disponívies
  * Se for usar um reposiotório privado, será necessário criar um [Token no Github](https://github.com/settings/tokens) para que o HDUpdate consiga obter as informações corretamente.

```delphi
begin
  GlobalUpdate  
    .GitAuth(True) True = Requer autenticação; False = Não requer autenticação
    .GitToken('Seu Token Github opcional caso não tenha autenticação')
    .GitRepo('Seu repositório')
    .GitUserName('Seu Usuário')
    .GitIni('Arquivo INI para ler as opções de atualizações (updates.ini)')
    .IniKeyName('A chave do arquivo INI')
    .ActualVersion('Versão atual do seu app')
    .ExtractNames(['&ALL para extrair tudo, ou especificar um arquivo ex: update.exe'])    
    .Titulo('Título que vai aparecer na tela de atualização. Default: ficará em branco')
    .RootPath('Nome da pasta onde deseja descompactar o executável atualizado. Default: Pasta Raiz do sistema')
    .PngResource('Resource identifier')
    .KillTaskApp(ExtractFileName(ParamStr(0)) 'Nome do exe que será fechado para executar o update')
    .ExeUpdateApp('Nome do exe que vai executar o update ex:Updates.exe');
end;   
```
## Parâmetros Obrigatórios
  * Para usar o parâmetro PngResource é necessário adicionar o recurso em: *Project > Resources and Images*, e passar o nome do recurso como parâmetro.
```delphi
begin
  GlobalUpdate  
    .GitAuth(True) True = Requer autenticação; False = Não requer autenticação
     .GitToken('Seu Token Github')
     .GitRepo('Seu repositório')
     .GitUserName('Seu Usuário')
     .GitIni('Arquivo INI para ler as opções de atualizações (updates.ini)')
     .IniKeyName('A chave do arquivo INI')
     .ActualVersion('Versão atual do seu app')
     .ExtractNames(['&ALL para extrair tudo, ou especificar um arquivo ex: update.exe']);
end;   
```

## Parâmetros Opcionais
  * Para usar o parâmetro PngResource é necessário adicionar o recurso em: *Project > Resources and Images*, e passar o nome do recurso (Resource identifier) como parâmetro.

```delphi
begin
   GlobalUpdate
    .Titulo('Título que vai aparecer na tela de atualização. Default: ficará em branco')
    .RootPath('Nome da pasta onde deseja descompactar o executável atualizado. Default: Pasta Raiz do sistema')
    .PngResource('Resource identifier');
end;   
```
## Procedures e Functions
```delphi
begin
  GlobalUpdate
    .GetVersionUpdate // Retorna uma string com a versão disponível no Github
    .GetUpdate        // Retorna verdadeiro ou falso para atualização
    .UpdateNow        // Atualiza o sistema
    .ThreadUpdate     // Atualiza o sistema em sistemas console
    .Standalone       // Chama um atualizador externo e fecha o sistema aberto
end;   
```
## ☕ Exemplos de uso
  * Veja alguns exemplos na [samples](https://github.com/Rtrevisan20/HDUpdate/Samples) 
  * Uses necessárias para a maioria dos usos
```delphi
uses 
  HDUpdate;
``` 
* Para usar o HDUpdate é necessário um arquivo .ini dentro da raiz do seu repositório. Segue a estrutura de como o arquivo ini estar para que o componente faça a leitura corretamente:
```ini
[HD.Update]
Download=Client/Client.zip
Version=4.0.0.211
Log=Um novo jeito de fazer atualização.
``` 
* Segue uma explicação do arquivo .INI:

  [AmbiSoft.Client] Chave do seu arquivo INI poderá passar a chave no parâmetro GitIni.
  #
  Download= Nessa opção coloque onde vai estar o seu arquivo zipado responsável pela atualização.
  * ex: Client.zip => Você pode colocar o atualizador na raiz do seu repositório e especificar apenas o nome do arquivo.
  * ex: Client/Client.zip => Client é uma pasta seguida / e o nome do arquivo.
  #
  Version= ex: 1.0.0.12 aqui você coloca a nova versão do seu sistema 
  #
  Log=Aqui você pode colocar uma descrição breve do que a atualização esta corrigindo, ou agregando, à nova versão do seu sistema ou aplicativo. Se não quiser poderá deixar vazio.

## 📝 Licença
Esse projeto está sob licença. Veja o arquivo [LICENÇA](LICENSE.md) para mais detalhes.