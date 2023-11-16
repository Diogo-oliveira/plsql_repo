CREATE OR REPLACE TYPE t_rec_inst_common AS OBJECT
(
    id_institution NUMBER(24),
    inst_name      VARCHAR2(1000 CHAR),
    inst_type      VARCHAR2(600 CHAR),
    inst_acronym   VARCHAR2(100 CHAR),
    adress         VARCHAR2(1000 CHAR),
    postal_code    VARCHAR2(200 CHAR),
    city           VARCHAR2(800 CHAR),
    phone_number VARCHAR2(200 CHAR),
    fax_number   VARCHAR2(200 CHAR),
    country_name VARCHAR2(1000 CHAR),
    e_mail       VARCHAR2(400 CHAR),
    inst_fields  t_table_inst_fields
)
;
