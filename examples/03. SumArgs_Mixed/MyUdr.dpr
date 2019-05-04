library MyUdr;

{$IFDEF FPC}
  {$MODE delphi}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads, cmem,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  FbTypes in '..\Common\FbTypes.pas',
  UdrInit in 'UdrInit.pas',
  SqrFunc in 'SqrFunc.pas';

exports firebird_udr_plugin;

begin
  IsMultiThread := true;
end.
