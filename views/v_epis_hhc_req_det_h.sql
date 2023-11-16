create or replace view v_epis_hhc_req_det_h as
select
ID_EPIS_HHC_REQ_DET
,id_prof_creation
,DT_CREATION
,ID_EPIS_HHC_REQ
,ID_HHC_DET_TYPE
,HHC_VALUE
,HHC_TEXT
,ID_GROUP
from EPIS_HHC_REQ_DET_H;
