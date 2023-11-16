create or replace view v_ds_event_target as
select
 DET.ID_DS_EVENT_TARGET
,DET.ID_DS_EVENT
,DET.ID_DS_CMPT_MKT_REL
,DET.FLG_EVENT_TYPE
,DET.FIELD_MASK
,'DS_EVENT_TARGET_VALIDATION_TEXT.'||to_char(ID_DS_EVENT_TARGET)  code_validation_message
from alert.DS_EVENT_TARGET DET
;






