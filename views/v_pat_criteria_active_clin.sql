CREATE OR REPLACE VIEW V_PAT_CRITERIA_ACTIVE_CLIN AS
SELECT v.triage_acuity acuity,
       v.triage_color_text color_text,
       v.triage_rank_acuity rank_acuity,
       cr.num_clin_record,
       v.id_episode,
       v.id_clinical_service,
       v.dt_begin_tstz_e dt_begin_tstz,
       v.flg_status_e flg_status_epis,
       v.id_fast_track,
       v.id_patient,
       v.id_visit,
       v.id_institution,
       v.id_epis_type,
       v.id_software,
       v.barcode_e barcode,
       pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                               alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                  sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_prof_software')),
                               v.id_patient,
                               v.id_episode) name_pat,
       pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                               alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                  sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_prof_software')),
                               v.id_patient,
                               v.id_episode,
                               NULL) name_pat_sort,
       pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       v.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                          alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                             sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                          v.id_patient) pat_nd_icon,
       pat.gender,
       pat.age,
       pat.dt_birth,
       pat.dt_birth_hijri,
       pat.dt_deceased,
       (SELECT nvl(nick_name, name)
          FROM professional
         WHERE id_professional = v.id_professional) name_prof,
       (SELECT nvl(nick_name, name)
          FROM professional
         WHERE id_professional = v.id_first_nurse_resp) name_nurse,
       (SELECT id_speciality
          FROM professional
         WHERE id_professional = v.id_professional) prof_spec,
       (SELECT id_speciality
          FROM professional
         WHERE id_professional = v.id_first_nurse_resp) nurse_spec,
       v.id_professional,
       v.id_first_nurse_resp,
       v.dt_first_obs_tstz,
       v.flg_status_ei flg_status_ei,
       v.id_room,
       v.id_department,
       g.id_grid_task,
       g.drug_presc,
       g.nurse_activity,
       g.intervention,
       g.monitorization,
       g.movement,
       g.drug_transp,
       g.discharge_pend,
       v.id_triage_color,
       v.has_transfer,
       g.oth_exam_d,
       g.oth_exam_n,
       g.img_exam_d,
       g.img_exam_n,
       g.analysis_d,
       g.analysis_n,
			 g.hemo_req
  FROM v_episode_act v, patient pat, clin_record cr, grid_task g
 WHERE g.id_episode(+) = v.id_episode
   AND v.flg_status_e = sys_context('ALERT_CONTEXT', 'g_epis_active')
   AND v.flg_ehr = 'N'
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND (EXISTS
        (SELECT 0, id_software
           FROM institution i
          WHERE v.id_institution = i.id_institution
            AND v.id_software = decode(sys_context('ALERT_CONTEXT', 'i_prof_software'),
                                       sys_context('ALERT_CONTEXT', 'g_soft_triage'),
                                       decode(i.flg_type,
                                              sys_context('ALERT_CONTEXT', 'g_inst_type_h'),
                                              sys_context('ALERT_CONTEXT', 'g_soft_edis'),
                                              sys_context('ALERT_CONTEXT', 'g_soft_ubu')),
                                       sys_context('ALERT_CONTEXT', 'i_prof_software'))) OR
        (v.id_software = sys_context('ALERT_CONTEXT', 'g_soft_inp') AND
        sys_context('ALERT_CONTEXT', 'l_prof_cat') = 'O' AND sys_context('ALERT_CONTEXT', 'l_show_inp_epis') = 'Y' AND
        EXISTS
         (SELECT 1
            FROM episode e
           WHERE e.id_visit = v.id_visit
             AND e.id_episode = v.id_prev_episode
             AND pk_episode.get_soft_by_epis_type(e.id_epis_type, sys_context('ALERT_CONTEXT', 'i_prof_institution')) =
                 sys_context('ALERT_CONTEXT', 'i_prof_software')
             AND e.flg_ehr = 'N')))
   AND v.id_patient = pat.id_patient
   AND cr.id_institution(+) = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND cr.id_patient(+) = v.id_patient
   AND cr.flg_status(+) = 'A';
/
