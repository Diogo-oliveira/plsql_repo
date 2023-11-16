-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/05/2016 09:24
-- CHANGE REASON: [ALERT-320563] 
CREATE OR REPLACE TYPE t_rec_vs_prm force AS OBJECT
(
    id_content             VARCHAR2(200 CHAR),
    id_vital_sign          NUMBER(24),
    flg_fill_type          VARCHAR2(1 CHAR),
    desc_flg_fill_type     VARCHAR2(200 CHAR),
    intern_name_vital_sign VARCHAR2(200 CHAR),
    desc_vital_sign        VARCHAR2(200 CHAR),
    desc_short_vital_sign  VARCHAR2(200 CHAR),
    CONSTRUCTOR FUNCTION t_rec_vs_prm RETURN SELF AS RESULT
);
-- CHANGE END: Paulo Teixeira