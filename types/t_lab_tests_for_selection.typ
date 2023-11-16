CREATE OR REPLACE TYPE t_lab_tests_for_selection force AS OBJECT
(
    id_analysis             NUMBER(12),
    desc_analysis           VARCHAR2(1000 CHAR),
    id_sample_type          NUMBER(12),
    desc_sample_type        VARCHAR2(200 CHAR),
    id_analysis_instit_soft NUMBER(24),
    desc_perform            VARCHAR2(200 CHAR),
    flg_clinical_question   VARCHAR2(2 CHAR),
    TYPE                    VARCHAR2(2 CHAR),
    rank                    NUMBER(12)
);
/
