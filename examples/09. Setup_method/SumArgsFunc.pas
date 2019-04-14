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
  SysUtils, FbTypes;

type
  // структура на которое будет отображено входное сообщение
  TSumArgsInMsg = record
    n1: Integer;
    n1Null: WordBool;
    n2: Integer;
    n2Null: WordBool;
    n3: Integer;
    n3Null: WordBool;
  end;

  PSumArgsInMsg = ^TSumArgsInMsg;

  // структура на которое будет отображено выходное сообщение
  TSumArgsOutMsg = record
    result: Integer;
    resultNull: WordBool;
  end;

  PSumArgsOutMsg = ^TSumArgsOutMsg;

{ TSumArgsFunctionFactory }

procedure TSumArgsFunctionFactory.dispose;
begin
  Destroy;
end;

function TSumArgsFunctionFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
begin
  Result := TSumArgsFunction.Create();
end;

procedure TSumArgsFunctionFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin
  // строим сообщение для входных параметров
  AInBuilder.setType(AStatus, 0, Cardinal(SQL_LONG));
  AInBuilder.setLength(AStatus, 0, sizeof(Int32));
  AInBuilder.setType(AStatus, 1, Cardinal(SQL_LONG));
  AInBuilder.setLength(AStatus, 1, sizeof(Int32));
  AInBuilder.setType(AStatus, 2, Cardinal(SQL_LONG));
  AInBuilder.setLength(AStatus, 2, sizeof(Int32));
  // строим сообщение для выходных параметров
  AOutBuilder.setType(AStatus, 0, Cardinal(SQL_LONG));
  AOutBuilder.setLength(AStatus, 0, sizeof(Int32));
end;

{ TSumArgsFunction }

procedure TSumArgsFunction.dispose;
begin
  Destroy;
end;

procedure TSumArgsFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
var
  xInput: PSumArgsInMsg;
  xOutput: PSumArgsOutMsg;
begin
  // преобразовываем указатели на вход и выход к типизированным
  xInput := PSumArgsInMsg(AInMsg);
  xOutput := PSumArgsOutMsg(AOutMsg);
  // по умолчанию выходной аргемент = NULL, а потому выставляем ему nullFlag
  xOutput^.resultNull := True;
  // если один из аргументов NULL значит и резултат NULL
  // в противном случае считаем сумму аргументов
  with xInput^ do
  begin
    if not(n1Null or n2Null or n3Null) then
    begin
      xOutput^.result := n1 + n2 + n3;
      // раз есть результат, то сбрасываем NULL флаг
      xOutput^.resultNull := False;
    end;
  end;
end;

procedure TSumArgsFunction.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin
end;

end.
