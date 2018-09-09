library MyUdr;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  UdrInit in 'UdrInit.pas',
  SumArgsFunc in 'SumArgsFunc.pas',
  UdrFactories in 'UdrFactories.pas',
  UdrMessages in 'UdrMessages.pas',
  Udr in 'Udr.pas',
  BlobCountFunc in 'BlobCountFunc.pas';

exports firebird_udr_plugin;

end.

