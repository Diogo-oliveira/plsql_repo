CREATE OR REPLACE TYPE t_rec_ext_prof AS OBJECT(
id_professional NUMBER(24),  
name VARCHAR2(800 CHAR),
zip_code VARCHAR2(200 CHAR),
city VARCHAR2(800 CHAR),
flg_status VARCHAR2(1 CHAR),
take_over_time TIMESTAMP(6) WITH LOCAL TIME ZONE,
id_professional_from NUMBER(24),
id_professional_to NUMBER(24),
notes VARCHAR2(4000 CHAR),
dn_flg_status VARCHAR2(1 CHAR)
);
/
