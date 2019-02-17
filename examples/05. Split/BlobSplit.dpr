library BlobSplit;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

uses
{$IFDEF unix}
  cthreads,
{$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  FbTypes in '..\Common\FbTypes.pas',
  FbCharsets in '..\Common\FbCharsets.pas',
  UdrFactories in '..\Common\UdrFactories.pas',
  UdrInit in 'UdrInit.pas',
  SplitProc in 'SplitProc.pas';

exports firebird_udr_plugin;

end.
