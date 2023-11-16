CREATE OR REPLACE TYPE t_rec_blood_product force AS OBJECT
(   id_institution      NUMBER(24),
    institution_name    VARCHAR2(200 CHAR),
    patient_file_number VARCHAR2(200 CHAR),
    id_episode          NUMBER(24),
    blood_component     VARCHAR2(200 CHAR),
    expiration_date     VARCHAR2(200 CHAR),
    blood_group         VARCHAR2(200 CHAR),
    dt_last_update_tstz TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update      VARCHAR2(200 CHAR)
)
;
/
