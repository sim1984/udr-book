{
 *	PROGRAM:	UDR samples.
 *	MODULE:		GenRowsProc.pas
 *	DESCRIPTION:	A sample external procedure.
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
 *  The Original Code was created by Adriano dos Santos
 *  for the Firebird Open Source RDBMS project.
 *
 *  Copyright (c) 2008 Adriano dos Santos Fernandes <adrianosf@gmail.com>
 *  and all contributors signed below.
 *
 *  All Rights Reserved.
 *  Contributor(s): ______________________________________. 
 *
 *  20.05.2018 Simonov Denis <sim-mail@list.ru> - comments }
 
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

  // Factory for creating an instance of an external procedure TGenRowsProcedure
  TGenRowsFactory = class(IUdrProcedureFactoryImpl)
    // Called when the factory is destroyed
    procedure dispose(); override;

    { Executed every time an external function is loaded into the metadata cache

      @param(AStatus Status vector)
      @param(AContext External procedure context)
      @param(AMetadata External procedure metadata)
      @param(AInBuilder Message Builder for Input Metadata)
      @param(AOutBuilder Message Builder for Output Metadata)
    }
    procedure setup(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata; AInBuilder: IMetadataBuilder;
      AOutBuilder: IMetadataBuilder); override;

    { Creating a new instance of the external procedure TGenRowsProcedure

      @param(AStatus Status vector)
      @param(AContext External procedure context)
      @param(AMetadata External procedure metadata)
      @returns(External Procedure Instance)
    }
    function newItem(AStatus: IStatus; AContext: IExternalContext;
      AMetadata: IRoutineMetadata): IExternalProcedure; override;
  end;

  // External procedure TGenRowsProcedure.
  TGenRowsProcedure = class(IExternalProcedureImpl)
  public
    // Called when a procedure instance is destroyed
    procedure dispose(); override;

    { This method is called just before open and tells the engine the requested 
	  character set to exchange data within this method. During this call, 
	  the context uses the character set obtained from ExternalEngine::getCharSet.

      @param(AStatus Status vector)
      @param(AContext External procedure context)
      @param(AName Character set name)
      @param(AName Character set name length)
    }
    procedure getCharSet(AStatus: IStatus; AContext: IExternalContext;
      AName: PAnsiChar; ANameSize: Cardinal); override;

    { Executing an external procedure

      @param(AStatus Status vector)
      @param(AContext External procedure context)
      @param(AInMsg Pointer to input message)
      @param(AOutMsg Pointer to output message)
      @returns(External Dataset)
    }
    function open(AStatus: IStatus; AContext: IExternalContext; AInMsg: Pointer;
      AOutMsg: Pointer): IExternalResultSet; override;
  end;

  // Output dataset for the TGenRowsProcedure procedure
  TGenRowsResultSet = class(IExternalResultSetImpl)
    Input: PInput;
    Output: POutput;

    // Called when a dataset instance is destroyed
    procedure dispose(); override;

    { Retrieving the next record from a data set.
      In some ways analogous to SUSPEND. 
	  In this method, the next record from the data set must be prepared.

      @param(AStatus Status vector)
      @returns(True if there is a record to be retrieved in the dataset, 
	           False if there are no more records.)
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
  Result := TGenRowsResultSet.create;
  with TGenRowsResultSet(Result) do
  begin
    Input := AInMsg;
    Output := AOutMsg;
  end;	

  // if one of the input arguments is NULL, we return nothing
  if PInput(AInMsg).startNull or PInput(AInMsg).finishNull then
  begin
    POutput(AOutMsg).nNull := True;
	  // intentionally set the output result so that
	  // method TGenRowsResultSet.fetch returned false
    Output.n := Input.finish;
    exit;
  end;

  if PInput(AInMsg).start > PInput(AInMsg).finish then
    raise Exception.Create('First parameter greater then second parameter.');

  with TGenRowsResultSet(Result) do
  begin
    // initial value
    Output.nNull := False;
    Output.n := Input.start - 1;
  end;
end;

{ TGenRowsResultSet }

procedure TGenRowsResultSet.dispose;
begin
  Destroy;
end;

// If it returns True, then the next record is retrieved from the dataset.
// If it returns False, then there are no more records in the data set. 
// New values are calculated each time this method is called.
function TGenRowsResultSet.fetch(AStatus: IStatus): Boolean;
begin
  Inc(Output.n);
  Result := (Output.n <= Input.finish);
end;

end.
