CREATE OR REPLACE PACKAGE BODY pk_api_progress_notes IS

    FUNCTION interface_ins_prog_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_flg_action      IN VARCHAR2,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd     IN VARCHAR2 DEFAULT g_add,
        i_flg_task_parent IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_reg          IN VARCHAR2,
        i_pn_soap_block   IN table_number,
        i_pn_data_block   IN table_number,
        i_free_text       IN table_varchar,
        i_id_task         IN table_table_number,
        i_id_task_type    IN table_table_number,
        o_id_epis_pn      OUT epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_dt_pn_date         table_varchar := table_varchar();
        l_date_type          table_varchar := table_varchar();
        l_epis_pn_det        table_number := table_number();
        l_pn_note            table_clob := table_clob();
        l_flg_add_remove     table_varchar := table_varchar();
        l_epis_pn_det_task   table_table_number := table_table_number();
        l_pn_note_task       table_table_clob := table_table_clob();
        l_flg_add_rem_task   table_table_varchar := table_table_varchar();
        l_flg_table_origin   table_table_varchar := table_table_varchar();
        l_id_task_aggregator table_table_number := table_table_number();
        l_dt_task            table_table_varchar := table_table_varchar();
        l_id_task_parent     table_table_number := table_table_number();
        l_id_multichoice     table_table_number := table_table_number();
        l_id_group_table     table_table_number := table_table_number();
        l_notes_task         table_clob := table_clob();
        l_num_records        NUMBER;
    
        l_flg_reload VARCHAR2(10 CHAR);
    
        l_result               BOOLEAN;
        l_tasks_groups_by_type pk_prog_notes_types.t_tasks_groups_by_type;
        o_tasks_descs_by_type  pk_prog_notes_types.t_tasks_descs_by_type;
    
        l_id_patient patient.id_patient%TYPE;
    
        l_flg_description       pn_dblock_ttp_mkt.flg_description%TYPE;
        l_description_condition pn_dblock_ttp_mkt.description_condition%TYPE;
    
    BEGIN
        g_error := 'get patient id';
    
        SELECT epis.id_patient
          INTO l_id_patient
          FROM episode epis
         WHERE epis.id_episode = i_episode;
    
        g_error := 'Parameters |  i_pn_soap_block.count :' || i_pn_soap_block.count || ' i_pn_data_block.count:' ||
                   i_pn_data_block.count || ' i_free_text.count:' || i_free_text.count;
    
        IF i_pn_soap_block.count != i_pn_data_block.count
           OR i_pn_soap_block.count != i_free_text.count
        THEN
            RAISE g_exception;
        END IF;
    
        l_num_records := i_free_text.count;
    
        IF l_num_records > 0
        THEN
            g_error := 'Extending types';
        
            l_dt_pn_date.extend(l_num_records);
            l_date_type.extend(l_num_records);
            l_epis_pn_det.extend(l_num_records);
            l_pn_note.extend(l_num_records);
            l_flg_add_remove.extend(l_num_records);
            l_epis_pn_det_task.extend(l_num_records);
            l_pn_note_task.extend(l_num_records);
            l_flg_add_rem_task.extend(l_num_records);
            l_flg_table_origin.extend(l_num_records);
            l_id_task_aggregator.extend(l_num_records);
            l_dt_task.extend(l_num_records);
            l_id_task_parent.extend(l_num_records);
            l_id_multichoice.extend(l_num_records);
            l_id_group_table.extend(l_num_records);
            l_notes_task.extend(l_num_records);
        
            g_error := 'populate arrays...';
            FOR i IN 1 .. l_num_records
            LOOP
            
                l_date_type(i) := NULL;
                l_pn_note(i) := i_free_text(i);
                l_flg_add_remove(i) := g_add;
                l_pn_note_task(i) := table_clob(i_free_text(i));
                l_flg_add_rem_task(i) := table_varchar('A');
                l_flg_table_origin(i) := table_varchar('D');
                l_id_task_aggregator(i) := table_number(NULL);
                l_dt_task(i) := table_varchar(NULL);
                l_id_task_parent(i) := table_number(NULL);
                l_id_multichoice(i) := table_number(NULL);
                l_id_group_table(i) := table_number(NULL);
				
				l_dt_pn_date(i) := i_dt_reg;
            
            END LOOP;
        
            l_dt_pn_date(1) := i_dt_reg;
        
            FOR i IN 1 .. i_id_task.count
            LOOP
            
                IF l_pn_note(i) IS NULL
                THEN
                    IF i_id_task_type(i) (1) = pk_prog_notes_constants.g_task_templates
                    THEN
                        l_tasks_groups_by_type(pk_prog_notes_constants.g_templates) := table_number();
                        l_tasks_groups_by_type(pk_prog_notes_constants.g_templates).extend(1);
                        l_tasks_groups_by_type(pk_prog_notes_constants.g_templates)(l_tasks_groups_by_type(pk_prog_notes_constants.g_templates).last) := i_id_task(i) (1);
                    
                        IF pk_prog_notes_in.get_group_descriptions(i_lang                 => i_lang,
                                                                   i_prof                 => i_prof,
                                                                   i_id_episode           => i_episode,
                                                                   i_id_patient           => l_id_patient,
                                                                   i_tasks_groups_by_type => l_tasks_groups_by_type,
                                                                   o_tasks_descs_by_type  => o_tasks_descs_by_type,
                                                                   o_error                => o_error)
                        THEN
                            l_notes_task(i) := o_tasks_descs_by_type(pk_prog_notes_constants.g_templates)(i_id_task(i)(1))
                                              .task_desc_long;
                        
                        END IF;
                    ELSE
                        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                                  i_prof                  => i_prof,
                                                                                  i_id_note_type          => i_id_pn_note_type,
                                                                                  i_id_sblock             => i_pn_soap_block(i),
                                                                                  i_id_dblock             => i_pn_data_block(i),
                                                                                  i_id_task               => i_id_task_type(i) (1),
                                                                                  o_flg_description       => l_flg_description,
                                                                                  o_description_condition => l_description_condition,
                                                                                  o_error                 => o_error)
                        THEN
                            l_flg_description       := NULL;
                            l_description_condition := NULL;
                        END IF;
                    
                        l_pn_note(i) := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                               i_prof                  => i_prof,
                                                                               i_id_episode            => i_episode,
                                                                               i_id_task_type          => i_id_task_type(i) (1),
                                                                               i_id_task               => i_id_task(i) (1),
                                                                               i_universal_description => NULL,
                                                                               i_short_desc            => NULL,
                                                                               i_code_description      => NULL,
                                                                               i_flg_description       => l_flg_description,
                                                                               i_description_condition => l_description_condition);
                    END IF;
                
                END IF;
            END LOOP;
        
        END IF;
        g_error := 'CALL pk_ux_progress_notes.set_all_data_block_work ';
    
        IF NOT pk_prog_notes_core.set_all_data_block(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_epis_pn            => i_epis_pn,
                                                     i_dt_pn_date         => l_dt_pn_date,
                                                     i_flg_action         => i_flg_action,
                                                     i_date_type          => l_date_type,
                                                     i_pn_soap_block      => i_pn_soap_block,
                                                     i_pn_data_block      => i_pn_data_block,
                                                     i_id_task            => i_id_task,
                                                     i_id_task_type       => i_id_task_type,
                                                     i_dep_clin_serv      => NULL,
                                                     i_epis_pn_det        => l_epis_pn_det,
                                                     i_pn_note            => l_pn_note,
                                                     i_flg_add_remove     => l_flg_add_remove,
                                                     i_id_pn_note_type    => i_id_pn_note_type,
                                                     i_flg_app_upd        => i_flg_app_upd,
                                                     i_flg_definitive     => pk_alert_constant.get_yes,
                                                     i_epis_pn_det_task   => l_epis_pn_det_task,
                                                     i_pn_note_task       => l_pn_note_task,
                                                     i_flg_add_rem_task   => l_flg_add_rem_task,
                                                     i_flg_table_origin   => l_flg_table_origin,
                                                     i_id_task_aggregator => l_id_task_aggregator,
                                                     i_dt_task            => l_dt_task,
                                                     i_id_task_parent     => l_id_task_parent,
                                                     i_flg_task_parent    => i_flg_task_parent,
                                                     i_id_multichoice     => l_id_multichoice,
                                                     i_id_group_table     => l_id_group_table,
                                                     o_id_epis_pn         => o_id_epis_pn,
                                                     o_flg_reload         => l_flg_reload,
                                                     o_error              => o_error)
        THEN
        
            RAISE g_exception;
        END IF;
    
        -- THOR para funcionar os templates nos detalhes...
    
        FOR i IN 1 .. l_notes_task.count
        LOOP
            IF i_id_task_type(i) (1) = pk_prog_notes_constants.g_task_templates
               AND l_notes_task(i) IS NOT NULL
            THEN
                BEGIN
                    UPDATE epis_pn_det_task
                       SET pn_note = l_notes_task(i)
                     WHERE id_epis_pn_det IN (SELECT id_epis_pn_det
                                                FROM epis_pn_det
                                               WHERE id_epis_pn = o_id_epis_pn
                                                 AND id_pn_data_block = i_pn_data_block(i)
                                                 AND id_pn_soap_block = i_pn_soap_block(i));
                END;

                BEGIN
                    UPDATE epis_pn_det_task e
                       SET e.flg_status = 'Z'
                     WHERE e.id_task <> i_id_task(i)
                     (1)
                       AND e.id_epis_pn_det IN (SELECT ed.id_epis_pn_det
                                                  FROM epis_pn_det_task ed
                                                 WHERE ed.id_task = i_id_task(i) (1));
                END;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INTERFACE_INS_PROG_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END interface_ins_prog_notes;

    FUNCTION interface_ins_prog_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_flg_action      IN VARCHAR2,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd     IN VARCHAR2 DEFAULT g_add,
        i_flg_task_parent IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_reg          IN VARCHAR2,
        i_pn_soap_block   IN table_number,
        i_pn_data_block   IN table_number,
        i_free_text       IN table_varchar,
        o_id_epis_pn      OUT epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_id_task      table_table_number := table_table_number();
        l_id_task_type table_table_number := table_table_number();
    
    BEGIN
    
        IF i_pn_data_block.count > 0
        THEN
            l_id_task.extend(i_pn_data_block.count);
            l_id_task_type.extend(i_pn_data_block.count);
        
            FOR i IN 1 .. i_pn_data_block.count
            LOOP
                l_id_task(i) := table_number(NULL);
                l_id_task_type(i) := table_number(NULL);
            
            END LOOP;
        END IF;
    
        IF NOT interface_ins_prog_notes(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_episode         => i_episode,
                                        i_epis_pn         => i_epis_pn,
                                        i_flg_action      => i_flg_action,
                                        i_id_pn_note_type => i_id_pn_note_type,
                                        i_flg_app_upd     => i_flg_app_upd,
                                        i_flg_task_parent => i_flg_task_parent,
                                        i_dt_reg          => i_dt_reg,
                                        i_pn_soap_block   => i_pn_soap_block,
                                        i_pn_data_block   => i_pn_data_block,
                                        i_free_text       => i_free_text,
                                        i_id_task         => l_id_task,
                                        i_id_task_type    => l_id_task_type,
                                        o_id_epis_pn      => o_id_epis_pn,
                                        o_error           => o_error)
        THEN
        
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INTERFACE_INS_PROG_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION interface_cancel_prog_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_cancel_reason IN NUMBER DEFAULT NULL,
        i_notes_cancel  IN VARCHAR2 DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.cancel_progress_note';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.cancel_progress_note(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_epis_pn       => i_epis_pn,
                                                       i_cancel_reason => i_cancel_reason,
                                                       i_notes_cancel  => i_notes_cancel,
                                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INTERFACE_CANCEL_PROG_NOTE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_cancel_prog_note;

--ARGS: [2,[247032,50002,11],"PN",3327058,2911,""]

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_api_progress_notes;
/
