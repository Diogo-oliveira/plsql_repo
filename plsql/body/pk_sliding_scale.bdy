/*-- Last Change Revision: $Rev: 1887484 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2019-01-24 09:36:10 +0000 (qui, 24 jan 2019) $*/

DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -04043);
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pk_sliding_scale';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
