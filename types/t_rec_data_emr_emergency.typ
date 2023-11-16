CREATE OR REPLACE TYPE t_rec_data_emr_emergency force AS OBJECT
(
    id_institution  NUMBER,
    id_patient      NUMBER,
    id_episode      NUMBER,
    id_next_episode NUMBER,
    flg_status      VARCHAR2(4000),
    dt_discharge    TIMESTAMP WITH LOCAL TIME ZONE
--***************************
,
    dis_flg_status   VARCHAR2(4000),
    dis_flg_type     VARCHAR2(4000),
    dis_dt_pend_tstz TIMESTAMP WITH LOCAL TIME ZONE
--***************************
,
    dt_examination          TIMESTAMP WITH LOCAL TIME ZONE,
    dt_triage               TIMESTAMP WITH LOCAL TIME ZONE,
    dt_visit                TIMESTAMP WITH LOCAL TIME ZONE,
    arrival_method          VARCHAR2(4000),
    discharge_destination   VARCHAR2(4000),
    discharge_status        VARCHAR2(4000),
    id_prof_discharge       NUMBER,
    id_habit                NUMBER,
    id_epis_triage          NUMBER,
    code_triage_color       VARCHAR2(4000),
    flg_type                VARCHAR2(4000),
    code_accuity            VARCHAR2(4000),
    id_triage_type          NUMBER,
    id_triage_color         NUMBER,
    id_epis_triage_first    NUMBER,
    code_triage_color_first VARCHAR2(4000),
    flg_type_first          VARCHAR2(4000),
    code_accuity_first      VARCHAR2(4000),
    id_triage_type_first    NUMBER,
    id_triage_color_first   NUMBER,
    id_software             NUMBER,
    patient_complaint       VARCHAR2(4000),
    code_complaint          VARCHAR2(4000),
    dt_complaint            TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update_tstz     TIMESTAMP WITH LOCAL TIME ZONE
)
;


create or replace type t_tbl_data_emr_emergency as table of t_rec_data_emr_emergency;