/*-- Last Change Revision: $Rev: 2028946 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:54 +0100 (ter, 02 ago 2022) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_schedule_analysis';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
