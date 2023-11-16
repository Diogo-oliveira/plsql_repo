begin
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_table_co_sign AS TABLE OF t_rec_co_sign]');
end;
/ 
