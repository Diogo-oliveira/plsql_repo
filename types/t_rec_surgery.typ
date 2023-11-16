CREATE OR REPLACE TYPE t_rec_surgery force AS OBJECT
(
    id_institution      NUMBER(24),
    institution_name    VARCHAR2(200 CHAR),
    patient_file_number VARCHAR2(200 CHAR),
    id_episode          NUMBER(24),
    id_epis_type        NUMBER(24),
    desc_epis_type      VARCHAR2(200 CHAR),
    requisition_date    VARCHAR2(200 CHAR),
    start_date          VARCHAR2(200 CHAR),
    end_date            VARCHAR2(200 CHAR),
    desc_surgery        VARCHAR2(2000 CHAR),
    code_surgery        VARCHAR2(200 CHAR),
    desc_room           VARCHAR2(200 CHAR),
    id_room             NUMBER(24),
    priority            VARCHAR2(200 CHAR),
    code_priority       VARCHAR2(200 CHAR),
    anesthesia          VARCHAR2(4000 CHAR),
    code_anesthesia     VARCHAR2(4000),
    initial_diagnosis   VARCHAR2(4000),
    secondary_diagnosis VARCHAR2(4000),
    final_diagnosis     VARCHAR2(4000),
    dt_last_update_tstz TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update      VARCHAR2(200 CHAR)
)
;
/
