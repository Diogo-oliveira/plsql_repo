/*-- Last Change Revision: $Rev: 2028757 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE PK_INTERFACE_REPORT_ER_OUTP AS

FUNCTION generate_report_outp(id_episode IN NUMBER) RETURN VARCHAR2;

  FUNCTION urlGo_rept (url_path IN VARCHAR2,id_lang IN NUMBER, id_episode IN NUMBER, id_prof IN NUMBER, type_rept IN VARCHAR2, id_format IN NUMBER) RETURN VARCHAR2;
END;
/
