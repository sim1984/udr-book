unit UdrInit;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird,
  LoadBlobFromFile,
  SaveBlobToFile;

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
  // регистрируем
  AUdrPlugin.registerProcedure(AStatus, 'SaveBlobToFile', TSaveBlobToFileProcFactory.Create());
  AUdrPlugin.registerFunction(AStatus, 'LoadBlobFromFile', TLoadBlobFromFileFuncFactory.Create());

  theirUnloadFlag := AUnloadFlagLocal;
  Result := @myUnloadFlag;
end;

initialization

myUnloadFlag := false;

finalization

if ((theirUnloadFlag <> nil) and not myUnloadFlag) then
  theirUnloadFlag^ := true;

end.