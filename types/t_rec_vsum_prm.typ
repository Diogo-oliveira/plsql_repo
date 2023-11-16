-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/05/2016 09:24
-- CHANGE REASON: [ALERT-320563] 
CREATE OR REPLACE TYPE t_rec_vsum_prm force AS OBJECT
(
    id_vital_sign_unit_measure NUMBER(24),
    id_vital_sign              NUMBER(24),
    desc_vital_sign            VARCHAR2(1000 CHAR),
    id_market                  NUMBER(24),
    desc_market                VARCHAR2(200 CHAR),
    id_software                NUMBER(24),
    desc_software              VARCHAR2(200 CHAR),
    version                    VARCHAR2(200 CHAR),
    id_unit_measure            NUMBER(24),
    desc_unit_measure          VARCHAR2(200 CHAR),
    val_min                    NUMBER(24, 3),
    val_max                    NUMBER(24, 3),
    format_num                 VARCHAR2(200 CHAR),
    decimals                   NUMBER(24),
    age_min                    NUMBER(24),
    age_max                    NUMBER(24),
    CONSTRUCTOR FUNCTION t_rec_vsum_prm RETURN SELF AS RESULT
);
-- CHANGE END: Paulo Teixeira