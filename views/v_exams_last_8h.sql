CREATE OR REPLACE VIEW v_exams_last_8h AS
SELECT id_episode,
       ext_episode,
       name,
       pk_adt.get_emergency_contact(language_id, profissional(0, id_institution, 0), id_patient) contato_urgencia,
       companion contato_acompanhante,
       (SELECT pk_exams_api_db.get_alias_translation(language_id,
                                                     profissional(0, id_institution, 0),
                                                     'EXAM.CODE_EXAM.' || id_exam,
                                                     NULL)
          FROM dual) exam_name,
       (SELECT pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_STATUS', flg_status_det, language_id)
          FROM dual) AS status,
       (SELECT pk_sysdomain.get_domain('EXAM.FLG_TYPE', flg_type, language_id)
          FROM dual) AS examtype,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_last_status, profissional(0, id_institution, 0))
          FROM dual) dt_last_status
  FROM (SELECT e.id_episode,
               ees.value ext_episode,
               p.name,
               p.id_patient,
               e.id_institution,
               ea.id_exam,
               ea.flg_status_det,
               ea.flg_type,
               coalesce(ea.dt_result, ea.dt_pend_req, ea.start_time, ea.dt_req) dt_last_status,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               e.companion
          FROM episode e
          JOIN exams_ea ea
            ON e.id_episode = ea.id_episode
           AND ea.dt_req > current_timestamp - numtodsinterval(8, 'HOUR')
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT OUTER JOIN epis_ext_sys ees
            ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND ees.id_epis_type = 2)
         WHERE e.flg_status = 'A')
UNION ALL
SELECT id_episode,
       ext_episode,
       name,
       pk_adt.get_emergency_contact(language_id, profissional(0, id_institution, 0), id_patient) contato_urgencia,
       companion contato_acompanhante,
       
       pk_lab_tests_utils.get_alias_translation(language_id,
                                                profissional(0, id_institution, 0),
                                                'A',
                                                'ANALYSIS.CODE_ANALYSIS.' || id_analysis,
                                                'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || id_sample_type,
                                                NULL) exam_name,
       (SELECT pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_STATUS', flg_status_det, language_id)
          FROM dual) AS status,
       'Análise' AS examtype,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_last_status, profissional(0, id_institution, 0))
          FROM dual) dt_last_status
  FROM (SELECT e.id_episode,
               ees.value ext_episode,
               p.name,
               p.id_patient,
               e.id_institution,
               lea.id_analysis,
               lea.id_sample_type,
               lea.flg_status_det,
               coalesce(lea.dt_analysis_result, lea.dt_harvest, lea.dt_pend_req, lea.dt_req) dt_last_status,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               e.companion
          FROM episode e
          JOIN lab_tests_ea lea
            ON e.id_episode = lea.id_episode
           AND lea.dt_req > current_timestamp - numtodsinterval(8, 'HOUR')
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT OUTER JOIN epis_ext_sys ees
            ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND ees.id_epis_type = 2)
         WHERE e.flg_status = 'A');
