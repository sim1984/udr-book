{
  *  PROGRAM:    UDR samples.
  *  MODULE:     JsonFunc.pas
  *  DESCRIPTION:    A sample work with IExternalContext in extenal function.
  *
  *  The contents of this file are subject to the Initial
  *  Developer's Public License Version 1.0 (the "License");
  *  you may not use this file except in compliance with the
  *  License. You may obtain a copy of the License at
  *  http://www.ibphoenix.com/main.nfs?a=ibphoenix&page=ibp_idpl.
  *
  *  Software distributed under the License is distributed AS IS,
  *  WITHOUT WARRANTY OF ANY KIND, either express or implied.
  *  See the License for the specific language governing rights
  *  and limitations under the License.
  *
  *  The Original Code was created by Simonov Denis
  *  for the book Writing UDR Firebird in Pascal.
  *
  *  Copyright (c) 2018 Simonov Denis <sim-mail@list.ru>
  *  and all contributors signed below.
  *
  *  All Rights Reserved.
  *  Contributor(s): ______________________________________. }

unit JsonFunc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird,
  FbTypes,
  FbCharsets,
  SysUtils,
{$IFDEF FPC}
  fpjson,
  base64
{$ELSE}
  System.NetEncoding,
  System.Json
{$ENDIF}
    ;

{ *********************************************************
  create function GetJson (
    sql_text blob sub_type text,
    sql_dialect smallint not null default 3
  ) returns blob sub_type text character set utf8
  external name 'JsonUtils!getJson'
  engine udr;
 ********************************************************* }

type

  TInput = record
    SqlText: ISC_QUAD;
    SqlNull: WordBool;
    SqlDialect: Smallint;
    SqlDialectNull: WordBool;
  end;

  InputPtr = ^TInput;

  TOutput = record
    Json: ISC_QUAD;
    NullFlag: WordBool;
  end;

  OutputPtr = ^TOutput;

  // Внешняя функция TSumArgsFunction.
  TJsonFunction = class(IExternalFunctionImpl)
  public
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    { Преобразует целое в строку в соответсвии с масштабом

      @param(AValue Значение)
      @param(Scale Масштаб)
      @returns(Строковое представление масштабированного целого)
    }
    function MakeScaleInteger(AValue: Int64; Scale: Smallint): string;

    { Добавляет закодированную запись в массив объектов Json

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AJson Массив объектов Json)
      @param(ABuffer Буфер записи)
      @param(AMeta Метаданые курсора)
      @param(AFormatSetting Установки формата даты и времени)
    }
    procedure writeJson(AStatus: IStatus; AContext: IExternalContext;
      AJson: TJsonArray; ABuffer: PByte; AMeta: IMessageMetadata;
      AFormatSettings: TFormatSettings);

    { Выполнение внешней функции

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AInMsg Указатель на входное сообщение)
      @param(AOutMsg Указатель на выходное сообщение)
    }
    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;
  end;

implementation

uses
  Classes, FbBlob;

{ TJsonFunction }

procedure TJsonFunction.dispose;
begin
  Destroy;
end;

procedure TJsonFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
var
  xFormatSettings: TFormatSettings;
  xInput: InputPtr;
  xOutput: OutputPtr;
  att: IAttachment;
  tra: ITransaction;
  stmt: IStatement;
  inBlob, outBlob: IBlob;
  inStream: TBytesStream;
  outStream: TStringStream;
  cursorMetaData: IMessageMetadata;
  rs: IResultSet;
  msgLen: Cardinal;
  msg: Pointer;
  jsonArray: TJsonArray;
