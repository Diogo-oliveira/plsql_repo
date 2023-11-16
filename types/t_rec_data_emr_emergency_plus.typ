CREATE OR REPLACE TYPE t_rec_data_emr_emergency_plus force AS OBJECT
(
    id_institution  NUMBER,
    id_patient      NUMBER,
    id_episode      NUMBER,
    id_next_episode NUMBER,
    flg_status      VARCHAR2(4000),
  desc_flg_status VARCHAR2(4000),
    dt_discharge    TIMESTAMP WITH LOCAL TIME ZONE,
--***************************
    dis_flg_status   VARCHAR2(4000),
  desc_dis_flg_status VARCHAR2(4000),
    dis_flg_type     VARCHAR2(4000),
  desc_dis_flg_type VARCHAR2(4000),
    dis_dt_pend_tstz TIMESTAMP WITH LOCAL TIME ZONE,
    dis_dt_admin_tstz TIMESTAMP WITH LOCAL TIME ZONE,
--***************************
    dt_examination          TIMESTAMP WITH LOCAL TIME ZONE,
    dt_triage               TIMESTAMP WITH LOCAL TIME ZONE,
    dt_visit                TIMESTAMP WITH LOCAL TIME ZONE,
    arrival_method          VARCHAR2(4000),
    discharge_destination   VARCHAR2(4000),
    discharge_status        VARCHAR2(4000),
  desc_discharge_status VARCHAR2(4000),
    id_prof_discharge       NUMBER,
    id_habit                NUMBER,
    id_epis_triage          NUMBER,
    code_triage_color       VARCHAR2(4000),
  desc_triage_color       VARCHAR2(4000),
    flg_type                VARCHAR2(4000),
  desc_flg_type           VARCHAR2(4000),
    code_accuity            VARCHAR2(4000),
  desc_accuity      VARCHAR2(4000),
    id_triage_type          NUMBER,
    id_triage_color         NUMBER,
    id_software             NUMBER,
    patient_complaint       VARCHAR2(4000),
    code_complaint          VARCHAR2(4000),
  desc_complaint       varchar2(4000),
    dt_complaint            TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update_tstz     TIMESTAMP WITH LOCAL TIME ZONE
);
/

