-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/Oct/2013 
-- CHANGE REASON: Nurse - Single Page documentation (INP)

DECLARE

    l_id_doc_area epis_documentation.id_doc_area%TYPE := 6724;

    CURSOR c_get_records IS
        SELECT er.id_epis_recomend,
               er.id_professional,
               nvl(er.dt_epis_recomend_tstz, e.dt_begin_tstz) dt_epis_recomend_tstz,
               er.id_episode,
               nvl(il.id_language, 2) id_language,
               ei.id_software,
               e.id_institution,
               ei.id_dep_clin_serv,
               er.desc_epis_recomend_clob,
               nvl(er.flg_status, 'A') flg_status
          FROM epis_recomend er
         INNER JOIN episode e
            ON e.id_episode = er.id_episode
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
          LEFT OUTER JOIN institution_language il
            ON i.id_institution = il.id_institution
         WHERE er.flg_type = 'N'
         AND er.id_notes_config = 0
         AND (er.flg_status IS NULL OR er.flg_status = 'A')
         AND er.desc_epis_recomend_clob IS NOT NULL;

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records   c_cursor_type;
    l_limit         PLS_INTEGER := 1000;
    l_records_count PLS_INTEGER;

    l_id_epis_pn     epis_pn.id_epis_pn%TYPE;
    l_date           VARCHAR2(1000 CHAR);
    l_id_institution institution.id_institution%TYPE;
    l_id_software    software.id_software%TYPE;
    l_id_language    language.id_language%TYPE;
    l_prof           profissional;
    l_error          t_error_out;

    l_id_epis_pn_det      epis_pn_det.id_epis_pn_det%TYPE;
    l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
    l_id_epis_pn_signoff  epis_pn_signoff.id_epis_pn_signoff%TYPE;
    l_rows_out            table_varchar;
    l_id_task             NUMBER;

