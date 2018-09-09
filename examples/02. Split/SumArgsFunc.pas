unit SumArgsFunc;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}
interface

uses
  Firebird, Udr;

type

// *********************************************************
// create function sum_args (
// n1 integer,
// n2 integer,
// n3 integer
// ) returns integer
// external name 'myudr!sum_args'
// engine udr;
// *********************************************************
  TSumArgsFunction = class(TUdrFunction)

    procedure execute(AStatus: IStatus; AContext: IExternalContext;
      AInMsg: Pointer; AOutMsg: Pointer); override;

  end;

implementation

uses SysUtils, UdrMessages;


{ TSumArgsFunction }

procedure TSumArgsFunction.execute(AStatus: IStatus; AContext: IExternalContext;
  AInMsg, AOutMsg: Pointer);
type
  // структура на которое будет отображено входное сообщение
  TInput = record
    n1: FB_INTEGER;
    n2: FB_INTEGER;
    n3: FB_INTEGER;
  end;
var
  Input: ^TInput;
  Output: ^FB_INTEGER;
begin
  // преобразовываем указатели на вход и выход к типизированным
  Input := AInMsg;
  Output := AOutMsg;
  // если один из аргументов NULL значит и резултат NULL
  // в противном случае считаем сумму аргументов
  with Input^ do
  begin
    if (n1.Null or n2.Null or n3.Null) then
    begin
      Output.Null := True;
    end
    else
    begin
      Output.Null := False;
      Output.Value := n1.Value + n2.Value + n3.Value;
    end;
  end;
end;


end.
