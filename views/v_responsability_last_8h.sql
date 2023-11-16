CREATE OR REPLACE VIEW v_responsability_last_8h AS
SELECT id_episode,
       ext_episode,
       name,
       pk_adt.get_emergency_contact(language_id, profissional(0, id_institution, 0), id_patient) contato_urgencia,
       companion contato_acompanhante,
       (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id, profissional(id_prof_prev, id_institution, 0))
          FROM dual) num_mecan_previous, -- da primeira responsabilidade
       (SELECT pk_prof_utils.get_name(language_id, id_prof_prev)
          FROM dual) profissional_name_previous,
       (SELECT pk_prof_utils.get_prof_speciality(language_id, profissional(id_prof_prev, id_institution, 0))
          FROM dual) profissional_spec_previous,
       (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id, profissional(id_prof_to, id_institution, 0))
          FROM dual) num_mecan_last, -- da ultima responsabilidade
       (SELECT pk_prof_utils.get_name(language_id, id_prof_to)
          FROM dual) profissional_name_last,
       (SELECT pk_prof_utils.get_prof_speciality(language_id, profissional(id_prof_to, id_institution, 0))
          FROM dual) profissional_spec_last,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_comp_tstz, profissional(0, id_institution, 0))
          FROM dual) dt_responsability
  FROM (SELECT e.id_episode,
               ees.value ext_episode,
               p.name,
               p.id_patient,
               e.id_institution,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               e.companion,
               epr.id_prof_to,
               epr.dt_comp_tstz,
               epr.id_prof_prev
          FROM episode e
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          JOIN epis_prof_resp epr
            ON epr.id_episode = e.id_episode
           AND epr.flg_status = 'F'
           AND epr.flg_type = 'D'
           AND epr.dt_comp_tstz > current_timestamp - numtodsinterval(8, 'HOUR')
          LEFT OUTER JOIN epis_ext_sys ees
            ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND ees.id_epis_type = 2)
         WHERE e.flg_status = 'A');
