/*-- Last Change Revision: $Rev: 2028327 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:08 +0100 (ter, 02 ago 2022) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE TS_PRESCRIPTION_INSTR_HIST';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
