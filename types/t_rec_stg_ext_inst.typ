CREATE OR REPLACE TYPE t_rec_stg_ext_inst AS OBJECT(
id_institution NUMBER(24), 
institution_name VARCHAR2(4000 CHAR),
flg_type VARCHAR2(4 CHAR), 
zip_code VARCHAR2(200 CHAR),
city VARCHAR2(800 CHAR),
flg_exist VARCHAR2(1 CHAR)
);
/
