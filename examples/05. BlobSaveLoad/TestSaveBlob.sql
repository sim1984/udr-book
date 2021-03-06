EXECUTE BLOCK
AS
DECLARE BR CHAR(2);
DECLARE PATH VARCHAR(255);
DECLARE FILENAME VARCHAR(255);
DECLARE CREATE_PACKAGE BLOB SUB_TYPE TEXT;
DECLARE CREATE_PACKAGE_BODY BLOB SUB_TYPE TEXT;
BEGIN
  BR =  ASCII_CHAR(13) || ASCII_CHAR(10);
  PATH = 'f:/1/';
  FOR
    SELECT
      P.RDB$PACKAGE_NAME,
      P.RDB$PACKAGE_HEADER_SOURCE,
      P.RDB$PACKAGE_BODY_SOURCE
    FROM RDB$PACKAGES P
  AS CURSOR C
  DO
  BEGIN
    -- создание заголовка пакета
    CREATE_PACKAGE = 'CREATE OR ALTER PACKAGE ' || TRIM(C.RDB$PACKAGE_NAME) ||
      BR || C.RDB$PACKAGE_HEADER_SOURCE || '^';
    -- создание тела пакета
    CREATE_PACKAGE_BODY = 'RECREATE PACKAGE BODY ' || TRIM(C.RDB$PACKAGE_NAME) ||
      BR || C.RDB$PACKAGE_BODY_SOURCE || '^';
    -- имя файла
    FILENAME = PATH || TRIM(C.RDB$PACKAGE_NAME) || '.sql';
    EXECUTE PROCEDURE BLOBFILEUTILS.SAVEBLOBTOFILE(
      CREATE_PACKAGE || BR || BR || CREATE_PACKAGE_BODY,
      FILENAME
    );
  END
END
