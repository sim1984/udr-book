{
 *	PROGRAM:	UDR samples.
 *	MODULE:		SqrFunc.pas
 *	DESCRIPTION:	A sample external function use IRoutineMetadata 
 *                  and message struct.
 *
 *  The contents of this file are subject to the Initial
 *  Developer's Public License Version 1.0 (the "License");
 *  you may not use this file except in compliance with the
 *  License. You may obtain a copy of the License at
 *  http://www.ibphoenix.com/main.nfs?a=ibphoenix&page=ibp_idpl.
 *
 *  Software distributed under the License is distributed AS IS,
 *  WITHOUT WARRANTY OF ANY KIND, either express or implied.
 *  See the License for the specific language governing rights
 *  and limitations under the License.
 *
 *  The Original Code was created by Simonov Denis
 *  for the book Writing UDR Firebird in Pascal.
 *
 *  Copyright (c) 2018 Simonov Denis <sim-mail@list.ru>
 *  and all contributors signed below.
 *
 *  All Rights Reserved.
 *  Contributor(s): ______________________________________. }

unit SqrFunc;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$DEFINE DEBUGFPC}
{$ENDIF}

interface

uses
  Firebird;

// *********************************************************
// create function sqr_args (
// n1 <T> not null
// ) returns <T>
// external name 'myudr!sqr_func'
// engine udr;
// *********************************************************

type
  // структура на которое будет отображено входное сообщение
  TSqrInMsg<T> = record
    n1: T;
    n1Null: WordBool;
  end;

  // структура на которое будет отображено выходное сообщение
  TSqrOutMsg<T> = record
    result: T;
    resultNull: WordBool;
  end;

  // Фабрика для создания экземпляра внешней функции TSqrFunction
  TSqrFunctionFactory = class(IUdrFunctionFactoryImpl)
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

    { Создание нового экземпляра внешней функции TSqrFunction

      @param(AStatus Статус вектор)
      @param(AContext Контекст выполнения внешней функции)
      @param(AMetadata Метаданные внешней функции)
      @returns(Экземпляр внешней функции)
    }
    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;


  // Внешняя функция TSqrFunction.
  TSqrFunction<TIn, TOut> = class(IExternalFunctionImpl)
  private
    function sqrExec(AIn: TIn): TOut; virtual; abstract;
  public
    type
      TInput = TSqrInMsg<TIn>;
      TOutput = TSqrOutMsg<TOut>;
      PInput = ^TInput;
      POutput = ^TOutput;
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

  TSqrExecSmallint = class(TSqrFunction<Smallint, Integer>)
  public
    function sqrExec(AIn: Smallint): Integer; override;
  end;

  TSqrExecInteger = class(TSqrFunction<Integer, Int64>)
  public
    function sqrExec(AIn: Integer): Int64; override;
  end;

  TSqrExecInt64 = class(TSqrFunction<Int64, Int64>)
  public
    function sqrExec(AIn: Int64): Int64; override;
  end;

  TSqrExecFloat = class(TSqrFunction<Single, Double>)
  public
    function sqrExec(AIn: Single): Double; override;
  end;

  TSqrExecDouble = class(TSqrFunction<Double, Double>)
  public
    function sqrExec(AIn: Double): Double; override;
  end;

implementation

uses
  SysUtils, FbTypes {$IFNDEF FPC}, System.TypInfo{$ENDIF}
;

{ TSqrFunctionFactory }

procedure TSqrFunctionFactory.dispose;
begin
  Destroy;
end;

function TSqrFunctionFactory.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
var
  xInputMetadata: IMessageMetadata;
  xInputType: Cardinal;
begin
  // олучаем тип входного аргумента
  xInputMetadata := AMetadata.getInputMetadata(AStatus);
  // аналог AMeta->getType(AStatus, i) & ~1
  xInputType := xInputMetadata.getType(AStatus, 0) and not 1;
  xInputMetadata.release;
  // создаём экземпляр функции в зависимости от типа
  case xInputType of
    SQL_SHORT:
      result := TSqrExecSmallint.Create();

    SQL_LONG:
      result := TSqrExecInteger.Create();
    SQL_INT64:
      result := TSqrExecInt64.Create();

    SQL_FLOAT:
      result := TSqrExecFloat.Create();
    SQL_DOUBLE, SQL_D_FLOAT:
      result := TSqrExecDouble.Create();
  else
    result := TSqrExecInt64.Create();
  end;

end;

procedure TSqrFunctionFactory.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TSqrFunction }

procedure TSqrFunction<TIn, TOut>.dispose;
begin
  Destroy;
end;

procedure TSqrFunction<TIn, TOut>.execute(AStatus: IStatus;
  AContext: IExternalContext; AInMsg, AOutMsg: Pointer);
var
  xInput: PInput;
  xOutput: POutput;
begin
  xInput := PInput(AInMsg);
  xOutput := POutput(AOutMsg);
  xOutput.resultNull := True;
  if (not xInput.n1Null) then
  begin
    xOutput.resultNull := False;
    xOutput.result := Self.sqrExec(xInput.n1);
  end;
end;

procedure TSqrFunction<TIn, TOut>.getCharSet(AStatus: IStatus;
  AContext: IExternalContext; AName: PAnsiChar; ANameSize: Cardinal);
begin
end;


{ TSqrtExecSmallint }

function TSqrExecSmallint.sqrExec(AIn: Smallint): Integer;
begin
  Result := AIn * AIn;
end;

{ TSqrExecInteger }

function TSqrExecInteger.sqrExec(AIn: Integer): Int64;
begin
  Result := AIn * AIn;
end;

{ TSqrExecInt64 }

function TSqrExecInt64.sqrExec(AIn: Int64): Int64;
begin
  Result := AIn * AIn;
end;

{ TSqrExecFloat }

function TSqrExecFloat.sqrExec(AIn: Single): Double;
begin
  Result := AIn * AIn;
end;

{ TSqrExecDouble }

function TSqrExecDouble.sqrExec(AIn: Double): Double;
begin
  Result := AIn * AIn;
end;

end.
