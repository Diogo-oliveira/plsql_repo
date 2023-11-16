/*-- Last Change Revision: $Rev: 1848397 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-06-25 09:46:13 +0100 (seg, 25 jun 2018) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_webservices';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
