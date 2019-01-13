SET TERM ^ ;

CREATE OR ALTER PACKAGE MYUDR2
AS
begin
  function SqrSmallint(AInput SMALLINT) RETURNS INTEGER;
  function SqrInteger(AInput INTEGER) RETURNS BIGINT;
  function SqrBigint(AInput BIGINT) RETURNS BIGINT;
  function SqrFloat(AInput FLOAT) RETURNS DOUBLE PRECISION;
  function SqrDouble(AInput DOUBLE PRECISION) RETURNS DOUBLE PRECISION;
end^

RECREATE PACKAGE BODY MYUDR2
AS
begin
  function SqrSmallint(AInput SMALLINT) RETURNS INTEGER
  external name 'myudr2!sqr_func'
  engine udr;

  function SqrInteger(AInput INTEGER) RETURNS BIGINT
  external name 'myudr2!sqr_func'
  engine udr;

  function SqrBigint(AInput BIGINT) RETURNS BIGINT
  external name 'myudr2!sqr_func'
  engine udr;

  function SqrFloat(AInput FLOAT) RETURNS DOUBLE PRECISION
  external name 'myudr2!sqr_func'
  engine udr;

  function SqrDouble(AInput DOUBLE PRECISION) RETURNS DOUBLE PRECISION
  external name 'myudr2!sqr_func'
  engine udr;

end
^

SET TERM ; ^