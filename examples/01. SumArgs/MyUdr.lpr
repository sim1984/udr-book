library MyUdr;

{$IFDEF FPC}
  {$MODE objfpc}{$H+}
{$ENDIF}

uses
{$IFDEF unix}
    cthreads,
    // the c memory manager is on some systems much faster for multi-threading
    cmem,
{$ENDIF}
  UdrInit in 'UdrInit.pas',
  SumArgsFunc in 'SumArgsFunc.pas';

exports firebird_udr_plugin;

end.

