create or replace view v_inpgrid_transfer as
select
'S' FLG_TRF_TYPE
,epr.dt_request_tstz  dt_transfer_init
,dpt.abbreviation
,ei.id_bed
,bd.rank  bed_rank
,ro.code_abbreviation
,bd.code_bed
,dpt.code_department
,ro.code_room
,dpt.rank dep_rank
,bd.desc_bed
,ro.desc_room
,epi.dt_begin_tstz  dt_admission
,ei.dt_first_obs_tstz
,nvl(dch.dt_med_tstz, dch.dt_admin_tstz) dt_med_tstz
,dch.dt_pend_tstz dt_pend_tstz
,epi.flg_status flg_status_e
,ei.flg_status  flg_status_ei
,pat.gender
,epi.id_clinical_service
,dcs.id_department
,epi.id_episode
,ei.id_first_nurse_resp
,vis.id_patient
,ei.id_professional
,vis.id_visit
,pat.identity_code
,ro.rank    room_rank
,epi.flg_ehr
,epi.id_prev_episode
,vis.id_institution
,epi.id_epis_type
,ro.desc_room_abbreviation
FROM episode           epi
join visit         vis  on vis.id_visit = epi.id_visit
join patient           pat  on pat.id_patient = vis.id_patient
join epis_info         ei   on ei.id_episode = epi.id_episode
join epis_prof_resp    epr  on  epr.id_episode  = epi.id_episode
join clinical_service  cso  on cso.id_clinical_service = epr.id_clinical_service_orig-- REQUESTING CLINICAL SERVICE
join dep_clin_serv     dcs  on dcs.id_dep_clin_serv = ei.id_dep_clin_serv
left join bed          bd on bd.id_bed = ei.id_bed
LEFT JOIN room         ro ON bd.id_room = ro.id_room
left join department   dpt  ON ro.id_department = dpt.id_department
LEFT JOIN discharge    dch  ON (dch.id_episode = epi.id_episode AND dch.flg_status IN ('A', 'P') and dch.dt_admin_tstz is null)
--join department        dpg        on epr.id_department_orig = dpg.id_department             -- REQUESTING SERVICE
--join professional      prg        on epr.id_prof_req = prg.id_professional                  -- REQUESTING PROFESSIONAL
--left join professional prt        on epr.id_prof_comp = prt.id_professional                 -- RECEIVING  PROFESSIONAL
--left join    department       dpt on epr.id_department_dest = dpt.id_department             -- RECEIVING  SERVICE
--left join    clinical_service csd on epr.id_clinical_service_dest = csd.id_clinical_service -- RECEIVING CLINICAL SERVICE
--left join    room roo             on epr.id_room = roo.id_room
WHERE epi.id_epis_type = 5
and vis.id_institution = alert_context('i_id_institution')
AND epi.flg_ehr = 'N'
and epi.flg_status != 'C'
AND epr.flg_transf_type = 'S'
and epr.flg_status != 'C'
/*
union
select
'S' FLG_TRF_TYPE
,epi.id_episode
,epi.id_patient
,epr.dt_request_tstz
FROM episode           epi
join epis_prof_resp    epr  on  epi.id_episode = epr.id_episode
join bed                    on epr.id_bed = bed.id_bed
--join department        dpg        on epr.id_department_orig = dpg.id_department             -- REQUESTING SERVICE
--join clinical_service  cso        on epr.id_clinical_service_orig = cso.id_clinical_service -- REQUESTING CLINICAL SERVICE
--join professional      prg        on epr.id_prof_req = prg.id_professional                  -- REQUESTING PROFESSIONAL
--left join professional prt        on epr.id_prof_to = prt.id_professional                   -- RECEIVING  PROFESSIONAL
--left join    department dpt on epr.id_department_dest = dpt.id_department      -- RECEIVING  SERVICE
--left join    clinical_service csd on epr.id_clinical_service_dest = csd.id_clinical_service -- RECEIVING CLINICAL SERVICE
--left join    room roo on epr.id_room = roo.id_room
WHERE epi.id_epis_type = 5
AND epi.flg_ehr = 'N'
AND epr.flg_transf_type = 'S'
and epr.flg_status != 'C'
*/
;
