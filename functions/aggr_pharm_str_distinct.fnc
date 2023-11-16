
create or replace function "PHARMACY_AGGR_STR_DISTINCT" (i_str varchar2) return table_varchar
aggregate using aggr_pharm_str_distinct;
/
