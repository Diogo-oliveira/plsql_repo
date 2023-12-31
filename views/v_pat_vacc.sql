create or replace view V_PAT_VACC AS
select ID_VACC, 
FLG_AVAILABLE, 
ID_PATIENT, 
DT_PAT_VACC, 
ID_PROFESSIONAL, 
DT_LAST_CHANGE, 
ID_EPISODE, 
FLG_STATUS, 
ID_PROF_STATUS, 
DT_STATUS,
NOTES,
pv.id_reason ID_REASON_SUS
from pat_vacc pv;
