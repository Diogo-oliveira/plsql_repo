CREATE OR REPLACE TYPE t_rec_stg_ext_prof AS OBJECT(
id_professional NUMBER(24),  
name VARCHAR2(800 CHAR),
zip_code VARCHAR2(200 CHAR),
city VARCHAR2(800 CHAR),
flg_exist VARCHAR2(1 CHAR)
);
/
