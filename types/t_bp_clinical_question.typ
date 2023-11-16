CREATE OR REPLACE TYPE t_bp_clinical_question force AS OBJECT
(
    desc_clinical_question     VARCHAR2(1000 CHAR),
    desc_clinical_question_new VARCHAR2(1000 CHAR),
    desc_response              VARCHAR2(1000 CHAR),
    desc_response_new          VARCHAR2(1000 CHAR),
    num_order                  NUMBER(24),
    rank                       NUMBER(24)
);