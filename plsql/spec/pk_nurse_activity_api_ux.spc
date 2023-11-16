/*-- Last Change Revision: $Rev: 1855067 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-18 12:07:19 +0100 (qua, 18 jul 2018) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_nurse_activity_api_ux';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
