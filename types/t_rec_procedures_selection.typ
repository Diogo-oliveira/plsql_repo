CREATE OR REPLACE TYPE t_rec_lab_tests_selection force AS OBJECT
(
    id_analysis             NUMBER(24),
    desc_analysis           VARCHAR2(300 CHAR),
    id_sample_type          NUMBER(24),
    desc_sample_type        VARCHAR2(300 CHAR),
    desc_perform            VARCHAR2(300 CHAR),
    flg_clinical_question   VARCHAR2(10 CHAR),
    TYPE                    VARCHAR2(10 CHAR),
    rank                    NUMBER(24),
    id_analysis_instit_soft NUMBER(24)

)
;
/
