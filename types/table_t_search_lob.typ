DECLARE
l_sql varchar2(1000 char);
BEGIN
l_sql := 'drop type table_t_search_lob';
pk_versioning.run(l_sql);
end;
/
