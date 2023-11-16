CREATE OR REPLACE TYPE t_rec_prof_common AS OBJECT
(
    id_professional   NUMBER(24),
    name              VARCHAR2(800 CHAR),
    license_number    VARCHAR2(200 CHAR),
    postal_code       VARCHAR2(200 CHAR),
    city              VARCHAR2(800 CHAR),
    gender            VARCHAR2(1 CHAR),
    dt_birth          DATE,
    street            VARCHAR2(800 CHAR),
    phone_number VARCHAR2(200 CHAR),
    e_mail       VARCHAR2(400 CHAR),
    flg_state    VARCHAR2(1 CHAR),
    prof_fields  t_table_prof_fields
)
;
