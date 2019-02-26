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
        AFileName varchar(255) character set none
    );
    external name 'BlobFileUtils!SaveBlobToFile'
    engine udr;

    ********************************************************* }

  TInput = record
    blobData: ISC_QUAD;
    blobDataNull: WordBool;
    filename: record
      len: Smallint;
      str: array [0 .. 254] of AnsiChar;
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
  att: IAttachment;
  trx: ITransaction;
  xUtil: IUtil;
begin
  xInput := AInMsg;
  if xInput.blobDataNull or xInput.filenameNull then
  begin
    Result := nil;
    Exit;
  end;

  att := AContext.getAttachment(AStatus);
  trx := AContext.getTransaction(AStatus);
  xUtil := AContext.getMaster().getUtilInterface();
  try
    xUtil.dumpBlob(AStatus, @xInput.blobData, att, trx, @xInput.filename.str, false);
  finally
    trx.release;
    att.release;
  end;
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
