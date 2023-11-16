/*-- Last Change Revision: $Rev: 2028597 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:45 +0100 (ter, 02 ago 2022) $*/

declare
  l_sql varchar2(4000);
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
begin
  l_sql := 'drop package alert.pk_dev_utils';
  pk_versioning.run(l_sql);
EXCEPTION
    WHEN e_not_exist THEN
        dbms_output.put_line('Object no longer exists. Resuming...');
end;
/


