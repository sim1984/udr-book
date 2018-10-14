unit UdrInit;

{$IFDEF FPC}
  {$MODE objfpc}{$H+}
{$ENDIF}

interface

uses
  Firebird,
  SumArgsFunc,
  UdrFactories;

// точка входа для External Engine модуля UDR
function firebird_udr_plugin(AStatus: IStatus; AUnloadFlagLocal: BooleanPtr;
  AUdrPlugin: IUdrPlugin): BooleanPtr; cdecl;

implementation

var
  myUnloadFlag: Boolean;
  theirUnloadFlag: BooleanPtr;

function firebird_udr_plugin(AStatus: IStatus; AUnloadFlagLocal: BooleanPtr;
  AUdrPlugin: IUdrPlugin): BooleanPtr; cdecl;
begin
  // регистрируем наши функции
  AUdrPlugin.registerFunction(AStatus, 'sum_args2', TFunctionFactory<TSumArgsFunction>.Create());
  // регистрируем наши процедуры
  //AUdrPlugin.registerProcedure(AStatus, 'gen_rows', TGenRowsFactory.create());
  // регистриуем наши триггеры
  //AUdrPlugin.registerTrigger(AStatus, 'replicate', TReplicateFactory.create());

  theirUnloadFlag := AUnloadFlagLocal;
  Result := @myUnloadFlag;
end;

initialization

myUnloadFlag := false;

finalization

if ((theirUnloadFlag <> nil) and not myUnloadFlag) then
  theirUnloadFlag^ := true;

end.

