CREATE OR REPLACE TYPE t_procedures_for_selection force AS OBJECT
(
    id_intervention       NUMBER(12),
    desc_intervention     VARCHAR2(1000 CHAR),
    desc_perform          VARCHAR2(200 CHAR),
    flg_clinical_question VARCHAR2(1 CHAR),
    flg_timeout           VARCHAR2(1 CHAR),
    flg_laterality_mcdt   VARCHAR2(2 CHAR),
    rank                  NUMBER(12),
    id_codification       NUMBER(24)
);
/
