/*-- Last Change Revision: $Rev: 2027280 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY PK_INTERFACE_REPORT_ER_OUTP AS

FUNCTION generate_report_outp(id_episode IN NUMBER) RETURN VARCHAR2 IS
  L_URL VARCHAR2(200) := PK_SYSCONFIG.GET_CONFIG('URL_REPORT_ER_OUTP', 0, 0);
   BEGIN
  RETURN  urlGo_rept(L_URL, 1, id_episode,0, 'C',0);
   END;

 FUNCTION urlGo_rept (url_path IN VARCHAR2,id_lang IN NUMBER, id_episode IN NUMBER, id_prof IN NUMBER, type_rept IN VARCHAR2, id_format IN NUMBER)
   RETURN VARCHAR2
   AS LANGUAGE JAVA
   NAME 'URLReader.urlGo
     (java.lang.String,int,int,int, java.lang.String,int) return java.lang.String';

     
END;
/
