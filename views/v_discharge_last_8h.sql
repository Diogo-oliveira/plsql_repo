CREATE OR REPLACE VIEW v_discharge_last_8h AS
SELECT id_episode,
       ext_episode,
       name,
       pk_adt.get_emergency_contact(language_id, profissional(0, id_institution, 0), id_patient) contato_urgencia,
       companion contato_acompanhante,
       (SELECT pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS', flg_status, language_id)
          FROM dual) AS disch_type,
       (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id, profissional(id_professional, id_institution, 0))
          FROM dual) num_mecan,
       (SELECT pk_prof_utils.get_name(language_id, id_professional)
          FROM dual) profissional_name,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_discharge, profissional(0, id_institution, 0))
          FROM dual) dt_discharge,
       (SELECT pk_translation.get_translation(language_id, dr.code_discharge_reason)
          FROM discharge_reason dr
         WHERE dr.id_discharge_reason = id_reason) razao_alta
  FROM (SELECT e.id_episode,
               ees.value ext_episode,
               p.name,
               p.id_patient,
               e.id_institution,
               disch.id_prof_med id_professional,
               disch.flg_status,
               nvl(disch.dt_med_tstz, disch.dt_pend_tstz) dt_discharge,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               ei.companion,
               id_discharge_reason id_reason
          FROM episode e
          LEFT OUTER JOIN (SELECT d.*,
                                 drd.id_discharge_reason,
                                 rank() over(PARTITION BY d.id_episode ORDER BY d.dt_med_tstz DESC, d.dt_admin_tstz DESC) AS rn
                            FROM discharge d
                            JOIN disch_reas_dest drd
                              ON drd.id_disch_reas_dest = d.id_disch_reas_dest
                           WHERE d.flg_status IN ('A', 'P')) disch
            ON (disch.id_episode = e.id_episode)
           AND (disch.dt_med_tstz > current_timestamp - numtodsinterval(8, 'HOUR') OR
               disch.dt_pend_tstz > current_timestamp - numtodsinterval(8, 'HOUR'))
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT OUTER JOIN epis_ext_sys ees
            ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND ees.id_epis_type = 2)
         WHERE disch.rn = 1);
