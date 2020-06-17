{
 *	PROGRAM:	UDR samples.
 *	MODULE:		SplitProc.pas
 *	DESCRIPTION:	A sample work with blob in extenal procedure.
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

unit SplitProc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird, Classes, SysUtils, FbCharsets;

type

  { **********************************************************

    create procedure split (
        txt blob sub_type text character set utf8,
        delimiter char(1) character set utf8 = ','
    ) returns (
        id integer
    )
    external name 'BlobSplit!split'
    engine udr;

    ********************************************************* }

  TInput = record
    txt: ISC_QUAD;
    txtNull: WordBool;
    delimiter: array [0 .. 3] of AnsiChar;
    delimiterNull: WordBool;
  end;

  TInputPtr = ^TInput;

  TOutput = record
    Id: Integer;
    Null: WordBool;
  end;

  TOutputPtr = ^TOutput;

  TSplitProcedure = class(IExternalProcedureImpl)
  private
    procedure SaveBlobToStream(AStatus: IStatus; AContext: IExternalContext;
      ABlobId: ISC_QUADPtr; AStream: TStream);
    function readBlob(AStatus: IStatus; AContext: IExternalContext;
      ABlobId: ISC_QUADPtr): string;
  public
    // Вызывается при уничтожении экземпляра процедуры
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    function open(AStatus: IStatus; AContext: IExternalContext; AInMsg: Pointer;
      AOutMsg: Pointer): IExternalResultSet; override;
  end;

  TSplitResultSet = class(IExternalResultSetImpl)
{$IFDEF FPC}
    OutputArray: TStringArray;
{$ELSE}
    OutputArray: TArray<string>;
{$ENDIF}
    Counter: Integer;
    Output: TOutputPtr;

    procedure dispose(); override;
    function fetch(AStatus: IStatus): Boolean; override;
  end;

implementation

{ TSplitResultSet }

procedure TSplitResultSet.dispose;
begin
  SetLength(OutputArray, 0);
  Destroy;
end;

function TSplitResultSet.fetch(AStatus: IStatus): Boolean;
var
  statusVector: array [0 .. 4] of NativeIntPtr;
begin
  if Counter <= High(OutputArray) then
  begin
    Output.Null := False;
    // исключение будут перехвачены в любом случае с кодом isc_random
    // здесь же мы будем выбрасывать стандартную для Firebird
    // ошибку isc_convert_error
    try
      Output.Id := OutputArray[Counter].ToInteger();
    except
      on e: EConvertError do
      begin

        statusVector[0] := NativeIntPtr(isc_arg_gds);
        statusVector[1] := NativeIntPtr(isc_convert_error);
        statusVector[2] := NativeIntPtr(isc_arg_string);
        statusVector[3] := NativeIntPtr(PAnsiChar('Cannot convert string to integer'));
        statusVector[4] := NativeIntPtr(isc_arg_end);

        AStatus.setErrors(@statusVector);
      end;
    end;
    inc(Counter);
    Result := True;
  end
  else
    Result := False;
end;

{ TSplitProcedure }

procedure TSplitProcedure.dispose;
begin
  Destroy;
end;

procedure TSplitProcedure.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin

end;

function TSplitProcedure.open(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer): IExternalResultSet;
var
  xInput: TInputPtr;
  xText: string;
  xDelimiter: string;
begin
  xInput := AInMsg;
  if xInput.txtNull or xInput.delimiterNull then
  begin
    Result := nil;
    Exit;
  end;

  xText := readBlob(AStatus, AContext, @xInput.txt);
  xDelimiter := TFBCharSet.CS_UTF8.GetString(TBytes(@xInput.delimiter), 0, 4);
  // автоматически не правильно определяется потому что строки
  // не завершены нулём
  // ставим кол-во байт/4
  SetLength(xDelimiter, 1);

  Result := TSplitResultSet.Create;
  with TSplitResultSet(Result) do
  begin
    Output := AOutMsg;
    OutputArray := xText.Split([xDelimiter], TStringSplitOptions.ExcludeEmpty);
    Counter := 0;
  end;
end;

function TSplitProcedure.readBlob(AStatus: IStatus; AContext: IExternalContext;
  ABlobId: ISC_QUADPtr): string;
var
{$IFDEF FPC}
  xStream: TBytesStream;
{$ELSE}
  xStream: TStringStream;
{$ENDIF}
begin
{$IFDEF FPC}
  xStream := TBytesStream.Create(nil);
{$ELSE}
  xStream := TStringStream.Create('', 65001);
{$ENDIF}
  try
    SaveBlobToStream(AStatus, AContext, ABlobId, xStream);
{$IFDEF FPC}
    Result := TEncoding.UTF8.GetString(xStream.Bytes, 0, xStream.Size);
{$ELSE}
    Result := xStream.DataString;
{$ENDIF}
  finally
    xStream.Free;
  end;
end;

procedure TSplitProcedure.SaveBlobToStream(AStatus: IStatus;
  AContext: IExternalContext; ABlobId: ISC_QUADPtr; AStream: TStream);
var
  att: IAttachment;
  trx: ITransaction;
  blob: IBlob;
  buffer: array [0 .. 32767] of AnsiChar;
  l: Integer;
begin
  try
    att := AContext.getAttachment(AStatus);
    trx := AContext.getTransaction(AStatus);
    blob := att.openBlob(AStatus, trx, ABlobId, 0, nil);
    while True do
    begin
      case blob.getSegment(AStatus, SizeOf(buffer), @buffer, @l) of
        IStatus.RESULT_OK:
          AStream.WriteBuffer(buffer, l);
        IStatus.RESULT_SEGMENT:
          AStream.WriteBuffer(buffer, l);
      else
        break;
      end;
    end;
    AStream.Position := 0;
    blob.close(AStatus);
  finally
    if Assigned(att) then
      att.release;
    if Assigned(trx) then
      trx.release;
    if Assigned(blob) then
      blob.release;
  end;
end;

end.
