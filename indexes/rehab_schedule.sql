declare
	l_sql varchar2(1000 char);
begin
	l_sql := q'[create index alert.rsc_search01_idx on alert.REHAB_SCHEDULE(ID_REHAB_SCH_NEED,FLG_STATUS) tablespace alert_idx]';
	pk_versioning.run(l_sql);
end;
/
