unit UdrInit;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses Firebird;

// точка входа для External Engine модуля UDR
function firebird_udr_plugin(AStatus: IStatus; AUnloadFlagLocal: BooleanPtr;
  AUdrPlugin: IUdrPlugin): BooleanPtr; cdecl;

implementation

uses
  SumArgsFunc,
  SumArgsProc,
  GenRowsProc,
  TestTrigger;

var
  myUnloadFlag: Boolean;
  theirUnloadFlag: BooleanPtr;

function firebird_udr_plugin(AStatus: IStatus; AUnloadFlagLocal: BooleanPtr;
  AUdrPlugin: IUdrPlugin): BooleanPtr; cdecl;
begin
  // регистрируем наши функции
  AUdrPlugin.registerFunction(AStatus, 'sum_args',
    TSumArgsFunctionFactory.Create());
  // регистрируем наши процедуры
  AUdrPlugin.registerProcedure(AStatus, 'sum_args_proc',
    TSumArgsProcedureFactory.Create());
  AUdrPlugin.registerProcedure(AStatus, 'gen_rows', TGenRowsFactory.Create());
  // регистриуем наши триггеры
  AUdrPlugin.registerTrigger(AStatus, 'test_trigger',
    TMyTriggerFactory.Create());

  theirUnloadFlag := AUnloadFlagLocal;
  Result := @myUnloadFlag;
end;

initialization

myUnloadFlag := false;

finalization

if ((theirUnloadFlag <> nil) and not myUnloadFlag) then
  theirUnloadFlag^ := true;

end.
