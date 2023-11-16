CREATE OR REPLACE VIEW v_transport_last_8h AS 
SELECT id_episode,
       ext_episode,
       name,
       pk_adt.get_emergency_contact(language_id, profissional(0, id_institution, 0), id_patient) contato_urgencia,
       companion contato_acompanhante,
       (SELECT pk_translation.get_translation(language_id, 'ROOM.CODE_ROOM.' || id_room_from)
          FROM dual) AS origin_room,
       (SELECT pk_translation.get_translation(language_id, 'ROOM.CODE_ROOM.' || id_room_to)
          FROM dual) AS dest_room,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_end_tstz, profissional(0, id_institution, 0))
          FROM dual) dt_transport
  FROM (SELECT e.id_episode,
               ees.value ext_episode,
               p.name,
               p.id_patient,
               e.id_institution,
               m.id_room_from,
               m.id_room_to,
               m.dt_end_tstz dt_end_tstz,
               (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                  FROM dual) language_id,
               e.companion
          FROM episode e
          JOIN movement m
            ON e.id_episode = m.id_episode
           AND m.dt_end_tstz > current_timestamp - numtodsinterval(8, 'HOUR')
           AND m.flg_status = 'F'
          JOIN patient p
            ON e.id_patient = p.id_patient
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT OUTER JOIN epis_ext_sys ees
            ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND ees.id_epis_type = 2)
         WHERE e.flg_status = 'A');
