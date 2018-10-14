unit FbTypes;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird;

type
  // типы Firebird
  TFBType = (
    SQL_VARYING = 448, // VARCHAR
    SQL_TEXT = 452, // CHAR
    SQL_DOUBLE = 480, // DOUBLE PRECISION
    SQL_FLOAT = 482, // FLOAT
    SQL_SHORT = 500, // SMALLINT
    SQL_LONG = 496, // INTEGER
    SQL_TIMESTAMP = 510, // TIMESTAMP
    SQL_BLOB = 520, // BLOB
    SQL_D_FLOAT = 530, // DOUBLE PRECISION
    SQL_ARRAY = 540, // ARRAY
    SQL_QUAD = 550, // BLOB_ID (QUAD)
    SQL_TIME = 560, // TIME
    SQL_DATE = 570, // DATE
    SQL_INT64 = 580, // BIGINT
    SQL_BOOLEAN = 32764, // BOOLEAN
    SQL_NULL = 32766 // NULL
    );

  // TIMESTAMP
  ISC_TIMESTAMP = record
    date: ISC_DATE;
    time: ISC_TIME;
  end;

  // указатели на специальные типы
  PISC_DATE = ^ISC_DATE;
  PISC_TIME = ^ISC_TIME;
  PISC_TIMESTAMP = ^ISC_TIMESTAMP;
  PISC_QUAD = ^ISC_QUAD;

  TVarChar<T> = record
    Length: Smallint;
    value: T
  end;

implementation

end.
