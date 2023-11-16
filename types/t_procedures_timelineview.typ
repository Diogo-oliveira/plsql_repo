CREATE OR REPLACE TYPE t_procedures_timelineview force AS OBJECT
(
    id_intervention        NUMBER(12),
    id_interv_presc_det    NUMBER(24),
    id_interv_presc_plan   NUMBER(24),
    id_order_recurrence    NUMBER(24),
    flg_prty               VARCHAR2(1 CHAR),
    flg_laterality         VARCHAR2(1 CHAR),
    id_interv_codification NUMBER(24),
    id_exec_institution    NUMBER(24),
    flg_status_det         VARCHAR2(2 CHAR),
    flg_referral           VARCHAR2(2 CHAR),
    flg_status             VARCHAR2(2 CHAR),
    dt_interv_prescription TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_plan_tstz           TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_cancel_tstz         TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_take_tstz           TIMESTAMP(6) WITH LOCAL TIME ZONE,
    status_str             VARCHAR2(200 CHAR),
    status_msg             VARCHAR2(200 CHAR),
    status_icon            VARCHAR2(200 CHAR),
    status_flg             VARCHAR2(200 CHAR),
    id_episode             NUMBER(24),
    id_patient             NUMBER(24),
    flg_time               VARCHAR2(2 CHAR)
)
;
/
