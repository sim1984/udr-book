unit SplitProc;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}
interface

uses
  Firebird, Udr, UdrMessages, Classes;

type
// *********************************************************
// create procedure split (
// txt blob sub_type text chacater set utf8,
// delimiter char(1) chacater set utf8 = ','
// ) returns (id integer)
// external name 'myudr!split'
// engine udr;
// *********************************************************

  TSplitProcedure = class(TUdrProcedure)
    function open(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer): IExternalResultSet; override;
  end;

  TSplitResultSet = class(IExternalResultSetImpl)
    type
      TInput = record
        txt: FB_BLOB;
        delimiter: FB_CHAR<array[0..3] of AnsiChar>;
      end;
      PInput = ^TInput;
  private
    FOutputArray: TArray<string>;
    FCounter: Integer;
  public
    Input: PInput;
    Output: ^FB_INTEGER;

		procedure dispose(); override;
    procedure open(AStatus: IStatus; AContext: IExternalContext);
		function fetch(AStatus: IStatus): Boolean; override;
  end;

implementation

uses SysUtils;

{ TSplitResultSet }


procedure TSplitResultSet.dispose;
begin
  SetLength(FOutputArray, 0);
  Destroy;
end;

function TSplitResultSet.fetch(AStatus: IStatus): Boolean;
var
	statusVector: array[0..4] of NativeIntPtr;
begin
  if FCounter <= High(FOutputArray) then
  begin
    Output.Null := False;
    try
      Output.Value := FOutputArray[FCounter].ToInteger();
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
    inc(FCounter);
    Result := True;
  end
  else
    Result := False;
end;

procedure TSplitResultSet.open(AStatus: IStatus; AContext: IExternalContext);
var
  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array[0..32767] of AnsiChar;
  l: Integer;
  xStream: TStringStream;
  xDelimiter: string;
begin
  if Input.txt.Null or Input.delimiter.Null then
    Exit;

  xStream := TStringStream.Create('', 65001);

  att := AContext.getAttachment(AStatus);
  trx := AContext.getTransaction(AStatus);
  blob := att.openBlob(AStatus, trx, @Input.txt.Value, 0, nil);
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
  blob.close(AStatus);
  blob.release;
  trx.release;
  att.release;

  xDelimiter := Utf8ToString(Input.delimiter.Value);
  // автоматически не правильно определяется
  SetLength(xDelimiter, 1);

  FOutputArray := xStream.DataString.Split([xDelimiter], ExcludeEmpty);
  xStream.Free;

  FCounter := 0;
end;

{ TSplitProcedure }

function TSplitProcedure.open(AStatus: IStatus; AContext: IExternalContext; AInMsg,
  AOutMsg: Pointer): IExternalResultSet;
begin
  Result := TSplitResultSet.create;
  TSplitResultSet(Result).Input := AInMsg;
  TSplitResultSet(Result).Output := AOutMsg;
  TSplitResultSet(Result).Open(AStatus, AContext);
end;

end.
