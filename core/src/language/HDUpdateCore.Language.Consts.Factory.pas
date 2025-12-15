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
unit HDUpdateCore.Language.Consts.Factory;

{$I Language.inc}

interface

uses
  HDUpdateCore.Language.Interfaces,
  System.Classes,
  System.SysUtils;

type
  TFactoryConsts = class (TInterfacedObject, IFactoryConsts)
    private
      FConsts : IMessageConsts;
    public
      constructor Create;
      destructor Destroy; override;
      class function New : IFactoryConsts;
      function Consts    : IMessageConsts;
  end;

implementation

uses
  HDUpdateCore.Language.PTbr,
  HDUpdateCore.Language.US;

function TFactoryConsts.Consts: IMessageConsts;
begin

{$IFDEF EN-Us}
  FConsts := TMessageConstsUS.New;
  Result  := FConsts;
{$ENDIF}

{$IFDEF PT-Br}
  FConsts := TMessageConstsPTbr.New;
  Result  := FConsts;
{$ENDIF}

end;

constructor TFactoryConsts.Create;
begin

end;

destructor TFactoryConsts.Destroy;
begin

  inherited;
end;

class function TFactoryConsts.New: IFactoryConsts;
begin
  Result := Self.Create;
end;

end.
