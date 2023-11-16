CREATE OR REPLACE TYPE t_rec_radiology force AS OBJECT
(
    id_institution      NUMBER(24),
    institution_name    VARCHAR2(200 CHAR),
    patient_file_number VARCHAR2(50 CHAR),
    id_episode          NUMBER(24),
    id_epis_type        NUMBER(24),
    desc_epis_type      VARCHAR2(50 CHAR),
    procedure_date      VARCHAR2(50 CHAR),
    report_date         VARCHAR2(50 CHAR),
    request_date        VARCHAR2(50 CHAR),
    begin_date          VARCHAR2(50 CHAR),
    priority            VARCHAR2(50 CHAR),
    code_priority       VARCHAR2(50 CHAR),
    flg_time            VARCHAR2(20 CHAR),
    desc_flg_time       VARCHAR2(200 CHAR),
    requested_from      VARCHAR2(200 CHAR),
    rad_service         VARCHAR2(200 CHAR),
    desc_exam           VARCHAR2(200 CHAR),
    dt_last_update_tstz TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update      VARCHAR2(200 CHAR)
)
;
/
