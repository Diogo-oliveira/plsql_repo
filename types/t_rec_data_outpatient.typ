begin
  pk_versioning.drop_types( table_varchar('t_tbl_data_outpatient', 't_rec_data_outpatient') );
end;
/  

CREATE OR REPLACE TYPE t_rec_data_outpatient AS OBJECT
(
    id_institution        NUMBER(24),
    institution_name      VARCHAR2(200 CHAR),
  id_episode        number,
    complaint             CLOB,
    professional          VARCHAR2(4000),
    dt_discharge_tstz     TIMESTAMP WITH LOCAL TIME ZONE,
    dt_discharge          VARCHAR2(4000),
    dt_examination_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    dt_examination        VARCHAR2(4000),
    dt_visit_tstz         TIMESTAMP WITH LOCAL TIME ZONE,
    dt_visit              VARCHAR2(4000),
    appointment_type      NUMBER,
    appointment_type_desc VARCHAR2(4000),
    id_discharge_destination number,
    discharge_destination VARCHAR2(4000),
    smoker                VARCHAR2(4000),
    discharge_status      VARCHAR2(4000),
    discharge_status_desc VARCHAR2(4000),
    final_diagnosis       VARCHAR2(4000),
    initial_diagnosis     VARCHAR2(4000),
    secondary_diagnosis     VARCHAR2(4000),
    clinical_service      VARCHAR2(4000),
  treatment_physician_code VARCHAR2(4000),
  treatment_physician      VARCHAR2(4000),
  discharge_physician_code VARCHAR2(4000),
  discharge_physician      VARCHAR2(4000),
    patient_file_number   VARCHAR2(4000),
    dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update        VARCHAR2(200 CHAR)
)
;
/

CREATE OR REPLACE TYPE t_tbl_data_outpatient AS TABLE OF t_rec_data_outpatient;
/

grant execute on alert.t_tbl_data_outpatient to alert_data_access;