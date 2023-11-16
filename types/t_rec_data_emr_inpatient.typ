CREATE OR REPLACE TYPE t_rec_data_emr_inpatient force AS OBJECT
(
    id_institution           NUMBER,
    id_software              NUMBER,
    id_episode               NUMBER,
    id_prev_episode          NUMBER,
    id_prof_discharge        NUMBER,
    dt_epis_dt_begin_tstz    TIMESTAMP WITH LOCAL TIME ZONE,
    dt_vis_dt_begin_tstz     TIMESTAMP WITH LOCAL TIME ZONE,
    dt_discharge             TIMESTAMP WITH LOCAL TIME ZONE,
    dt_discharge_pend        TIMESTAMP WITH LOCAL TIME ZONE,
    dt_discharge_adm         TIMESTAMP WITH LOCAL TIME ZONE,
    dis_flg_status       varchar2(0010 char),
    id_discharge_destination NUMBER,
    id_habit                 NUMBER,
    id_patient               NUMBER,
    id_first_dep_clin_serv   NUMBER,
    id_room                  NUMBER,
    code_room                VARCHAR2(4000),
    id_bed                   NUMBER,
    code_bed                 VARCHAR2(4000),
    dt_last_update_tstz      TIMESTAMP WITH LOCAL TIME ZONE,
    flg_ehr                  VARCHAR2(1 CHAR)
);
/

