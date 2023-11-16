DECLARE
    TYPE tab_epis_recommend IS TABLE OF epis_recomend%ROWTYPE;

    l_tab_epis_recommend tab_epis_recommend;

    l_error             t_error_out;
    l_id_pn_soap_block  pn_soap_block.id_pn_soap_block%TYPE := 5;
    l_id_pn_data_block  pn_data_block.id_pn_data_block%TYPE := 90;
    l_id_epis_pn        epis_pn.id_epis_pn%TYPE;
    l_dep_clin_serv     epis_info.id_dep_clin_serv%TYPE;
    l_date_cancel       epis_pn_hist.dt_epis_pn_hist%TYPE;
    l_tab_pn_soap_block table_number := table_number();
    l_tab_pn_area_block table_number := table_number();
    l_tab_notes         table_clob := table_clob();
    l_id_institution    episode.id_institution%TYPE;
    l_date              VARCHAR2(1000char);
    l_error_msg         VARCHAR2(4000);
BEGIN
    -- Active records without childs
    SELECT er.* BULK COLLECT
      INTO l_tab_epis_recommend
      FROM epis_recomend er
      JOIN episode e
        ON e.id_episode = er.id_episode
      JOIN institution i
        ON i.id_institution = e.id_institution
     WHERE e.id_epis_type = 5       
       AND er.flg_type = 'L'
       AND i.id_market = 2;

    IF (l_tab_epis_recommend.exists(1))
    THEN
        FOR indx IN 1 .. l_tab_epis_recommend.count
        LOOP
            IF (l_tab_epis_recommend(indx).desc_epis_recomend IS NOT NULL)
            THEN
                SELECT e.id_dep_clin_serv
                  INTO l_dep_clin_serv
                  FROM epis_info e
                 WHERE e.id_episode = l_tab_epis_recommend(indx).id_episode;
            
                SELECT e.id_institution
                  INTO l_id_institution
                  FROM episode e
                 WHERE e.id_episode = l_tab_epis_recommend(indx).id_episode;
            
                l_tab_pn_soap_block := table_number();
                l_tab_pn_area_block := table_number();
                l_tab_notes         := table_clob();
            
                l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                             i_date => l_tab_epis_recommend(indx).dt_epis_recomend_tstz,
                                                             i_prof => profissional(l_tab_epis_recommend(indx)
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
                l_tab_notes(l_tab_notes.last) := l_tab_epis_recommend(indx).desc_epis_recomend;
            
                IF NOT
                    pk_prog_notes_core.set_save_def_note(i_lang                  => 2,
                                                         i_prof                  => NULL,
                                                         i_epis_pn               => NULL,
                                                         i_id_dictation_report   => NULL,
                                                         i_id_episode            => l_tab_epis_recommend(indx).id_episode,
                                                         i_pn_flg_status         => 'M',
                                                         i_pn_flg_type           => 'P',
                                                         i_pn_date               => l_tab_epis_recommend(indx)
                                                                                    .dt_epis_recomend_tstz,
                                                         i_id_dep_clin_serv      => l_dep_clin_serv,
                                                         i_id_pn_data_block      => l_tab_pn_area_block,
                                                         i_id_pn_soap_block      => l_tab_pn_soap_block,
                                                         i_id_epis_documentation => table_number(NULL, NULL),
                                                         i_pn_note               => l_tab_notes,
                                                         i_id_professional       => l_tab_epis_recommend(indx)
                                                                                    .id_professional,
                                                         i_dt_last_update        => l_tab_epis_recommend(indx)
                                                                                    .dt_epis_recomend_tstz,
                                                         i_dt_create             => l_tab_epis_recommend(indx)
                                                                                    .dt_epis_recomend_tstz,
                                                         i_dt_sent_to_hist       => l_tab_epis_recommend(indx)
                                                                                    .dt_epis_recomend_tstz,
                                                         i_id_prof_sign_off      => l_tab_epis_recommend(indx)
                                                                                    .id_professional,
                                                         i_dt_sign_off           => l_tab_epis_recommend(indx)
                                                                                    .dt_epis_recomend_tstz,
                                                         o_id_epis_pn            => l_id_epis_pn,
                                                         o_error                 => l_error)
                THEN
                    l_error_msg := 'ERROR. id_episode: ' || l_tab_epis_recommend(indx).id_episode || ' text: ' || l_tab_epis_recommend(indx)
                                  .desc_epis_recomend || ' id_complete_history: ' || l_tab_epis_recommend(indx)
                                  .id_epis_recomend;
                    dbms_output.put_line(l_error_msg);
                    pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_PLAN');
                END IF;
            END IF;
        END LOOP;
    END IF;
END;
/
