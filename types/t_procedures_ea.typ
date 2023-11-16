CREATE OR REPLACE TYPE t_procedures_ea force AS OBJECT
(
    id_interv_prescription  NUMBER(24),
    id_interv_presc_det     NUMBER(24),
    id_interv_presc_plan    NUMBER(24),
    id_intervention         NUMBER(24),
    flg_status_intervention VARCHAR2(1 CHAR),
    flg_status_req          VARCHAR2(2 CHAR),
    flg_status_det          VARCHAR2(2 CHAR),
    flg_status_plan         VARCHAR2(1 CHAR),
    flg_time                VARCHAR2(1 CHAR),
    flg_interv_type         VARCHAR2(1 CHAR),
    dt_begin_req            TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_begin_det            TIMESTAMP(6) WITH LOCAL TIME ZONE,
    INTERVAL                NUMBER(12, 4),
    dt_interv_prescription  TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_plan                 TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_professional         NUMBER(24),
    flg_notes               VARCHAR2(1 CHAR),
    status_str              VARCHAR2(200 CHAR),
    status_msg              VARCHAR2(200 CHAR),
    status_icon             VARCHAR2(200 CHAR),
    status_flg              VARCHAR2(2 CHAR),
    id_prof_order           NUMBER(24),
    code_intervention_alias VARCHAR2(200 CHAR),
    flg_prty                VARCHAR2(1 CHAR),
    num_take                NUMBER(3),
    id_episode_origin       NUMBER(24),
    id_visit                NUMBER(24),
    id_episode              NUMBER(24),
    id_patient              NUMBER(24),
    flg_referral            VARCHAR2(1 CHAR),
    dt_interv_presc_det     TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_dg_last_update       TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_order                TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_laterality          VARCHAR2(1 CHAR),
    flg_clinical_purpose    VARCHAR2(1 CHAR),
    flg_prn                 VARCHAR2(1 CHAR),
    flg_doc                 VARCHAR2(1 CHAR),
    id_interv_codification  NUMBER(24),
    id_order_recurrence     NUMBER(24),
    id_task_dependency      NUMBER(24),
    flg_req_origin_module   VARCHAR2(1 CHAR),
    notes                   VARCHAR2(1000 CHAR),
    notes_cancel            VARCHAR2(1000 CHAR),
    id_clinical_purpose     NUMBER(24),
    clinical_purpose_notes  VARCHAR2(1000 CHAR),
    id_epis_type            NUMBER(12),
    id_epis                 NUMBER(24)
);
/