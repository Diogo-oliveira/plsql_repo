-- CHANGED BY: Gisela Couto 
-- CHANGE DATE: 18-02-2014
-- CHANGE REASON: ALERT-274443 - Current pregnancy record end by the system incoherent viewer info


DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_item_index_details'; 
  EXECUTE IMMEDIATE 'DROP TYPE t_item_index_detail'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/

CREATE OR REPLACE TYPE t_item_index_detail IS OBJECT
(
       id_pat_pregnancy number(24),
       description VARCHAR2(4000),
       professional VARCHAR2(800),
       dt_register DATE,
	   dt_register_term VARCHAR2(1 CHAR),
	   dt_register_init VARCHAR2(1 CHAR),
       speciality VARCHAR2(200),
       counter number(10)

);
/

CREATE OR REPLACE TYPE t_item_index_details IS TABLE OF t_item_index_detail;
/
-- CHANGE END: Gisela Couto