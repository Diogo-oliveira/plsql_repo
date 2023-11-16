CREATE OR REPLACE TYPE t_rec_data_outpatient_base force AS OBJECT
(
    id_institution          NUMBER,
    code_institution        VARCHAR2(4000),
    so_flg_state            varchar2(0050 char),
    flg_sched               varchar2(0050 char),
    flg_ehr                 varchar2(0050 char),
    id_epis_type            number,
    dis_flg_status          varchar2(0050 char),
    dis_dt_pend_tstz        TIMESTAMP WITH LOCAL TIME ZONE,
    dis_flg_type            varchar2(0050 char),
    flg_contact_type        varchar2(0050 char),
    id_patient              NUMBER,
    id_episode              NUMBER,
    patient_complaint       VARCHAR2(4000),
    code_complaint          VARCHAR2(4000),
    ei_id_professional      NUMBER,
    ps_id_professional      NUMBER,
    id_prof_discharge       number,
    dt_discharge            TIMESTAMP WITH LOCAL TIME ZONE,
    dt_examinat             TIMESTAMP WITH LOCAL TIME ZONE,
    dt_visit                TIMESTAMP WITH LOCAL TIME ZONE,
    appointment_type        NUMBER,
    appointment_type_code   VARCHAR2(4000),
    discharge_destination   VARCHAR2(4000),
    discharge_status        VARCHAR2(4000),
    clinical_service        NUMBER,
    dt_first_obs            TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update_tstz     TIMESTAMP WITH LOCAL TIME ZONE
);
/


/
CREATE OR REPLACE TYPE t_tbl_data_outpatient_base AS TABLE OF t_rec_data_outpatient_base;
/