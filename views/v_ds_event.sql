create or replace view v_ds_event as
select
 de.ID_DS_EVENT
,de.ID_DS_CMPT_MKT_REL
,de.VALUE
,de.FLG_TYPE
,coalesce( de.id_action, pk_dyn_form_constant.get_default_action()  ) ID_ACTION
from ds_Event de;
