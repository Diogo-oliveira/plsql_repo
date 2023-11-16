create or replace function pharmacy_top_one_num (i_num number) return number
aggregate using aggr_pharm_n_to_top_one;
/
