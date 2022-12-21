{
 *	PROGRAM:	UDR samples.
 *	MODULE:		LoadBlobFromFile.pas
 *	DESCRIPTION:	A sample work with blob in extenal function.
 *
 *  The contents of this file are subject to the Initial
 *  Developer's Public License Version 1.0 (the "License");
 *  you may not use this file except in compliance with the
 *  License. You may obtain a copy of the License at
 *  http://www.ibphoenix.com/main.nfs?a=ibphoenix&page=ibp_idpl.
 *
 *  Software distributed under the License is distributed AS IS,
 *  WITHOUT WARRANTY OF ANY KIND, either express or implied.
 *  See the License for the specific language governing rights
 *  and limitations under the License.
 *
 *  The Original Code was created by Simonov Denis
 *  for the book Writing UDR Firebird in Pascal.
 *
 *  Copyright (c) 2018 Simonov Denis <sim-mail@list.ru>
 *  and all contributors signed below.
 *
 *  All Rights Reserved.
 *  Contributor(s): ______________________________________. }

unit LoadBlobFromFile;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird, Classes, SysUtils;

type

  { **********************************************************

    create procedure LoadBlobFromFile (
    AFileName varchar(255) character set none
    ) returns blob sub_type binary
    external name 'BlobFileUtils!SaveBlobToFile'
    engine udr;

    ********************************************************* }

  TInput = record
    filename: record
      len: Smallint;
      str: array [0 .. 254] of AnsiChar;
    end;

    filenameNull: WordBool;
  end;

  TInputPtr = ^TInput;

  TOutput = record
    blobData: ISC_QUAD;
    blobDataNull: WordBool;
  end;

  TOutputPtr = ^TOutput;

  TLoadBlobFromFileFunc = class(IExternalFunctionImpl)
  public
    // Вызывается при уничтожении экземпляра
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;
  end;

  // Фабрика для создания экземпляра внешней функции TLoadBlobFromFileFunc
  TLoadBlobFromFileFuncFactory = class(IUdrFunctionFactoryImpl)
    // Вызывается при уничтожении фабрики
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;

implementation

{ TLoadBlobFromFileFunc }

procedure TLoadBlobFromFileFunc.dispose;
begin

end;

procedure TLoadBlobFromFileFunc.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin

end;

procedure TLoadBlobFromFileFunc.execute(AStatus: IStatus;
  AContext: IExternalContext; AInMsg: Pointer; AOutMsg: Pointer);
var
  xInput: TInputPtr;
  xOutput: TOutputPtr;
  att: IAttachment;
  trx: ITransaction;
  xUtil: IUtil;
begin
  xInput := AInMsg;
  xOutput := AOutMsg;
  if xInput.filenameNull then
  begin
    xOutput.blobDataNull := True;
    Exit;
  end;
  xOutput.blobDataNull := False;

  att := AContext.getAttachment(AStatus);
  trx := AContext.getTransaction(AStatus);
  xUtil := AContext.getMaster().getUtilInterface();
  try
    xUtil.loadBlob(AStatus, @xOutput.blobData, att, trx, @xInput.filename.str, false);
  finally
    trx.release;
    att.release;
  end;
end;

{ TLoadBlobFromFileFuncFactory }

procedure TLoadBlobFromFileFuncFactory.dispose;
begin

end;

procedure TLoadBlobFromFileFuncFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder: IMetadataBuilder; AOutBuilder: IMetadataBuilder);
begin

end;

function TLoadBlobFromFileFuncFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
begin
  Result := TLoadBlobFromFileFunc.Create;
end;

end.
