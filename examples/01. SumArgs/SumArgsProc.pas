unit SumArgsProc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird;

  { **********************************************************

    create procedure sp_sum_args (
      n1 integer,
      n2 integer,
      n3 integer
    ) returns (result integer)
    external name 'myudr!sum_args_proc'
    engine udr;

    ********************************************************* }
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

  // Фабрика для создания экземпляра внешней процедуры TSumArgsProcedure
  TSumArgsProcedureFactory = class(IUdrProcedureFactoryImpl)
    // Вызывается при уничтожении фабрики
    procedure dispose(); override;

    { Выполняется каждый раз при загрузке внешней процедуры в кеш метаданных

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней процедуры)
      @param(AMetadata Метаданные внешней процедуры)
      @param(AInBuilder Построитель сообщения для входных метаданных)
      @param(AOutBuilder Построитель сообщения для выходных метаданных)
    }
    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    { Создание нового экземпляра внешней процедуры TSumArgsProcedure

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней процедуры)
      @param(AMetadata Метаданные внешней процедуры)
      @returns(Экземпляр внешней процедуры)
    }
    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  TSumArgsProcedure = class(IExternalProcedureImpl)
  public
    // Вызывается при уничтожении экземпляра процедуры
    procedure dispose(); override;

    { Этот метод вызывается непосредственно перед open и сообщает
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

    { Выполнение внешней процедуры

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AInMsg Указатель на входное сообщение)
      @param(AOutMsg Указатель на выходное сообщение)
      @returns(Набор данных для селективной процедуры или
               nil для процедур выполнения)
    }
    function open(AStatus: IStatus; AContext: IExternalContext; AInMsg: Pointer;
      AOutMsg: Pointer): IExternalResultSet; override;
  end;

implementation

{ TSumArgsProcedureFactory }

procedure TSumArgsProcedureFactory.dispose;
begin
  Destroy;
end;

function TSumArgsProcedureFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalProcedure;
begin
  Result := TSumArgsProcedure.create;
end;

procedure TSumArgsProcedureFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
begin

end;

{ TSumArgsProcedure }

procedure TSumArgsProcedure.dispose;
begin
  Destroy;
end;

procedure TSumArgsProcedure.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin

end;

function TSumArgsProcedure.open(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer): IExternalResultSet;
var
  xInput: PSumArgsInMsg;
  xOutput: PSumArgsOutMsg;
begin
  Result := nil;
  // преобразовываем указатели на вход и выход к типизированным
  xInput := PSumArgsInMsg(AInMsg);
  xOutput := PSumArgsOutMsg(AOutMsg);
  // если один из аргументов NULL значит и результат NULL
  xOutput^.resultNull := xInput^.n1Null or xInput^.n2Null or xInput^.n3Null;
  xOutput^.result := xInput^.n1 + xInput^.n2 + xInput^.n3;
end;

end.
