library JsonUtils;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  UdrFactories in '..\Common\UdrFactories.pas',
  FbBlob in '..\Common\FbBlob.pas',
  FbTypes in '..\Common\FbTypes.pas',
  FbCharsets in '..\Common\FbCharsets.pas',
  UdrInit in 'UdrInit.pas',
  JsonFunc in 'JsonFunc.pas';
  
exports firebird_udr_plugin;

end.

