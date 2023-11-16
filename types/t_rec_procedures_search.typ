CREATE OR REPLACE TYPE t_rec_procedures_search force AS OBJECT
(
    id_intervention           NUMBER(24),
    desc_intervention         VARCHAR2(1000 CHAR),
    desc_perform              VARCHAR2(1000 CHAR),
    flg_clinical_question     VARCHAR2(1 CHAR),
    flg_timeout               VARCHAR2(1 CHAR),
    flg_laterality_mcdt       VARCHAR2(1 CHAR),
    doc_template_intervention VARCHAR2(100 CHAR)
);
/
