/*-- Last Change Revision: $Rev: 1853001 $*/
/*-- Last Change by: $Author: adriana.ramos $*/
/*-- Date of last change: $Date: 2018-07-09 11:14:32 +0100 (seg, 09 jul 2018) $*/
DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW ME_PHARM_GROUP_PT';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
