unit UdrInit;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird,
  UdrFactories,
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
  // регистрируем нашу процедуру
  AUdrPlugin.registerProcedure(AStatus, 'split', TProcedureSimpleFactory<TSplitProcedure>.Create());

  theirUnloadFlag := AUnloadFlagLocal;
  Result := @myUnloadFlag;
end;

initialization

myUnloadFlag := false;

finalization

if ((theirUnloadFlag <> nil) and not myUnloadFlag) then
  theirUnloadFlag^ := true;

end.