CREATE OR REPLACE TYPE t_rec_laboratory force AS OBJECT
(
    id_institution        NUMBER(24),
    institution_name      VARCHAR2(500 CHAR),
    patient_file_number   VARCHAR2(50 CHAR),
    id_episode            NUMBER(24),
    id_epis_type          NUMBER(24),
    desc_epis_type        VARCHAR2(200 CHAR),
    lab_test_description  VARCHAR2(200 CHAR),
    collection_date       VARCHAR2(200 CHAR),
    receiving_date        VARCHAR2(200 CHAR),
    request_date          VARCHAR2(200 CHAR),
    result_date           VARCHAR2(200 CHAR),
    to_be_performed_date  VARCHAR2(200 CHAR),
    flg_priority          VARCHAR2(200 CHAR),
    priority              VARCHAR2(200 CHAR),
    flg_time_harvest      VARCHAR2(200 CHAR),
    desc_flg_time_harvest VARCHAR2(200 CHAR),
    RESULT                VARCHAR2(4000 CHAR),
    result_code           VARCHAR2(4000),
    lab_section           VARCHAR2(200 CHAR),
    requested_from        VARCHAR2(200 CHAR),
    dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update        VARCHAR2(200 CHAR)
)
;
/
