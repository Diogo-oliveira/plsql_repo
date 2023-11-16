CREATE OR REPLACE TYPE t_rec_report_doc_arch force AS OBJECT
(
    rank                     NUMBER(6),
    id_reports               NUMBER(24),
    desc_report              VARCHAR2(32000 CHAR),
    flg_type                 VARCHAR2(1 CHAR),
    flg_tools                VARCHAR2(1 CHAR),
    flg_filter               VARCHAR2(1 CHAR),
    flg_printer              VARCHAR2(1 CHAR),
    flg_auth_req             VARCHAR2(1 CHAR),
    flg_action               VARCHAR2(100 CHAR),
    det_screen_name          VARCHAR2(200 CHAR),
    flg_status               VARCHAR2(200 CHAR),
    flg_time_fraction        VARCHAR2(1 CHAR),
    flg_param_profs          VARCHAR2(1 CHAR),
    max_prof_count           NUMBER,
    interval_count           NUMBER,
    id_parent                NUMBER(24),
    flg_date_filters         VARCHAR2(1 CHAR),
    level_rank               NUMBER(24),
    flg_disclosure           VARCHAR2(1 CHAR),
    has_sections             VARCHAR2(1 CHAR),
    id_task_type             VARCHAR2(32000 CHAR),
    flg_date_filters_context VARCHAR2(2 CHAR),
    column_values            table_varchar,
    flg_active               VARCHAR2(1 CHAR)
);
/
