program GenerateManifest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.JSON,
  System.Zip;

var
  LZipFile      : TZipFile;
  LZipNew       : TZipFile;
  LManifest     : TJSONObject;
  LFilesObj     : TJSONObject;
  LFileName     : string;
  LHash         : string;
  LStream       : TStream;
  LHeader       : TZipHeader;
  LOutputFile   : string;
  LManifestBytes: TBytes;
  LTempZip      : string;
  LInject       : Boolean;
  LHasManifest  : Boolean;
  i: Integer;

  // Detecta manifest.json em qualquer nivel do zip (raiz ou subpasta)
  function ZipHasManifest(const AZip: TZipFile): Boolean;
  var
    j: Integer;
  begin
    Result := False;
    for j := 0 to AZip.FileCount - 1 do
      if SameText(ExtractFileName(AZip.FileName[j]), 'manifest.json') then
        Exit(True);
  end;

begin
  try
    // Novo : 1 parametro -> calcula os hashes e INJETA o manifest.json dentro do zip
    // Antigo: 2 parametros -> grava o manifest como arquivo externo (compatibilidade)
    LInject := (ParamCount = 1);
    if not (LInject or (ParamCount = 2)) then
    begin
      WriteLn('Uso 1: GenerateManifest <arquivo.zip>                   (injeta manifest.json dentro do zip)');
      WriteLn('Uso 2: GenerateManifest <arquivo.zip> <manifest.json>   (gera apenas o arquivo externo)');
      ExitCode := 1;
      Exit;
    end;

    LZipFile  := TZipFile.Create;
    LManifest := TJSONObject.Create;
    LFilesObj := TJSONObject.Create;
    try
      LZipFile.Open(ParamStr(1), TZipMode.zmRead);

      WriteLn('Gerando manifest para: ' + ParamStr(1));
      WriteLn('Arquivos no zip: ' + LZipFile.FileCount.ToString);

      for i := 0 to LZipFile.FileCount - 1 do
      begin
        LFileName := LZipFile.FileName[i];
        // O proprio manifest.json nao entra na lista de hashes
        if SameText(ExtractFileName(LFileName), 'manifest.json') then
          Continue;
        // Entrada de diretorio (termina com '/'): nada a hashear nem a copiar
        if LFileName.EndsWith('/') then
          Continue;

        LZipFile.Read(LFileName, LStream, LHeader);
        try
          LStream.Position := 0;
          LHash := THashSHA2.GetHashString(LStream).ToLower;
        finally
          LStream.Free;
        end;
        LFilesObj.AddPair(LFileName, 'sha256:' + LHash);
        WriteLn('  ' + LFileName + ' -> sha256:' + LHash);
      end;

      LManifest.AddPair('version', '1.0');
      LManifest.AddPair('generated', FormatDateTime('YYYY-MM-DD"T"HH:NN:SS"Z"', Now));
      LManifest.AddPair('files', LFilesObj);
      // UTF-8 sem BOM: o componente le o manifest com TEncoding.UTF8 e faz ParseJSONValue
      LManifestBytes := TEncoding.UTF8.GetBytes(LManifest.Format);

      WriteLn('');
      if LInject then
      begin
        LHasManifest := ZipHasManifest(LZipFile);

        if not LHasManifest then
        begin
          // Simples: reabre em zmReadWrite e anexa o manifest ao final do zip
          LZipFile.Close;
          LZipFile.Open(ParamStr(1), TZipMode.zmReadWrite);
          LZipFile.Add(LManifestBytes, 'manifest.json', TZipCompression.zcDeflate);
          LZipFile.Close;  // fecha gravando o zip atualizado
          WriteLn('manifest.json injetado dentro do zip: ' + ParamStr(1));
        end
        else
        begin
          // Zip ja contem manifest.json (re-execucao): reconstrui o zip em temp
          // sem o manifest antigo + novo manifest, e substitui o original so
          // depois de gravar/fechar o novo com sucesso.
          WriteLn('Zip ja contem manifest.json -> reconstruindo com o manifest atualizado');
          LZipNew := TZipFile.Create;
          LTempZip := TPath.Combine(TPath.GetTempPath, TGUID.NewGuid.ToString + '.zip');
          try
            if FileExists(LTempZip) then
              TFile.Delete(LTempZip);
            LZipNew.Open(LTempZip, TZipMode.zmWrite);
            for i := 0 to LZipFile.FileCount - 1 do
            begin
              LFileName := LZipFile.FileName[i];
              if SameText(ExtractFileName(LFileName), 'manifest.json') then
                Continue;
              if LFileName.EndsWith('/') then
                Continue;
              LZipFile.Read(i, LStream, LHeader);
              try
                LStream.Position := 0;
                LZipNew.Add(LStream, LFileName, TZipCompression(LHeader.CompressionMethod));
              finally
                LStream.Free;
              end;
            end;
            LZipNew.Add(LManifestBytes, 'manifest.json', TZipCompression.zcDeflate);
            LZipNew.Close;
            LZipNew.Free;
            LZipNew := nil;

            // Fecha o origem antes de substituir o arquivo
            LZipFile.Close;
            LZipFile.Free;
            LZipFile := nil;
            TFile.Delete(ParamStr(1));
            TFile.Move(LTempZip, ParamStr(1));
            WriteLn('manifest.json atualizado dentro do zip: ' + ParamStr(1));
          finally
            if Assigned(LZipNew) then
              LZipNew.Free;
            // LZipFile pode ter sido fechado/liberado acima; Free em nil e seguro
            LZipFile.Free;
          end;
        end;
      end
      else
      begin
        LOutputFile := ParamStr(2);
        TFile.WriteAllText(LOutputFile, LManifest.Format, TEncoding.UTF8);
        WriteLn('Manifest salvo em: ' + LOutputFile);
      end;

      WriteLn('Total de arquivos no manifest: ' + LFilesObj.Count.ToString);
    finally
      LZipFile.Free;
      LManifest.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('ERRO: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
