library MyUdrSetup;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  Firebird in '..\Common\Firebird.pas',
  FbTypes in '..\Common\FbTypes.pas',
  UdrInit in 'UdrInit.pas',
  SumArgsFunc in 'SumArgsFunc.pas';

exports firebird_udr_plugin;

begin
  IsMultiThread := true;
end.
