unit UdrInit;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird,
  UdrFactories,
  SumArgsFunc,
  BlobCountFunc,
  SplitProc;

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
  AUdrPlugin.registerFunction(AStatus, 'sum_args', TFunctionFactory<TSumArgsFunction>.Create());
  AUdrPlugin.registerFunction(AStatus, 'blob_count', TFunctionFactory<TBlobCountFunction>.Create());
  // регистрируем наши процедуры
  AUdrPlugin.registerProcedure(AStatus, 'split', TProcedureFactory<TSplitProcedure>.Create());

  theirUnloadFlag := AUnloadFlagLocal;
  Result := @myUnloadFlag;
end;

initialization

myUnloadFlag := false;

finalization

if ((theirUnloadFlag <> nil) and not myUnloadFlag) then
  theirUnloadFlag^ := true;

end.

