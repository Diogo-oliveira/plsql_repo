CREATE OR REPLACE VIEW v_pat_crit_inactive_clin AS
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
       p.nick_name nick_name, 
       sp.flg_state,
			 sp.flg_type,
       sd.rank,
			 sd.img_name,
       epis.dt_begin_tstz,
			 drt.id_discharge_dest,
			 drt.id_institution id_institution_drt,
			 drt.id_dep_clin_serv,
			 inst.code_institution,
			 dep.code_department,
			 cs2.code_clinical_service code_clinical_service2,
			 ddn.code_discharge_dest,
			 gt.drug_presc,
			 gt.intervention
  FROM schedule_outp sp, 
                    schedule s, 
                    sch_group sg, 
                    patient pat, 
                    clinical_service cs, 
                    professional p, 
                    clin_record cr, 
                    pat_soc_attributes psa, 
                    epis_info ei,
                    discharge d, 
                    disch_reas_dest drt,
                    dep_clin_serv dcs1, 
                    department dep1, 
                    clinical_service cs1, 
                    episode epis, 
                    discharge_reason drn, 
                    discharge_dest ddn, 
                    dep_clin_serv dcs2, 
                    department dep, 
                    clinical_service cs2, 
                    institution inst,
                    epis_ext_sys ees, 
                    sys_domain sd, 
                    grid_task gt,
 (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value id_epis_type
          FROM TABLE(pk_episode.get_epis_type_access(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'), sys_context('ALERT_CONTEXT', 'i_prof_institution'), sys_context('ALERT_CONTEXT', 'i_prof_software')),'Y')) t) eta 
 WHERE sp.dt_target_tstz <= sys_context('ALERT_CONTEXT', 'l_date')
                AND s.id_schedule = sp.id_schedule 
                AND s.id_instit_requested = sys_context('ALERT_CONTEXT', 'i_prof_institution') 
                AND s.flg_status != 'C' 
                AND ei.sch_prof_outp_id_prof = p.id_professional(+)    
                AND cr.flg_status = 'A'         
                AND sg.id_schedule = s.id_schedule 
                AND pat.id_patient = sg.id_patient 
                AND psa.id_patient(+) = pat.id_patient 
                AND psa.id_institution(+) = sys_context('ALERT_CONTEXT', 'i_prof_institution') 
                AND cs.id_clinical_service = epis.id_cs_requested 
                AND cr.id_patient = pat.id_patient 
                AND cr.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') 
                AND ei.id_schedule = s.id_schedule 
                AND epis.flg_status NOT IN ('A', 'C') 
                AND d.id_episode(+) = epis.id_episode 
                AND d.dt_cancel_tstz(+) IS NULL 
                AND drt.id_disch_reas_dest(+) = d.id_disch_reas_dest 
                AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv 
                AND cs1.id_clinical_service(+) = dcs1.id_clinical_service 
                AND dep1.id_department(+) = dcs1.id_department 
                AND epis.id_episode = ei.id_episode 
                AND gt.id_episode(+) = epis.id_episode 
                AND drn.id_discharge_reason(+) = drt.id_discharge_reason 
                AND ddn.id_discharge_dest(+) = drt.id_discharge_dest 
                AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv 
                AND dep.id_department(+) = dcs2.id_department 
                AND cs2.id_clinical_service(+) = dcs2.id_clinical_service
                AND inst.id_institution(+) = drt.id_institution 
                AND ees.id_episode(+) = epis.id_episode 
                and ees.id_institution(+) = sys_context('ALERT_CONTEXT', 'i_prof_institution') 
						   AND ees.id_external_sys(+) = sys_context('ALERT_CONTEXT', 'id_ext_sys') 
                 AND epis.flg_ehr = 'N' 
                AND eta.id_epis_type IN (0, epis.id_epis_type) 
                AND sd.code_domain = decode(epis.id_epis_type, sys_context('ALERT_CONTEXT', 'id_nurse_et'), 'SCHEDULE_OUTP.FLG_NURSE_ACTION', 'SCHEDULE_OUTP.FLG_SCHED')
                AND sd.val = decode(epis.id_epis_type, sys_context('ALERT_CONTEXT', 'id_nurse_et'), 'N', sp.flg_sched)
                AND sd.id_language = sys_context('ALERT_CONTEXT', 'i_lang');
/
