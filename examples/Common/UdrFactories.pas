{
 *	PROGRAM:	UDR samples.
 *	MODULE:		UdrFactories.pas
 *	DESCRIPTION:	Generic UDR factories
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

unit UdrFactories;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses SysUtils, Firebird;

type

  // Простая фабрика внешних функций
  TFunctionSimpleFactory<T: IExternalFunctionImpl, constructor> = class
    (IUdrFunctionFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;

  // Внешняя функция с метаданными
  TExternalFunction = class(IExternalFunctionImpl)
    Metadata: IRoutineMetadata;
  end;

  // Фабрика внешних функций с метаданными
  TFunctionFactory<T: TExternalFunction, constructor> = class
    (IUdrFunctionFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;

  // Простая фабрика внешних процедур
  TProcedureSimpleFactory<T: IExternalProcedureImpl, constructor> = class
    (IUdrProcedureFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  // Внешняя процедура с метаданными
  TExternalProcedure = class(IExternalProcedureImpl)
    Metadata: IRoutineMetadata;
  end;

  // Фабрика внешних процедур с метаданными
  TProcedureFactory<T: TExternalProcedure, constructor> = class
    (IUdrProcedureFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  // Простая фабрика внешних триггеров
  TTriggerSimpleFactory<T: IExternalTriggerImpl, constructor> = class
    (IUdrTriggerFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AFieldsBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalTrigger; override;
  end;

  // Внешний триггер с метаданными
  TExternalTrigger = class(IExternalTriggerImpl)
    Metadata: IRoutineMetadata;
  end;

  // Фабрика внешних триггеров с метаданными
  TTriggerFactory<T: TExternalTrigger, constructor> = class
    (IUdrTriggerFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AFieldsBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalTrigger; override;
  end;

implementation

{ TProcedureSimpleFactory<T> }

procedure TProcedureSimpleFactory<T>.dispose;
begin
  Destroy;
end;

function TProcedureSimpleFactory<T>.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalProcedure;
begin
  Result := T.Create;
end;

procedure TProcedureSimpleFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TFunctionFactory<T> }

procedure TFunctionSimpleFactory<T>.dispose;
begin
  Destroy;
end;

function TFunctionSimpleFactory<T>.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
begin
  Result := T.Create;
end;

procedure TFunctionSimpleFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TFunctionFactory<T> }

procedure TFunctionFactory<T>.dispose;
begin
  Destroy;
end;

function TFunctionFactory<T>.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalFunction;
begin
  Result := T.Create;
  (Result as T).Metadata := AMetadata;
end;

procedure TFunctionFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TProcedureFactory<T> }

procedure TProcedureFactory<T>.dispose;
begin
  Destroy;
end;

function TProcedureFactory<T>.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalProcedure;
begin
  Result := T.Create;
  (Result as T).Metadata := AMetadata;
end;

procedure TProcedureFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AInBuilder, AOutBuilder: IMetadataBuilder);
begin

end;

{ TTriggerSimpleFactory<T> }

procedure TTriggerSimpleFactory<T>.dispose;
begin
  Destroy;
end;

function TTriggerSimpleFactory<T>.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalTrigger;
begin
  Result := T.Create;
end;

procedure TTriggerSimpleFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata;
  AFieldsBuilder: IMetadataBuilder);
begin

end;

{ TTriggerFactory<T> }

procedure TTriggerFactory<T>.dispose;
begin
  Destroy;
end;

function TTriggerFactory<T>.newItem(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata): IExternalTrigger;
begin
  Result := T.Create;
  (Result as T).Metadata := AMetadata;
end;

procedure TTriggerFactory<T>.setup(AStatus: IStatus; AContext: IExternalContext;
  AMetadata: IRoutineMetadata; AFieldsBuilder: IMetadataBuilder);
begin

end;

end.
