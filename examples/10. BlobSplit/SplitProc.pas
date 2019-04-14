unit SplitProc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird, Classes, SysUtils, FbCharsets, FbTypes;

type

  { **********************************************************

    create procedure split (
        txt blob sub_type text character set utf8,
        delimiter varchar(8) character set utf8 = ','
    ) returns (
        id integer
    )
    external name 'BlobSplit!split'
    engine udr;

    ********************************************************* }

  TInput = record
    txt: ISC_QUAD;
    txtNull: WordBool;
    delimiter: record
      length: Smallint;
      data: array [0 .. 31] of AnsiChar;
    end;
    delimiterNull: WordBool;
  end;

  TInputPtr = ^TInput;

  TOutput = record
    txt: record
      length: Smallint;
      data: array [0 .. 32763] of AnsiChar;
    end;
    txtNull: WordBool;
  end;

  TOutputPtr = ^TOutput;

  // Фабрика для создания экземпляра внешней процедуры TSplitProcedure
  TSplitProcedureFactory = class(IUdrProcedureFactoryImpl)
    // Вызывается при уничтожении фабрики
    procedure dispose(); override;

    { Выполняется каждый раз при загрузке внешней процедуры в кеш метаданных

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней процедуры)
      @param(AMetadata Метаданные внешней процедуры)
      @param(AInBuilder Построитель сообщения для входных метаданных)
      @param(AOutBuilder Построитель сообщения для выходных метаданных)
    }
    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    { Создание нового экземпляра внешней процедуры TSplitProcedure

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения процедуры функции)
      @param(AMetadata Метаданные внешней процедуры)
      @returns(Экземпляр внешней функции)
    }
    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  TSplitProcedure = class(IExternalProcedureImpl)
  private
    procedure SaveBlobToStream(AStatus: IStatus; AContext: IExternalContext;
      ABlobId: ISC_QUADPtr; AStream: TStream);
    function readBlob(AStatus: IStatus; AContext: IExternalContext;
      ABlobId: ISC_QUADPtr): string;
  public
    // Вызывается при уничтожении экземпляра процедуры
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    function open(AStatus: IStatus; AContext: IExternalContext; AInMsg: Pointer;
      AOutMsg: Pointer): IExternalResultSet; override;
  end;

  TSplitResultSet = class(IExternalResultSetImpl)
{$IFDEF FPC}
    OutputArray: TStringArray;
{$ELSE}
    OutputArray: TArray<string>;
{$ENDIF}
    Counter: Integer;
    Output: TOutputPtr;

    procedure dispose(); override;
    function fetch(AStatus: IStatus): Boolean; override;
  end;

implementation

{ TSplitResultSet }

procedure TSplitResultSet.dispose;
begin
  SetLength(OutputArray, 0);
  Destroy;
end;

function TSplitResultSet.fetch(AStatus: IStatus): Boolean;
var
  xBytes: TBytes;
  xString: string;
begin
  if Counter <= High(OutputArray) then
  begin
    Output.txtNull := False;
    xString := OutputArray[Counter];
    if (xString.Length > 8191) then
      raise Exception.Create('String overflow');
    Output.txt.length := xString.Length;
    xBytes := TEncoding.UTF8.GetBytes(xString);
    Move(xBytes[0], Output.txt.data[0], High(xBytes) + 1);
    inc(Counter);
    Result := True;
  end
  else
    Result := False;
end;

{ TSplitProcedure }

procedure TSplitProcedure.dispose;
begin
  Destroy;
end;

procedure TSplitProcedure.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin

end;

function TSplitProcedure.open(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer): IExternalResultSet;
var
  xInput: TInputPtr;
  xText: string;
  xDelimiter: string;
begin
  xInput := AInMsg;
  if xInput.txtNull or xInput.delimiterNull then
  begin
    Result := nil;
    Exit;
  end;

  xText := readBlob(AStatus, AContext, @xInput.txt);
  xDelimiter := TFBCharSet.CS_UTF8.GetString(TBytes(@xInput.delimiter.data), 0, 4 * xInput.delimiter.length);
  // автоматически не правильно определяется потому что строки
  // не завершены нулём
  SetLength(xDelimiter, xInput.delimiter.length);

  Result := TSplitResultSet.Create;
  with TSplitResultSet(Result) do
  begin
    Output := AOutMsg;
    OutputArray := xText.Split([xDelimiter], TStringSplitOptions.ExcludeEmpty);
    Counter := 0;
  end;
end;

function TSplitProcedure.readBlob(AStatus: IStatus; AContext: IExternalContext;
  ABlobId: ISC_QUADPtr): string;
var
{$IFDEF FPC}
  xStream: TBytesStream;
{$ELSE}
  xStream: TStringStream;
{$ENDIF}
begin
{$IFDEF FPC}
  xStream := TBytesStream.Create(nil);
{$ELSE}
  xStream := TStringStream.Create('', 65001);
{$ENDIF}
  try
    SaveBlobToStream(AStatus, AContext, ABlobId, xStream);
{$IFDEF FPC}
    Result := TEncoding.UTF8.GetString(xStream.Bytes, 0, xStream.Size);
{$ELSE}
    Result := xStream.DataString;
{$ENDIF}
  finally
    xStream.Free;
  end;
end;

procedure TSplitProcedure.SaveBlobToStream(AStatus: IStatus;
  AContext: IExternalContext; ABlobId: ISC_QUADPtr; AStream: TStream);
var
  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array [0 .. 32767] of AnsiChar;
  l: Integer;
begin
  try
    att := AContext.getAttachment(AStatus);
    trx := AContext.getTransaction(AStatus);
    blob := att.openBlob(AStatus, trx, ABlobId, 0, nil);
    while True do
    begin
      case blob.getSegment(AStatus, SizeOf(buffer), @buffer, @l) of
        IStatus.RESULT_OK:
          AStream.WriteBuffer(buffer, l);
        IStatus.RESULT_SEGMENT:
          AStream.WriteBuffer(buffer, l);
      else
        break;
      end;
    end;
    AStream.Position := 0;
    blob.close(AStatus);
  finally
    if Assigned(att) then
      att.release;
    if Assigned(trx) then
      trx.release;
    if Assigned(blob) then
      blob.release;
  end;
end;

{ TSplitProcedureFactory }

procedure TSplitProcedureFactory.dispose;
begin
  Destroy;
end;

function TSplitProcedureFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalProcedure;
begin
  Result :=  TSplitProcedure.create();
end;

procedure TSplitProcedureFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
begin
  // входной BLOB
  AInBuilder.setType(AStatus, 0, Cardinal(SQL_QUAD));
  AInBuilder.setSubType(AStatus, 0, 1);
  AInBuilder.setCharSet(AStatus, 0, Cardinal(CS_UTF8));
  // разделитель
  AInBuilder.setType(AStatus, 1, Cardinal(SQL_VARYING));
  AInBuilder.setCharSet(AStatus, 1, Cardinal(CS_UTF8));
  AInBuilder.setLength(AStatus, 1, 4 * 8);
  // выходная строка
  AOutBuilder.setType(AStatus, 0, Cardinal(SQL_VARYING));
  AOutBuilder.setCharSet(AStatus, 0, Cardinal(CS_UTF8));
  AOutBuilder.setLength(AStatus, 0, 4 * 8191);
end;

end.
