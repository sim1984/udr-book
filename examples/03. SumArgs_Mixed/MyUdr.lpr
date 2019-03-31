library MyUdr;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  FbTypes in '..\Common\FbTypes.pas',
  UdrInit in 'UdrInit.pas',
  SqrFunc in 'SqrFunc.pas';

exports firebird_udr_plugin;

end.

