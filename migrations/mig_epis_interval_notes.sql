-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 08/11/2010 14:35
-- CHANGE REASON: [ALERT-138460] Editable areas: Make prioritary areas editable: Progress Notes (EDIS)
DECLARE
    l_count NUMBER;
BEGIN

    SELECT COUNT(*)
      INTO l_count
      FROM epis_documentation ed
     WHERE ed.id_doc_area IN (1092, 6724, 6725);

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
                   ein.id_episode,
                   ein.id_episode id_episode_context,
                   ein.id_professional,
                   ein.id_professional id_prof_last_update,
                   'A' flg_status,
                   decode(coalesce(
                                   /*prof's category  in episode's institution */
 (SELECT cat.flg_type
                                      FROM prof_cat prc
                                     INNER JOIN category cat ON cat.id_category = prc.id_category
                                     INNER JOIN professional prf ON prf.id_professional = prc.id_professional
                                     WHERE prc.id_professional = ein.id_professional
                                       AND prc.id_institution = e.id_institution),
                                   /* No prof's category found for episode's institution, we use Physician category as default */
                                   'D'),
                          'D',
                          1092,
                          'N',
                          6724,
                          'T',
                          6725,
                          1092) id_doc_area,
                   nvl(ein.dt_creation_tstz, ein.adw_last_update) dt_creation_tstz,
                   ein.adw_last_update dt_last_update_tstz,
                   'N' flg_edition_type,
                   ein.desc_interval_notes
              FROM epis_interval_notes ein
             INNER JOIN episode e ON ein.id_episode = e.id_episode;
    END IF;
END;
/
-- CHANGE END: Ariel Machado