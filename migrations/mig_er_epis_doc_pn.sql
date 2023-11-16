-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 01/04/2016 14:53
-- CHANGE REASON: [ALERT-319997] Templates in plan

DECLARE
    TYPE tab_epis_recomend IS TABLE OF epis_recomend%ROWTYPE;

    l_tab_epis_recomend tab_epis_recomend;
    l_lang              language.id_language%TYPE := 7;
    l_id_doc_area       doc_area.id_doc_area%TYPE := 36110;

    l_id_institution      episode.id_institution%TYPE;
    l_error               t_error_out;
    l_table_number_empty  table_number := table_number();
    l_table_varchar_empty table_varchar := table_varchar();
    l_table_table_number  table_table_number := table_table_number();
    l_epis_documentation  epis_documentation.id_epis_documentation%TYPE;
    l_error_msg           VARCHAR2(4000);

    TYPE plan_documentation IS RECORD(
        id_epis_recomend      epis_recomend.id_epis_recomend%TYPE,
        id_epis_documentation epis_documentation.id_epis_documentation%TYPE);
    TYPE plan_d IS TABLE OF plan_documentation INDEX BY BINARY_INTEGER;
    l_tbl_plan plan_d;

    l_id_prof_cancel        cancel_info_det.id_prof_cancel%TYPE;
    l_dt_cancel             cancel_info_det.dt_cancel%TYPE;
    l_notes_cancel          cancel_info_det.notes_cancel_long%TYPE;
    l_id_cancel_reason      cancel_info_det.id_cancel_reason%TYPE;
    l_id_episode_prev       epis_recomend.id_episode%TYPE;
    l_id_prof_prev          epis_recomend.id_professional%TYPE;
    l_id_dt_creation_prev   epis_recomend.dt_epis_recomend_tstz%TYPE;
    l_id_documentation_prev epis_documentation.id_epis_documentation%TYPE;
    l_status_prev           epis_documentation.flg_status%TYPE;
    l_count                 NUMBER;
