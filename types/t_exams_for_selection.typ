CREATE OR REPLACE TYPE t_exams_for_selection force AS OBJECT
(
    id_exam               NUMBER(12),
    desc_exam             VARCHAR2(1000 CHAR),
    desc_perform          VARCHAR2(200 CHAR),
    flg_clinical_question VARCHAR2(2 CHAR),
    flg_laterality_mcdt   VARCHAR2(2 CHAR),
    TYPE                  VARCHAR2(2 CHAR),
    rank                  NUMBER(12)
);
/
