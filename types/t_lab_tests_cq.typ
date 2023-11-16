CREATE OR REPLACE TYPE t_lab_tests_cq force AS OBJECT
(
    id_analysis_req_det    NUMBER(24),
    id_content             VARCHAR2(1000 CHAR),
    flg_time               VARCHAR2(1 CHAR),
    desc_clinical_question CLOB,
    desc_response          CLOB,
    dt_last_update         VARCHAR2(100 CHAR),
    num_clinical_question  NUMBER(24),
    rn                     NUMBER(24)
)
;
/
