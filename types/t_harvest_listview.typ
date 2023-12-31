CREATE OR REPLACE TYPE t_harvest_listview force AS OBJECT
(
    id_harvest             NUMBER(24),
    id_analysis_harvest    table_number,
    id_analysis_req_det    table_number,
    id_analysis_req        table_number,
    id_analysis            table_number,
    id_sample_type         table_number,
    flg_status             VARCHAR2(1 CHAR),
    harvest_num            VARCHAR2(50 CHAR),
    flg_priority           VARCHAR2(1 CHAR),
    id_sample_recipient    NUMBER(24),
    num_recipient          VARCHAR2(200 CHAR),
    notes                  VARCHAR2(1000 CHAR),
    id_body_location       NUMBER(24),
    flg_laterality         VARCHAR2(1 CHAR),
    id_collection_location VARCHAR2(200 CHAR),
    flg_type_lab           VARCHAR2(1 CHAR),
    id_laboratory          NUMBER(24),
    flg_clinical_question  VARCHAR2(1 CHAR),
    min_dt_target          TIMESTAMP WITH LOCAL TIME ZONE,
    max_dt_target          TIMESTAMP WITH LOCAL TIME ZONE,
    avail_button_ok        VARCHAR2(1 CHAR),
    avail_button_cancel    VARCHAR2(1 CHAR),
    dt_target              TIMESTAMP WITH LOCAL TIME ZONE,
    dt_req                 TIMESTAMP WITH LOCAL TIME ZONE,
    dt_pend_req            TIMESTAMP WITH LOCAL TIME ZONE,
    dt_begin_harvest       TIMESTAMP WITH LOCAL TIME ZONE,
    flg_time_harvest       VARCHAR2(1 CHAR),
    rank                   NUMBER(6),
    analysis_rank          NUMBER(6),
    harvest_rank           NUMBER(6)
);
/