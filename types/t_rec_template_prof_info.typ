-- CHANGED BY: Orlando Antunes
-- CHANGED DATE: 2010-ABR-16
-- CHANGED REASON: ALERT-ALERT-89605

CREATE OR REPLACE TYPE t_rec_template_prof_info IS OBJECT
(
    id        NUMBER,
	dt        VARCHAR2(100 CHAR),
	prof_sign VARCHAR2(1000 CHAR),
	flg_status VARCHAR2(1 CHAR)
);
/

-- CHANGE END