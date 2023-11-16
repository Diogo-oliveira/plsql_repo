CREATE OR REPLACE VIEW V_DISCHARGE_NOTES AS
      SELECT dn.id_discharge_notes,
             dn.id_episode,
             dn.id_patient,
             dn.recommended,
             dn.release_from,
             dn.dt_from,
             dn.dt_until,
             dn.notes_release,
             dn.instructions_discussed,
             dn.id_pending_issue,
             dn.flg_issue_assign,
             dn.dt_creation_tstz,
             dn.id_professional,
             dn.epis_complaint,
             dn.epis_diagnosis,
             dn.epis_tests,
             dn.epis_drugs,
             dn.flg_status,
             dn.follow_up_with,
             dn.follow_up_in,
             dn.id_follow_up_type,
             dn.id_epis_report,
			 dn.discharge_instructions
        FROM discharge_notes dn
       WHERE dn.flg_status != 'C'
         AND dn.dt_creation_tstz IN (SELECT MAX(dt_creation_tstz)
                                       FROM discharge_notes dn2
                                      WHERE dn2.id_episode = dn.id_episode);
                                      
