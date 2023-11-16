-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 02/12/2013 09:27
-- CHANGE REASON: [ALERT-275904] 
CREATE OR REPLACE TYPE alert.t_rec_pat_trial FORCE AS OBJECT(
        id_trial NUMBER(24),
        code     VARCHAR2(100 CHAR),
        name     VARCHAR2(1000 CHAR)
);
/