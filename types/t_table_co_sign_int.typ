-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 07/11/2016 
-- CHANGE REASON: [ALERT-325833] [REDUC] - Get TODO_LIST_COUNT slow
begin
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_table_co_sign_int AS TABLE OF t_rec_co_sign_int]');
end;
/ 
