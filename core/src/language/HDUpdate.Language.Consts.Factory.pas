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
unit HDUpdate.Language.Consts.Factory;

interface

uses
  HDUpdate.Language.Interfaces,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type
  TFactoryConsts = class (TInterfacedObject, IFactoryConsts)
    private
      FConsts       : IMessageConsts;
      FLanguage     : string;
      function CreateConsts(const ALanguage: string): IMessageConsts;
    public
      constructor Create;
      destructor Destroy; override;
      class function New : IFactoryConsts;
      class function Global : IFactoryConsts;   // instancia unica compartilhada (i18n runtime)
      function Consts    : IMessageConsts;
      // Item 9: i18n runtime
      procedure SetLanguage(const ALanguage: string);
      function  GetLanguage: string;
      function  SupportedLanguages: TArray<string>;
  end;

implementation

uses
  HDUpdate.Language.PTbr,
  HDUpdate.Language.US;

var
  GGlobalFact: IFactoryConsts = nil;   // instancia compartilhada referente a TFactoryConsts.Global

constructor TFactoryConsts.Create;
begin
  FLanguage := 'pt-BR'; // default
end;

destructor TFactoryConsts.Destroy;
begin
  inherited;
end;

class function TFactoryConsts.New: IFactoryConsts;
begin
  Result := Self.Create;
end;

class function TFactoryConsts.Global: IFactoryConsts;
begin
  if not Assigned(GGlobalFact) then
    GGlobalFact := TFactoryConsts.New;
  Result := GGlobalFact;
end;

function TFactoryConsts.Consts: IMessageConsts;
begin
  if FConsts = nil then
    FConsts := CreateConsts(FLanguage);
  Result := FConsts;
end;

function TFactoryConsts.CreateConsts(const ALanguage: string): IMessageConsts;
begin
  if SameText(ALanguage, 'en-US') then
    Result := TMessageConstsUS.New
  else
    Result := TMessageConstsPTbr.New; // default pt-BR
end;

procedure TFactoryConsts.SetLanguage(const ALanguage: string);
begin
  if SameText(FLanguage, ALanguage) then Exit;
  FLanguage := ALanguage;
  FConsts := CreateConsts(FLanguage);
end;

function TFactoryConsts.GetLanguage: string;
begin
  Result := FLanguage;
end;

function TFactoryConsts.SupportedLanguages: TArray<string>;
begin
  Result := ['pt-BR', 'en-US'];
end;

end.