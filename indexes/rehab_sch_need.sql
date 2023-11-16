declare
	l_sql varchar2(1000 char);
begin
	l_sql := q'[create index alert.rsnd_search01_idx on alert.REHAB_SCH_NEED(ID_REHAB_SESSION_TYPE) tablespace alert_idx]';
	pk_versioning.run(l_sql);
end;
/
