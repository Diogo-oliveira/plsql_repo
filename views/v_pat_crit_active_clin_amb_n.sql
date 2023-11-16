 CREATE OR REPLACE VIEW v_pat_crit_active_clin_amb_n AS
      SELECT s.id_schedule,
       sg.id_patient,
       cr.num_clin_record,
       epis.id_episode,
			 epis.id_visit,
			 epis.id_institution,
			 epis.barcode,
       pat.name,
       pat.gender,
       pat.dt_birth,
       pat.age,
			 cs.id_clinical_service,
       cs.code_clinical_service cons_type,
       cs.code_clinical_service,
       sp.dt_target_tstz,
       nvl(p1.nick_name, p.nick_name) nick_name, 
       sp.flg_state,
			 sp.flg_type,
       sd.rank,
			 sd.img_name,
       epis.dt_begin_tstz,
			 spc1.code_speciality code_speciality1,
			 spc.code_speciality,
			 drt.id_discharge_dest,
			 drt.id_institution id_institution_drt,
			 drt.id_dep_clin_serv,
			 inst.code_institution,
			 dep.code_department,
			 cs2.code_clinical_service code_clinical_service2,
			 ddn.code_discharge_dest,
			 gt.drug_presc,
			 gt.intervention,
			 d.flg_payment
  FROM schedule_outp sp,
       schedule s,
       sch_group sg,
       patient pat,
       clinical_service cs,
       professional p,
       clin_record cr,
       epis_info ei,
       episode epis,
       pat_soc_attributes psa,
       speciality spc,
       discharge d,
       disch_reas_dest drt,
       institution inst,
       department dep,
       discharge_dest ddn,
       clinical_service cs2,
       dep_clin_serv dcs2,
       professional p1,
       speciality spc1,
       epis_ext_sys ees,
       sys_domain sd,
       grid_task gt,
 (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value id_epis_type
          FROM TABLE(pk_episode.get_epis_type_access(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'), sys_context('ALERT_CONTEXT', 'i_prof_institution'), sys_context('ALERT_CONTEXT', 'i_prof_software')),'Y')) t) eta 
 WHERE s.id_schedule = sp.id_schedule
   AND s.id_instit_requested = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND s.flg_status != 'C'
   AND cr.flg_status = 'A'
   AND sp.id_software = sys_context('ALERT_CONTEXT', 'i_prof_software')
   AND sp.dt_target_tstz BETWEEN pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'), sys_context('ALERT_CONTEXT', 'i_prof_institution'), sys_context('ALERT_CONTEXT', 'i_prof_software')), current_timestamp) AND
       pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'), sys_context('ALERT_CONTEXT', 'i_prof_institution'), sys_context('ALERT_CONTEXT', 'i_prof_software')), current_timestamp) + INTERVAL '1'
 DAY
   AND p.id_professional(+) = ei.sch_prof_outp_id_prof
   AND spc.id_speciality(+) = p.id_speciality
   AND sg.id_schedule = s.id_schedule
   AND pat.id_patient = sg.id_patient
   AND psa.id_patient(+) = pat.id_patient
   AND psa.id_institution(+) = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND epis.id_cs_requested = cs.id_clinical_service
   AND cr.id_patient = pat.id_patient
   AND cr.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND ei.id_schedule = s.id_schedule
   AND epis.id_episode = ei.id_episode
   AND epis.flg_status NOT IN ('I', 'C')
   AND gt.id_episode(+) = epis.id_episode
   AND p1.id_professional(+) = ei.id_professional
   AND spc1.id_speciality(+) = p1.id_speciality
   AND d.id_episode(+) = epis.id_episode
   AND d.dt_cancel_tstz(+) IS NULL
   AND d.id_prof_admin(+) IS NULL
   AND drt.id_disch_reas_dest(+) = d.id_disch_reas_dest
   AND inst.id_institution(+) = drt.id_institution
   AND dep.id_department(+) = dcs2.id_department
   AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv
   AND cs2.id_clinical_service(+) = dcs2.id_clinical_service
   AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
   AND ees.id_episode(+) = epis.id_episode
   AND ees.id_institution(+) = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND ees.id_external_sys(+) = sys_context('ALERT_CONTEXT', 'id_ext_sys')
   AND sd.code_domain = decode(epis.id_epis_type, sys_context('ALERT_CONTEXT', 'id_nurse_et'), 'SCHEDULE_OUTP.FLG_NURSE_ACTION', 'SCHEDULE_OUTP.FLG_SCHED')
   AND sd.val = decode(epis.id_epis_type, sys_context('ALERT_CONTEXT', 'id_nurse_et'), 'N', sp.flg_sched)
   AND sd.id_language = sys_context('ALERT_CONTEXT', 'i_lang')
   AND epis.flg_ehr = 'N'
   AND eta.id_epis_type IN (0, epis.id_epis_type)
	 AND EXISTS (SELECT 1 FROM PROF_DEP_CLIN_SERV PDCS WHERE PDCS.ID_PROFESSIONAL = sys_context('ALERT_CONTEXT', 'i_prof_id')
                        AND PDCS.ID_DEP_CLIN_SERV(+) = EI.ID_DEP_CLIN_SERV AND PDCS.FLG_STATUS =  'S');
/
