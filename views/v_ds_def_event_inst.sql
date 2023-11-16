create or replace view v_ds_def_event_inst as
select
	 ID_DEF_EVENT_INST
	,ID_DS_CMPT_INST_REL
	,ID_DS_CMPT_MKT_REL
	,FLG_EVENT_TYPE
	,ID_ACTION
from DS_DEF_EVENT_INST;
