
declare
mview_already_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_already_exists, -12003);
begin
execute immediate 'drop materialized view MV_EPISODE_ACT_PEND_1';
exception
when mview_already_exists then null;
end;
/

declare
mview_already_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_already_exists, -12003);
begin
execute immediate 'drop materialized view MV_EPISODE_ACT_PEND_2';
exception
when mview_already_exists then null;
end;
/

declare
mview_already_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_already_exists, -12003);
begin
execute immediate 'drop materialized view log on visit';
exception
when mview_already_exists then null;
end;
/

declare
mview_already_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_already_exists, -12003);
begin
execute immediate 'drop materialized view log on epis_type';
exception
when mview_already_exists then null;
end;
/

declare
mview_already_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_already_exists, -12003);
begin
execute immediate 'drop materialized view log on episode';
exception
when mview_already_exists then null;
end;
/

declare
mview_already_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(mview_already_exists, -12003);
begin
execute immediate 'drop materialized view log on epis_info';
exception
when mview_already_exists then null;
end;
/
