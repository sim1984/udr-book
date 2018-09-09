unit UdrMessages;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird;

type

  FB_CHAR<T> = packed record
    Value: T;
    Null: WordBool;
  end;

  FB_VARCHAR<T> = packed record
    Length: Smallint;
    Value: T;
    Null: WordBool;
  end;

  FB_SMALLINT = packed record
    Value: Smallint;
    Null: WordBool;
  end;

  FB_INTEGER = packed record
    Value: Integer;
    Null: WordBool;
  end;

  FB_BIGINT = packed record
    Value: Int64;
    Null: WordBool;
  end;

  FB_FLOAT = packed record
    Value: Single;
    Null: WordBool;
  end;

  FB_DOUBLE = packed record
    Value: Double;
    Null: WordBool;
  end;

  FB_BOOLEAN = packed record
    Value: ByteBool;
    Null: WordBool;
  end;

  FB_DATE = packed record
    Value: ISC_DATE;
    Null: WordBool;
  end;

  FB_TIME = packed record
    Value: ISC_TIME;
    Null: WordBool;
  end;

  ISC_TIMESTAMP = record
    date: ISC_DATE;
    time: ISC_TIME;
  end;

  FB_TIMESTAMP = packed record
    Value: ISC_TIMESTAMP;
    Null: WordBool;
  end;

  FB_BLOB = packed record
    Value: ISC_QUAD;
    Null: WordBool;
  end;

implementation

end.
