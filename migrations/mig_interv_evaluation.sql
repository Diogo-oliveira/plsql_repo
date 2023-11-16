-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 18/09/2012 17:33
-- CHANGE REASON: [ALERT-240395] 
begin
INSERT INTO epis_documentation
    (id_epis_documentation,
     id_doc_area,
     flg_edition_type,
     id_episode,
     id_professional,
     id_prof_last_update,
     dt_creation_tstz,
     dt_last_update_tstz,
     flg_status,
     notes)
    SELECT seq_epis_documentation.nextval,
           5097,
           'N',--NEW
           ie.id_episode,
           ie.id_professional,
           ie.id_professional,
           ie.dt_interv_evaluation_tstz,
           ie.dt_interv_evaluation_tstz,
           ie.flg_status,
           ie.notes
      FROM interv_evaluation ie
     WHERE ie.flg_type = 'N'--NOTES
       AND ie.flg_status = 'A'--ACTIVE
       AND ie.id_episode IS NOT NULL
       AND NOT EXISTS (SELECT 1
              FROM epis_documentation ed
             WHERE ed.id_doc_area = 5097
               AND ed.id_episode = ie.id_episode
               AND ed.id_professional = ie.id_professional
               AND ed.dt_creation_tstz = ie.dt_interv_evaluation_tstz);
end;
/
               
-- CHANGE END:  Nuno Neves