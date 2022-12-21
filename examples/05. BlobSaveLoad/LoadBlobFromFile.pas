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
    AFileName varchar(255) character set utf8
    ) returns blob sub_type binary
    external name 'BlobFileUtils!SaveBlobToFile'
    engine udr;

    ********************************************************* }
	
  // входное сообщений функции
  TInput = record
    filename: record
      len: Smallint;
      str: array [0 .. 1019] of AnsiChar;
    end;
    filenameNull: WordBool;
  end;
  TInputPtr = ^TInput;
  
  // выходное сообщение функции
  TOutput = record
    blobData: ISC_QUAD;
    blobDataNull: WordBool;
  end;
  TOutputPtr = ^TOutput;

  // реализаци€ функции LoadBlobFromFile
  TLoadBlobFromFileFunc = class(IExternalFunctionImpl)
  public
    // вызывается при уничтожении экземпл€ра
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;
  end;

  // Фабрика для создания экземпл€ра внешней функции LoadBlobFromFile
  TLoadBlobFromFileFuncFactory = class(IUdrFunctionFactoryImpl)
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
const
  MaxBufSize = 16384;
var
  xInput: TInputPtr;
  xOutput: TOutputPtr;
  xFileName: string;
  xStream: TFileStream;
  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array [0 .. 32767] of Byte;
  xStreamSize: Integer;
  xBufferSize: Integer;
  xReadLength: Integer;
begin
  xInput := AInMsg;
  xOutput := AOutMsg;
  if xInput.filenameNull then
  begin
    xOutput.blobDataNull := True;
    Exit;
  end;
  xOutput.blobDataNull := False;
  // получаем имя файла
  xFileName := TEncoding.UTF8.GetString(TBytes(@xInput.filename.str), 0,
    xInput.filename.len * 4);
  SetLength(xFileName, xInput.filename.len);
  // читаем файл в поток
  xStream := TFileStream.Create(xFileName, fmOpenRead or fmShareDenyNone);
  att := AContext.getAttachment(AStatus);
  trx := AContext.getTransaction(AStatus);
  blob := nil;
  try
    xStreamSize := xStream.Size;
	// определяем максимальный размер буфера (сегмента)
    if xStreamSize > MaxBufSize then
      xBufferSize := MaxBufSize
    else
      xBufferSize := xStreamSize;
	// создаЄм новый blob  
    blob := att.createBlob(AStatus, trx, @xOutput.blobData, 0, nil);
	// читаем содержимое потока и пишем его в BLOB посегментно
    while xStreamSize <> 0 do
    begin
      if xStreamSize > xBufferSize then
        xReadLength := xBufferSize
      else
        xReadLength := xStreamSize;
      xStream.ReadBuffer(buffer, xReadLength);

      blob.putSegment(AStatus, xReadLength, @buffer[0]);

      Dec(xStreamSize, xReadLength);
    end;
	// закрываем BLOB
    blob.close(AStatus);
	blob := nil;
  finally
    if Assigned(blob) then
      blob.release;
    att.release;
    trx.release;
    xStream.Free;
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
