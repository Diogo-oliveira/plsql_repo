/*-- Last Change Revision: $Rev: 2027424 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:11 +0100 (ter, 02 ago 2022) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_p1_core_internal';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
drop package PK_P1_CORE_INTERNAL;


/
