CREATE OR REPLACE TYPE monit AS OBJECT
(
    id_monit                  NUMBER(24),
    id_prof                   NUMBER(24),
    id_inst                   NUMBER(24),
    id_soft                   NUMBER(24),
    id_epis                   NUMBER(24),
    notes                     CLOB,
    flg_time                  VARCHAR2(1),
    dt_begin_str              VARCHAR2(24),
    dt_end_str                VARCHAR2(24),
    dt_begin_final_str        VARCHAR2(24),
    INTERVAL                  VARCHAR2(24),
    interval_final            NUMBER(12, 4),
    id_vs                     table_number,
    notes_detail              table_varchar,
    flg_status                VARCHAR2(1),
    flg_status_det            VARCHAR2(1),
    id_prof_order             NUMBER(24),
    dt_order_str              VARCHAR2(24),
    id_order_type             NUMBER(12),
    flg_monitorization_action VARCHAR2(1 CHAR),
    id_co_sign_order          NUMBER(24),
    id_co_sign_cancel         NUMBER(24)
);
/
