unit BlobCountFunc;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}
interface

uses
  Firebird, Udr;

type

// *********************************************************
// create function blob_count (
// s blob
// ) returns integer
// external name 'myudr!blob_count'
// engine udr;
// *********************************************************
  TBlobCountFunction = class(TUdrFunction)

    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;

  end;

implementation

uses UdrMessages, Classes;

{ TBlobCountFunction }

procedure TBlobCountFunction.execute(AStatus: IStatus;
  AContext: IExternalContext; AInMsg, AOutMsg: Pointer);
var
  Input: ^FB_BLOB;
  Output: ^FB_INTEGER;

  xStream: TStringStream;

  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array[0..1023] of AnsiChar;
  l: Integer;
begin
  Input := AInMsg;
  Output := AOutMsg;
  if Input.Null then
  begin
    Output.Null := True;
    Exit;
  end;
  {$IFDEF FPC}
  xStream := TStringStream.Create('');
  {$ELSE}
  xStream := TStringStream.Create('', 65001);
  {$ENDIF}

  att := AContext.getAttachment(AStatus);
  trx := AContext.getTransaction(AStatus);
  blob := att.openBlob(AStatus, trx, @Input.Value, 0, nil);
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
  blob.close(AStatus);
  blob.release;
  trx.release;
  att.release;

  Output.Null := False;
  Output.Value := Length(xStream.DataString);

  xStream.Free;

end;

end.
