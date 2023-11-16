
create or replace function pharmacy_tbl_states (i_state_id number) return table_number
aggregate using aggr_pharm_id_state;
/
