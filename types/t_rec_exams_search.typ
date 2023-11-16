CREATE OR REPLACE TYPE t_rec_exams_search force AS OBJECT
(
    id_exam                  NUMBER(24),
    desc_exam                VARCHAR2(1000 CHAR),
    TYPE                     VARCHAR2(1 CHAR),
    desc_perform             VARCHAR2(1000 CHAR),
    flg_clinical_question    VARCHAR2(1 CHAR),
    flg_laterality_mcdt      VARCHAR2(1 CHAR),
    doc_template_exam        NUMBER(24),
    doc_template_exam_result NUMBER(24)
)
;
/
