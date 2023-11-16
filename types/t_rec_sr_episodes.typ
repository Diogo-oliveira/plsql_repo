-- CHANGED BY: Luís Maia
-- CHANGE DATE: 06/06/2011 08:45
-- CHANGE REASON: [ALERT-182676] Versioning 01 - types
CREATE OR REPLACE TYPE t_rec_sr_episodes AS OBJECT
(
    id_patient          NUMBER(24),
    id_episode          NUMBER(24),
    id_schedule_sr      NUMBER(24),
    id_waiting_list     NUMBER(24),
    surg_proc           VARCHAR2(4000 CHAR),
    flg_status          VARCHAR2(30 CHAR),
    admiss_epis_done    VARCHAR2(30 CHAR),
    surgery_epis_done   VARCHAR2(30 CHAR),
    waiting_list_type   VARCHAR2(30 CHAR),
    adm_needed          VARCHAR2(30 CHAR),
    dt_surgery          VARCHAR2(4000 CHAR),
    dt_surgery_str      VARCHAR2(4000 CHAR),
    duration            VARCHAR2(30 CHAR),
    duration_minutes    VARCHAR2(30 CHAR),
    pos_status          VARCHAR2(4000 CHAR),
    admiss_status       VARCHAR2(4000 CHAR),
    oris_status         VARCHAR2(4000 CHAR),
    sr_type             VARCHAR2(30 CHAR),
    sr_type_icon        VARCHAR2(200 CHAR),
    id_inst_surg        NUMBER(24),
    inst_surg_name      VARCHAR2(4000 CHAR),
    sr_status           VARCHAR2(4000 CHAR),
    flg_pos_expired     VARCHAR2(30 CHAR), --
    inst_adm_name       VARCHAR2(4000 CHAR),
    id_inst_adm         NUMBER(24),
    id_adm_request      NUMBER(24),
    dt_admission_tsz    TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_prof_req         NUMBER(24),
    id_dest_prof        NUMBER(24),
    schedule_flg_status VARCHAR2(200 CHAR),
    id_dep_clin_serv    NUMBER(24),
    id_schedule         NUMBER(24),
    desc_admission      VARCHAR2(4000 CHAR),
    id_dest_inst        NUMBER(24), --
    flg_surg_nat        VARCHAR2(30 CHAR),
    desc_surg_nat       VARCHAR2(4000 CHAR),
    flg_priority        VARCHAR2(30 CHAR),
    desc_priority       VARCHAR2(4000 CHAR),
    flg_sr_proc         VARCHAR2(30 CHAR),
    id_room             NUMBER(24),
    desc_room           VARCHAR2(4000 CHAR)
);
/
-- CHANGE END: Luís Maia

-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 25/11/2014
-- CHANGE REASON: [ALERT-301549] Surgical Episodes - Edit info POS/ Cancel Surgery request when POS appointment is scheduled - An error occurs
DROP TYPE t_tbl_sr_episodes;

