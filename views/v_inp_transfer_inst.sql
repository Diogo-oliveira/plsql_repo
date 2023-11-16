CREATE OR REPLACE VIEW V_INP_TRANSFER_INST AS
select
'I' FLG_TRF_TYPE
,ti.dt_creation_tstz dt_transfer_init
,dpto.abbreviation
,epo.id_bed
,bd.rank   bed_rank
,ro.code_abbreviation
,bd.code_bed
,dpto.code_department
,ro.code_room
,dpto.rank  dep_rank
,bd.desc_bed
,ro.desc_room
,epi.dt_begin_tstz  dt_admission
,epo.dt_first_obs_tstz
,nvl(d.dt_med_tstz, d.dt_admin_tstz) dt_med_tstz
,d.dt_pend_tstz dt_pend_tstz
,epi.flg_status  flg_status_e
,epo.flg_status  flg_status_ei
,pat.gender
,epi.id_clinical_service
,dcs.id_department
,epi.id_episode
,epo.id_first_nurse_resp
,vis.id_patient
,epo.id_professional
,vis.id_visit
,pat.identity_code
,ro.rank    room_rank
,epi.flg_ehr
,epi.id_prev_episode
,vis.id_institution
,epi.id_epis_type
,ro.desc_room_abbreviation
-------
FROM transfer_institution ti
JOIN episode epi         ON ti.id_episode = epi.id_episode
join visit vis           on vis.id_visit = epi.id_visit
JOIN patient pat         ON pat.id_patient = vis.id_patient
JOIN epis_info epo       ON epi.id_episode = epo.id_episode
LEFT JOIN bed bd         ON epo.id_bed = bd.id_bed
LEFT JOIN room ro        ON bd.id_room = ro.id_room
JOIN department dpt      ON epi.id_department = dpt.id_department
--**
left join department dpto ON ro.id_department = dpto.id_department
JOIN dep_clin_serv   dcs ON epo.id_dep_clin_serv = dcs.id_dep_clin_serv
--**
LEFT JOIN clinical_service cli ON epi.id_clinical_service = cli.id_clinical_service
LEFT JOIN (
    SELECT flg_status, dt_med_tstz, dt_pend_tstz, dt_admin_tstz, id_episode
    FROM discharge
    WHERE flg_status IN ('A','P')
    ) d ON epi.id_episode = d.id_episode
----
WHERE epi.id_epis_type = 5
AND instr(dpt.flg_type, 'I') > 0
AND (epi.flg_ehr = 'N')
AND epi.flg_status IN ('A')
AND epi.dt_begin_tstz < pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(
                                profissional(
                                      alert_context('i_id_prof'),
                                      alert_context('i_id_institution'),
                                      alert_context('i_id_software')
                                      )
                                , current_timestamp
                                , NULL
                                ),1)
AND ti.id_dep_clin_serv IN (
    SELECT
    dcs1.id_dep_clin_serv
    FROM prof_dep_clin_serv pdc1
    JOIN dep_clin_serv dcs1   ON pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
    JOIN department dpt     ON dpt.id_department = dcs1.id_department
    WHERE pdc1.flg_status = 'S'
    AND dpt.id_institution = alert_context('i_id_institution')
    AND instr(dpt.flg_type, 'I') > 0
    --AND instr(dpt.flg_type, 'O') < 1
    AND pdc1.id_professional = alert_context('i_id_prof')
    )
AND (ti.id_institution_dest = alert_context('i_id_institution') AND ti.flg_status = 'T')
;
