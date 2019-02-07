library MyUdr;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '../Common/Firebird.pas',
  UdrInit in 'UdrInit.pas',
  BlobUtils in 'BlobUtils.pas';

exports firebird_udr_plugin;

end.

