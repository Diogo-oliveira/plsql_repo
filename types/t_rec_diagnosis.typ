-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 19/11/2012
-- CHANGE REASON: [ALERT-245129]
DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_table_diagnoses'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/

CREATE OR REPLACE TYPE t_rec_diagnosis AS OBJECT
(
    id_diagnosis        NUMBER(24),
    id_alert_diagnosis  NUMBER(24),
    desc_epis_diagnosis VARCHAR2(1000 CHAR)
);
/

CREATE OR REPLACE TYPE t_table_diagnoses IS TABLE OF t_rec_diagnosis;
/
-- CHANGE END: Tiago Silva
