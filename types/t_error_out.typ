CREATE OR REPLACE TYPE "T_ERROR_OUT" AS OBJECT(ora_sqlcode VARCHAR2(0200), ora_sqlerrm VARCHAR2(4000), err_desc VARCHAR2(4000), err_action VARCHAR2(4000), log_id VARCHAR2(0100), err_instance_id_out NUMBER(24), msg_title VARCHAR2(200 CHAR), flg_msg_type VARCHAR2(1 CHAR));
/
