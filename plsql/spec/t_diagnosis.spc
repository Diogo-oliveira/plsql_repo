/*-- Last Change Revision: $Rev: 1847268 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-06-19 16:54:42 +0100 (ter, 19 jun 2018) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE t_diagnosis';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
