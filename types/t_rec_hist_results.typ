CREATE OR REPLACE TYPE t_rec_hist_results force AS OBJECT
(
    id_analysis           NUMBER(24),
    id_sample_type        NUMBER(24),
    id_analysis_parameter NUMBER(24),
    id_analysis_param     NUMBER(24),
    element_desc          VARCHAR2(1000 CHAR),
    analysis_count        NUMBER(24),
    analysis_status       VARCHAR2(1000 CHAR),
    flg_has_parent        VARCHAR2(1 CHAR),
    flg_has_children      VARCHAR2(1 CHAR),
    rank_lab_test         NUMBER(24),
    rank_lab_test_param   NUMBER(24),
    lab_test_desc         VARCHAR2(1000 CHAR),
    column_1              VARCHAR2(1000 CHAR),
    column_2              VARCHAR2(1000 CHAR),
    column_3              VARCHAR2(1000 CHAR),
    column_4              VARCHAR2(1000 CHAR),
    column_5              VARCHAR2(1000 CHAR),
    column_6              VARCHAR2(1000 CHAR),
    column_7              VARCHAR2(1000 CHAR),
    column_8              VARCHAR2(1000 CHAR),
    column_9              VARCHAR2(1000 CHAR),
    column_10             VARCHAR2(1000 CHAR),
    column_11             VARCHAR2(1000 CHAR),
    column_12             VARCHAR2(1000 CHAR)
);
/
