-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 22/04/2015 
-- CHANGE REASON: [ALERT-310274] 
BEGIN
   pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_table_co_sign_cfg IS TABLE OF t_rec_co_sign_cfg]');
END;
/
