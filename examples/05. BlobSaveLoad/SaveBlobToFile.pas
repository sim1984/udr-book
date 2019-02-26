unit SaveBlobToFile;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird, Classes, SysUtils;

type

  { **********************************************************

    create procedure SaveBlobToFile (
        ABlobData blob sub_type binary,
        AFileName varchar(255) character set utf8
    );
    external name 'BlobFileUtils!SaveBlobToFile'
    engine udr;

    ********************************************************* }

  TInput = record
    blobData: ISC_QUAD;
    blobDataNull: WordBool;
    filename: record
      len: Smallint;
      str: array [0 .. 1019] of AnsiChar;
    end;
    filenameNull: WordBool;
  end;

  TInputPtr = ^TInput;


  TSaveBlobToFileProc = class(IExternalProcedureImpl)
  public
    // Вызывается при уничтожении экземпляра процедуры
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    function open(AStatus: IStatus; AContext: IExternalContext; AInMsg: Pointer;
      AOutMsg: Pointer): IExternalResultSet; override;
  end;

  // Фабрика для создания экземпляра внешней процедуры TSaveBlobToFileProc
  TSaveBlobToFileProcFactory = class(IUdrProcedureFactoryImpl)
    // Вызывается при уничтожении фабрики
    procedure dispose(); override;


    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;


    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

implementation

{ TSaveBlobToFileProc }

procedure TSaveBlobToFileProc.dispose;
begin

end;


procedure TSaveBlobToFileProc.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin

end;

function TSaveBlobToFileProc.open(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer): IExternalResultSet;
var
  xInput: TInputPtr;
  xFileName: string;
  xStream: TFileStream;
  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array [0 .. 32767] of AnsiChar;
  l: Integer;
begin
  xInput := AInMsg;
  if xInput.blobDataNull or xInput.filenameNull then
  begin
    Result := nil;
    Exit;
  end;

  xFileName := TEncoding.UTF8.GetString(TBytes(@xInput.filename.str), 0, xInput.filename.len * 4);
  SetLength(xFileName, xInput.filename.len);
  xStream := TFileStream.Create(xFileName, fmCreate);
  att := AContext.getAttachment(AStatus);
  trx := AContext.getTransaction(AStatus);
  blob := nil;
  try
    xStream.Seek(0, soFromBeginning);
    blob := att.openBlob(AStatus, trx, @xInput.blobData, 0, nil);
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
  finally
    if Assigned(blob) then
      blob.release;
    att.release;
    trx.release;
    xStream.Free;
  end;

  Result := nil;
end;


{ TSaveBlobToFileProcFactory }

procedure TSaveBlobToFileProcFactory.dispose;
begin

end;

function TSaveBlobToFileProcFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalProcedure;
begin
  Result := TSaveBlobToFileProc.create;
end;

procedure TSaveBlobToFileProcFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
begin

end;

end.
