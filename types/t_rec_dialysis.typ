CREATE OR REPLACE TYPE t_rec_dialysis force AS OBJECT
(
    id_institution        NUMBER(24),
    institution_name      VARCHAR2(200 CHAR),
    patient_file_number   VARCHAR2(200 CHAR),
    id_episode            NUMBER(24),
    start_time            VARCHAR2(200 CHAR),
    end_time              VARCHAR2(200 CHAR),
    dialysis_type         VARCHAR2(200 CHAR),
    code_dialysis         VARCHAR(200 CHAR),
    dialysis_section      VARCHAR2(200 CHAR),
    discharge_info        VARCHAR2(1000 CHAR),
    code_discharge_status VARCHAR2(200 CHAR),
    dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update        VARCHAR2(200 CHAR)
);
/
