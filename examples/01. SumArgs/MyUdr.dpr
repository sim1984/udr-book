library MyUdr;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  UdrInit in 'UdrInit.pas',
  SumArgsFunc in 'SumArgsFunc.pas',
  GenRowsProc in 'GenRowsProc.pas',
  SumArgsProc in 'SumArgsProc.pas',
  TestTrigger in 'TestTrigger.pas';

exports firebird_udr_plugin;

end.


