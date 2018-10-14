library MyUdr;

{$IFDEF FPC}
  {$MODE objfpc}{$H+}
{$ENDIF}

uses
  {$IFDEF unix}
  cthreads,
  {$ENDIF }
  Firebird in '..\Common\Firebird.pas',
  FbTypes in '..\Common\FbTypes.pas',
  FbMessageMetadata in '..\Common\FbMessageMetadata.pas',
  FbMessageData in '..\Common\FbMessageData.pas',
  UdrFactories in '..\Common\UdrFactories.pas',
  UdrInit in 'UdrInit.pas',
  SumArgsFunc in 'SumArgsFunc.pas';

exports firebird_udr_plugin;

end.


