library PlanUtils;

{$IFDEF FPC}
  {$MODE objfpc}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  UdrFactories in '..\Common\UdrFactories.pas',
  FbBlob in '..\Common\FbBlob.pas',
  UdrInit in 'UdrInit.pas',
  PlanFunc in 'PlanFunc.pas';

exports firebird_udr_plugin;

end.


