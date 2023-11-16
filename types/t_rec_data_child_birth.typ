begin
  pk_versioning.drop_types( table_varchar('t_table_data_child_birth', 't_rec_data_child_birth') );
end;
/  

CREATE OR REPLACE TYPE t_rec_data_child_birth force AS OBJECT
(
    id_institution          NUMBER(24),
    institution_name        VARCHAR2(200 CHAR),
    id_episode              NUMBER,
    delivery_date_time      VARCHAR2(200 CHAR),
    delivery_date_time_tstz TIMESTAMP WITH LOCAL TIME ZONE,
    child_gender            VARCHAR2(200 CHAR),
    child_gender_desc       VARCHAR2(4000),
    child_file_number       VARCHAR2(200 CHAR),
    delivery_type_code      VARCHAR2(4000),
    delivery_type           VARCHAR2(4000),
    patient_file_number     VARCHAR2(200 CHAR),
    dt_last_update_tstz     TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update          VARCHAR2(200 CHAR)
);
/

CREATE OR REPLACE TYPE t_table_data_child_birth AS TABLE OF t_rec_data_child_birth;
/


GRANT EXECUTE ON t_table_data_child_birth TO ALERT_DATA_ACCESS;
