create or replace view v_ds_def_event as
select
 ID_DEF_EVENT
,ID_DS_CMPT_MKT_REL
,FLG_EVENT_TYPE
,ID_ACTION
,FLG_DEFAULT
from  DS_DEF_EVENT;
