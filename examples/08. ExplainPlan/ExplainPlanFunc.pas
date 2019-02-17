unit ExplainPlanFunc;

{$IFDEF FPC}
{$MODE objfpc}{$H+}
{$DEFINE DEBUGFPC}
{$ENDIF}

interface

uses
  Firebird,
  UdrFactories;

// *********************************************************
// create function GetExplainPlan (
// sql_text blob sub_type text
// ) returns blob sub_type text characte rset none
// external name 'planUtils!explainPlan'
// engine udr;
// *********************************************************

type

  // Внешняя функция TSumArgsFunction.
  TExplainPlanFunction = class(TExternalFunction)
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
    NullFlag: WordBool;
  end;

  InputPtr = ^TInput;

  TOutput = record
    Plan: ISC_QUAD;
    NullFlag: WordBool;
  end;

  OutputPtr = ^TOutput;

{ TExplainPlanFunction }

procedure TExplainPlanFunction.dispose;
begin
  Destroy;
end;

procedure TExplainPlanFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
var
  xInput: InputPtr;
  xOutput: OutputPtr;
  att: IAttachment;
  tra: ITransaction;
  stmt: IStatement;
  plan: PAnsiChar;
  inBlob, outBlob: IBlob;
  inStream, outStream: TBytesStream;
begin
  xInput := AInMsg;
  xOutput := AOutMsg;
  if xInput.NullFlag then
  begin
    xOutput.NullFlag := True;
    Exit;
  end;
  xOutput.NullFlag := False;
  // создаём поток байт для чтения blob
  inStream := TBytesStream.Create(nil);
  outStream :=  TBytesStream.Create(nil);
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
    // получаем explain plan
    plan := stmt.getPlan(AStatus, True);
    outStream.Write(plan^, AnsiStrings.StrLen(plan));
    // пишем explain plan в выходной blob
    outBlob := att.createBlob(AStatus, tra, @xOutput.Plan, 0, nil);
    outBlob.LoadFromStream(AStatus, outStream);
    //outBlob.Write(AStatus, plan^, AnsiStrings.StrLen(plan));
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
    outStream.Free;
  end;
end;

procedure TExplainPlanFunction.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin
end;

end.
