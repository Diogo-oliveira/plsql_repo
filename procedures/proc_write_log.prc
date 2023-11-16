CREATE OR REPLACE PROCEDURE PROC_WRITE_LOG ( i_file_name IN varchar2,
                         i_file_path in varchar2,
                         i_msg IN varchar2,
                         O_ERROR out VARCHAR2) IS

  fileHandler UTL_FILE.FILE_TYPE;
  file_name varchar2(40);
  file_path varchar2(200);

BEGIN
  file_name := nvl(i_file_name, 'default.txt');
  file_path := nvl(i_file_path, 'DIR_ROOT');
  
  fileHandler := UTL_FILE.FOPEN(file_path, file_name, 'a');
  UTL_FILE.PUT_LINE(fileHandler, /*to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss - ')||*/i_msg);
  UTL_FILE.FCLOSE(fileHandler);
  
EXCEPTION
  WHEN utl_file.invalid_path THEN
     raise_application_error(-20000, 'ERROR: Invalid path for file or path not in INIT.ORA.');
END;
/
