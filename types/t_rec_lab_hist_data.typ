CREATE OR REPLACE TYPE t_rec_lab_hist_data force AS OBJECT
(
--column_data
    id_column     VARCHAR2(1000 CHAR),
    dt_sample     VARCHAR2(1000 CHAR),
    hour_read     VARCHAR2(1000 CHAR),
    short_dt_read VARCHAR2(1000 CHAR),
    header_desc   VARCHAR2(1000 CHAR),
    date_target   VARCHAR2(1000 CHAR),
    hour_target   VARCHAR2(1000 CHAR),
    column_number VARCHAR2(1000 CHAR),
--rows_data
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
--results_data
    id_element             NUMBER(24),
    id_analysis_req_par    NUMBER(24),
    id_analysis_result     NUMBER(24),
    id_analysis_result_par NUMBER(24),
    id_harvest             NUMBER(24),
    VALUE                  VARCHAR2(1000 CHAR),
    abnorm                 VARCHAR2(1000 CHAR),
    flg_notes              VARCHAR2(1 CHAR),
		desc_notes             VARCHAR2(4000),
    flg_notes_cancel       VARCHAR2(1 CHAR),
    prof_results           VARCHAR2(1000 CHAR),
-- identifies the column_number for flash 
    desc_column VARCHAR2(1000 CHAR)
)
;
/