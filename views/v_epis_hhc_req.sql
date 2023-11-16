--
create or replace view v_epis_hhc_req as
select
ID_EPIS_HHC_REQ
, ID_PATIENT
,ID_EPISODE
,ID_PROF_MANAGER
,DT_PROF_MANAGER
,FLG_STATUS
,ID_CANCEL_REASON
,CANCEL_NOTES
, id_epis_hhc
, id_prof_coordinator
from epis_hhc_Req;
