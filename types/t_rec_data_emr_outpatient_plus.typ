CREATE OR REPLACE TYPE t_rec_data_emr_outpatient_plus force AS OBJECT
(
    id_institution        NUMBER,
    code_institution      VARCHAR2(4000),
    desc_institution      VARCHAR2(4000),
    so_flg_state          VARCHAR2(0050 CHAR),
    desc_so_flg_state     VARCHAR2(4000),
    img_state             VARCHAR2(4000),
    flg_sched             VARCHAR2(0050 CHAR),
    desc_flg_sched        VARCHAR2(4000),
    flg_ehr               VARCHAR2(0050 CHAR),
    desc_flg_ehr          VARCHAR2(4000),
    id_epis_type          NUMBER,
    dis_flg_status        VARCHAR2(0050 CHAR),
    desc_dis_flg_status   VARCHAR2(4000),
    dis_dt_pend_tstz      TIMESTAMP WITH LOCAL TIME ZONE,
    dis_flg_type          VARCHAR2(0050 CHAR),
    desc_dis_flg_type     VARCHAR2(4000),
    flg_contact_type      VARCHAR2(0050 CHAR),
    desc_contact_type     VARCHAR2(4000),
    id_patient            NUMBER,
    id_episode            NUMBER,
    patient_complaint     VARCHAR2(4000),
    code_complaint        VARCHAR2(4000),
    desc_complaint        VARCHAR2(4000),
    ei_id_professional    NUMBER,
    ps_id_professional    NUMBER,
    id_prof_discharge     NUMBER,
    dt_discharge          TIMESTAMP WITH LOCAL TIME ZONE,
    dt_examinat           TIMESTAMP WITH LOCAL TIME ZONE,
    dt_visit              TIMESTAMP WITH LOCAL TIME ZONE,
    appointment_type      NUMBER,
    appointment_type_code VARCHAR2(4000),
	desc_appointment_type VARCHAR2(4000),
    discharge_destination VARCHAR2(4000),
    discharge_status      VARCHAR2(4000),
    clinical_service      NUMBER,
    desc_contact          VARCHAR2(4000),
    dt_first_obs          TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE
)
;

CREATE OR REPLACE TYPE t_tbl_data_emr_outpatient_plus AS TABLE OF t_rec_data_emr_outpatient_plus;
