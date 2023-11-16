-- CHANGED BY: Gisela Couto 
-- CHANGE DATE: 02-05-2014
-- CHANGE REASON: ALERT-280707 - DEV DB - CDA Section: Care team member(s) (generation)

DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_resp_professional_cda'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/

CREATE OR REPLACE TYPE t_resp_professional_cda IS TABLE OF profissional;
/

-- CHANGE END: Gisela Couto
