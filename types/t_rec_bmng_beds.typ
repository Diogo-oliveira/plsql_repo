begin
  pk_versioning.drop_types( table_varchar('t_table_bmng_beds', 't_rec_bmng_beds') );
end;
/

CREATE OR REPLACE TYPE t_rec_bmng_beds force AS OBJECT
(
    id_institution      NUMBER(24),
    institution_name    VARCHAR2(200 CHAR),
    id_bed              NUMBER(24),
    bed_name            VARCHAR2(200 CHAR),
    date_begin_tstz     TIMESTAMP WITH LOCAL TIME ZONE,
    date_begin          VARCHAR2(200 CHAR),
    date_end_tstz       TIMESTAMP WITH LOCAL TIME ZONE,
    date_end            VARCHAR2(200 CHAR),
    room_type           VARCHAR2(200 CHAR),
    ward_code           VARCHAR2(200 CHAR),
    ward                VARCHAR2(4000),
    patient_file_number VARCHAR2(200 CHAR),
    room_code           VARCHAR2(200 CHAR),
    room                VARCHAR2(200 CHAR),
    bed_code            VARCHAR2(200 CHAR),
    bed_status          VARCHAR2(200 CHAR),
    bed_type            VARCHAR2(4000),
    bed_type_desc       VARCHAR2(4000),
    dt_last_update_tstz TIMESTAMP WITH LOCAL TIME ZONE,
    dt_last_update      VARCHAR2(200 CHAR)
);
/


CREATE OR REPLACE TYPE t_table_bmng_beds AS TABLE OF t_rec_bmng_beds;

grant execute on t_table_bmng_beds to alert_data_access;
