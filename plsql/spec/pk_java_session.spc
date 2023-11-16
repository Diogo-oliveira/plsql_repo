/*-- Last Change Revision: $Rev: 2028765 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_java_session IS

    -- Author  : SUSANA
    -- Created : 03-09-2007 15:43:02
    -- Purpose : Reset packages status

    FUNCTION reset_packages RETURN BOOLEAN;

END pk_java_session;
/
