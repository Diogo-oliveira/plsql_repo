DECLARE
    l_tab_epis_rec table_number;
BEGIN
    SELECT e.id_epis_recomend BULK COLLECT
      INTO l_tab_epis_rec
      FROM epis_recomend e
      JOIN epis_documentation d ON d.id_episode = e.id_episode
     WHERE e.id_item IS NULL
       AND e.id_notes_config IN (6, 7, 9)
       AND e.flg_type = 'M'
       AND e.id_item IS NULL
       AND d.notes IS NOT NULL
       AND e.desc_epis_recomend = to_char(substr(notes, 1, 4000))
       AND d.id_doc_area IN (21, 22, 28)
       AND d.dt_creation_tstz BETWEEN e.dt_epis_recomend_tstz - INTERVAL '10'
     SECOND
       AND e.dt_epis_recomend_tstz + INTERVAL '10' SECOND
     GROUP BY e.id_episode, e.id_epis_recomend
    HAVING COUNT(1) = 1;

    UPDATE epis_recomend er
       SET er.id_item =
           (SELECT d.id_epis_documentation FROM epis_recomend e JOIN epis_documentation d ON d.id_episode = e.id_episode WHERE
            e.id_item IS NULL AND e.id_notes_config IN (6, 7, 9) AND e.flg_type = 'M' AND e.id_item IS NULL AND
            d.notes IS NOT NULL AND e.desc_epis_recomend = to_char(substr(notes, 1, 4000)) AND
            d.id_doc_area IN (21, 22, 28) AND d.dt_creation_tstz BETWEEN e.dt_epis_recomend_tstz - INTERVAL '10'
            SECOND AND e.dt_epis_recomend_tstz + INTERVAL '10' SECOND AND e.id_epis_recomend = er.id_epis_recomend)
     WHERE er.id_epis_recomend IN (SELECT column_value
                                     FROM TABLE(l_tab_epis_rec));

END;
/
