unit SumArgsFunc;

{$IFDEF FPC}
{$MODE objfpc}{$H+}
{$DEFINE DEBUGFPC}
{$ENDIF}

interface

uses
  Firebird,
  UdrFactories,
  FbMessageMetadata,
  FbMessageData;

// *********************************************************
//    create function sum_args (
//      n1 integer not null,
//      n2 integer not null,
//      n3 integer not null
//    ) returns integer
//    external name 'myudr!sum_args'
//    engine udr;
// *********************************************************

type

  // Внешняя функция TSumArgsFunction.
  TSumArgsFunction = class(TExternalFunction)
  private
    FInputMetadata: TFbMessageMetadata;
    FOutputMetadata: TFbMessageMetadata;
  public
    // создаёт внешнюю функцию
    class function createFunction(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;

    // Вызывается при уничтожении экземпляра функции
    procedure dispose(); override;


    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    { Выполнение внешней функции

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AInMsg Указатель на входное сообщение)
      @param(AOutMsg Указатель на выходное сообщение)
    }
    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;
  end;

implementation

uses
  SysUtils;


{ TSumArgsFunction }

class function TSumArgsFunction.createFunction(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
var
  xInMetadata, xOutMetadata: IMessageMetadata;
begin
  Result := TSumArgsFunction.Create();
  xInMetadata := AMetaData.getInputMetadata(AStatus);
  xOutMetadata:= AMetaData.getOutputMetadata(AStatus);
  with TSumArgsFunction(Result) do
  begin
    FInputMetadata := TFbMessageMetadata.Create(AStatus, xInMetadata);
    FOutputMetadata := TFbMessageMetadata.Create(AStatus, xOutMetadata);
  end;
  xInMetadata.release;
  xOutMetadata.release;
end;

procedure TSumArgsFunction.dispose;
begin
  FInputMetadata.Free;
  FOutputMetadata.Free;
  Destroy;
end;

procedure TSumArgsFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
var
  xInput: TFbMessageData;
  xOutput: TFbMessageData;
begin
  xInput := TFbMessageData.Create(AContext, FInputMetadata, AInMsg);
  xOutput := TFbMessageData.Create(AContext, FOutputMetadata, AOutMsg);
  try
    // по умолчанию выходной аргемент = NULL, а потому выставляем ему nullFlag
    xOutput.Null[0] := True;
    // если один из аргументов NULL значит и резултат NULL
    // в противном случае считаем сумму аргументов
    if not (xInput.Null[0] or xInput.Null[1] or xInput.Null[2]) then
    begin
      xOutput.AsInteger[0] :=
          xInput.AsInteger[0] +
          xInput.AsInteger[1] +
          xInput.AsInteger[2];
      // раз есть результат, то сбрасываем NULL флаг
      xOutput.Null[0] := False;
    end;
  finally
    xInput.Free;
    xOutput.Free;
  end;
end;

procedure TSumArgsFunction.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin
end;

end.