CREATE OR REPLACE TYPE t_rec_sr_episodes AS OBJECT
(
    id_patient          NUMBER(24),
    id_episode          NUMBER(24),
    id_schedule_sr      NUMBER(24),
    id_waiting_list     NUMBER(24),
    surg_proc           VARCHAR2(4000 CHAR),
    flg_status          VARCHAR2(30 CHAR),
    admiss_epis_done    VARCHAR2(30 CHAR),
    surgery_epis_done   VARCHAR2(30 CHAR),
    waiting_list_type   VARCHAR2(30 CHAR),
    adm_needed          VARCHAR2(30 CHAR),
    dt_surgery          VARCHAR2(4000 CHAR),
    dt_surgery_str      VARCHAR2(4000 CHAR),
    duration            VARCHAR2(30 CHAR),
    duration_minutes    VARCHAR2(30 CHAR),
    pos_status          VARCHAR2(4000 CHAR),
    admiss_status       VARCHAR2(4000 CHAR),
    oris_status         VARCHAR2(4000 CHAR),
    sr_type             VARCHAR2(30 CHAR),
    sr_type_icon        VARCHAR2(200 CHAR),
    id_inst_surg        NUMBER(24),
    inst_surg_name      VARCHAR2(4000 CHAR),
    sr_status           VARCHAR2(4000 CHAR),
    flg_pos_expired     VARCHAR2(30 CHAR), --
    inst_adm_name       VARCHAR2(4000 CHAR),
    id_inst_adm         NUMBER(24),
    id_adm_request      NUMBER(24),
    dt_admission_tsz    TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_req         NUMBER(24),
    id_dest_prof        NUMBER(24),
    schedule_flg_status VARCHAR2(200 CHAR),
    id_dep_clin_serv    NUMBER(24),
    id_schedule         NUMBER(24),
    desc_admission      VARCHAR2(4000 CHAR),
    id_dest_inst        NUMBER(24), --
    flg_surg_nat        VARCHAR2(30 CHAR),
    desc_surg_nat       VARCHAR2(4000 CHAR),
    flg_priority        VARCHAR2(30 CHAR),
    desc_priority       VARCHAR2(4000 CHAR),
    flg_sr_proc         VARCHAR2(30 CHAR),
    id_room             NUMBER(24),
    desc_room           VARCHAR2(4000 CHAR),
    flg_request_edit    VARCHAR2(1 CHAR)
);

CREATE OR REPLACE TYPE t_tbl_sr_episodes IS TABLE OF T_REC_SR_EPISODES;
/
-- Vanessa Barsottelli



-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 01/03/2016 14:57
-- CHANGE REASON: [ALERT-319114] 
CREATE OR REPLACE TYPE t_rec_sr_episodes AS OBJECT
(
    id_patient          NUMBER(24),
    id_episode          NUMBER(24),
    id_schedule_sr      NUMBER(24),
    id_waiting_list     NUMBER(24),
    surg_proc           VARCHAR2(4000 CHAR),
    flg_status          VARCHAR2(30 CHAR),
    admiss_epis_done    VARCHAR2(30 CHAR),
    surgery_epis_done   VARCHAR2(30 CHAR),
    waiting_list_type   VARCHAR2(30 CHAR),
    adm_needed          VARCHAR2(30 CHAR),
    dt_surgery          VARCHAR2(4000 CHAR),
    dt_surgery_str      VARCHAR2(4000 CHAR),
    duration            VARCHAR2(30 CHAR),
    duration_minutes    VARCHAR2(30 CHAR),
    pos_status          VARCHAR2(4000 CHAR),
    admiss_status       VARCHAR2(4000 CHAR),
    oris_status         VARCHAR2(4000 CHAR),
    sr_type             VARCHAR2(30 CHAR),
    sr_type_icon        VARCHAR2(200 CHAR),
    id_inst_surg        NUMBER(24),
    inst_surg_name      VARCHAR2(4000 CHAR),
    sr_status           VARCHAR2(4000 CHAR),
    flg_pos_expired     VARCHAR2(30 CHAR), --
    inst_adm_name       VARCHAR2(4000 CHAR),
    id_inst_adm         NUMBER(24),
    id_adm_request      NUMBER(24),
    dt_admission_tsz    TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_req         NUMBER(24),
    id_dest_prof        NUMBER(24),
    schedule_flg_status VARCHAR2(200 CHAR),
    id_dep_clin_serv    NUMBER(24),
    id_schedule         NUMBER(24),
    desc_admission      VARCHAR2(4000 CHAR),
    id_dest_inst        NUMBER(24), --
    flg_surg_nat        VARCHAR2(30 CHAR),
    desc_surg_nat       VARCHAR2(4000 CHAR),
    flg_priority        VARCHAR2(30 CHAR),
    desc_priority       VARCHAR2(4000 CHAR),
    flg_sr_proc         VARCHAR2(30 CHAR),
    id_room             NUMBER(24),
    desc_room           VARCHAR2(4000 CHAR),
    flg_request_edit    VARCHAR2(1 CHAR),
    id_prev_episode     NUMBER(24)
);
-- CHANGE END: Paulo Teixeira