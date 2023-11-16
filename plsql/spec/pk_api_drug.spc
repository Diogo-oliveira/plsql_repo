/*-- Last Change Revision: $Rev: 1977955 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-01-28 12:18:01 +0000 (qui, 28 jan 2021) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_api_drug';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
