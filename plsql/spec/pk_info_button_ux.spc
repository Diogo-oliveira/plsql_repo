/*-- Last Change Revision: $Rev: 1993370 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-07-05 11:07:06 +0100 (seg, 05 jul 2021) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_info_button_ux';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
