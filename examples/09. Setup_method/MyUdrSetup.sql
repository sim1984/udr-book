create or alter function FN_SUM_ARGS (
  n1 varchar(15),
  n2 varchar(15),
  n3 varchar(15)
)
returns varchar(15)
EXTERNAL NAME 'MyUdrSetup!sum_args'
ENGINE UDR;