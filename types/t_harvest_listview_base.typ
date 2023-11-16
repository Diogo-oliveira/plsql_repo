CREATE OR REPLACE TYPE t_harvest_listview_base force AS OBJECT
(
    id_harvest             NUMBER(24),
    id_analysis_harvest    NUMBER(24),
    id_analysis_req_det    NUMBER(24),
    id_analysis_req        NUMBER(24),
    id_analysis            NUMBER(24),
    id_sample_type         NUMBER(24),
    flg_status             VARCHAR2(1 CHAR),
    flg_status_det         VARCHAR2(3 CHAR),
    flg_priority           VARCHAR2(1 CHAR),
    id_sample_recipient    NUMBER(24),
    num_recipient          VARCHAR2(200 CHAR),
    notes                  VARCHAR2(1000 CHAR),
    id_body_location       NUMBER(24),
    flg_laterality         VARCHAR2(1 CHAR),
    id_collection_location VARCHAR2(200 CHAR),
    flg_type_lab           VARCHAR2(1 CHAR),
    id_laboratory          NUMBER(24),
    dt_target              timestamp with local time zone,
    dt_req                 timestamp with local time zone,
    dt_pend_req            timestamp with local time zone,
    dt_begin_harvest       timestamp with local time zone,
    flg_time_harvest       VARCHAR2(1 CHAR),
    id_rep_coll_reason     NUMBER(24),
    rank                   NUMBER(24)
);
/
