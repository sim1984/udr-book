unit SplitProc;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird, Udr, UdrMessages, Classes, SysUtils;

type
  // *********************************************************
  // create procedure split (
  // txt blob sub_type text character set utf8,
  // delimiter char(1) character set utf8 = ','
  // ) returns (id integer)
  // external name 'myudr!split'
  // engine udr;
  // *********************************************************

  TSplitProcedure = class(TUdrProcedure)
  private
    function readBlob(AStatus: IStatus; AContext: IExternalContext;
      ABlobId: ISC_QUADPtr): string;
  public
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
    Output: ^FB_INTEGER;

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
  statusVector: array [0 .. 4] of NativeIntPtr;
begin
  if Counter <= High(OutputArray) then
  begin
    Output^.Null := False;
    // исключение будут перехвачены в любом случае с кодом isc_random
    // здесь же мы будем выбрасывать стандартную для Firebird
    // ошибку isc_convert_error
    try
      Output^.Value := OutputArray[Counter].ToInteger();
    except
      on e: EConvertError do
      begin

        statusVector[0] := NativeIntPtr(isc_arg_gds);
        statusVector[1] := NativeIntPtr(isc_convert_error);
        statusVector[2] := NativeIntPtr(isc_arg_string);
        statusVector[3] := NativeIntPtr(PAnsiChar(''));
        statusVector[4] := NativeIntPtr(isc_arg_end);

        AStatus.setErrors(@statusVector);
      end;
    end;
    inc(Counter);
    Result := True;
  end
  else
    Result := False;
end;


{ TSplitProcedure }

function TSplitProcedure.open(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer): IExternalResultSet;
type
  {$IFDEF FPC}
  CHAR_1 = array[0 .. 3] of AnsiChar;
  TInput = record
    txt: FB_BLOB;
    delimiter: FB_CHAR <CHAR_1>;
  end;
  {$ELSE}
  TInput = record
    txt: FB_BLOB;
    delimiter: FB_CHAR <array[0 .. 3] of AnsiChar>;
  end;
  {$ENDIF}
var
  xInput: ^TInput;
  xText: string;
  xDelimiter: string;
begin
  xInput := AInMsg;
  if xInput.txt.Null or xInput.delimiter.Null then
  begin
    Result := nil;
    Exit;
  end;

  xText := readBlob(AStatus, AContext, @xInput.txt.Value);
  {$IFDEF FPC}
  // c FPC надо серьёзно подумать не пашет
  xDelimiter := string(utf8string(xInput.delimiter.Value));
  {$ELSE}
  xDelimiter := Utf8ToString(xInput.delimiter.Value);
  {$ENDIF}
  // автоматически не правильно определяется
  SetLength(xDelimiter, 1);

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
  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array [0 .. 32767] of AnsiChar;
  l: Integer;
  xStream: TStringStream;
begin
  {$IFDEF FPC}
  xStream := TStringStream.Create('');
  {$ELSE}
  xStream := TStringStream.Create('', 65001);
  {$ENDIF}
  try
    att := AContext.getAttachment(AStatus);
    trx := AContext.getTransaction(AStatus);
    blob := att.openBlob(AStatus, trx, ABlobId, 0, nil);
    while True do
    begin
      case blob.getSegment(AStatus, SizeOf(buffer), @buffer, @l) of
        IStatus.RESULT_OK:
          xStream.WriteBuffer(buffer, l);
        IStatus.RESULT_SEGMENT:
          xStream.WriteBuffer(buffer, l);
      else
        break;
      end;
    end;
    xStream.Position := 0;
    Result := xStream.DataString;
    blob.close(AStatus);
  finally
    if Assigned(att) then
      att.release;
    if Assigned(trx) then
      trx.release;
    if Assigned(blob) then
      blob.release;
    xStream.Free;
  end;

end;

end.
