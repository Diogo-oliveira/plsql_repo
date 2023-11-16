-- CHANGED BY: António Neto
-- CHANGE DATE: 25/02/2011 17:38
-- CHANGE REASON: [ALERT-164712] DDL Migrations - H & P reformulation in INPATIENT

DECLARE
    TYPE tab_complete_hist IS TABLE OF complete_history%ROWTYPE;

    l_tab_complete_hist       tab_complete_hist;
    l_tab_complete_hist_child tab_complete_hist;
    l_error                   t_error_out;
    l_id_pn_soap_block        pn_soap_block.id_pn_soap_block%TYPE := 14;
    l_id_pn_data_block        pn_data_block.id_pn_data_block%TYPE := 81;
    l_id_epis_pn              epis_pn.id_epis_pn%TYPE;
    l_dep_clin_serv           epis_info.id_dep_clin_serv%TYPE;
    l_date_cancel             epis_pn_hist.dt_epis_pn_hist%TYPE;
    l_tab_pn_soap_block       table_number := table_number();
    l_tab_pn_area_block       table_number := table_number();
    l_tab_notes               table_clob := table_clob();
    l_id_institution          episode.id_institution%TYPE;
    l_date                    VARCHAR2(1000char);
    l_error_msg               VARCHAR2(4000);
