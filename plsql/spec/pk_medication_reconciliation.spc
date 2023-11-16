/*-- Last Change Revision: $Rev: 2028800 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:01 +0100 (ter, 02 ago 2022) $*/
DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE PK_MEDICATION_RECONCILIATION';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
