unit PlanFunc;

{$IFDEF FPC}
{$MODE objfpc}{$H+}
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
  SysUtils, Classes, FbBlob, AnsiStrings;

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
    outBlob.Write(AStatus, plan^, AnsiStrings.StrLen(plan));
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
