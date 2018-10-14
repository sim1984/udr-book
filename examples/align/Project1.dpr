program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

type
  TRec = record
    n1: Integer;
    n2: WordBool;
    n3: Integer;
    n4: WordBool;
    n5: Integer;
    n6: WordBool;
    n7: Smallint;
    n8: WordBool;
  end;
  PRec = ^TRec;

  TRec2 = record
    n1: packed record
      value: integer;
      null: wordbool
    end;
    n2: packed record
      value: integer;
      null: wordbool
    end;
    n3: packed record
      value: integer;
      null: wordbool
    end;
    n4: packed record
      value: Smallint;
      null: wordbool
    end;
  end;
  PRec2 = ^TRec2;

function ByteToStr(bytes: TBytes): string;
const
  BytesHex: array[0..15] of char =
    ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  i, len: integer;
begin
  len := Length(bytes);
  SetLength(Result, len * 5);
  for i := 0 to len - 1 do begin
    Result[i * 5 + 1] := '0';
    Result[i * 5 + 2] := 'x';
    Result[i * 5 + 3] := BytesHex[bytes[i] shr 4];
    Result[i * 5 + 4] := BytesHex[bytes[i] and $0F];
    Result[i * 5 + 5] := ' ';
  end;
end;

var
  xBuffer: TBytes;
  xRec: TRec;
  xRec2: TRec2;

begin
  try
    SetLength(xBuffer, 26);
    //FillChar(xBuffer, 26, 0);
    xBuffer[0] := $01;
    xBuffer[4] := $01;
    xBuffer[8] := $02;
    xBuffer[12] := $00;
    xBuffer[16] := $03;
    xBuffer[20] := $01;
    xBuffer[22] := $04;
    xBuffer[24] := $01;
    Writeln(ByteToStr(xBuffer));
    Writeln('SizeOf(TRec) = ', Sizeof(TRec));
    xRec := PRec(@xBuffer[0])^;
    Writeln('n1 = ', xRec.n1);
    Writeln('n2 = ', xRec.n2);
    Writeln('n3 = ', xRec.n3);
    Writeln('n4 = ', xRec.n4);
    Writeln('n5 = ', xRec.n5);
    Writeln('n6 = ', xRec.n6);
    Writeln('n7 = ', xRec.n7);
    Writeln('n8 = ', xRec.n8);
    Writeln('SizeOf(TRec2) = ', Sizeof(TRec2));
    xRec2 := PRec2(@xBuffer[0])^;
    Writeln('n1 = ', xRec2.n1.value);
    Writeln('null_1 = ', xRec2.n1.null);
    Writeln('n2 = ', xRec2.n2.value);
    Writeln('null_2 = ', xRec2.n2.null);
    Writeln('n3 = ', xRec2.n3.value);
    Writeln('null_3 = ', xRec2.n3.null);
    Writeln('n4 = ', xRec2.n4.value);
    Writeln('null_4 = ', xRec2.n4.null);
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
