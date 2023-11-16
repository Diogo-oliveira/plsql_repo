BEGIN
    pk_versioning.drop_types(table_varchar('t_tbl_data_inpatient', 't_rec_data_inpatient'));
END;
/
CREATE OR REPLACE TYPE t_rec_data_inpatient FORCE AS OBJECT
(
    id_institution           NUMBER,
    institution              VARCHAR2(4000),
    id_episode               NUMBER,
    complaint                CLOB,
    treatment_physician_code VARCHAR2(4000),
    treatment_physician      VARCHAR2(4000),
    discharge_physician_code VARCHAR2(4000),
    discharge_physician      VARCHAR2(4000),
    dt_admission_tstz        TIMESTAMP WITH LOCAL TIME ZONE,
    dt_admission             VARCHAR2(4000),
    dt_admission_req_tstz    TIMESTAMP WITH LOCAL TIME ZONE,
    dt_admission_req         VARCHAR2(4000),
    dt_discharge_tstz        TIMESTAMP WITH LOCAL TIME ZONE,
    dt_discharge             VARCHAR2(4000),
    id_discharge_destination NUMBER,
    discharge_destination    VARCHAR2(4000),
    smoker                   VARCHAR2(4000),
    origin                   VARCHAR2(4000),
    admission_ward_code      VARCHAR2(4000),
    admission_ward           VARCHAR2(4000),
    final_diagnosis          VARCHAR2(4000),
    initial_diagnosis        VARCHAR2(4000),
    secondary_diagnosis      VARCHAR2(4000),
    patient_file_number      VARCHAR2(4000),
    room_code                VARCHAR2(4000),
    room                     VARCHAR2(4000),
    bed_code                 VARCHAR2(4000),
    bed                      VARCHAR2(4000),
    major_incident           VARCHAR2(4000),
    dt_last_update_tstz      TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update           VARCHAR2(200 CHAR),
    flg_ehr                  VARCHAR2(1 CHAR)
)
;
/

CREATE TYPE t_tbl_data_inpatient AS TABLE OF t_rec_data_inpatient;
/
grant execute on t_tbl_data_inpatient to alert_data_access;
grant execute on t_tbl_data_inpatient to alert_data_access_external;
