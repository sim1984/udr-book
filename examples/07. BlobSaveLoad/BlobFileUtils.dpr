library BlobFileUtils;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  UdrInit in 'UdrInit.pas',
  SaveBlobToFile in 'SaveBlobToFile.pas',
  LoadBlobFromFile in 'LoadBlobFromFile.pas';

exports firebird_udr_plugin;

end.
