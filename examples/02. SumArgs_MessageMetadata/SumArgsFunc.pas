unit SumArgsFunc;

{$IFDEF FPC}
{$MODE objfpc}{$H+}
{$DEFINE DEBUGFPC}
{$ENDIF}

interface

uses
  Firebird;

// *********************************************************
// create function sum_args (
// n1 integer not null,
// n2 integer not null,
// n3 integer not null
// ) returns integer
// external name 'myudr!sum_args'
// engine udr;
// *********************************************************

type

  // Фабрика для создания экземпляра внешней функции TSumArgsFunction
  TSumArgsFunctionFactory = class(IUdrFunctionFactoryImpl)
    // Вызывается при уничтожении фабрики
    procedure dispose(); override;

    { Выполняется каждый раз при загрузке внешней функции в кеш метаданных

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AMetadata Метаданные внешней функции)
      @param(AInBuilder Построитель сообщения для входных метаданных)
      @param(AOutBuilder Построитель сообщения для выходных метаданных)
    }
    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    { Создание нового экземпляра внешней функции TSumArgsFunction

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AMetadata Метаданные внешней функции)
      @returns(Экземпляр внешней функции)
    }
    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;

  // Внешняя функция TSumArgsFunction.
  TSumArgsFunction = class(IExternalFunctionImpl)
  private
    FInputMetadata: IMessageMetadata;
    FOutputMetadata: IMessageMetadata;
  public
    property InputMetadata: IMessageMetadata read FInputMetadata
      write FInputMetadata;
    property OutputMetadata: IMessageMetadata read FOutputMetadata
      write FOutputMetadata;
  public
    // Вызывается при уничтожении экземпляра функции
    procedure dispose(); override;

    { Этот метод вызывается непосредственно перед execute и сообщает
      ядру наш запрошенный набор символов для обмена данными внутри
      этого метода. Во время этого вызова контекст использует набор символов,
      полученный из ExternalEngine::getCharSet.

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AName Имя набора символов)
      @param(AName Длина имени набора символов)
    }
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

{ TSumArgsFunctionFactory }

procedure TSumArgsFunctionFactory.dispose;
begin
  Destroy;
end;

function TSumArgsFunctionFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
begin
  Result := TSumArgsFunction.Create();
  with Result as TSumArgsFunction do
  begin
    InputMetadata := AMetadata.getInputMetadata(AStatus);
    OutputMetadata := AMetadata.getOutputMetadata(AStatus);
  end;
end;

procedure TSumArgsFunctionFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TSumArgsFunction }

procedure TSumArgsFunction.dispose;
begin
  FInputMetadata.release;
  FInputMetadata := nil;
  FOutputMetadata.release;
  FOutputMetadata := nil;
  Destroy;
end;

procedure TSumArgsFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
var
  n1, n2, n3: Integer;
  n1Null, n2Null, n3Null: WordBool;
  Result: Integer;
  resultNull: WordBool;
begin
  // получаем значения входных аргументов по их смещениям
  n1 := PInteger(PByte(AInMsg) + FInputMetadata.getOffset(AStatus, 0))^;
  n2 := PInteger(PByte(AInMsg) + FInputMetadata.getOffset(AStatus, 1))^;
  n3 := PInteger(PByte(AInMsg) + FInputMetadata.getOffset(AStatus, 2))^;
  // получаем значения null-индикаторов входных аргументов по их смещениям
  n1Null := PWordBool(PByte(AInMsg) + FInputMetadata.getNullOffset(AStatus, 0))^;
  n2Null := PWordBool(PByte(AInMsg) + FInputMetadata.getNullOffset(AStatus, 1))^;
  n3Null := PWordBool(PByte(AInMsg) + FInputMetadata.getNullOffset(AStatus, 2))^;
  // по умолчанию выходной аргемент = NULL, а потому выставляем ему nullFlag
  resultNull := True;
  Result := 0;
  // если один из аргументов NULL значит и резултат NULL
  // в противном случае считаем сумму аргументов=
  if not(n1Null or n2Null or n3Null) then
  begin
    Result := n1 + n2 + n3;
    // раз есть результат, то сбрасываем NULL флаг
    resultNull := False;
  end;
  PWordBool(PByte(AInMsg) + FOutputMetadata.getNullOffset(AStatus, 0))^ := resultNull;
  PInteger(PByte(AInMsg) + FOutputMetadata.getOffset(AStatus, 0))^ := Result;
end;

procedure TSumArgsFunction.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin
end;

end.
