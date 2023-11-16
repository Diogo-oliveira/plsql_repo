begin
  pk_versioning.drop_types( table_varchar('t_TBL_data_emergency', 't_rec_data_emergency') );
end;
/


CREATE OR REPLACE TYPE t_rec_data_emergency force AS OBJECT
(
    id_institution           NUMBER,
    institution              VARCHAR2(4000),
    id_episode               NUMBER,
    complaint                VARCHAR2(4000),
    dt_discharge_tstz        TIMESTAMP WITH LOCAL TIME ZONE,
    dt_discharge             VARCHAR2(4000),
    dt_examination_tstz      TIMESTAMP WITH LOCAL TIME ZONE,
    dt_examination           VARCHAR2(4000),
    dt_triage_tstz           TIMESTAMP WITH LOCAL TIME ZONE,
    dt_triage                VARCHAR2(4000),
    dt_visit_tstz            TIMESTAMP WITH LOCAL TIME ZONE,
    dt_visit                 VARCHAR2(4000),
    arrival_method_code      NUMBER,
    arrival_method           VARCHAR2(4000),
    id_discharge_destination NUMBER,
    discharge_destination    VARCHAR2(4000),
    discharge_status_code    VARCHAR2(0050 CHAR),
    discharge_status         VARCHAR2(4000),
    smoker                   VARCHAR2(4000),
    triage_level             VARCHAR2(4000),
    arrival_status           VARCHAR2(4000),
    initial_diagnosis        VARCHAR2(4000),
    final_diagnosis          VARCHAR2(4000),
    secondary_diagnosis      VARCHAR2(4000),
    pain_level_scale_first   VARCHAR2(4000),
    pain_level_scale_last    VARCHAR2(4000),
    treatment_physician_code VARCHAR2(4000),
    treatment_physician      VARCHAR2(4000),
    discharge_physician_code VARCHAR2(4000),
    discharge_physician      VARCHAR2(4000),
    patient_file_number      VARCHAR2(4000),
    major_incident           VARCHAR2(4000),
    dt_last_update_tstz      TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update           VARCHAR2(200 CHAR)
)
;
/

CREATE OR REPLACE TYPE t_tbl_data_emergency AS TABLE OF t_rec_data_emergency;
/

grant execute on t_tbl_data_emergency to alert_data_access;
grant execute on t_tbl_data_emergency to alert_data_access_external;
