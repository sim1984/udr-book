unit UdrFactories;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses SysUtils, Firebird;

type


  TFunctionSimpleFactory<T: IExternalFunctionImpl, constructor> =
  class(IUdrFunctionFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;

  TExternalFunction = class(IExternalFunctionImpl)
    class function createFunction(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; virtual; abstract;
  end;

  TFunctionFactory<T: TExternalFunction> = class(IUdrFunctionFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalFunction; override;
  end;

  TProcedureSimpleFactory<T: IExternalProcedureImpl, constructor> =
  class(IUdrProcedureFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  TExternalProcedure = class(IExternalProcedureImpl)
    class function createProcedure(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; virtual; abstract;
  end;

  TProcedureFactory<T: TExternalProcedure> = class(IUdrProcedureFactoryImpl)
    procedure dispose(); override;

    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
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
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
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
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
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
  Result := T.createFunction(AStatus, AContext, AMetadata);
end;

procedure TFunctionFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
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
  Result := T.createProcedure(AStatus, AContext, AMetadata);
end;

procedure TProcedureFactory<T>.setup(AStatus: IStatus;
  AContext: IExternalContext; AMetadata: IRoutineMetadata; AInBuilder,
  AOutBuilder: IMetadataBuilder);
begin

end;


end.
