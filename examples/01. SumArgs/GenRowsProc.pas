unit GenRowsProc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  Firebird, SysUtils;

type
  { **********************************************************

    create procedure gen_rows (
      start  integer,
      finish integer
    ) returns (n integer)
    external name 'myudr!gen_rows'
    engine udr;

    ********************************************************* }

  TInput = record
    start: Integer;
    startNull: WordBool;
    finish: Integer;
    finishNull: WordBool;
  end;
  PInput = ^TInput;

  TOutput = record
    n: Integer;
    nNull: WordBool;
  end;
  POutput = ^TOutput;

  // Фабрика для создания экземпляра внешней процедуры TGenRowsProcedure
  TGenRowsFactory = class(IUdrProcedureFactoryImpl)
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

    { Создание нового экземпляра внешней процедуры TGenRowsProcedure

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AMetadata Метаданные внешней функции)
      @returns(Экземпляр внешней функции)
    }
    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  // Внешняя процедура TGenRowsProcedure.
  TGenRowsProcedure = class(IExternalProcedureImpl)
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
      @returns(Набор данных для селективной процедуры или nil для процедур выполнения)
    }
    function open(AStatus: IStatus; AContext: IExternalContext; AInMsg: Pointer;
      AOutMsg: Pointer): IExternalResultSet; override;
  end;

  // Выходной набор данных для процедуры TGenRowsProcedure
  TGenRowsResultSet = class(IExternalResultSetImpl)
    Input: PInput;
    Output: POutput;

    // Вызывается при уничтожении экземпляра набора данных
    procedure dispose(); override;

    { Извлечение очередной записи из набора данных.
      В некотором роде аналог SUSPEND. В этом методе должна
      подготовливаться очередная запись из набора данных.

      @param(AStatus Статус вектор)
      @returns(True если в наборе данных есть запись для извлечения,
               False если записи закончились)
    }
    function fetch(AStatus: IStatus): Boolean; override;
  end;

implementation

{ TGenRowsFactory }

procedure TGenRowsFactory.dispose;
begin
  Destroy;
end;

function TGenRowsFactory.newItem(AStatus: IStatus; AContext: IExternalContext;
  AMetadata: IRoutineMetadata): IExternalProcedure;
begin
  Result := TGenRowsProcedure.create;
end;

procedure TGenRowsFactory.setup(AStatus: IStatus; AContext: IExternalContext;
  AMetadata: IRoutineMetadata; AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TGenRowsProcedure }

procedure TGenRowsProcedure.dispose;
begin
  Destroy;
end;

procedure TGenRowsProcedure.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin

end;

function TGenRowsProcedure.open(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer): IExternalResultSet;
begin
  // если один из входных аргументов NULL ничего не возвращаем
  if PInput(AInMsg).startNull or PInput(AInMsg).finishNull then
  begin
    POutput(AOutMsg).nNull := True;
    Result := nil;
    exit;
  end;
  // проверки
  if PInput(AInMsg).start > PInput(AInMsg).finish then
    raise Exception.Create('First parameter greater then second parameter.');

  Result := TGenRowsResultSet.create;
  with TGenRowsResultSet(Result) do
  begin
    Input := AInMsg;
    Output := AOutMsg;
    // начальное значение
    Output.nNull := False;
    Output.n := Input.start - 1;
  end;
end;

{ TGenRowsResultSet }

procedure TGenRowsResultSet.dispose;
begin
  Destroy;
end;

// Если возвращает True то извлекается очередная запись из набора данных.
// Если возвращает False то записи в наборе данных закончились
// новые значения в выходном векторе вычисляются каждый раз при вызове этого метода
function TGenRowsResultSet.fetch(AStatus: IStatus): Boolean;
begin
  Inc(Output.n);
  Result := (Output.n <= Input.finish);
end;

end.
