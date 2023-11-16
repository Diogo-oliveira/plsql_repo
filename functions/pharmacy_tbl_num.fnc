create or replace function pharmacy_tbl_num (i_num number) return table_number
aggregate using aggr_pharm_num_to_tblnum;
/
