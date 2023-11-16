CREATE OR REPLACE TYPE t_rec_lab_tests_search force AS OBJECT
(
    id_analysis             NUMBER(24),
    desc_analysis           VARCHAR2(300 CHAR),
    id_sample_type          NUMBER(24),
    desc_sample_type        VARCHAR2(300 CHAR),
    desc_perform            VARCHAR2(300 CHAR),
    flg_clinical_question   VARCHAR2(10 CHAR),
    id_analysis_instit_soft NUMBER(24),
    TYPE                    VARCHAR2(10 CHAR)
)
;
/