begin
  xInput := AInMsg;
  xOutput := AOutMsg;
  // если один из входных аргументов NULL, то и результат NULL
  if xInput.SqlNull or xInput.SqlDialectNull then
  begin
    xOutput.NullFlag := True;
    Exit;
  end;
  xOutput.NullFlag := False;
  // установки форматирования даты и времени
{$IFNDEF FPC}
  xFormatSettings := TFormatSettings.Create;
{$ELSE}
  xFormatSettings := DefaultFormatSettings;
{$ENDIF}
  xFormatSettings.DateSeparator := '-';
  xFormatSettings.TimeSeparator := ':';
  // создаём поток байт для чтения blob
  inStream := TBytesStream.Create(nil);
{$IFNDEF FPC}
  outStream := TStringStream.Create('', 65001);
{$ELSE}
  outStream := TStringStream.Create('');
{$ENDIF}
  jsonArray := TJsonArray.Create;
  // получение текущего соединения и транзакции
  att := AContext.getAttachment(AStatus);
  tra := AContext.getTransaction(AStatus);
  stmt := nil;
  rs := nil;
  inBlob := nil;
  outBlob := nil;
  try
    // читаем BLOB в поток
    inBlob := att.openBlob(AStatus, tra, @xInput.SqlText, 0, nil);
    inBlob.SaveToStream(AStatus, inStream);
    // метод close в случае успеха совобождает интерфейс IBlob
    // поэтому последующий вызов release не нужен
    inBlob.close(AStatus);
    inBlob := nil;
    // подготавливаем оператор
    stmt := att.prepare(AStatus, tra, inStream.Size, @inStream.Bytes[0],
      xInput.SqlDialect, IStatement.PREPARE_PREFETCH_METADATA);
    // получаем выходные метаданные курсора
    cursorMetaData := stmt.getOutputMetadata(AStatus);
    // откурываем курсор
    rs := stmt.openCursor(AStatus, tra, nil, nil, nil, 0);
    // выделяем буфер нужного размера
    msgLen := cursorMetaData.getMessageLength(AStatus);
    msg := AllocMem(msgLen);
    try
      // читаем каждую запись курсора
      while rs.fetchNext(AStatus, msg) = IStatus.RESULT_OK do
      begin
        // и пишем её в JSON
        writeJson(AStatus, AContext, jsonArray, msg, cursorMetaData,
          xFormatSettings);
      end;
    finally
      // освобождаем буфер
      FreeMem(msg);
    end;
    // закрываем курсор
    // метод close в случае успеха совобождает интерфейс IResultSet
    // поэтому последующий вызов release не нужен
    rs.close(AStatus);
    rs := nil;
    // освобождаем подготовленный запрос
    // метод free в случае успеха совобождает интерфейс IStatement
    // поэтому последующий вызов release не нужен
    stmt.free(AStatus);
    stmt := nil;
    // пишем JSON в поток
{$IFNDEF FPC}
    outStream.WriteString(jsonArray.ToJSON);
{$ELSE}
    outStream.WriteString(jsonArray.AsJSON);
{$ENDIF}
    // пишем json в выходной blob
    outBlob := att.createBlob(AStatus, tra, @xOutput.Json, 0, nil);
    outBlob.LoadFromStream(AStatus, outStream);
    // метод close в случае успеха совобождает интерфейс IBlob
    // поэтому последующий вызов release не нужен
    outBlob.close(AStatus);
    outBlob := nil;
  finally
    if Assigned(inBlob) then
      inBlob.release;
    if Assigned(stmt) then
      stmt.release;
    if Assigned(rs) then
      rs.release;
    if Assigned(outBlob) then
      outBlob.release;
    tra.release;
    att.release;
    jsonArray.Free;
    inStream.Free;
    outStream.Free;
  end;
end;

procedure TJsonFunction.getCharSet(AStatus: IStatus; AContext: IExternalContext;
  AName: PAnsiChar; ANameSize: Cardinal);
begin
end;

function TJsonFunction.MakeScaleInteger(AValue: Int64; Scale: Smallint): string;
var
  L: Integer;
begin
  Result := AValue.ToString;
  L := Result.Length;
  if (-Scale >= L) then
    Result := '0.' + Result.PadLeft(-Scale, '0')
  else
    Result := Result.Insert(Scale + L, '.');
end;

procedure TJsonFunction.writeJson(AStatus: IStatus; AContext: IExternalContext;
  AJson: TJsonArray; ABuffer: PByte; AMeta: IMessageMetadata;
  AFormatSettings: TFormatSettings);
