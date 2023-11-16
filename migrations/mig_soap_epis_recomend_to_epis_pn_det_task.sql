DECLARE
    CURSOR c_get_records IS
        SELECT nvl(il.id_language, 2) id_language,
               ep.id_prof_create id_professional,
               e.id_institution,
               nvl(ei.id_software,
                   (SELECT etsi.id_software
                      FROM episode e
                      JOIN epis_type_soft_inst etsi
                        ON e.id_epis_type = etsi.id_epis_type
                     WHERE e.id_episode = e.id_episode
                       AND rownum = 1)) id_software,
               CASE
                    WHEN epd.id_pn_soap_block = 2
                         AND epd.id_pn_data_block = 87 THEN
                     'S'
                    WHEN epd.id_pn_soap_block = 3
                         AND epd.id_pn_data_block = 88 THEN
                     'B'
                    WHEN epd.id_pn_soap_block = 4
                         AND epd.id_pn_data_block = 89 THEN
                     'A'
                    WHEN epd.id_pn_soap_block = 5
                         AND epd.id_pn_data_block = 90 THEN
                     'L'
                END flg_type,
               CASE
                    WHEN epd.id_pn_soap_block = 2
                         AND epd.id_pn_data_block = 87 THEN
                     118
                    WHEN epd.id_pn_soap_block = 3
                         AND epd.id_pn_data_block = 88 THEN
                     119
                    WHEN epd.id_pn_soap_block = 4
                         AND epd.id_pn_data_block = 89 THEN
                     120
                    WHEN epd.id_pn_soap_block = 5
                         AND epd.id_pn_data_block = 90 THEN
                     60
                END id_task_type,
               ep.id_episode,
               epd.id_epis_pn_det,
               epd.id_pn_data_block,
               epd.id_pn_soap_block,
               epd.pn_note,
               epd.dt_pn
          FROM alert.epis_pn_det epd
          JOIN alert.epis_pn ep
            ON epd.id_epis_pn = ep.id_epis_pn
           AND ep.id_pn_note_type = 32
         INNER JOIN episode e
            ON e.id_episode = ep.id_episode
         INNER JOIN epis_info ei
            ON ei.id_episode = ep.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
          LEFT OUTER JOIN institution_language il
            ON i.id_institution = il.id_institution
         WHERE epd.id_pn_data_block IN (90, 89, 88, 87)
           AND epd.id_pn_soap_block IN (5, 4, 3, 2)
           AND epd.flg_status = 'A'
           AND NOT EXISTS (SELECT 1
                  FROM alert.epis_pn_det_task epdt
                 WHERE epdt.id_epis_pn_det = epd.id_epis_pn_det);

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records         c_cursor_type;
    l_limit               PLS_INTEGER := 1000;
    l_records_count       PLS_INTEGER;
    l_id_institution      institution.id_institution%TYPE;
    l_id_software         software.id_software%TYPE;
    l_lang                language.id_language%TYPE;
    l_prof                profissional;
    l_id_episode          episode.id_episode%TYPE;
    l_flg_type            epis_recomend.flg_type%TYPE;
    l_id_epis_recomend    epis_recomend.id_epis_recomend%TYPE;
    l_error               t_error_out;
    l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
    l_exception EXCEPTION;

BEGIN

    OPEN c_get_records;
    LOOP
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        l_records_count := l_get_records.count;
        FOR i IN 1 .. l_records_count
        LOOP
            l_id_episode     := l_get_records(i).id_episode;
            l_flg_type       := l_get_records(i).flg_type;
            l_lang           := l_get_records(i).id_language;
            l_id_institution := l_get_records(i).id_institution;
            l_id_software    := l_get_records(i).id_software;
            l_prof           := profissional(l_get_records(i).id_professional, l_id_institution, l_id_software);
        
            IF NOT pk_discharge.set_epis_recomend_int(i_lang             => l_lang,
                                                      i_prof             => l_prof,
                                                      i_episode          => l_id_episode,
                                                      i_patient          => NULL,
                                                      i_flg_type         => l_flg_type,
                                                      i_desc             => l_get_records(i).pn_note,
                                                      i_parent           => NULL,
                                                      o_id_epis_recomend => l_id_epis_recomend,
                                                      o_error            => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            SELECT seq_epis_pn_det_task.nextval
              INTO l_id_epis_pn_det_task
              FROM dual;
        
            INSERT INTO epis_pn_det_task
                (id_epis_pn_det_task,
                 id_epis_pn_det,
                 id_task,
                 id_task_type,
                 flg_status,
                 pn_note,
                 dt_last_update,
                 id_prof_task,
                 dt_task)
            VALUES
                (l_id_epis_pn_det_task,
                 l_get_records(i).id_epis_pn_det,
                 l_id_epis_recomend,
                 l_get_records(i).id_task_type,
                 'A',
                 l_get_records(i).pn_note,
                 l_get_records(i).dt_pn,
                 l_prof.id,
                 l_get_records(i).dt_pn);
        
        END LOOP;
    
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

    dbms_output.put_line('Success');
EXCEPTION
    WHEN l_exception THEN
        dbms_output.put_line('ERROR pk_discharge.set_epis_recomend_int i_episode: ' || l_id_episode || ' i_flg_type: ' ||
                             l_flg_type || l_error.ora_sqlcode || ' ' || l_error.ora_sqlerrm || ' ' ||
                             l_error.err_desc || ' ' || l_error.err_action || ' ' || l_error.log_id || ' ' ||
                             l_error.err_instance_id_out);
    
    WHEN OTHERS THEN
        dbms_output.put_line('ERRROR mig_soap i_episode: ' || l_id_episode || ' i_flg_type: ' || l_flg_type || chr(13) ||
                             SQLERRM);
END;
/
