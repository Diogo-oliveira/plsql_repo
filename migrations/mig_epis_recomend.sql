-- CHANGED BY: José Silva
-- CHANGE DATE: 14/10/2010 12:19
-- CHANGE REASON: [ALERT-117834] 
DECLARE
    l_count NUMBER;
BEGIN

    SELECT COUNT(*)
      INTO l_count
      FROM epis_documentation ed
     WHERE ed.id_doc_area = 6710;

    IF l_count = 0
    THEN
        INSERT INTO epis_documentation
            (id_epis_documentation,
             id_episode,
 id_episode_context,
             id_professional,
             id_prof_last_update,
             flg_status,
             id_doc_area,
             dt_creation_tstz,
             dt_last_update_tstz,
             flg_edition_type,
             notes)
            SELECT seq_epis_documentation.NEXTVAL,
                   er.id_episode,
 er.id_episode,
                   er.id_professional,
                   er.id_professional,
                   decode(er.flg_temp, 'H', 'O', 'A'),
                   6710,
                   er.dt_epis_recomend_tstz,
                   er.dt_epis_recomend_tstz,
                   'N',
                   er.desc_epis_recomend
              FROM epis_recomend er
WHERE er.flg_type = 'D';
    END IF;
END;
/
-- CHANGE END: José Silva

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 13/10/2011 11:38
-- CHANGE REASON: [ALERT-176957] 
BEGIN
    UPDATE epis_recomend er
       SET er.flg_status = 'A'
     WHERE er.flg_type = 'N'
       AND er.flg_status IS NULL;
END;
/
-- CHANGE END: Alexandre Santos
