CREATE OR REPLACE VIEW V_AT_EPIS_INACTIVE AS
SELECT (SELECT COUNT(epis2.id_episode) counter
          FROM episode epis2
         WHERE epis2.flg_ehr = 'N'
           AND epis2.flg_status IN ('I', 'P')
           AND epis2.id_patient = epis.id_patient
           AND epis2.id_epis_type = 23
         GROUP BY epis2.id_patient) counter,
       pat.id_patient,
       pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                               profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                            sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_prof_software')),
                               pat.id_patient,
                               epis.id_episode) name_pat,
       pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       epis.id_patient,
                                       epis.id_episode) name_pat_to_sort,
       pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       pat.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                          alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                             sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                          pat.id_patient) pat_nd_icon,
       pat.dt_birth,
       epis.id_episode,
       epis.id_prev_episode,
       ei.id_software id_software,
       epis.id_institution id_institution,
       cr.num_clin_record,
       epis.dt_begin_tstz,
       epis.barcode,
       (SELECT name
          FROM professional p
         WHERE p.id_professional = nvl(ei.id_professional, o.id_prof_questioned)) name_prof,
       ei.dt_admin_tstz,
       o.id_opinion
  FROM episode epis
 INNER JOIN patient pat
    ON epis.id_patient = pat.id_patient
 INNER JOIN epis_type et
    ON et.id_epis_type = epis.id_epis_type
 INNER JOIN clin_record cr
    ON cr.id_patient = epis.id_patient
   AND cr.id_institution = epis.id_institution
 INNER JOIN epis_info ei
    ON ei.id_episode = epis.id_episode
 INNER JOIN (SELECT column_value id_institution
               FROM TABLE(pk_list.tf_get_all_inst_group(sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_inst_grp_flg_relation')))) tbl_inst_grp
    ON tbl_inst_grp.id_institution = epis.id_institution
  LEFT JOIN opinion o
    ON o.id_episode_answer = epis.id_episode
 WHERE epis.id_epis_type = sys_context('ALERT_CONTEXT', 'id_epis_type')
      /* AND epis.flg_ehr = 'N'*/
   AND epis.flg_status = 'I';