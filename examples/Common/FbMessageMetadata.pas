unit FbMessageMetadata;

{$IFDEF MSWINDOWS}
{$DEFINE WINDOWS}
{$ENDIF}
{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses Firebird,
  FbTypes,
{$IFDEF WINDOWS} windows, {$ENDIF}
  Classes,
  SysUtils,
  SysConst,
  System.Generics.Collections;

const
  MAX_IDENTIFIER_LENGTH = 31; // дл¤ 4.0 = 63 * 4 -1

type



  // Ёлемент метаданных
  TFbMessageMetadataItem = class
  private
    FIndex: Cardinal;
    FSQLType: Cardinal;
    FSQLSubType: Integer;
    FDataLength: Cardinal;
    FNullable: Boolean;
    FScale: Integer;
    FCharSetID: Cardinal;
    FRelationName: AnsiString;
    FFieldName: AnsiString;
    FOwnerName: AnsiString;
    FAliasName: AnsiString;
    FOffset: Cardinal;
    FNullOffset: Cardinal;
    FEncoding: TEncoding;
    function GetCharSetName: AnsiString;
    function GetCharSetWidth: Word;
    function GetCodePage: Integer;
    function GetMaxCharLength: Integer;
    function GetEncoding: TEncoding;
    function GetSQLTypeAsString: string;
  public
    constructor Create(AStatus: IStatus; AMetaData: IMessageMetadata;
      AIndex: Cardinal);
    // ---------------
    property SQLType: Cardinal read FSQLType;
    property SQLSubType: Integer read FSQLSubType;
    property DataLength: Cardinal read FDataLength;
    property Nullable: Boolean read FNullable;
    property Scale: Integer read FScale;
    property CharsetID: Cardinal read FCharSetID;
    property RelationName: AnsiString read FRelationName;
    property FieldName: AnsiString read FFieldName;
    property OwnerName: AnsiString read FOwnerName;
    property AliasName: AnsiString read FAliasName;
    property Offset: Cardinal read FOffset;
    property NullOffset: Cardinal read FNullOffset;
    property Index: Cardinal read FIndex;
    // ---------------
    property CharSetName: AnsiString read GetCharSetName;
    property CharSetWidth: Word read GetCharSetWidth;
    property CodePage: Integer read GetCodePage;
    property MaxCharLength: Integer read GetMaxCharLength;
    property Encoding: TEncoding read GetEncoding;
    property SQLTypeAsString: string read GetSQLTypeAsString;
  end;

  // ћетаданные
  TFbMessageMetadata = class(TObjectList<TFbMessageMetadataItem>)
  private
    FMessageLength: Cardinal;
  public
    constructor Create(AStatus: IStatus; AMetaData: IMessageMetadata); overload;
    property MessageLength: Cardinal read FMessageLength;
  end;

implementation

uses FbCharsets;

  { TFbMessageMetadataItem }

constructor TFbMessageMetadataItem.Create(AStatus: IStatus;
  AMetaData: IMessageMetadata; AIndex: Cardinal);
begin
  FIndex := AIndex;
  SetLength(FRelationName, MAX_IDENTIFIER_LENGTH);
  SetLength(FFieldName, MAX_IDENTIFIER_LENGTH);
  SetLength(FOwnerName, MAX_IDENTIFIER_LENGTH);
  SetLength(FAliasName, MAX_IDENTIFIER_LENGTH);
  FRelationName := AMetaData.getRelation(AStatus, AIndex);
  FFieldName := AMetaData.getField(AStatus, AIndex);
  FOwnerName := AMetaData.getOwner(AStatus, AIndex);
  FAliasName := AMetaData.getAlias(AStatus, AIndex);
  FSQLType := AMetaData.getType(AStatus, AIndex);
  FNullable := AMetaData.isNullable(AStatus, AIndex);
  FSQLSubType := AMetaData.getSubType(AStatus, AIndex);
  FDataLength := AMetaData.getLength(AStatus, AIndex);
  FScale := AMetaData.getScale(AStatus, AIndex);
  FCharSetID := AMetaData.getCharSet(AStatus, AIndex);
  FOffset := AMetaData.getOffset(AStatus, AIndex);
  FNullOffset := AMetaData.getNullOffset(AStatus, AIndex);
end;

function TFbMessageMetadataItem.GetCharSetName: AnsiString;
begin
  Result := TFBCharSet(FCharSetID).GetCharSetName();
end;

function TFbMessageMetadataItem.GetCharSetWidth: Word;
begin
  Result := TFBCharSet(FCharSetID).GetCharWidth;
end;

function TFbMessageMetadataItem.GetCodePage: Integer;
begin
  Result := TFBCharSet(FCharSetID).GetCodePage;
end;

function TFbMessageMetadataItem.GetEncoding: TEncoding;
begin
  if not Assigned(FEncoding) then
    FEncoding := TEncoding.GetEncoding(CodePage);
  Result := FEncoding;
end;

function TFbMessageMetadataItem.GetMaxCharLength: Integer;
begin
  case TFBType(FSQLSubType) of
    SQL_VARYING, SQL_TEXT:
      Result := FDataLength div CharSetWidth;
    SQL_BLOB, SQL_QUAD:
      Result := High(Integer); // 2 √б
  else
    Result := 0;
  end;
end;

function TFbMessageMetadataItem.GetSQLTypeAsString: string;
begin
  case TFBType(FSQLType) of
    SQL_BOOLEAN:
    begin
      Result := 'BOOLEAN';
    end;

    SQL_SHORT:
    begin
      // учесть масштаб
      Result := 'SMALLINT';
    end;

    SQL_LONG:
    begin
      // учесть масштаб
      Result := 'INTEGER';
    end;

    SQL_INT64:
    begin
      // в 3-м диалекте учитваетс¤ масштаб
      if Scale = 0 then
        Result := 'BIGINT'
      else
        Result := 'NUMERIC(18 ,' + Abs(Scale).ToString() + ')';
    end;

    SQL_FLOAT:
    begin
      Result := 'FLOAT';
    end;

    SQL_DOUBLE, SQL_D_FLOAT:
    begin
      // в 1-м диалекте учитваетс¤ масштаб
      if Scale = 0 then
        Result := 'DOUBLE PRECISION'
      else
        Result := 'NUMERIC(15 ,' + Abs(Scale).ToString() + ')';
    end;

    SQL_DATE:
      Result := 'DATE';

    SQL_TIME:
      Result := 'TIME';

    SQL_TIMESTAMP:
      Result := 'TIMESTAMP';

    SQL_TEXT:
    begin
      Result := 'CHAR(' + MaxCharLength.ToString() + ')';
      if CharSetID <> 0 then
        Result := Result + ' CHARACTER SET ' + GetCharSetName();
    end;

    SQL_VARYING:
    begin
      Result := 'VARCHAR(' + MaxCharLength.ToString() + ')';
      if CharSetID <> 0 then
        Result := Result + ' CHARACTER SET ' + GetCharSetName();
    end;

    SQL_BLOB, SQL_QUAD:
    begin
      Result := 'BLOB';
      case SqlSubType of
        0: Result := Result + ' SUB_TYPE BINARY';
        1:
        begin
          Result := Result + ' SUB_TYPE TEXT';
          if CharSetID <> 0 then
            Result := Result + ' CHARACTER SET ' + GetCharSetName();
        end
        else
          Result := Result + ' SUB_TYPE ' + SqlSubType.ToString();
      end;
    end;
  end;
end;


{ TFbMessageMetadata }

constructor TFbMessageMetadata.Create(AStatus: IStatus;
  AMetaData: IMessageMetadata);
var
  xCount: Cardinal;
  i: Cardinal;
  xItem: TFbMessageMetadataItem;
begin
  inherited Create(True);
  xCount := AMetaData.getCount(AStatus);
  FMessageLength := AMetaData.getMessageLength(AStatus);
  for i := 0 to xCount - 1 do
  begin
    xItem := TFbMessageMetadataItem.Create(AStatus, AMetaData, i);
    Add(xItem);
  end;
end;


end.
