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
unit HDUpdate.Internet.Factory;

interface

uses
  HDUpdate.Internet.Interfaces,
  System.SysUtils;

type
  TModelIternetFactory = class(TInterfacedObject, IModelIternetFactory)
  private
    FInternetSystem         : IModelInternet;
    FInternet               : IModelInternet;
    function InternetSystem : IModelInternet;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IModelIternetFactory;
    function Internet : IModelInternet;
  end;

implementation

uses
  HDUpdate.Internet;

constructor TModelIternetFactory.Create;
begin

end;

destructor TModelIternetFactory.Destroy;
begin

  inherited;
end;

function TModelIternetFactory.Internet: IModelInternet;
begin
  if not Assigned(FInternet) then
    FInternet := InternetSystem;
  Result := FInternet;
end;

function TModelIternetFactory.InternetSystem: IModelInternet;
begin
  if not Assigned(FInternetSystem) then
    FInternetSystem := TModelInternet.New;

  Result := FInternetSystem;
end;

class function TModelIternetFactory.New: IModelIternetFactory;
begin
  Result := Self.Create;
end;

end.
