CREATE OR REPLACE TYPE t_exams_ea force AS OBJECT
(
    id_exam_req           NUMBER(24),
    id_exam_req_det       NUMBER(24),
    id_exam_result        NUMBER(24),
    id_exam               NUMBER(12),
    id_exam_group         NUMBER(24),
    id_exam_cat           NUMBER(24),
    dt_req                TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_begin              TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_pend_req           TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_result             TIMESTAMP(6) WITH LOCAL TIME ZONE,
    status_str_req        VARCHAR2(100),
    status_msg_req        VARCHAR2(100),
    status_icon_req       VARCHAR2(100),
    status_flg_req        VARCHAR2(100),
    status_str            VARCHAR2(100),
    status_msg            VARCHAR2(100),
    status_icon           VARCHAR2(100),
    status_flg            VARCHAR2(100),
    flg_type              VARCHAR2(1),
    flg_available         VARCHAR2(1),
    flg_notes             VARCHAR2(1),
    flg_doc               VARCHAR2(1),
    flg_time              VARCHAR2(1),
    flg_status_req        VARCHAR2(2),
    flg_status_det        VARCHAR2(2),
    flg_status_result     VARCHAR2(1),
    flg_referral          VARCHAR2(1),
    priority              VARCHAR2(1),
    id_prof_req           NUMBER(24),
    id_exam_codification  NUMBER(24),
    id_task_dependency    NUMBER(24),
    id_room               NUMBER(24),
    id_movement           NUMBER(24),
    notes                 VARCHAR2(4000),
    notes_technician      VARCHAR2(4000),
    notes_patient         VARCHAR2(4000),
    notes_cancel          VARCHAR2(4000),
    id_prof_performed     NUMBER(24),
    start_time            TIMESTAMP(6) WITH LOCAL TIME ZONE,
    end_time              TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_epis_doc_perform   NUMBER(24),
    desc_perform_notes    CLOB,
    id_epis_doc_result    NUMBER(24),
    desc_result           CLOB,
    flg_req_origin_module VARCHAR2(1),
    id_patient            NUMBER(24),
    id_visit              NUMBER(24),
    id_episode            NUMBER(24),
    id_episode_origin     NUMBER(24),
    id_prev_episode       NUMBER(24),
    dt_dg_last_update     TIMESTAMP(6) WITH LOCAL TIME ZONE,
    notes_scheduler       VARCHAR2(1000 CHAR),
    id_epis_type          NUMBER(12),
    id_epis               NUMBER(24)
);
/
