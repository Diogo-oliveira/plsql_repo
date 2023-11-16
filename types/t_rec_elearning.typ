-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 18/02/2014 15:38
-- CHANGE REASON: [ALERT-274709] 
CREATE OR REPLACE TYPE t_rec_elearning AS OBJECT
(
    id_elearning  NUMBER(24),
    username      VARCHAR2(200 CHAR),
    id_software   NUMBER(24),
    flg_certified VARCHAR2(1 CHAR)
);
-- CHANGE END: Rui Spratley