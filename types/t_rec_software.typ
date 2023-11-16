-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/05/2016 09:24
-- CHANGE REASON: [ALERT-320563] 
CREATE OR REPLACE TYPE t_rec_software force AS OBJECT
(
    soft_name   VARCHAR2(200 CHAR),
    id_software NUMBER(24),
    CONSTRUCTOR FUNCTION t_rec_software RETURN SELF AS RESULT
);
-- CHANGE END: Paulo Teixeira