BEGIN
    --   l_epis_documentation := 1000000;
    SELECT er.* BULK COLLECT
      INTO l_tab_epis_recomend
      FROM epis_recomend er
      JOIN episode e
        ON er.id_episode = e.id_episode
     WHERE er.flg_type = 'L'
       AND e.id_epis_type NOT IN (8, 11, 14, 17)
          --       and er.id_epis_recomend in( 1722309) --,1724309, 1724311,1724809,1724811)
       AND NOT EXISTS (SELECT 1
              FROM epis_documentation ed
             WHERE ed.id_doc_area = l_id_doc_area
               AND ed.id_episode = er.id_episode
               AND ed.id_professional = er.id_professional
               AND ed.dt_creation_tstz = er.dt_epis_recomend_tstz)
     ORDER BY er.id_epis_recomend_parent NULLS FIRST, dt_epis_recomend_tstz;

    IF (l_tab_epis_recomend.exists(1))
    THEN
        FOR i IN 1 .. l_tab_epis_recomend.count
        LOOP
            --      dbms_output.put_line(l_tab_epis_recomend(i).id_episode || ' : ' ||l_tab_epis_recomend(i).ID_EPIS_RECOMEND);
            SELECT e.id_institution
              INTO l_id_institution
              FROM episode e
             WHERE e.id_episode = l_tab_epis_recomend(i).id_episode;
            --get institution language
            BEGIN
                SELECT VALUE
                  INTO l_lang
                  FROM sys_config s
                 WHERE s.id_sys_config = 'LANGUAGE'
                   AND id_institution = l_id_institution;
            EXCEPTION
                WHEN OTHERS THEN
                    BEGIN
                        SELECT il.id_language
                          INTO l_lang
                          FROM institution_language il
                         WHERE il.id_institution = l_id_institution;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_lang := 2;
                    END;
            END;
            l_epis_documentation := seq_epis_documentation.nextval;
            INSERT INTO epis_documentation
                (id_epis_documentation,
                 id_episode,
                 id_professional,
                 dt_creation_tstz,
                 id_prof_last_update,
                 flg_status,
                 id_doc_area,
                 notes,
                 flg_edition_type)
            VALUES
                (l_epis_documentation,
                 l_tab_epis_recomend(i).id_episode,
                 l_tab_epis_recomend(i).id_professional,
                 l_tab_epis_recomend(i).dt_epis_recomend_tstz,
                 l_tab_epis_recomend(i).id_professional,
                 l_tab_epis_recomend(i).flg_status,
                 l_id_doc_area,
                 l_tab_epis_recomend(i).desc_epis_recomend_clob,
                 'N');
        
            l_error_msg := 'id_episode:' || l_tab_epis_recomend(i).id_episode || ' id_epis_recomend :' || l_tab_epis_recomend(i)
                          .id_epis_recomend || ' estado:' || l_tab_epis_recomend(i).flg_status || ' parent:' || l_tab_epis_recomend(i)
                          .id_epis_recomend_parent || ' epis_documentation :' || l_epis_documentation;
        
             pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_EPIS_REC_EPIS_DOC');
        
            -- update single page information
            UPDATE epis_pn_det_task
               SET id_task          = l_epis_documentation,
                   id_task_type     = 36,
                   flg_table_origin = 'D',
                   id_group_import  = l_id_doc_area
             WHERE id_task = l_tab_epis_recomend(i).id_epis_recomend
               AND id_task_type = 60;
        
            UPDATE epis_pn_det_task_hist
               SET id_task          = l_epis_documentation,
                   id_task_type     = 36,
                   flg_table_origin = 'D',
                   id_group_import  = l_id_doc_area
             WHERE id_task = l_tab_epis_recomend(i).id_epis_recomend
               AND id_task_type = 60;
            --registo cancelado
            IF l_tab_epis_recomend(i).flg_status = 'C'
            THEN
                SELECT c.id_prof_cancel, c.id_cancel_reason, c.dt_cancel, c.notes_cancel_long
                  INTO l_id_prof_cancel, l_id_cancel_reason, l_dt_cancel, l_notes_cancel
                  FROM cancel_info_det c
                 WHERE c.id_cancel_info_det = l_tab_epis_recomend(i).id_cancel_info_det;
            
                UPDATE epis_documentation ed
                   SET dt_cancel_tstz         = l_dt_cancel,
                       ed.id_prof_cancel      = l_id_prof_cancel,
                       ed.id_prof_last_update = l_id_prof_cancel,
                       ed.id_cancel_reason    = l_id_cancel_reason,
                       ed.notes_cancel        = l_notes_cancel
                 WHERE id_epis_documentation = l_epis_documentation;
            
                pk_alertlog.log_debug(text        => 'CANCELAR DOCUMENTATION' || l_tab_epis_recomend(i)
                                                    .id_cancel_info_det || ' l_id_prof_cancel:' || l_id_prof_cancel ||
                                                     ' l_id_cancel_reason:' || l_id_cancel_reason || 'l_dt_cancel:' ||
                                                     l_dt_cancel,
                                      object_name => 'MIGRATION_EPIS_REC_EPIS_DOC');
            
            END IF;
            -- registo criado a partir de outro
            IF l_tab_epis_recomend(i).id_epis_recomend_parent IS NOT NULL
            THEN
                IF l_tbl_plan.exists(l_tab_epis_recomend(i).id_epis_recomend_parent)
                THEN
                    IF l_tbl_plan(l_tab_epis_recomend(i).id_epis_recomend_parent).id_epis_documentation IS NOT NULL
                    THEN
                    
                   
                        pk_alertlog.log_debug(text        => ' PARENT HAST:' || l_tab_epis_recomend(i)
                                                            
                                                            .id_epis_recomend_parent || ' epis_documentation:' || l_tbl_plan(l_tab_epis_recomend(i).id_epis_recomend_parent)
                                                            .id_epis_documentation,
                                              object_name => 'MIGRATION_EPIS_REC_EPIS_DOC');
                    
                        UPDATE epis_documentation ed
                           SET id_epis_documentation_parent = l_tbl_plan(l_tab_epis_recomend(i).id_epis_recomend_parent)
                                                              .id_epis_documentation
                         WHERE id_epis_documentation = l_epis_documentation;
                    ELSE
                        SELECT id_episode, id_professional, dt_epis_recomend_tstz
                          INTO l_id_episode_prev, l_id_prof_prev, l_id_dt_creation_prev
                          FROM epis_recomend er
                         WHERE er.id_epis_recomend = l_tab_epis_recomend(i).id_epis_recomend_parent;
                    
                        SELECT ed.id_epis_documentation
                          INTO l_id_documentation_prev
                          FROM epis_documentation ed
                         WHERE ed.id_doc_area = l_id_doc_area
                           AND ed.id_episode = l_id_episode_prev
                           AND ed.id_professional = l_id_prof_prev
                           AND ed.dt_creation_tstz = l_id_dt_creation_prev;

                        UPDATE epis_documentation ed
                           SET id_epis_documentation_parent = l_id_documentation_prev
                         WHERE id_epis_documentation = l_epis_documentation;
                    
                        IF l_status_prev = 'O' -- parent outdated
                        THEN
                            UPDATE epis_documentation ed
                               SET flg_status = 'O'
                             WHERE ed.id_epis_documentation = l_id_documentation_prev
                               AND ed.flg_status = 'A';
                        END IF;
                    END IF;
                
                END IF;
            END IF;
        
            l_tbl_plan(l_tab_epis_recomend(i).id_epis_recomend).id_epis_recomend := l_tab_epis_recomend(i)
                                                                                    .id_epis_recomend;
            l_tbl_plan(l_tab_epis_recomend(i).id_epis_recomend).id_epis_documentation := l_epis_documentation;
        END LOOP;
    END IF;

END;
-- CHANGE END: Elisabete Bugalho