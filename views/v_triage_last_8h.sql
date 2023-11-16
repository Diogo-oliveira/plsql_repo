CREATE OR REPLACE VIEW v_triage_last_8h AS
SELECT id_episode,
       ext_episode,
       name,
       pk_adt.get_emergency_contact(language_id, profissional(0, id_institution, 0), id_patient) contato_urgencia,
       companion contato_acompanhante,
       (SELECT pk_translation.get_translation(language_id, 'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || id_triage_color)
          FROM dual) AS triage_color,
       (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id, profissional(professional_triage, id_institution, 0))
          FROM dual) num_mecan_triage,
       (SELECT pk_prof_utils.get_name(language_id, professional_triage)
          FROM dual) profissional_name,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_triage_begin, profissional(0, id_institution, 0))
          FROM dual) dt_triage_begin,
       (SELECT pk_translation.get_translation(language_id, 'ORIGIN.CODE_ORIGIN.' || id_origin)
          FROM dual) desc_origin
  FROM (SELECT e.id_episode,
               ees.value ext_episode,
               p.name,
               p.id_patient,
               e.id_institution,
               et.id_professional professional_triage,
               et.id_triage_color,
               et.dt_begin_tstz dt_triage_begin,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               v.id_origin,
               e.companion
          FROM episode e
          JOIN epis_triage et
            ON e.id_episode = et.id_episode
           AND et.dt_begin_tstz > current_timestamp - numtodsinterval(8, 'HOUR')
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN visit v
            ON e.id_visit = v.id_visit
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT OUTER JOIN epis_ext_sys ees
            ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND ees.id_epis_type = 2)
         WHERE e.flg_status = 'A');
