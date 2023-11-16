-- CHANGED BY: Orlando Antunes
-- CHANGED DATE: 2010-ABR-16
-- CHANGED REASON: ALERT-ALERT-89605

CREATE OR REPLACE TYPE t_rec_template_info IS OBJECT
(
    id        NUMBER,
	id_episode NUMBER,
	desc_template        CLOB
);
/

-- CHANGE END