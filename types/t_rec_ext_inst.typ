CREATE OR REPLACE TYPE t_rec_ext_inst AS OBJECT(
id_institution NUMBER(24), 
institution_name VARCHAR2(4000 CHAR),
flg_type VARCHAR2(4 CHAR), 
zip_code VARCHAR2(200 CHAR),
city VARCHAR2(800 CHAR),
country NUMBER(12),
dn_flg_status VARCHAR2(1 CHAR),
flg_editable VARCHAR2(1 CHAR)
);
/
