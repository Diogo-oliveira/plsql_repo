CREATE OR REPLACE TYPE t_rec_comm_order_plan_info force AS OBJECT
(
    action                VARCHAR2(50 CHAR),
    flg_origin            VARCHAR2(1 CHAR),
    id_comm_order_plan    number(24),
    id_comm_order_req     number(24),
    flg_status            VARCHAR2(1 CHAR),
    id_epis_documentation number(24),
    exec_number           number(24),
    prof_performed        VARCHAR2(1000 CHAR),
    registry              VARCHAR2(1000 CHAR),
    start_time            VARCHAR2(50 CHAR),
    end_time              VARCHAR2(50 CHAR),
    cancel_reason         VARCHAR2(1000 CHAR),
    cancel_notes          VARCHAR2(4000 CHAR),
    notes                 VARCHAR2(4000 CHAR),
    dt_rec                TIMESTAMP(6) WITH LOCAL TIME ZONE
)
;
/