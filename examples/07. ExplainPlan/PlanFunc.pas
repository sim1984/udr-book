{
 *	PROGRAM:	UDR samples.
 *	MODULE:		PlanFunc.pas
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

unit PlanFunc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$DEFINE DEBUGFPC}
{$ENDIF}

interface

uses
  Firebird,
  UdrFactories;

// *********************************************************
// create function GetPlan (
//   sql_text blob sub_type text,
//   explain boolean default false
// ) returns blob sub_type text character set none
// external name 'planUtils!getPlan'
// engine udr;
// *********************************************************

type

  // Внешняя функция TSumArgsFunction.
  TPlanFunction = class(TExternalFunction)
  public
    // Вызывается при уничтожении экземпляра функции
    procedure dispose(); override;

    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    { Выполнение внешней функции

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AInMsg Указатель на входное сообщение)
      @param(AOutMsg Указатель на выходное сообщение)
    }
    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;
  end;

implementation

uses
  SysUtils, Classes, FbBlob {$IFNDEF FPC} , AnsiStrings {$ENDIF}
;

type
  TInput = record
    SqlText: ISC_QUAD;
    SqlNull: WordBool;
    Explain: Boolean;
    ExplainNull: WordBool
  end;

  InputPtr = ^TInput;

  TOutput = record
    Plan: ISC_QUAD;
    NullFlag: WordBool;
  end;

  OutputPtr = ^TOutput;

{ TExplainPlanFunction }

procedure TPlanFunction.dispose;
begin
  Destroy;
end;

procedure TPlanFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
var
  xInput: InputPtr;
  xOutput: OutputPtr;
  att: IAttachment;
  tra: ITransaction;
  stmt: IStatement;
  plan: PAnsiChar;
  inBlob, outBlob: IBlob;
  inStream: TBytesStream;
begin
  xInput := AInMsg;
  xOutput := AOutMsg;
  if xInput.SqlNull or xInput.ExplainNull then
  begin
    xOutput.NullFlag := True;
    Exit;
  end;
  xOutput.NullFlag := False;
  // создаём поток байт для чтения blob
  inStream := TBytesStream.Create(nil);
  att := AContext.getAttachment(AStatus);
  tra := AContext.getTransaction(AStatus);
  stmt := nil;
  inBlob := nil;
  outBlob := nil;
  try
    inBlob := att.openBlob(AStatus, tra, @xInput.SqlText, 0, nil);
    inBlob.SaveToStream(AStatus, inStream);
    inBlob.close(AStatus);

    stmt := att.prepare(AStatus, tra, inStream.Size, @inStream.Bytes[0], 3, 0);
    // получаем plan
    plan := stmt.getPlan(AStatus, xInput.Explain);
    // пишем plan в выходной blob
    outBlob := att.createBlob(AStatus, tra, @xOutput.Plan, 0, nil);
    {$IFDEF FPC}
    outBlob.Write(AStatus, plan^, StrLen(plan));
    {$ELSE}
    outBlob.Write(AStatus, plan^, AnsiStrings.StrLen(plan));
    {$ENDIF}
    outBlob.close(AStatus);
  finally
    if Assigned(inBlob) then
      inBlob.release;
    if Assigned(stmt) then
      stmt.release;
    if Assigned(outBlob) then
      outBlob.release;
    tra.release;
    att.release;
    inStream.Free;
  end;
end;

procedure TPlanFunction.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin
end;

end.
