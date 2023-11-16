-- CHANGED BY: Luís Maia
-- CHANGE DATE: 01/06/2011 08:31
-- CHANGE REASON: [ALERT-180710]
CREATE OR REPLACE TYPE t_rec_ar_episodes AS OBJECT
(
    rank                NUMBER(24),
    desc_admission      VARCHAR2(4000 CHAR),
    waiting_list_type   VARCHAR2(30 CHAR),
    id_waiting_list     NUMBER(24),
    adm_needed          VARCHAR2(30 CHAR),
    sur_needed          VARCHAR2(30 CHAR),
    admiss_epis_done    VARCHAR2(30 CHAR),
    dt_admission        VARCHAR2(4000 CHAR),
    duration            VARCHAR2(4000 CHAR),
    id_episode          NUMBER(24),
    id_dest_inst        NUMBER(24),
    flg_status          VARCHAR2(30 CHAR),
    nurse_intake_status VARCHAR2(4000 CHAR),
    oris_status         VARCHAR2(4000 CHAR),
    admiss_status       VARCHAR2(4000 CHAR),
    adm_type            VARCHAR2(30 CHAR),
    adm_status          VARCHAR2(4000 CHAR),
    inst_adm_name       VARCHAR2(4000 CHAR),
    id_inst_adm         NUMBER(24),
    adm_type_icon       VARCHAR2(200 CHAR),
    id_discharge        NUMBER(24),
    flg_epis_status     VARCHAR2(30 CHAR),
    id_schedule         NUMBER(24), --
    id_adm_request      NUMBER(24),
    dt_admission_tsz    TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_prof_req         NUMBER(24),
    id_dest_prof        NUMBER(24),
    schedule_flg_status VARCHAR2(200 CHAR),
    id_dep_clin_serv    NUMBER(24),
    flg_cancel          VARCHAR2(1 CHAR), --
    dt_discharge        TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_department       NUMBER(24),
    desc_dpt            VARCHAR2(4000 CHAR),
    discharge_type      VARCHAR2(4000 CHAR)
)
;
/
-- CHANGE END: Luís Maia

-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 25/11/2014
-- CHANGE REASON: [ALERT-301549] Surgical Episodes - Edit info POS/ Cancel Surgery request when POS appointment is scheduled - An error occurs
DROP TYPE t_tbl_ar_episodes;

CREATE OR REPLACE TYPE t_rec_ar_episodes AS OBJECT
(
    rank                NUMBER(24),
    desc_admission      VARCHAR2(4000 CHAR),
    waiting_list_type   VARCHAR2(30 CHAR),
    id_waiting_list     NUMBER(24),
    adm_needed          VARCHAR2(30 CHAR),
    sur_needed          VARCHAR2(30 CHAR),
    admiss_epis_done    VARCHAR2(30 CHAR),
    dt_admission        VARCHAR2(4000 CHAR),
    duration            VARCHAR2(4000 CHAR),
    id_episode          NUMBER(24),
    id_dest_inst        NUMBER(24),
    flg_status          VARCHAR2(30 CHAR),
    nurse_intake_status VARCHAR2(4000 CHAR),
    oris_status         VARCHAR2(4000 CHAR),
    admiss_status       VARCHAR2(4000 CHAR),
    adm_type            VARCHAR2(30 CHAR),
    adm_status          VARCHAR2(4000 CHAR),
    inst_adm_name       VARCHAR2(4000 CHAR),
    id_inst_adm         NUMBER(24),
    adm_type_icon       VARCHAR2(200 CHAR),
    id_discharge        NUMBER(24),
    flg_epis_status     VARCHAR2(30 CHAR),
    id_schedule         NUMBER(24), --
    id_adm_request      NUMBER(24),
    dt_admission_tsz    TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_req         NUMBER(24),
    id_dest_prof        NUMBER(24),
    schedule_flg_status VARCHAR2(200 CHAR),
    id_dep_clin_serv    NUMBER(24),
    flg_cancel          VARCHAR2(1 CHAR), --
    dt_discharge        TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_department       NUMBER(24),
    desc_dpt            VARCHAR2(4000 CHAR),
    discharge_type      VARCHAR2(4000 CHAR),
    flg_request_edit    VARCHAR2(1 CHAR)
);

CREATE OR REPLACE type t_tbl_ar_episodes IS TABLE OF t_rec_ar_episodes;
/
-- Vanessa Barsottelli


-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 01/03/2016 14:57
-- CHANGE REASON: [ALERT-319114] 
CREATE OR REPLACE TYPE t_rec_ar_episodes AS OBJECT
(
    rank                NUMBER(24),
    desc_admission      VARCHAR2(4000 CHAR),
    waiting_list_type   VARCHAR2(30 CHAR),
    id_waiting_list     NUMBER(24),
    adm_needed          VARCHAR2(30 CHAR),
    sur_needed          VARCHAR2(30 CHAR),
    admiss_epis_done    VARCHAR2(30 CHAR),
    dt_admission        VARCHAR2(4000 CHAR),
    duration            VARCHAR2(4000 CHAR),
    id_episode          NUMBER(24),
    id_dest_inst        NUMBER(24),
    flg_status          VARCHAR2(30 CHAR),
    nurse_intake_status VARCHAR2(4000 CHAR),
    oris_status         VARCHAR2(4000 CHAR),
    admiss_status       VARCHAR2(4000 CHAR),
    adm_type            VARCHAR2(30 CHAR),
    adm_status          VARCHAR2(4000 CHAR),
    inst_adm_name       VARCHAR2(4000 CHAR),
    id_inst_adm         NUMBER(24),
    adm_type_icon       VARCHAR2(200 CHAR),
    id_discharge        NUMBER(24),
    flg_epis_status     VARCHAR2(30 CHAR),
    id_schedule         NUMBER(24), --
    id_adm_request      NUMBER(24),
    dt_admission_tsz    TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_prof_req         NUMBER(24),
    id_dest_prof        NUMBER(24),
    schedule_flg_status VARCHAR2(200 CHAR),
    id_dep_clin_serv    NUMBER(24),
    flg_cancel          VARCHAR2(1 CHAR), --
    dt_discharge        TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_department       NUMBER(24),
    desc_dpt            VARCHAR2(4000 CHAR),
    discharge_type      VARCHAR2(4000 CHAR),
    flg_request_edit    VARCHAR2(1 CHAR),
    id_prev_episode     NUMBER(24)
);
-- CHANGE END: Paulo Teixeira