BEGIN
    -- Active records without childs
    SELECT ch.* BULK COLLECT
      INTO l_tab_complete_hist
      FROM complete_history ch
      JOIN episode e
        ON e.id_episode = ch.id_episode
      JOIN institution i
        ON i.id_institution = e.id_institution
     WHERE e.id_epis_type = 5
       AND ch.flg_status IN ('A', 'I', 'O')
       AND ch.id_parent IS NULL
       AND NOT EXISTS (SELECT 1
              FROM complete_history ch1
             WHERE ch1.id_parent = ch.id_complete_history)
       AND i.id_market = 2;

    IF (l_tab_complete_hist.exists(1))
    THEN
        FOR indx IN 1 .. l_tab_complete_hist.count
        LOOP
            IF (l_tab_complete_hist(indx).text IS NOT NULL)
            THEN
                SELECT e.id_dep_clin_serv
                  INTO l_dep_clin_serv
                  FROM epis_info e
                 WHERE e.id_episode = l_tab_complete_hist(indx).id_episode;
            
                SELECT e.id_institution
                  INTO l_id_institution
                  FROM episode e
                 WHERE e.id_episode = l_tab_complete_hist(indx).id_episode;
            
                l_tab_pn_soap_block := table_number();
                l_tab_pn_area_block := table_number();
                l_tab_notes         := table_clob();
            
                l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                             i_date => l_tab_complete_hist(indx).dt_creation_tstz,
                                                             i_prof => profissional(l_tab_complete_hist(indx)
                                                                                    .id_professional,
                                                                                    l_id_institution,
                                                                                    11));
                IF (l_date IS NOT NULL)
                THEN
                    l_tab_pn_soap_block.extend;
                    l_tab_pn_soap_block(1) := 6;
                
                    l_tab_pn_area_block.extend;
                    l_tab_pn_area_block(1) := 47;
                
                    l_tab_notes.extend;
                    l_tab_notes(1) := l_date;
                END IF;
            
                l_tab_pn_soap_block.extend;
                l_tab_pn_soap_block(l_tab_pn_soap_block.last) := l_id_pn_soap_block;
            
                l_tab_pn_area_block.extend;
                l_tab_pn_area_block(l_tab_pn_area_block.last) := l_id_pn_data_block;
            
                l_tab_notes.extend;
                l_tab_notes(l_tab_notes.last) := l_tab_complete_hist(indx).text;
            
                IF NOT pk_prog_notes_core.set_save_def_note(i_lang                  => 2,
                                                            i_prof                  => NULL,
                                                            i_epis_pn               => NULL,
                                                            i_id_dictation_report   => NULL,
                                                            i_id_episode            => l_tab_complete_hist(indx).id_episode,
                                                            i_pn_flg_status         => 'M',
                                                            i_pn_flg_type           => 'H',
                                                            i_pn_date               => l_tab_complete_hist(indx)
                                                                                       .dt_creation_tstz,
                                                            i_id_dep_clin_serv      => l_dep_clin_serv,
                                                            i_id_pn_data_block      => l_tab_pn_area_block,
                                                            i_id_pn_soap_block      => l_tab_pn_soap_block,
                                                            i_id_epis_documentation => table_number(NULL, NULL),
                                                            i_pn_note               => l_tab_notes,
                                                            i_id_professional       => l_tab_complete_hist(indx)
                                                                                       .id_professional,
                                                            i_dt_last_update        => l_tab_complete_hist(indx)
                                                                                       .dt_creation_tstz,
                                                            i_dt_create             => l_tab_complete_hist(indx)
                                                                                       .dt_creation_tstz,
                                                            i_dt_sent_to_hist       => l_tab_complete_hist(indx)
                                                                                       .dt_creation_tstz,
                                                            i_id_prof_sign_off      => l_tab_complete_hist(indx)
                                                                                       .id_professional,
                                                            i_dt_sign_off           => l_tab_complete_hist(indx)
                                                                                       .dt_creation_tstz,
                                                            o_id_epis_pn            => l_id_epis_pn,
                                                            o_error                 => l_error)
                THEN
                    l_error_msg := 'ERROR. id_episode: ' || l_tab_complete_hist(indx).id_episode || ' text: ' || l_tab_complete_hist(indx).text ||
                                   ' id_complete_history: ' || l_tab_complete_hist(indx).id_complete_history;
                    dbms_output.put_line(l_error_msg);
                    pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_PAST_HIST_ADM');
                END IF;
            
                IF (l_tab_complete_hist(indx).flg_status IN ('O', 'I'))
                THEN
                    SELECT t.dt_creation_tstz
                      INTO l_date_cancel
                      FROM (SELECT ch.dt_creation_tstz
                            
                              FROM complete_history ch
                             WHERE ch.id_episode = l_tab_complete_hist(indx).id_episode
                               AND ch.dt_creation_tstz > l_tab_complete_hist(indx).dt_creation_tstz
                             ORDER BY 1) t
                     WHERE rownum = 1;
                
                    --cancel the note
                    IF NOT pk_prog_notes_core.cancel_progress_note(i_lang          => 2,
                                                                   i_prof          => profissional(l_tab_complete_hist(indx)
                                                                                                   .id_professional,
                                                                                                   NULL,
                                                                                                   11),
                                                                   i_epis_pn       => l_id_epis_pn,
                                                                   i_cancel_reason => NULL,
                                                                   i_notes_cancel  => pk_message.get_message(i_lang      => 2,
                                                                                                             i_code_mess => 'PN_M022'),
                                                                   i_dt_cancel     => l_date_cancel,
                                                                   o_error         => l_error)
                    THEN
                        l_error_msg := 'ERROR Cancel note. l_id_epis_pn: ' || l_id_epis_pn;
                        dbms_output.put_line(l_error_msg);
                        pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_PAST_HIST_ADM');
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END IF;

    --if the registry has childs 
    -- begin with the first created record (the one that does not have parent)
    SELECT ch.* BULK COLLECT
      INTO l_tab_complete_hist
      FROM complete_history ch
      JOIN episode e
        ON e.id_episode = ch.id_episode
      JOIN institution i
        ON i.id_institution = e.id_institution
     WHERE e.id_epis_type = 5
       AND ch.flg_status IN ('A', 'O')
       AND ch.id_parent IS NOT NULL
       AND i.id_market = 2;

    FOR indx IN 1 .. l_tab_complete_hist.count
    LOOP
    
        SELECT ch.* BULK COLLECT
          INTO l_tab_complete_hist_child
          FROM complete_history ch
        CONNECT BY PRIOR ch.id_parent = ch.id_complete_history
         START WITH ch.id_complete_history = l_tab_complete_hist(indx).id_complete_history
         ORDER BY ch.dt_creation_tstz ASC;
    
        SELECT e.id_dep_clin_serv
          INTO l_dep_clin_serv
          FROM epis_info e
         WHERE e.id_episode = l_tab_complete_hist(indx).id_episode;
    
        SELECT e.id_institution
          INTO l_id_institution
          FROM episode e
         WHERE e.id_episode = l_tab_complete_hist(indx).id_episode;
    
        l_id_epis_pn := NULL;
    
        FOR indx_child IN 1 .. l_tab_complete_hist_child.count
        LOOP
            IF (l_tab_complete_hist_child(indx_child).text IS NOT NULL)
            THEN
                l_tab_pn_soap_block := table_number();
                l_tab_pn_area_block := table_number();
                l_tab_notes         := table_clob();
            
                l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                             i_date => l_tab_complete_hist_child(indx_child)
                                                                       .dt_creation_tstz,
                                                             i_prof => profissional(l_tab_complete_hist_child(indx_child)
                                                                                    .id_professional,
                                                                                    l_id_institution,
                                                                                    11));
            
                IF (l_date IS NOT NULL)
                THEN
                    l_tab_pn_soap_block.extend;
                    l_tab_pn_soap_block(1) := 6;
                
                    l_tab_pn_area_block.extend;
                    l_tab_pn_area_block(1) := 47;
                
                    l_tab_notes.extend;
                    l_tab_notes(1) := l_date;
                END IF;
            
                l_tab_pn_soap_block.extend;
                l_tab_pn_soap_block(l_tab_pn_soap_block.last) := l_id_pn_soap_block;
            
                l_tab_pn_area_block.extend;
                l_tab_pn_area_block(l_tab_pn_area_block.last) := l_id_pn_data_block;
            
                l_tab_notes.extend;
                l_tab_notes(l_tab_notes.last) := l_tab_complete_hist_child(indx_child).text;
            
                --create the note to the 1st created complete history
                IF NOT pk_prog_notes_core.set_save_def_note(i_lang                  => 2,
                                                            i_prof                  => NULL,
                                                            i_epis_pn               => l_id_epis_pn,
                                                            i_id_dictation_report   => NULL,
                                                            i_id_episode            => l_tab_complete_hist_child(indx_child)
                                                                                       .id_episode,
                                                            i_pn_flg_status         => 'M',
                                                            i_pn_flg_type           => 'H',
                                                            i_pn_date               => l_tab_complete_hist_child(indx_child)
                                                                                       .dt_creation_tstz,
                                                            i_id_dep_clin_serv      => l_dep_clin_serv,
                                                            i_id_pn_data_block      => l_tab_pn_area_block,
                                                            i_id_pn_soap_block      => l_tab_pn_soap_block,
                                                            i_id_epis_documentation => table_number(NULL, NULL),
                                                            i_pn_note               => l_tab_notes,
                                                            i_id_professional       => l_tab_complete_hist_child(indx_child)
                                                                                       .id_professional,
                                                            i_dt_last_update        => l_tab_complete_hist_child(indx_child)
                                                                                       .dt_creation_tstz,
                                                            i_dt_create             => l_tab_complete_hist_child(indx_child)
                                                                                       .dt_creation_tstz,
                                                            i_dt_sent_to_hist       => l_tab_complete_hist_child(indx_child)
                                                                                       .dt_creation_tstz,
                                                            i_id_prof_sign_off      => l_tab_complete_hist_child(indx_child)
                                                                                       .id_professional,
                                                            i_dt_sign_off           => l_tab_complete_hist_child(indx_child)
                                                                                       .dt_creation_tstz,
                                                            o_id_epis_pn            => l_id_epis_pn,
                                                            o_error                 => l_error)
                THEN
                    l_error_msg := 'ERROR2. id_episode: ' || l_tab_complete_hist_child(indx_child).id_episode ||
                                   ' text: ' || l_tab_complete_hist_child(indx_child).text || ' id_complete_history: ' || l_tab_complete_hist_child(indx_child)
                                  .id_complete_history;
                
                    dbms_output.put_line(l_error.ora_sqlerrm || l_error.err_desc || '   lcall: ' || l_error.log_id);
                    dbms_output.put_line(l_error_msg);
                    pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_PAST_HIST_ADM');
                END IF;
            
                IF (l_tab_complete_hist_child(indx_child).flg_status = 'O')
                THEN
                
                    SELECT t.dt_creation_tstz
                      INTO l_date_cancel
                      FROM (SELECT ch.dt_creation_tstz
                            
                              FROM complete_history ch
                             WHERE ch.id_episode = l_tab_complete_hist_child(indx_child).id_episode
                               AND ch.dt_creation_tstz > l_tab_complete_hist_child(indx_child).dt_creation_tstz
                             ORDER BY 1) t
                     WHERE rownum = 1;
                
                    --cancel the note
                    IF NOT pk_prog_notes_core.cancel_progress_note(i_lang          => 2,
                                                                   i_prof          => profissional(l_tab_complete_hist_child(indx_child)
                                                                                                   .id_professional,
                                                                                                   NULL,
                                                                                                   11),
                                                                   i_epis_pn       => l_id_epis_pn,
                                                                   i_cancel_reason => NULL,
                                                                   i_notes_cancel  => pk_message.get_message(i_lang      => 2,
                                                                                                             i_code_mess => 'PN_M022'),
                                                                   i_dt_cancel     => l_date_cancel,
                                                                   o_error         => l_error)
                    THEN
                        l_error_msg := 'ERROR Cancel note2. l_id_epis_pn: ' || l_id_epis_pn;
                    
                        l_error_msg := 'ERROR2. id_episode: ' || l_tab_complete_hist_child(indx_child).id_episode ||
                                       ' text: ' || l_tab_complete_hist_child(indx_child).text ||
                                       ' id_complete_history: ' || l_tab_complete_hist_child(indx_child)
                                      .id_complete_history;
                    
                        dbms_output.put_line(l_error_msg);
                        pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_PAST_HIST_ADM');
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
    END LOOP;

END;
/

-- CHANGE END: António Neto
