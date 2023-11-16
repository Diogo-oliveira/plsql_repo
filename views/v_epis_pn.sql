CREATE OR REPLACE VIEW v_epis_pn AS
SELECT pn.id_prof_create id_professional,
       i.id_institution,
       pn.id_episode,
       pn.id_epis_pn,
       pn.dt_pn_date,
       pk_message.get_message(il.id_language,
                              profissional(pn.id_prof_create, i.id_institution, pn.id_software),
                              n.code_pn_note_type) pn_note_description,
id_cancel_reason,	
notes_cancel,
pn.id_pn_note_type,
pn.dt_create,
pn.dt_signoff,
pn.update_time					  
  FROM epis_pn pn
 INNER JOIN pn_note_type n
    ON n.id_pn_note_type = pn.id_pn_note_type
 INNER JOIN episode e
    ON e.id_episode = pn.id_episode
 INNER JOIN institution i
    ON i.id_institution = e.id_institution
 INNER JOIN institution_language il
    ON il.id_institution = i.id_institution;
