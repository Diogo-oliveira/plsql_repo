CREATE OR REPLACE FUNCTION Long_To_Char (
   in_rowid        ROWID,
   in_owner        VARCHAR,
   in_table_name   VARCHAR,
   in_column       VARCHAR2
)
   RETURN VARCHAR
AS
/** @headcom
 * Public Function.  Long to varchar2 conversion   
 * Utilizada para actualização da BD do Infarmed.

 * @param      in_rowid      	     rowid
 * @param      in_owner      	     owner
 * @param      in_table_name       nome da tabela
 * @param      in_column           coluna a converter
 *
 *
 * @return     boolean
 * @author     SS
 * @version    0.1
 * @since      2006/03/03
 
Notes: Errors out with varchar > 32767
       ORA-06502: PL/SQL: numeric or value error: character string
                 buffer too small
 */

   text_c1   VARCHAR2 (32767);
   sql_cur   VARCHAR2 (2000);
--
BEGIN
   sql_cur :=
         'select '
      || in_column
      || ' from
'
      || in_owner
      || '.'
      || in_table_name
      || ' where rowid =
'
      || CHR (39)
      || in_rowid
      || CHR (39);
  -- DBMS_OUTPUT.put_line (sql_cur);

   EXECUTE IMMEDIATE sql_cur
                INTO text_c1;

   text_c1 := SUBSTR (text_c1, 1, 4000);
   RETURN text_c1;
END;
/