var
  jsonObject: TJsonObject;
  i: Integer;
  FieldName: string;
  NullFlag: WordBool;
  fieldType: Cardinal;
  pData: PByte;
  util: IUtil;
  metaLength: Integer;
  // типы
  CharBuffer: TBytes;
  charLength: Smallint;
  charset: TFBCharSet;
  StringValue: string;
  SmallintValue: Smallint;
  IntegerValue: Integer;
  BigintValue: Int64;
  Scale: Smallint;
  SingleValue: Single;
  DoubleValue: Double;
  BooleanValue: Boolean;
  DateValue: ISC_DATE;
  TimeValue: ISC_TIME;
  TimestampValue: ISC_TIMESTAMP;
  DateTimeValue: TDateTime;
  year, month, day: Cardinal;
  hours, minutes, seconds, fractions: Cardinal;
  blobId: ISC_QUADPtr;
  BlobSubtype: Smallint;
  att: IAttachment;
  tra: ITransaction;
  blob: IBlob;
  textStream: TStringStream;
  binaryStream: TBytesStream;
{$IFDEF FPC}
  base64Stream: TBase64EncodingStream;
  xFloatJson: TJSONFloatNumber;
{$ENDIF}
begin
  // Получаем IUtil
  util := AContext.getMaster().getUtilInterface();
  // Создаём объект TJsonObject в которой будем
  // записывать значение полей записи
  jsonObject := TJsonObject.Create;
  for i := 0 to AMeta.getCount(AStatus) - 1 do
  begin
    // получаем алиас поля в запросе
    FieldName := AMeta.getAlias(AStatus, i);
    NullFlag := PWordBool(ABuffer + AMeta.getNullOffset(AStatus, i))^;
    if NullFlag then
    begin
      // если NULL пишем его в JSON и переходим к следующему полю
{$IFNDEF FPC}
      jsonObject.AddPair(FieldName, TJsonNull.Create);
{$ELSE}
      jsonObject.Add(FieldName, TJsonNull.Create);
{$ENDIF}
      continue;
    end;
    // получаем указатель на данные поля
    pData := ABuffer + AMeta.getOffset(AStatus, i);
    // аналог AMeta->getType(AStatus, i) & ~1
    fieldType := AMeta.getType(AStatus, i) and not 1;
    case fieldType of
      // VARCHAR
      SQL_VARYING:
        begin
          // размер буфера для VARCHAR
          metaLength := AMeta.getLength(AStatus, i);
          SetLength(CharBuffer, metaLength);
          charset := TFBCharSet(AMeta.getCharSet(AStatus, i));
          charLength := PSmallint(pData)^;
          // бинарные данные кодируем в base64
          if charset = CS_BINARY then
          begin
{$IFNDEF FPC}
            StringValue := TNetEncoding.base64.EncodeBytesToString((pData + 2),
              charLength);
{$ELSE}
            // Для VARCHAR первые 2 байта - длина в байтах
            // поэтому копируем в буфер начиная с 3 байта
            Move((pData + 2)^, CharBuffer[0], metaLength);
            StringValue := charset.GetString(CharBuffer, 0, charLength);
            StringValue := EncodeStringBase64(StringValue);
{$ENDIF}
          end
          else
          begin
            // Для VARCHAR первые 2 байта - длина в байтах
            // поэтому копируем в буфер начиная с 3 байта
            Move((pData + 2)^, CharBuffer[0], metaLength);
            StringValue := charset.GetString(CharBuffer, 0, charLength);
          end;
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, StringValue);
{$ELSE}
          jsonObject.Add(FieldName, StringValue);
{$ENDIF}
        end;
      // CHAR
      SQL_TEXT:
        begin
          // размер буфера для CHAR
          metaLength := AMeta.getLength(AStatus, i);
          SetLength(CharBuffer, metaLength);
          charset := TFBCharSet(AMeta.getCharSet(AStatus, i));
          Move(pData^, CharBuffer[0], metaLength);
          // бинарные данные кодируем в base64
          if charset = CS_BINARY then
          begin
{$IFNDEF FPC}
            StringValue := TNetEncoding.base64.EncodeBytesToString(pData,
              metaLength);
{$ELSE}
            StringValue := charset.GetString(CharBuffer, 0, metaLength);
            StringValue := EncodeStringBase64(StringValue);
{$ENDIF}
          end
          else
          begin
            StringValue := charset.GetString(CharBuffer, 0, metaLength);
            charLength := metaLength div charset.GetCharWidth;
            SetLength(StringValue, charLength);
          end;
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, StringValue);
{$ELSE}
          jsonObject.Add(FieldName, StringValue);
{$ENDIF}
        end;
      // FLOAT
      SQL_FLOAT:
        begin
          SingleValue := PSingle(pData)^;
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, TJSONNumber.Create(SingleValue));
{$ELSE}
          jsonObject.Add(FieldName, TJSONFloatNumber.Create(SingleValue));
{$ENDIF}
        end;
      // DOUBLE PRECISION
      // DECIMAL(p, s), где p = 10..15 в 1 диалекте
      SQL_DOUBLE, SQL_D_FLOAT:
        begin
          DoubleValue := PDouble(pData)^;
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, TJSONNumber.Create(DoubleValue));
{$ELSE}
          jsonObject.Add(FieldName, TJSONFloatNumber.Create(DoubleValue));
{$ENDIF}
        end;
      // INTEGER
      // NUMERIC(p, s), где p = 1..4
      SQL_SHORT:
        begin
          Scale := AMeta.getScale(AStatus, i);
          SmallintValue := PSmallint(pData)^;
          if (Scale = 0) then
          begin
{$IFNDEF FPC}
            jsonObject.AddPair(FieldName, TJSONNumber.Create(SmallintValue));
{$ELSE}
            jsonObject.Add(FieldName, SmallintValue);
{$ENDIF}
          end
          else
          begin
            StringValue := MakeScaleInteger(SmallintValue, Scale);
{$IFNDEF FPC}
            jsonObject.AddPair(FieldName, TJSONNumber.Create(StringValue));
{$ELSE}
            xFloatJson := TJSONFloatNumber.Create(0);
            xFloatJson.AsString := StringValue;
            jsonObject.Add(FieldName, xFloatJson);
{$ENDIF}
          end;
        end;
      // INTEGER
      // NUMERIC(p, s), где p = 5..9
      // DECIMAL(p, s), где p = 1..9
      SQL_LONG:
        begin
          Scale := AMeta.getScale(AStatus, i);
          IntegerValue := PInteger(pData)^;
          if (Scale = 0) then
          begin
{$IFNDEF FPC}
            jsonObject.AddPair(FieldName, TJSONNumber.Create(IntegerValue));
{$ELSE}
            jsonObject.Add(FieldName, IntegerValue);
{$ENDIF}
          end
          else
          begin
            StringValue := MakeScaleInteger(IntegerValue, Scale);
{$IFNDEF FPC}
            jsonObject.AddPair(FieldName, TJSONNumber.Create(StringValue));
{$ELSE}
            xFloatJson := TJSONFloatNumber.Create(0);
            xFloatJson.AsString := StringValue;
            jsonObject.Add(FieldName, xFloatJson);
{$ENDIF}
          end;
        end;
      // BIGINT
      // NUMERIC(p, s), где p = 10..18 в 3 диалекте
      // DECIMAL(p, s), где p = 10..18 в 3 диалекте
      SQL_INT64:
        begin
          Scale := AMeta.getScale(AStatus, i);
          BigintValue := Pint64(pData)^;
          if (Scale = 0) then
          begin
{$IFNDEF FPC}
            jsonObject.AddPair(FieldName, TJSONNumber.Create(BigintValue));
{$ELSE}
            jsonObject.Add(FieldName, BigintValue);
{$ENDIF}
          end
          else
          begin
            StringValue := MakeScaleInteger(BigintValue, Scale);
{$IFNDEF FPC}
            jsonObject.AddPair(FieldName, TJSONNumber.Create(StringValue));
{$ELSE}
            xFloatJson := TJSONFloatNumber.Create(0);
            xFloatJson.AsString := StringValue;
            jsonObject.Add(FieldName, xFloatJson);
{$ENDIF}
          end;
        end;
      // TIMESTAMP
      SQL_TIMESTAMP:
        begin
          TimestampValue := PISC_TIMESTAMP(pData)^;
          // получаем составные части даты-времени
          util.decodeDate(TimestampValue.date, @year, @month, @day);
          util.decodeTime(TimestampValue.time, @hours, @minutes, @seconds,
            @fractions);
          // получаем дату-время в родном типе Delphi
          DateTimeValue := EncodeDate(year, month, day) +
            EncodeTime(hours, minutes, seconds, fractions div 10);
          // форматируем дату-время по заданному формату
          StringValue := FormatDateTime('yyyy/mm/dd hh:nn:ss', DateTimeValue,
            AFormatSettings);
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, StringValue);
{$ELSE}
          jsonObject.Add(FieldName, StringValue);
{$ENDIF}
        end;
      // DATE
      SQL_DATE:
        begin
          DateValue := PISC_DATE(pData)^;
          // получаем составные части даты
          util.decodeDate(DateValue, @year, @month, @day);
          // получаем дату в родном типе Delphi
          DateTimeValue := EncodeDate(year, month, day);
          // форматируем дату по заданному формату
          StringValue := FormatDateTime('yyyy/mm/dd', DateTimeValue,
            AFormatSettings);
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, StringValue);
{$ELSE}
          jsonObject.Add(FieldName, StringValue);
{$ENDIF}
        end;
      // TIME
      SQL_TIME:
        begin
          TimeValue := PISC_TIME(pData)^;
          // получаем составные части времени
          util.decodeTime(TimeValue, @hours, @minutes, @seconds, @fractions);
          // получаем время в родном типе Delphi
          DateTimeValue := EncodeTime(hours, minutes, seconds,
            fractions div 10);
          // форматируем время по заданному формату
          StringValue := FormatDateTime('hh:nn:ss', DateTimeValue,
            AFormatSettings);
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, StringValue);
{$ELSE}
          jsonObject.Add(FieldName, StringValue);
{$ENDIF}
        end;
      // BOOLEAN
      SQL_BOOLEAN:
        begin
          BooleanValue := PBoolean(pData)^;
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, TJsonBool.Create(BooleanValue));
{$ELSE}
          jsonObject.Add(FieldName, BooleanValue);
{$ENDIF}
        end;
      // BLOB
      SQL_BLOB, SQL_QUAD:
        begin
          BlobSubtype := AMeta.getSubType(AStatus, i);
          blobId := ISC_QUADPtr(pData);
          att := AContext.getAttachment(AStatus);
          tra := AContext.getTransaction(AStatus);
          blob := att.openBlob(AStatus, tra, blobId, 0, nil);
          try
            if BlobSubtype = 1 then
            begin
              // текст
              charset := TFBCharSet(AMeta.getCharSet(AStatus, i));
              // создаём поток с заданой кодировкой
{$IFNDEF FPC}
              textStream := TStringStream.Create('', charset.GetCodePage);
              try
                blob.SaveToStream(AStatus, textStream);
                blob.close(AStatus);
                blob := nil;
                StringValue := textStream.DataString;
              finally
                textStream.Free;
              end;
{$ELSE}
              binaryStream := TBytesStream.Create(nil);
              try
                blob.SaveToStream(AStatus, binaryStream);
                blob.close(AStatus);
                blob := nil;
                StringValue := TEncoding.UTF8.GetString(binaryStream.Bytes, 0,
                  binaryStream.Size);
              finally
                binaryStream.Free;
              end;
{$ENDIF}
            end
            else
            begin
{$IFNDEF FPC}
              // все остальные подтипытипы считаем бинарными
              binaryStream := TBytesStream.Create;
              try
                blob.SaveToStream(AStatus, binaryStream);
                blob.close(AStatus);
                blob := nil;
                // кодируем строку в base64
                StringValue := TNetEncoding.base64.EncodeBytesToString
                  (binaryStream.Memory, binaryStream.Size);
              finally
                binaryStream.Free;
              end
{$ELSE}
              textStream := TStringStream.Create('');
              base64Stream := TBase64EncodingStream.Create(textStream);
              try
                blob.SaveToStream(AStatus, base64Stream);
                blob.close(AStatus);
                blob := nil;
                StringValue := textStream.DataString;
              finally
                base64Stream.Free;
                textStream.Free;
              end;
{$ENDIF}
            end;
          finally
            if Assigned(blob) then blob.release;
            if Assigned(tra) then tra.release;
            if Assigned(att) then att.release;
          end;
{$IFNDEF FPC}
          jsonObject.AddPair(FieldName, StringValue);
{$ELSE}
        end;
        jsonObject.Add(FieldName, StringValue);
{$ENDIF}
      end;

    end;
  end;
  // добавление записи в формате Json в массив
{$IFNDEF FPC}
  AJson.AddElement(jsonObject);
{$ELSE}
  AJson.Add(jsonObject);
{$ENDIF}
end;

end.
