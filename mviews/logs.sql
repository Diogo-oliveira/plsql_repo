
create materialized view log on EPISODE with rowid;
create materialized view log on EPIS_INFO with rowid;
create materialized view log on EPIS_TASK with rowid;
create materialized view log on EPIS_TYPE with rowid;
create materialized view log on GRID_TASK with rowid;
create materialized view log on VISIT with rowid;

--Tabelas removidas das views de episódios
drop materialized view log on EPIS_TASK;
drop materialized view log on GRID_TASK;