BEGIN
    OPEN c_get_records;
    LOOP
    
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        l_records_count := l_get_records.count;
        FOR i IN 1 .. l_records_count
        LOOP
        
            l_id_institution := l_get_records(i).id_institution;
            l_id_software    := l_get_records(i).id_software;
            l_id_language    := l_get_records(i).id_language;
            l_prof           := profissional(l_get_records(i).id_professional, l_id_institution, l_id_software);
        
            l_id_epis_pn := NULL;
        
            l_id_task := l_get_records(i).id_epis_recomend;
        
            --check if the record were already inserted in the single page
            BEGIN
                SELECT epn.id_epis_pn
                  INTO l_id_epis_pn
                  FROM epis_pn_det_task epdt
                  JOIN epis_pn_det epd
                    ON epdt.id_epis_pn_det = epd.id_epis_pn_det
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = epd.id_epis_pn
                 WHERE epn.id_episode = l_get_records(i).id_episode
                   AND epn.flg_status = 'M'
                   AND epn.id_pn_note_type = 20
                   AND epd.id_pn_data_block = 92
                   AND epdt.id_task = l_get_records(i).id_epis_recomend
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;        
                    
            IF (l_id_epis_pn IS NULL)
            THEN
            
                BEGIN
                    IF (l_id_epis_pn IS NULL)
                    THEN
                        l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => l_id_language,
                                                                     i_date => l_get_records(i).dt_epis_recomend_tstz,
                                                                     i_prof => l_prof);
                    
                        IF (l_date IS NULL AND l_get_records(i).dt_epis_recomend_tstz IS NOT NULL)
                        THEN
                            l_date := to_char(l_get_records(i).dt_epis_recomend_tstz, 'YYYYMMDDHH24MISS');
                        END IF;
                    
                        SELECT seq_epis_pn.nextval
                          INTO l_id_epis_pn
                          FROM dual;
                    
                        IF (l_get_records(i).id_software IS NULL)
                        THEN
                            SELECT etsi.id_software
                              INTO l_get_records(i).id_software
                              FROM episode e
                              JOIN epis_type_soft_inst etsi
                                ON e.id_epis_type = etsi.id_epis_type
                             WHERE e.id_episode = l_get_records(i).id_episode
                               AND rownum = 1;
                        END IF;
                    
                        INSERT INTO epis_pn
                            (id_epis_pn,
                             id_episode,
                             flg_status,
                             dt_pn_date,
                             id_prof_create,
                             dt_create,
                             id_dep_clin_serv,
                             id_dictation_report,
                             id_prof_signoff,
                             dt_signoff,
                             id_pn_note_type,
                             id_pn_area,
                             id_software)
                        VALUES
                            (l_id_epis_pn,
                             l_get_records(i).id_episode,
                             'M',
                             l_get_records(i).dt_epis_recomend_tstz,
                             l_prof.id,
                             l_get_records(i).dt_epis_recomend_tstz,
                             l_get_records(i).id_dep_clin_serv,
                             NULL,
                             l_prof.id,
                             l_get_records(i).dt_epis_recomend_tstz,
                             20,
                             7,
                             l_get_records(i).id_software)
                        RETURNING ROWID BULK COLLECT INTO l_rows_out;
                    
                        t_data_gov_mnt.process_insert(i_lang       => l_id_language,
                                                      i_prof       => l_prof,
                                                      i_table_name => 'EPIS_PN',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        SELECT seq_epis_pn_det.nextval
                          INTO l_id_epis_pn_det
                          FROM dual;
                    
                        INSERT INTO epis_pn_det
                            (id_epis_pn_det,
                             id_epis_pn,
                             id_professional,
                             dt_pn,
                             id_pn_data_block,
                             id_pn_soap_block,
                             flg_status,
                             pn_note,
                             dt_note)
                        VALUES
                            (l_id_epis_pn_det,
                             l_id_epis_pn,
                             l_prof.id,
                             l_get_records(i).dt_epis_recomend_tstz,
                             92,
                             17,
                             'A',
                             NULL,
                             l_get_records(i).dt_epis_recomend_tstz)
                        RETURNING ROWID BULK COLLECT INTO l_rows_out;
                    
                        t_data_gov_mnt.process_insert(i_lang       => l_id_language,
                                                      i_prof       => l_prof,
                                                      i_table_name => 'EPIS_PN_DET',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
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
                             id_prof_last_update,
                             flg_table_origin)
                        VALUES
                            (l_id_epis_pn_det_task,
                             l_id_epis_pn_det,
                             l_get_records(i).id_epis_recomend,
                             13,
                             'A',
                             l_get_records(i).desc_epis_recomend_clob,
                             l_get_records(i).dt_epis_recomend_tstz,
                             l_prof.id,
                             'D')
                        RETURNING ROWID BULK COLLECT INTO l_rows_out;
                    
                        t_data_gov_mnt.process_insert(i_lang       => l_id_language,
                                                      i_prof       => l_prof,
                                                      i_table_name => 'EPIS_PN_DET_TASK',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        SELECT seq_epis_pn_det.nextval
                          INTO l_id_epis_pn_det
                          FROM dual;
                    
                        INSERT INTO epis_pn_det
                            (id_epis_pn_det,
                             id_epis_pn,
                             id_professional,
                             dt_pn,
                             id_pn_data_block,
                             id_pn_soap_block,
                             flg_status,
                             pn_note,
                             dt_note)
                        VALUES
                            (l_id_epis_pn_det,
                             l_id_epis_pn,
                             l_prof.id,
                             l_get_records(i).dt_epis_recomend_tstz,
                             47,
                             6,
                             'A',
                             l_date,
                             l_get_records(i).dt_epis_recomend_tstz)
                        RETURNING ROWID BULK COLLECT INTO l_rows_out;
                    
                        t_data_gov_mnt.process_insert(i_lang       => l_id_language,
                                                      i_prof       => l_prof,
                                                      i_table_name => 'EPIS_PN_DET',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => l_error);
                    
                        SELECT seq_epis_pn_signoff.nextval
                          INTO l_id_epis_pn_signoff
                          FROM dual;
                    
                        INSERT INTO epis_pn_signoff
                            (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
                        VALUES
                            (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).desc_epis_recomend_clob); 
                    
                        SELECT seq_epis_pn_signoff.nextval
                          INTO l_id_epis_pn_signoff
                          FROM dual;
                        INSERT INTO epis_pn_signoff
                            (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
                        VALUES
                            (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
                    END IF;
                    
                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        dbms_output.put_line('mig_inp_nurse_notes l_id_epis_pn: ' || l_id_epis_pn ||
                                             ' id_epis_recommend: ' || l_id_task || '  ERROR: ' || SQLERRM);
                END;
            
            END IF;
            l_id_epis_pn := NULL;
        END LOOP;
    
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('mig_inp_nurse_notes l_id_epis_pn: ' || l_id_epis_pn || chr(13) || 'id_epis_recommend: ' ||
                             l_id_task || SQLERRM);        
END;
/
-- CHANGE END: Sofia.Mendes
