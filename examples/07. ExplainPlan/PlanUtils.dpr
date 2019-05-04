library PlanUtils;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads, cmem,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  UdrFactories in '..\Common\UdrFactories.pas',
  FbBlob in '..\Common\FbBlob.pas',
  UdrInit in 'UdrInit.pas',
  PlanFunc in 'PlanFunc.pas';

exports firebird_udr_plugin;

begin
  IsMultiThread := true;
end.
