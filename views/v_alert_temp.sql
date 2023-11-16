
create or replace view v_alert_temp as 
select
 sat.ID_SYS_ALERT_DET
,pat.name
,sat.ID_REG
,sat.ID_EPISODE
,sat.ID_INSTITUTION
,sat.ID_PROF
,sat.DT_REQ
,pk_date_utils.get_string_tstz
            (i_lang => alert_context('i_lang'),
            i_prof      => profissional( alert_context('i_prof'), alert_context('i_institution'), alert_context('i_software') ),
            i_timestamp => sat.dt_req,
            i_timezone  => NULL) dt_req_tstz
,sat.TIME
,sat.TIME
,sat.MESSAGE
,sat.ID_ROOM
,sat.ID_PATIENT
,sat.NAME_PAT
,sat.PHOTO
,sat.GENDER
,sat.PAT_AGE
,sat.DESC_ROOM
,sat.DATE_SEND
,sat.DESC_EPIS_ANAMNESIS
,sat.ACUITY
,sat.RANK_ACUITY
,sat.ID_SCHEDULE
,sat.ID_SYS_SHORTCUT
,sat.ID_REG_DET
,sat.ID_SYS_ALERT
,sat.DT_FIRST_OBS_TSTZ
,sat.FLG_DETAIL
,sat.ID_SOFTWARE_ORIGIN
,sat.PAT_NDO
,sat.PAT_ND_ICON
,sat.FAST_TRACK_ICON
,sat.FAST_TRACK_COLOR
,sat.FAST_TRACK_STATUS
,sat.ESI_LEVEL
,sat.NAME_PAT_SORT
,sat.RESP_ICONS
,sat.ID_PROF_ORDER
,sa.id_sys_alert_type
from sys_alert_temp sat
join sys_alert sa on sa.id_sys_alert = sat.id_sys_alert
join patient pat on pat.id_patient = sat.id_patient
;