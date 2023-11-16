CREATE OR REPLACE PACKAGE BODY pk_prog_notes_in IS

    -- Private type declarations    
    -- Private constant declarations    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /********************************************************************************************
    * get all actions of a task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               type of the task
    * @param       i_task                    task requisition id
    * @param       i_flg_table_origin        Templates table origin
    * @param       i_task_request            task requisition id
    * @param       o_task_actions            list of task actions 
    * @param       o_error                g_task_prognosis
       error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 16-Mar-2012
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN tl_task.id_tl_task%TYPE,
        i_id_task           IN epis_pn_det_task.id_task%TYPE,
        i_flg_table_origin  IN epis_pn_det_task.flg_table_origin%TYPE,
        i_flg_write         IN VARCHAR2,
        i_last_n_records_nr IN pn_dblock_ttp_mkt.last_n_records_nr%TYPE DEFAULT NULL,
        o_task_actions      OUT t_coll_action,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_task_actions pk_types.cursor_type;
        l_rec          t_rec_action := t_rec_action(id_action => NULL,
                                                    
                                                    id_parent   => NULL,
                                                    level_nr    => NULL,
                                                    from_state  => NULL,
                                                    to_state    => NULL,
                                                    desc_action => NULL,
                                                    icon        => NULL,
                                                    flg_default => NULL,
                                                    action      => NULL,
                                                    flg_active  => NULL);
    
        l_rec_index PLS_INTEGER := 0;
        l_doc_area  doc_area.id_doc_area%TYPE;
    BEGIN
    
        g_error := 'get o_task_actions cursor for i_task_type=' || to_char(i_task_type) || ', i_id_task: ' || i_id_task ||
                   ', i_episode=' || i_episode;
        pk_alertlog.log_debug(g_error, g_package);
    
        CASE
        
        -- Reported medication
            WHEN i_task_type = pk_prog_notes_constants.g_task_reported_medic THEN
                g_error := 'CALL pk_api_pfh_clindoc_in.get_medication_actions reported medication. i_id_task: ' ||
                           i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_api_pfh_clindoc_in.get_home_med_actions(i_lang                 => i_lang,
                                                                  i_prof                 => i_prof,
                                                                  i_presc                => i_id_task,
                                                                  i_class_origin_context => pk_prog_notes_constants.g_ctx_reported_medication,
                                                                  o_action               => l_task_actions,
                                                                  o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        -- Local medication
            WHEN i_task_type IN
                 (pk_prog_notes_constants.g_task_medic_here, pk_prog_notes_constants.g_task_amb_medication) THEN
                g_error := 'CALL pk_api_pfh_clindoc_in.get_medication_actions reported medication. i_id_task: ' ||
                           i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_api_pfh_clindoc_in.get_presc_actions(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_presc                => i_id_task,
                                                          i_class_origin         => CASE
                                                                                        WHEN i_task_type =
                                                                                             pk_prog_notes_constants.g_task_medic_here THEN
                                                                                         'PrescViewAdminAndTasks'
                                                                                        ELSE
                                                                                         'PrescViewAmbulatoryMedication'
                                                                                    END,
                                                          i_class_origin_context => pk_prog_notes_constants.g_ctx_local_medication,
                                                          o_action               => l_task_actions,
                                                          o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        --Chief complaint
            WHEN i_task_type = pk_prog_notes_constants.g_task_chief_complaint THEN
                g_error := 'CALL pk_complaint.get_actions chief complaint. i_id_task: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_complaint.get_actions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_epis_complaint => i_id_task,
                                                i_id_epis_anamnesis => NULL,
                                                o_actions           => l_task_actions,
                                                o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        --Chief complaint free text
            WHEN i_task_type IN (pk_prog_notes_constants.g_task_chief_complaint_anm) THEN
                g_error := 'CALL pk_complaint.get_actions chief complaint free txt. i_id_task: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_complaint.get_actions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_epis_complaint => NULL,
                                                i_id_epis_anamnesis => i_id_task,
                                                o_actions           => l_task_actions,
                                                o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                -- chief_complaint epis reason
            WHEN i_task_type IN (pk_prog_notes_constants.g_task_chief_complaint_out) THEN
                g_error := 'CALL pk_complaint.get_actions g_task_chief_complaint_out. i_id_task: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_complaint.get_actions_epis_reason(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_pn_epis_reason => i_id_task,
                                                            o_actions           => l_task_actions,
                                                            o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        --Diagnosis general notes
            WHEN i_task_type IN (pk_prog_notes_constants.g_task_diag_notes, pk_prog_notes_constants.g_task_diagnosis) THEN
                g_error := 'CALL get_actions. i_id_task: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_diagnosis.get_actions(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_task_request => i_id_task,
                                                o_actions      => l_task_actions,
                                                o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        --Templates
            WHEN i_task_type IN (pk_prog_notes_constants.g_task_templates, pk_prog_notes_constants.g_task_ph_templ) THEN
                IF (pk_hcn.check_is_hcn_record(i_lang => i_lang, i_prof => i_prof, i_epis_documentation => i_id_task) = 1)
                THEN
                    g_error := 'CALL pk_hcn.get_hcn_actions. i_id_task: ' || i_id_task;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_hcn.get_hcn_actions(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_epis_documentation => i_id_task,
                                                  o_actions            => l_task_actions,
                                                  o_error              => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    g_error := 'CALL pk_touch_option_out.get_entry_actions. i_epis_documentation: ' || i_id_task ||
                               ' i_flg_table_origin: ' || i_flg_table_origin || ' i_flg_write: ' || i_flg_write;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_touch_option.get_doc_area_from_epis_doc(i_lang     => i_lang,
                                                                      i_prof     => i_prof,
                                                                      i_epis_doc => i_id_task,
                                                                      o_doc_area => l_doc_area,
                                                                      o_error    => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF l_doc_area IN (pk_touch_option.g_doc_area_ntiss, pk_touch_option.g_doc_area_routine_pci)
                    THEN
                        pk_touch_option_out.get_entry_actions(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_epis_documentation    => i_id_task,
                                                              i_flg_table_origin      => i_flg_table_origin,
                                                              i_flg_write             => i_flg_write,
                                                              i_flg_update            => pk_alert_constant.g_no,
                                                              i_flg_no_changes        => pk_alert_constant.g_no,
                                                              i_show_disabled_actions => pk_alert_constant.g_no,
                                                              i_nr_record             => i_last_n_records_nr,
                                                              o_actions               => l_task_actions);
                    ELSE
                        pk_touch_option_out.get_entry_actions(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_epis_documentation    => i_id_task,
                                                              i_flg_table_origin      => i_flg_table_origin,
                                                              i_flg_write             => i_flg_write,
                                                              i_flg_update            => pk_alert_constant.g_yes,
                                                              i_flg_no_changes        => pk_alert_constant.g_no,
                                                              i_show_disabled_actions => pk_alert_constant.g_yes,
                                                              i_nr_record             => i_last_n_records_nr,
                                                              o_actions               => l_task_actions);
                    END IF;
                
                END IF;
                -- subjective, objective, assessment, plan notes
            WHEN i_task_type IN (pk_prog_notes_constants.g_task_plan_notes,
                                 pk_prog_notes_constants.g_task_subjective,
                                 pk_prog_notes_constants.g_task_objective,
                                 pk_prog_notes_constants.g_task_assessment) THEN
                g_error := 'CALL pk_discharge.get_actions_soap_notes i_id_task: ' || i_id_task || ' i_task_type: ' ||
                           i_task_type;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_discharge.get_actions_soap_notes(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_epis_recomend => i_id_task,
                                                           i_id_task_type     => i_task_type,
                                                           o_actions          => l_task_actions,
                                                           o_error            => o_error)
                
                THEN
                    RAISE g_exception;
                END IF;
            
        -- final diagnosis
            WHEN i_task_type = pk_prog_notes_constants.g_task_final_diag THEN
            
                g_error := 'CALL pk_diagnosis.get_actions_final_diags i_task_request: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_diagnosis.get_actions_final_diags(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_task_request => i_id_task,
                                                            o_actions      => l_task_actions,
                                                            o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --severity scores
            WHEN i_task_type = pk_prog_notes_constants.g_task_mtos_score THEN
            
                g_error := 'CALL pk_sev_scores_core.get_sev_scores_actions i_task_request: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sev_scores_core.get_sev_scores_actions(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_task_request => i_id_task,
                                                                 o_actions      => l_task_actions,
                                                                 o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        --Emergency law
            WHEN i_task_type = pk_prog_notes_constants.g_task_emergency_law THEN
            
                g_error := 'CALL pk_epis_er_law_api.get_actions i_id_epis_er_law: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_epis_er_law_api.get_actions(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_epis_er_law => i_id_task,
                                                      o_actions        => l_task_actions,
                                                      o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            WHEN i_task_type = pk_prog_notes_constants.g_task_prognosis THEN
            
                g_error := 'CALL PK_PROGNOSIS.GET_ACTIONS ID_EPIS_PROGNOSIS: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_prognosis.get_actions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_epis_prognosis => i_id_task,
                                                o_actions           => l_task_actions,
                                                o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            WHEN i_task_type = pk_prog_notes_constants.g_task_prof_resp THEN
                g_error := 'CALL PK_HAND_OFF.GET_ACTIONS ID: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.get_handoff_actions_sp(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_epis_prof_resp => i_id_task,
                                                               o_actions        => l_task_actions,
                                                               o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            WHEN i_task_type = pk_prog_notes_constants.g_task_cits_procedures THEN
                g_error := 'CALL PK_.GET_ACTIONS ID: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
            
            WHEN i_task_type = pk_prog_notes_constants.g_task_document_status THEN
                g_error := 'CALL PK_.GET_ACTIONS ID: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
            
                IF NOT pk_action.get_actions(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_subject    => 'DOC_STATUS_SINGLEPAGE',
                                             i_from_state => NULL,
                                             o_actions    => l_task_actions,
                                             o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                -- Body diagrams
            WHEN i_task_type = pk_prog_notes_constants.g_task_body_diagram THEN
                g_error := 'CALL PK_BODY_DIAGRAMS_NEW.GET_ACTIONS FOR I_ID_TASK: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_diagram_new.get_epis_diagram_actions(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_epis_diagram => i_id_task,
                                                               o_actions         => l_task_actions,
                                                               o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            WHEN i_task_type = pk_prog_notes_constants.g_task_problems_group_ass THEN
                g_error := 'CALL PK_ACTION.GET_ACTIONS PROBLEMS ASSESSMENT ID: ' || i_id_task;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_action.get_actions(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_subject    => 'PROBLEMS_NOT_KNOWN',
                                             i_from_state => NULL,
                                             o_actions    => l_task_actions,
                                             o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            WHEN i_task_type = pk_prog_notes_constants.g_task_nurse_intervention THEN
                g_error := 'CALL pk_icnp_fo.GET_ACTIONS get_actions_permissions ASSESSMENT ID: ' || i_id_task;
            
                pk_icnp_fo.get_icnp_actions_sp(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               id_icnp_epis_interv_diag => i_id_task,
                                               o_actions                => l_task_actions);
            
            ELSE
                l_task_actions := NULL;
        END CASE;
    
        o_task_actions := t_coll_action();
    
        LOOP
            g_error := 'fetch record from l_task_actions cursor';
            pk_alertlog.log_debug(g_error, g_package);
        
            -- if this task type support actions then fetch them
            IF l_task_actions IS NOT NULL
            THEN
            
                FETCH l_task_actions
                    INTO l_rec.id_action,
                         l_rec.id_parent,
                         l_rec.level_nr,
                         l_rec.from_state,
                         l_rec.to_state,
                         l_rec.desc_action,
                         l_rec.icon,
                         l_rec.flg_default,
                         l_rec.flg_active,
                         l_rec.action;
                EXIT WHEN l_task_actions%NOTFOUND;
            ELSE
                pk_types.open_my_cursor(l_task_actions);
                EXIT;
            END IF;
        
            -- extend and associates the new record into actions table
            o_task_actions.extend;
            l_rec_index := l_rec_index + 1;
            o_task_actions(l_rec_index) := l_rec;
        
        END LOOP;
    
        CLOSE l_task_actions;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TASK_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(l_task_actions);
            RETURN FALSE;
    END get_task_actions;

    /**************************************************************************
    * When editing some data inserted by template validates
    * if the template was edited since the note creation date.
    * This is used because the physical exam template inserts vital signs values
    * and if the vital signs are edited in the vital signs area the template is updated.
    * However in the H&P appear the values inserted when the template was created. So,
    * when the user edits this template he should be notified that the template had been edited
    * after its insertion in the H&P area.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_epis_documentation  Epis documentation Id
    * @param i_id_epis_pn             Epis Progress Note Id
    * @param o_flg_edited             Y-the template was edited.
    *                                 N-otherwise    
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes                       
    * @version                        2.6.1                                
    * @since                          19-Mai-2011                                
    **************************************************************************/
    FUNCTION check_documentation_edition
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_dt_creation           IN epis_pn_det_task.dt_last_update%TYPE,
        o_flg_show              OUT NOCOPY VARCHAR2,
        o_msg_title             OUT NOCOPY VARCHAR2,
        o_msg                   OUT NOCOPY VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_touch_option_ti.check_ti_info_changed.';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option_ti.check_ti_info_changed(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_epis_documentation => i_id_epis_documentation,
                                                        i_dt_creation        => i_dt_creation,
                                                        o_ref_info_changed   => o_flg_show,
                                                        o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (o_flg_show = pk_alert_constant.g_yes)
        THEN
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M080');
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T052');
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
                                              'CHECK_DOCUMENTATION_EDITION',
                                              o_error);
            RETURN FALSE;
    END check_documentation_edition;

    /**
    * Get the exam results descriptions.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task                Task id
    * @param o_short_desc             Short description to the import last level
    * @param o_detailed_desc          Detailed desc for more info and note
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          09-Feb-2012
    */
    FUNCTION get_exam_result_descs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char,
        i_flg_image_exam        IN pk_types.t_flg_char,
        o_short_desc            OUT CLOB,
        o_detailed_desc         OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(21) := 'GET_EXAM_RESULT_DESCS';
        l_interpretation    CLOB;
        l_notes_result      CLOB;
        l_result_notes      CLOB;
        l_result            pk_translation.t_desc_translation;
        l_report_date       exam_req.dt_req_tstz%TYPE;
        l_exec_date         exam_req_det.start_time%TYPE;
        l_token_list        table_varchar;
        l_description_split table_varchar;
        l_final_desc_cond   CLOB;
        l_inst_name         CLOB;
        l_result_date       exam_result.dt_exam_result_tstz%TYPE;
        l_desc_exam         pk_translation.t_desc_translation;
    BEGIN
    
        --because of performance reasons the short and long descs of the exam results will be calculated at the same time
    
        g_error := 'CALL pk_exams_external_api_db.get_exam_result_desc -  i_id_task: ' || i_id_task;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_exams_external_api_db.get_exam_result_desc(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_exam_result => i_id_task,
                                                             i_flg_image_exam => i_flg_image_exam,
                                                             o_description    => o_short_desc,
                                                             o_notes_result   => l_notes_result,
                                                             o_result_notes   => l_result_notes,
                                                             o_interpretation => l_interpretation,
                                                             o_exec_date      => l_exec_date,
                                                             o_result         => l_result,
                                                             o_report_date    => l_report_date,
                                                             o_inst_name      => l_inst_name,
                                                             o_result_date    => l_result_date,
                                                             o_exam_desc      => l_desc_exam,
                                                             o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_flg_description IS NULL
        THEN
            IF l_result_notes IS NOT NULL
               AND l_notes_result IS NULL
            THEN
                l_result_notes := l_result_notes || chr(13);
            END IF;
        
            IF l_notes_result IS NOT NULL
            THEN
                l_notes_result := l_notes_result || chr(13);
            END IF;
        
            o_detailed_desc := o_short_desc || CASE
                                   WHEN (l_interpretation IS NOT NULL AND dbms_lob.compare(l_interpretation, empty_clob()) > 0)
                                        OR (l_result_notes IS NOT NULL)
                                        OR l_notes_result IS NOT NULL THEN
                                    pk_prog_notes_constants.g_colon || l_interpretation || l_result_notes || l_notes_result
                                   ELSE
                                    NULL
                               END;
        
        ELSIF i_flg_description = pk_prog_notes_constants.g_flg_description_c
        THEN
            l_description_split := pk_string_utils.str_split(i_list => i_description_condition, i_delim => ';');
        
            IF i_flg_desc_for_dblock = pk_alert_constant.g_yes
               OR i_flg_desc_for_dblock IS NULL
            THEN
                l_final_desc_cond := l_description_split(1);
            ELSIF l_description_split.exists(2)
            THEN
                l_final_desc_cond := l_description_split(2);
            END IF;
        
            l_token_list := pk_string_utils.str_split(i_list => l_final_desc_cond, i_delim => '|');
        
            FOR i IN l_token_list.first .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'RESULT-DATE'
                THEN
                    IF o_detailed_desc IS NOT NULL
                    THEN
                        o_detailed_desc := o_detailed_desc || pk_prog_notes_constants.g_comma ||
                                           pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                       i_date => l_result_date,
                                                                       i_inst => i_prof.institution,
                                                                       i_soft => i_prof.software);
                    ELSE
                        o_detailed_desc := o_detailed_desc ||
                                           pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                       i_date => l_result_date,
                                                                       i_inst => i_prof.institution,
                                                                       i_soft => i_prof.software);
                    END IF;
                ELSIF l_token_list(i) = 'ORDER-DATE'
                THEN
                    IF o_detailed_desc IS NOT NULL
                    THEN
                        o_detailed_desc := o_detailed_desc || pk_prog_notes_constants.g_comma ||
                                           pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                       i_date => l_report_date,
                                                                       i_inst => i_prof.institution,
                                                                       i_soft => i_prof.software);
                    ELSE
                        o_detailed_desc := o_detailed_desc ||
                                           pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                       i_date => l_report_date,
                                                                       i_inst => i_prof.institution,
                                                                       i_soft => i_prof.software);
                    END IF;
                ELSIF l_token_list(i) = 'DESCRIPTION'
                THEN
                    IF o_detailed_desc IS NOT NULL
                    THEN
                        o_detailed_desc := o_detailed_desc || pk_prog_notes_constants.g_comma || o_short_desc;
                    ELSE
                        o_detailed_desc := o_detailed_desc || o_short_desc;
                    END IF;
                ELSIF l_token_list(i) = 'EXAM'
                THEN
                    IF o_detailed_desc IS NOT NULL
                    THEN
                        o_detailed_desc := o_detailed_desc || pk_prog_notes_constants.g_comma || l_desc_exam;
                    ELSE
                        o_detailed_desc := o_detailed_desc || l_desc_exam;
                    END IF;
                ELSIF l_token_list(i) = 'RESULT'
                THEN
                    IF o_detailed_desc IS NOT NULL
                    THEN
                        o_detailed_desc := o_detailed_desc || pk_prog_notes_constants.g_comma || l_interpretation;
                    ELSE
                        o_detailed_desc := o_detailed_desc || l_interpretation;
                    END IF;
                END IF;
            END LOOP;
        
            o_short_desc := o_detailed_desc;
        
        ELSE
            o_short_desc := '(' || pk_date_utils.date_char_tsz(i_lang, l_exec_date, i_prof.institution, i_prof.software) || ') ' ||
                            pk_translation.get_translation(i_lang, i_code_description) || l_result_notes || CASE
                                WHEN l_notes_result IS NOT NULL
                                     AND dbms_lob.compare(l_notes_result, empty_clob()) > 0 THEN
                                 l_notes_result
                            END;
        
            o_detailed_desc := o_short_desc;
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
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_exam_result_descs;

    /**
    * Get the habits description.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task                Task id
    * @param o_detailed_desc          Detailed desc for more info and note
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          09-Feb-2012
    */
    FUNCTION get_habit_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task          IN epis_pn_det_task.id_task%TYPE,
        i_short_desc       IN CLOB,
        i_code_description task_timeline_ea.code_description%TYPE,
        o_detailed_desc    OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name              VARCHAR2(21) := 'GET_HABIT_DESC';
        l_habit_characterization pk_translation.t_desc_translation;
        l_start_date             pk_translation.t_desc_translation;
        l_short_desc             pk_translation.t_desc_translation;
        l_date_and_char          pk_translation.t_desc_translation;
    BEGIN
    
        --because of performance reasons the short and long descs of the exam results will be calculated at the same time
    
        g_error := 'CALL pk_patient.get_pat_habit_info -  i_id_task: ' || i_id_task;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_patient.get_pat_habit_info(i_lang                   => i_lang,
                                             i_prof                   => i_prof,
                                             i_id_pat_habit           => i_id_task,
                                             o_habit_characterization => l_habit_characterization,
                                             o_start_date             => l_start_date,
                                             o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_short_desc := CASE
                            WHEN i_short_desc IS NULL THEN
                             pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_description)
                            ELSE
                             i_short_desc
                        END;
        l_date_and_char := pk_string_utils.surround(i_string  => l_start_date,
                                                    i_pattern => pk_string_utils.g_pattern_parenthesis) || CASE
                               WHEN l_habit_characterization IS NOT NULL THEN
                                pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_hifen ||
                                pk_prog_notes_constants.g_space
                               ELSE
                                NULL
                           END || l_habit_characterization;
    
        o_detailed_desc := l_short_desc || CASE
                               WHEN l_date_and_char IS NOT NULL THEN
                                pk_prog_notes_constants.g_space
                           END || l_date_and_char;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_habit_desc;

    /**
    * Get the task detailed description.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_pn_task_type        Task type id
    * @param i_id_task                Task id
    * @param i_universal_description  Free text in the EA table
    * @param i_short_desc             Short descs: sometimes the sort desc is already calculated 
    *                                 and the detailed desc is based on the short desc
    * @param i_code_description       Code translation
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          25-Aug-2011
    */
    FUNCTION get_detailed_desc_all
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_universal_description IN task_timeline_ea.universal_desc_clob%TYPE,
        i_short_desc            IN CLOB,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
        l_error            t_error_out;
        l_pat_hist_diag    epis_pn_det_task.id_task%TYPE;
        l_desc             CLOB;
        l_dummy            CLOB;
        l_code_description task_timeline_ea.code_description%TYPE := i_code_description;
        l_func_name        VARCHAR2(30 CHAR) := 'GET_DETAILED_DESC_ALL';
    
        l_id_patient NUMBER;
    
    BEGIN
    
        --get the auto-populated data blocks
        g_error := 'get_detailed_desc_all. i_id_pn_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_detailed_desc_all');
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        -- PAST HISTORY
        IF (i_id_task_type IN (pk_prog_notes_constants.g_task_ph_medical_hist,
                               pk_prog_notes_constants.g_task_ph_surgical_hist,
                               pk_prog_notes_constants.g_task_ph_relevant_notes,
                               pk_prog_notes_constants.g_task_ph_treatments,
                               pk_prog_notes_constants.g_task_ph_cong_anomalies,
                               pk_prog_notes_constants.g_task_ph_family_diag,
                               pk_prog_notes_constants.g_task_ph_gynec_diag))
        THEN
            l_pat_hist_diag := i_id_task;
        
            g_error := 'CALL pk_past_history.get_past_hist_rec_desc. i_id_pn_task_type: ' || i_id_task_type ||
                       ' i_id_pat_history_diagnosis: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc := pk_past_history.get_past_hist_rec_desc(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_pat_hist_diag         => l_pat_hist_diag,
                                                             i_pat_ph_ft_hist        => NULL,
                                                             i_flg_description       => i_flg_description,
                                                             i_description_condition => i_description_condition);
        
            -- EXAMS RESULTS 
        ELSIF (i_id_task_type IN
              (pk_prog_notes_constants.g_task_exam_results, pk_prog_notes_constants.g_task_oth_exam_results))
        THEN
            g_error := 'CALL get_exam_result_descs. i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT get_exam_result_descs(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_task               => i_id_task,
                                         i_code_description      => i_code_description,
                                         i_flg_description       => i_flg_description,
                                         i_description_condition => i_description_condition,
                                         i_flg_desc_for_dblock   => pk_prog_notes_constants.g_no,
                                         i_flg_image_exam        => pk_prog_notes_constants.g_no,
                                         o_short_desc            => l_dummy,
                                         o_detailed_desc         => l_desc,
                                         o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- IMAGE EXAMS RESULTS
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_img_exam_results))
        THEN
        
            IF NOT get_exam_result_descs(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_task               => i_id_task,
                                         i_code_description      => i_code_description,
                                         i_flg_description       => i_flg_description,
                                         i_description_condition => i_description_condition,
                                         i_flg_desc_for_dblock   => pk_prog_notes_constants.g_no,
                                         i_flg_image_exam        => pk_prog_notes_constants.g_yes,
                                         o_short_desc            => l_dummy,
                                         o_detailed_desc         => l_desc,
                                         o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSIF (i_id_task_type = pk_prog_notes_constants.g_task_habits)
        THEN
            IF (i_short_desc IS NULL AND i_code_description IS NULL)
            THEN
                g_error := 'GET universal_description. i_id_task: ' || i_id_task || ' i_id_task_type: ' ||
                           i_id_task_type;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                SELECT vpt.code_description
                  INTO l_code_description
                  FROM v_pn_tasks vpt
                 WHERE vpt.id_task = i_id_task
                   AND vpt.id_tl_task = i_id_task_type;
            END IF;
        
            g_error := 'CALL get_habit_desc. i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT get_habit_desc(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_id_task          => i_id_task,
                                  i_short_desc       => i_short_desc,
                                  i_code_description => l_code_description,
                                  o_detailed_desc    => l_desc,
                                  o_error            => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_positioning
        THEN
            g_error := 'PK_INP_POSITIONING.GET_DESCRIPTION';
            l_desc  := pk_inp_positioning.get_description(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_epis_positioning => i_id_task,
                                                          i_desc_type           => pk_prog_notes_constants.g_desc_type_l);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems
        THEN
            g_error := 'pk_problems.get_description_phd';
            l_desc  := pk_problems.get_description_phd(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_id_phd    => i_id_task,
                                                       i_desc_type => i_flg_description);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_allergies
        THEN
            g_error := 'pk_allergy.get_desc_allergy';
            l_desc  := pk_allergy.get_desc_allergy(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_pat_allergy => i_id_task,
                                                   i_desc_type      => pk_prog_notes_constants.g_desc_type_l);
        
            --allergy by type
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_allergies_allergy,
                                 pk_prog_notes_constants.g_task_allergies_adverse,
                                 pk_prog_notes_constants.g_task_allergies_intolerance,
                                 pk_prog_notes_constants.g_task_allergies_propensity)
        THEN
            g_error := 'pk_allergy.get_desc_allergy D';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc := pk_allergy.get_desc_allergy(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_pat_allergy => i_id_task,
                                                  i_desc_type      => pk_prog_notes_constants.g_desc_type_d);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_no_known_allergies
        THEN
            g_error := 'pk_allergy.get_desc_allergy_unaware';
            l_desc  := pk_allergy.get_desc_allergy_unaware(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_id_pat_allergy_unaware => i_id_task,
                                                           i_desc_type              => pk_prog_notes_constants.g_desc_type_l);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_no_known_prob
        THEN
            g_error := 'pk_problems.get_desc_prob_unaware';
            l_desc  := pk_problems.get_desc_prob_unaware(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_pat_prob_unaware => i_id_task,
                                                         i_desc_type           => pk_prog_notes_constants.g_desc_type_l);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_diag
        THEN
            g_error := 'pk_problems.get_description_pp';
            l_desc  := pk_problems.get_description_pp(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_id_pp     => i_id_task,
                                                      i_desc_type => pk_prog_notes_constants.g_desc_type_l);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_surgery
        THEN
            g_error := 'pk_sr_visit.get_desc_surg_proc';
            l_desc  := pk_sr_visit.get_desc_surg_proc(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_episode     => i_id_task,
                                                      i_desc_type      => nvl(i_flg_description,
                                                                              pk_logic_episode.g_desc_type_l),
                                                      i_desc_condition => i_description_condition);
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_medical_appointment,
                                 pk_prog_notes_constants.g_task_nursing_appointment,
                                 pk_prog_notes_constants.g_task_nutrition_appointment,
                                 pk_prog_notes_constants.g_task_rehabilitation,
                                 pk_prog_notes_constants.g_task_social_service,
                                 pk_prog_notes_constants.g_task_psychology,
                                 pk_prog_notes_constants.g_task_speech_therapy,
                                 pk_prog_notes_constants.g_task_occupational_therapy)
        THEN
            g_error := 'pk_consult_req.GET_DESCRIPTION';
            l_desc  := pk_consult_req.get_description(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_consult_req => i_id_task,
                                                      i_desc_type      => pk_prog_notes_constants.g_desc_type_l);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_triage
        THEN
            g_error := 'pk_edis_triage.get_task_description';
            l_desc  := pk_edis_triage.get_task_description(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_epis_triage => i_id_task,
                                                           i_desc_type      => pk_edis_triage.g_desc_type_l);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_mtos_score
        THEN
            g_error := 'pk_sev_scores_core.GET_task_DESCRIPTION';
            l_desc  := pk_sev_scores_core.get_task_description(i_lang                  => i_lang,
                                                               i_prof                  => i_prof,
                                                               i_id_epis_mtos_score    => i_id_task,
                                                               i_desc_type             => pk_sev_scores_core.g_desc_type_l,
                                                               i_flg_description       => i_flg_description,
                                                               i_description_condition => i_description_condition);
            -- Consults
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_opinion,
                                 pk_prog_notes_constants.g_task_opinion_die,
                                 pk_prog_notes_constants.g_task_opinion_sw,
                                 pk_prog_notes_constants.g_task_opinion_cm,
                                 pk_prog_notes_constants.g_task_opinion_at,
                                 pk_prog_notes_constants.g_task_opinion_psy,
                                 pk_prog_notes_constants.g_task_opinion_speech,
                                 pk_prog_notes_constants.g_task_opinion_occupational,
                                 pk_prog_notes_constants.g_task_opinion_physical,
                                 pk_prog_notes_constants.g_task_opinion_cdc,
                                 pk_prog_notes_constants.g_task_opinion_mental,
                                 pk_prog_notes_constants.g_task_opinion_religious,
                                 pk_prog_notes_constants.g_task_opinion_rehabilitation)
        THEN
            g_error := 'PK_OPINION.GET_SP_DESCRIPTION - FULL DESC';
            l_desc  := pk_opinion.get_sp_consult_desc(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_opinion               => i_id_task,
                                                      i_opinion_type          => pk_ea_logic_opinion.get_id_op_type_from_id_tt(i_id_task_type),
                                                      i_flg_description       => i_flg_description,
                                                      i_description_condition => i_description_condition,
                                                      i_flg_desc_for_dblock   => pk_alert_constant.g_no,
                                                      i_flg_short             => pk_alert_constant.g_no);
            -- Discharge instructions
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_disch_instructions
        THEN
            g_error := 'PK_DISCHARGE.GET_SP_DISCH_INSTR_DESC - FULL DESC';
            l_desc  := pk_discharge.get_sp_disch_instr_desc(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_disch_notes        => i_id_task,
                                                            i_flg_short             => pk_alert_constant.g_no,
                                                            i_desc_type             => i_flg_description,
                                                            i_description_condition => i_description_condition);
        
            --procedures
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_procedures
        THEN
            g_error := 'CALL pk_prog_notes_in.get_procedures_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_in.get_procedures_desc(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_id_interv_presc_det   => i_id_task,
                                                        i_flg_description       => i_flg_description,
                                                        i_description_condition => i_description_condition,
                                                        o_short_desc            => l_dummy,
                                                        o_long_desc             => l_desc,
                                                        o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
            --patient education
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_pat_education
        THEN
            g_error := 'CALL pk_prog_notes_in.get_pat_education_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_in.get_pat_education_desc(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_id_nurse_tea_req      => i_id_task,
                                                           i_flg_description       => i_flg_description,
                                                           i_description_condition => i_description_condition,
                                                           o_short_desc            => l_dummy,
                                                           o_long_desc             => l_desc,
                                                           o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
            --cits
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_cits
        THEN
            g_error := 'CALL pk_cit.get_cit_det_description';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc := pk_cit.get_cit_det_description(i_lang => i_lang, i_prof => i_prof, i_cit => i_id_task);
        ELSIF (i_id_task_type = pk_prog_notes_constants.g_task_ph_free_txt)
        THEN
        
            IF (i_universal_description IS NULL)
            THEN
                g_error := 'GET universal_description. i_id_task: ' || i_id_task || ' i_id_task_type: ' ||
                           i_id_task_type;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                SELECT vpt.universal_desc_clob
                  INTO l_desc
                  FROM v_pn_tasks vpt
                 WHERE vpt.id_task = i_id_task
                   AND vpt.id_tl_task = i_id_task_type;
            ELSE
                l_desc := i_universal_description;
            END IF;
            --comunication orders
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_communications
        THEN
            g_error := 'CALL PK_COMM_ORDERS_DB.get_comm_orders_req_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc := pk_comm_orders_db.get_comm_order_req_desc(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_id_comm_order_req     => i_id_task,
                                                                i_description_condition => i_description_condition,
                                                                i_flg_desc_for_dblock   => pk_alert_constant.g_no);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_cits_procedures
        THEN
            g_error := 'CALL  pk_aih.get_aih_simple_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc := pk_aih.get_aih_simple_desc(i_lang => i_lang, i_prof => i_prof, i_id_aih_simple => i_id_task);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_cits_procedures_special
        THEN
            g_error := 'CALL pk_aih.get_aih_special_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_desc := pk_aih.get_aih_special_desc(i_lang => i_lang, i_prof => i_prof, i_id_aih_special => i_id_task);
        
            -- Lab Orders Results                                                                
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_lab_results
        THEN
            g_error := 'CALL pk_lab_tests_external_api_db.get_lab_test_result_desc - i_id_task_type: ' ||
                       i_id_task_type || ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_lab_tests_external_api_db.get_lab_test_result_desc(i_lang                   => i_lang,
                                                                         i_prof                   => i_prof,
                                                                         i_id_analysis_result_par => i_id_task,
                                                                         i_description_condition  => i_description_condition,
                                                                         i_flg_desc_for_dblock    => pk_alert_constant.g_no,
                                                                         o_description            => l_desc,
                                                                         o_error                  => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_lab
              AND i_description_condition IS NOT NULL
        THEN
            g_error := 'CALL pk_lab_tests_external.get_lab_test_order_desc - i_id_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF NOT pk_lab_tests_external.get_lab_test_order_cond_desc(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_id_analysis_req_det   => i_id_task,
                                                                      i_description_condition => i_description_condition,
                                                                      i_flg_desc_for_dblock   => pk_alert_constant.g_no,
                                                                      o_description           => l_desc,
                                                                      o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_episode
        THEN
            g_error := 'CALL pk_lab_tests_external.get_lab_test_order_desc - i_id_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_desc := pk_problems.get_epis_prob_description(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_problems           => i_id_task,
                                                            i_flg_desc_for_dblock   => pk_alert_constant.g_no,
                                                            i_flg_description       => i_flg_description,
                                                            i_description_condition => i_description_condition);
            -- GROUP PROBLEMS ASSESSMENT
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_group_ass
        THEN
            g_error := 'CALL pk_lab_tests_external.get_lab_test_order_desc - i_id_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_desc := pk_problems.get_prob_group_description(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_id_group_ass          => i_id_task,
                                                             i_flg_desc_for_dblock   => pk_alert_constant.g_no,
                                                             i_flg_description       => i_flg_description,
                                                             i_description_condition => i_description_condition);
        
        ELSIF (i_id_task_type = pk_prog_notes_constants.g_task_other_exams_req)
        THEN
            g_error := 'pk_sev_scores_core.GET_task_DESCRIPTION';
            l_desc  := pk_prog_notes_in.get_lab_exam_order_description(i_lang                  => i_lang,
                                                                       i_prof                  => i_prof,
                                                                       i_id_task_type          => i_id_task_type,
                                                                       i_id_task               => i_id_task,
                                                                       i_code_description      => NULL,
                                                                       i_flg_sos               => NULL,
                                                                       i_dt_begin              => NULL,
                                                                       i_id_task_aggregator    => NULL,
                                                                       i_code_desc_sample_type => NULL,
                                                                       i_flg_description       => i_flg_description,
                                                                       i_description_condition => i_description_condition);
        
        END IF;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_detailed_desc_all',
                                              l_error);
        
            RETURN NULL;
    END get_detailed_desc_all;

    /**
    * Get the task short description for Lab and Exam Orders
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_task_type           Task type identifier
    * @param       i_id_task                Task identifier
    * @param       i_code_description       Code translation to the task description
    * @param       i_flg_sos                Flag SOS/PRN
    * @param       i_dt_begin               Lab/Exam order begin date
    * @param       i_id_task_aggregator     Task Aggregator identifier
    * @param       i_flg_status             Task flg_status
    * @param       i_code_desc_sample_type  Sample type code description
    *
    * @return                               Lab detailed description
    *
    * @value       i_flg_sos                {*} 'Y'- Yes {*} 'N'- No
    *
    * @author                               António Neto
    * @version                              2.6.2
    * @since                                30-Jan-2012
    */
    FUNCTION get_lab_exam_order_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_sos               IN task_timeline_ea.flg_sos%TYPE,
        i_dt_begin              IN task_timeline_ea.dt_begin%TYPE,
        i_id_task_aggregator    IN task_timeline_ea.id_task_aggregator%TYPE,
        i_code_desc_sample_type IN task_timeline_ea.code_desc_sample_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
    
        l_id_task         epis_pn_det_task.id_task%TYPE;
        l_category        VARCHAR(1000 CHAR);
        l_order_date_time TIMESTAMP;
        l_desc_temp       CLOB;
        l_description     CLOB;
        l_status          pk_translation.t_desc_translation;
        l_instructions    VARCHAR2(1000 CHAR);
        l_exec            VARCHAR2(4000);
    
        l_error              t_error_out;
        l_tbl_desc_condition table_varchar;
    BEGIN
        IF i_id_task_type = pk_prog_notes_constants.g_task_lab
           AND i_description_condition IS NOT NULL
        THEN
        
            IF NOT pk_lab_tests_external.get_lab_test_order_cond_desc(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_id_analysis_req_det   => i_id_task,
                                                                      i_description_condition => i_description_condition,
                                                                      i_flg_desc_for_dblock   => 'Y',
                                                                      o_description           => l_description,
                                                                      o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
        
            IF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab, pk_prog_notes_constants.g_task_lab_recur))
            THEN
                g_error := 'Get Analysis description: ' || i_code_description;
                pk_alertlog.log_debug(g_error);
                l_description := pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                           i_prof,
                                                                           pk_lab_tests_constant.g_analysis_alias,
                                                                           i_code_description,
                                                                           i_code_desc_sample_type,
                                                                           NULL);
            ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_img_exams_req,
                                      pk_prog_notes_constants.g_task_other_exams_req,
                                      pk_prog_notes_constants.g_task_img_exam_recur,
                                      pk_prog_notes_constants.g_task_other_exams_recur))
            THEN
                g_error := 'Get exam description: ' || i_code_description;
                pk_alertlog.log_debug(g_error);
            
                l_description := pk_exams_api_db.get_alias_translation(i_lang          => i_lang,
                                                                       i_prof          => i_prof,
                                                                       i_code_exam     => i_code_description,
                                                                       i_dep_clin_serv => NULL);
            
            END IF;
        
            g_error := 'Check i_id_task_type is a recurrence: ' || i_id_task_type;
            pk_alertlog.log_debug(g_error);
            IF i_id_task_type = pk_prog_notes_constants.g_task_lab_recur
            THEN
                g_error := 'CALL get_lab_req_det_by_id_recurr: ' || i_id_task_aggregator;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_lab_tests_external_api_db.get_lab_req_det_by_id_recurr(i_lang             => i_lang,
                                                                                 i_prof             => i_prof,
                                                                                 i_order_recurrence => i_id_task_aggregator,
                                                                                 o_analysis_req_det => l_id_task,
                                                                                 o_error            => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'CALL get_lab_test_task_instructions';
                IF NOT pk_lab_tests_external_api_db.get_lab_test_task_instructions(i_lang              => i_lang,
                                                                                   i_prof              => i_prof,
                                                                                   i_task_request      => NULL,
                                                                                   i_task_request_det  => l_id_task,
                                                                                   o_task_instructions => l_instructions,
                                                                                   o_error             => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_description := l_description || CASE
                                     WHEN l_instructions IS NOT NULL THEN
                                      pk_prog_notes_constants.g_flg_sep || l_instructions
                                     ELSE
                                      NULL
                                 END;
            END IF;
        
            g_error := 'Check i_id_task_type is a recurrence: ' || i_id_task_type;
            pk_alertlog.log_debug(g_error);
            IF i_id_task_type IN
               (pk_prog_notes_constants.g_task_img_exam_recur, pk_prog_notes_constants.g_task_other_exams_recur)
            THEN
                g_error := 'CALL get_exam_req_det_by_id_recurr: ' || i_id_task_aggregator;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_exams_external_api_db.get_exam_req_det_by_id_recurr(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_order_recurrence => i_id_task_aggregator,
                                                                              o_exam_req_det     => l_id_task,
                                                                              o_error            => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'CALL get_exam_task_instructions';
                IF NOT pk_exams_external_api_db.get_exam_task_instructions(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_task_request      => NULL,
                                                                           i_task_request_det  => l_id_task,
                                                                           o_task_instructions => l_instructions,
                                                                           o_error             => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_description := l_description || CASE
                                     WHEN l_instructions IS NOT NULL THEN
                                      pk_prog_notes_constants.g_flg_sep || l_instructions
                                     ELSE
                                      NULL
                                 END;
            END IF;
        
            IF (i_id_task_type IN
               (pk_prog_notes_constants.g_task_img_exams_req, pk_prog_notes_constants.g_task_other_exams_req))
            THEN
            
                IF i_flg_description IS NULL
                THEN
                    g_error := 'CALL get_status_desc';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_exams_external_api_db.get_exam_status_desc(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_id_exam_req_det => i_id_task,
                                                                         o_status          => l_status,
                                                                         o_error           => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF l_description IS NULL
                    THEN
                        l_description := pk_exam_external.get_exam_description(i_lang         => i_lang,
                                                                               i_prof         => i_prof,
                                                                               i_exam_req_det => i_id_task,
                                                                               i_co_sign_hist => NULL);
                    END IF;
                
                    g_error := 'CALL get_exam_task_instructions';
                    IF NOT pk_exams_external_api_db.get_exam_task_instructions(i_lang              => i_lang,
                                                                               i_prof              => i_prof,
                                                                               i_task_request      => NULL,
                                                                               i_task_request_det  => i_id_task,
                                                                               o_task_instructions => l_instructions,
                                                                               o_error             => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_description := l_description || CASE
                                         WHEN l_instructions IS NOT NULL THEN
                                          pk_prog_notes_constants.g_flg_sep || l_instructions
                                         ELSE
                                          NULL
                                     END || pk_prog_notes_constants.g_flg_sep || l_status;
                
                ELSIF i_flg_description = pk_prog_notes_constants.g_flg_description_c
                THEN
                    l_description := NULL;
                    l_desc_temp   := pk_exam_external.get_exam_description(i_lang         => i_lang,
                                                                           i_prof         => i_prof,
                                                                           i_exam_req_det => i_id_task,
                                                                           i_co_sign_hist => NULL);
                
                    l_order_date_time := pk_exam_external.get_exam_date_to_order(i_lang         => i_lang,
                                                                                 i_prof         => i_prof,
                                                                                 i_exam_req_det => i_id_task,
                                                                                 i_co_sign_hist => NULL);
                
                    l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
                
                    IF (i_id_task_type = pk_prog_notes_constants.g_task_other_exams_req)
                    THEN
                        l_category := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T1489');
                    ELSIF i_id_task_type = pk_prog_notes_constants.g_task_img_exams_req
                    THEN
                        l_category := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T191');
                    END IF;
                
                    FOR i IN 1 .. l_tbl_desc_condition.last
                    LOOP
                        IF l_tbl_desc_condition(i) = 'CATEGORY'
                        THEN
                            IF l_description IS NOT NULL
                            THEN
                                l_description := l_description || pk_prog_notes_constants.g_space || l_category;
                            ELSE
                                l_description := l_description || l_category;
                            END IF;
                        ELSIF l_tbl_desc_condition(i) = 'EXAM'
                        THEN
                            IF l_description IS NOT NULL
                            THEN
                                l_description := l_description || pk_prog_notes_constants.g_space || l_desc_temp;
                            ELSE
                                l_description := l_description || l_desc_temp;
                            END IF;
                        ELSIF l_tbl_desc_condition(i) = 'ORDER-DATE'
                        THEN
                            IF l_description IS NOT NULL
                            THEN
                                l_description := l_description || pk_prog_notes_constants.g_comma ||
                                                 pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                             i_date => l_order_date_time,
                                                                             i_inst => i_prof.institution,
                                                                             i_soft => i_prof.software);
                            ELSE
                                l_description := l_description ||
                                                 pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                             i_date => l_order_date_time,
                                                                             i_inst => i_prof.institution,
                                                                             i_soft => i_prof.software);
                            END IF;
                        END IF;
                    END LOOP;
                ELSE
                    g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.GET_EXAM_EXEC_DATE';
                    pk_alertlog.log_debug(g_error);
                    l_exec := pk_exams_external_api_db.get_exam_exec_date(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_exam_req_det => i_id_task);
                
                    l_description := CASE
                                         WHEN l_exec IS NOT NULL THEN
                                          '(' || l_exec || ') '
                                         ELSE
                                          NULL
                                     END || l_description;
                
                END IF;
            
            ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab))
            THEN
                g_error := 'CALL get_analysis_status_desc';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_lab_tests_external_api_db.get_analysis_status_desc(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_analysis_req_det => i_id_task,
                                                                             o_status              => l_status,
                                                                             o_error               => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'CALL get_lab_test_task_instructions';
                IF NOT pk_lab_tests_external_api_db.get_lab_test_task_instructions(i_lang              => i_lang,
                                                                                   i_prof              => i_prof,
                                                                                   i_task_request      => NULL,
                                                                                   i_task_request_det  => i_id_task,
                                                                                   o_task_instructions => l_instructions,
                                                                                   o_error             => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_description := l_description || CASE
                                     WHEN l_instructions IS NOT NULL THEN
                                      pk_prog_notes_constants.g_flg_sep || l_instructions
                                     ELSE
                                      NULL
                                 END || pk_prog_notes_constants.g_flg_sep || l_status;
            END IF;
        END IF;
    
        RETURN l_description;
    
    END get_lab_exam_order_description;

    /**
    * Get the task short description for Chief Complaint
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_task                Task identifier
    * @param       i_id_task_type           Task type identifier
    * @param       i_code_description       Code translation to the task description
    * @param       i_universal_desc_clob    Universal description
    *
    * @return                               Chief Complaint description
    *
    * @author                               António Neto
    * @version                              2.6.2
    * @since                                15-Feb-2012
    */
    FUNCTION get_complaint_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char,
        i_universal_desc_clob   IN task_timeline_ea.universal_desc_clob%TYPE,
        o_description           OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_description CLOB;
        l_scope_chief_complaint CONSTANT VARCHAR(30 CHAR) := 'COMPLAINTDOCTOR_T014';
    
        --       l_multiple_selection sys_config.value%TYPE := pk_sysconfig.get_config('CHIEF_COMPLAINT_MULTIPLE_SELECTION',                                                                              i_prof);
    
        l_description_cond_array table_varchar;
    BEGIN
    
        g_error := 'Check free text complaint';
        IF i_universal_desc_clob IS NOT NULL
           AND i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint_anm
        THEN
            l_description := i_universal_desc_clob;
        END IF;
    
        IF i_flg_description = pk_prog_notes_constants.g_desc_type_c
           AND i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint
        THEN
            IF i_description_condition IS NOT NULL
            THEN
                l_description_cond_array := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
                <<lup_thru_conditions>>
                FOR i IN 1 .. l_description_cond_array.count
                LOOP
                    IF l_description_cond_array(i) = 'ARABIC'
                    THEN
                        l_description := pk_complaint.get_arabic_complaint(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_id_epis_complaint => i_id_task);
                    END IF;
                END LOOP lup_thru_conditions;
            ELSE
            
                /*                    IF i_flg_desc_for_dblock = pk_prog_notes_constants.g_yes
                   AND l_multiple_selection = pk_prog_notes_constants.g_no
                THEN
                        l_description := pk_message.get_message(i_lang      => i_lang,
                                                                i_code_mess => l_scope_chief_complaint) ||
                                     pk_prog_notes_constants.g_colon ||
                                         pk_translation.get_translation(i_lang      => i_lang,
                                                                        i_code_mess => i_code_description) ||
                                     pk_prog_notes_constants.g_enter || l_description;
                
                ELSIF i_flg_desc_for_dblock = pk_prog_notes_constants.g_yes
                      AND l_multiple_selection = pk_prog_notes_constants.g_yes
                    THEN*/
                l_description := pk_complaint.get_complaint_desc_sp(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_id_epis_complaint => i_id_task);
                /*   l_description := pk_complaint.get_multi_complaint_desc(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_id_epis_complaint => i_id_task);
                                      pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_description) || CASE
                                     WHEN l_description IS NOT NULL THEN
                                      pk_prog_notes_constants.g_comma || l_description
                                     ELSE
                                      pk_prog_notes_constants.g_period
                END;*/
                --    END IF;
            END IF;
        ELSE
            IF i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint
            THEN
                l_description := pk_complaint.get_complaint_desc_sp(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_id_epis_complaint => i_id_task);
            END IF;
            /*                l_description := l_description ||
            pk_message.get_message(i_lang => i_lang, i_code_mess => l_scope_chief_complaint) ||
            pk_prog_notes_constants.g_colon ||
            pk_complaint.get_multi_complaint_desc(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_epis_complaint => i_id_task);*/
        END IF;
    
        o_description := l_description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMPLAINT_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_complaint_description;

    /**
    * Get the task description for Diagnosis
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_epis_diagnosis      Episode Diagnosis identifier
    *
    * @return                               Diagnosis detailed description
    *
    * @author                               ANTONIO.NETO
    * @version                              2.6.2
    * @since                                22-Mar-2012
    */
    FUNCTION get_diagnosis_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_diagnosis     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
    
        l_description    CLOB;
        l_desc_diagnosis CLOB;
        l_desc_status    CLOB;
        l_notes          CLOB;
        l_flg_final_type epis_diagnosis.flg_final_type%TYPE;
        l_title_msg      VARCHAR2(1000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_code_mess => 'PN_M030');
    
        l_rec_diag           pk_edis_types.rec_epis_diagnosis;
        l_tbl_desc_condition table_varchar;
        l_complications      pk_translation.t_desc_translation;
        l_dt_init            VARCHAR2(200 CHAR);
    BEGIN
    
        g_error    := 'CALL PK_DIAGNOSIS.GET_EPIS_DIAG ' || i_id_epis_diagnosis;
        l_rec_diag := pk_diagnosis.get_epis_diag(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_id_episode,
                                                 i_epis_diag      => i_id_epis_diagnosis,
                                                 i_epis_diag_hist => NULL);
    
        l_desc_diagnosis := l_rec_diag.desc_diagnosis;
        l_notes          := l_rec_diag.diag_notes;
        l_desc_status    := l_rec_diag.desc_status;
        l_flg_final_type := l_rec_diag.flg_final_type;
        l_dt_init        := l_rec_diag.dt_initial_diag_chr;
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_tbl_desc_condition.last
            LOOP
                IF l_tbl_desc_condition(i) = 'DIAG_DESC'
                THEN
                    l_description := l_description || l_desc_diagnosis;
                ELSIF l_tbl_desc_condition(i) = 'COMPLICATIONS'
                THEN
                    l_complications := pk_complication.get_complications_desc_serial(i_lang              => i_lang,
                                                                                     i_prof              => i_prof,
                                                                                     i_id_epis_diagnosis => i_id_epis_diagnosis);
                    IF (l_complications IS NOT NULL)
                    THEN
                        l_description := l_description || chr(10) ||
                                         pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMPLICATION_MSG001') ||
                                         pk_prog_notes_constants.g_colon || pk_prog_notes_constants.g_space ||
                                         l_complications;
                    END IF;
                ELSIF l_tbl_desc_condition(i) = 'DT_INIT'
                THEN
                
                    l_description := l_description || pk_prog_notes_constants.g_space ||
                                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIAGNOSIS_M058') ||
                                     pk_prog_notes_constants.g_space ||
                                     nvl(l_dt_init, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_tbl_desc_condition(i) = 'STATUS'
                THEN
                    IF l_desc_status IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_space ||
                                         pk_prog_notes_constants.g_open_parenthesis || l_desc_status ||
                                         pk_prog_notes_constants.g_close_parenthesis;
                    END IF;
                ELSIF l_tbl_desc_condition(i) = 'STATUS_TYPE'
                THEN
                    IF l_desc_status IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_space ||
                                         pk_prog_notes_constants.g_open_parenthesis;
                    
                        IF l_flg_final_type = pk_diagnosis.g_flg_final_type_p
                        THEN
                            l_description := l_description ||
                                             pk_message.get_message(i_lang, i_prof, 'DIAGNOSIS_FINAL_T017') ||
                                             pk_prog_notes_constants.g_comma;
                        END IF;
                        l_description := l_description || l_desc_status || pk_prog_notes_constants.g_close_parenthesis;
                    END IF;
                END IF;
            END LOOP;
        ELSE
            IF l_desc_diagnosis IS NOT NULL
            THEN
                l_description := l_desc_diagnosis || pk_prog_notes_constants.g_colon || l_desc_status ||
                                 pk_prog_notes_constants.g_period;
            
                IF l_notes IS NOT NULL
                THEN
                    l_description := l_description || l_title_msg || pk_prog_notes_constants.g_space || l_notes ||
                                     pk_prog_notes_constants.g_period;
                END IF;
            
                IF l_flg_final_type = pk_diagnosis.g_flg_final_type_p
                THEN
                    l_description := l_description || pk_message.get_message(i_lang, i_prof, 'DIAGNOSIS_FINAL_T017') ||
                                     pk_prog_notes_constants.g_period;
                END IF;
            ELSE
                l_description := NULL;
            END IF;
        END IF;
    
        RETURN l_description;
    END get_diagnosis_desc;

    /**
    * Get the task description for procedures
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_interv_presc_det    Procedure task ID
    * @param       o_short_desc             Procedure task short description
    * @param       o_long_desc              Procedure task long descripton
    *
    * @return                               sucess/error
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                10-Set-2012
    */
    FUNCTION get_procedures_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_interv_presc_det   IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT CLOB,
        o_long_desc             OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_info         pk_types.cursor_type;
        l_id_interv_presc_det interv_presc_det.id_interv_presc_det%TYPE;
        l_status              interv_presc_det.flg_status%TYPE;
        l_desc_status         pk_translation.t_desc_translation;
        l_proc_description    CLOB;
        l_instructions        CLOB;
        l_id_intervention     intervention.id_intervention%TYPE;
        l_desc_time           pk_translation.t_desc_translation;
        l_notes               CLOB;
        l_exec_date           pk_translation.t_desc_translation;
        l_start_date          VARCHAR2(50 CHAR);
        l_token_list          table_varchar;
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_INFO. i_ID_INTERV_PRESC_DET: ' ||
                   i_id_interv_presc_det;
        IF NOT pk_procedures_external_api_db.get_procedure_info(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_interv_presc_det => i_id_interv_presc_det,
                                                                o_interv           => l_interv_info,
                                                                o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_interv_info
            INTO l_id_interv_presc_det,
                 l_status,
                 l_desc_status,
                 l_proc_description,
                 l_instructions,
                 l_id_intervention,
                 l_desc_time,
                 l_notes,
                 l_exec_date,
                 l_start_date;
        CLOSE l_interv_info;
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'START-DATE'
                   AND l_start_date IS NOT NULL
                THEN
                    IF o_short_desc IS NULL
                    THEN
                        o_short_desc := l_start_date;
                    ELSE
                        o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_start_date;
                    END IF;
                    IF i = 1
                    THEN
                        o_short_desc := o_short_desc || pk_prog_notes_constants.g_space;
                    END IF;
                ELSIF l_token_list(i) = 'DESCRIPTION'
                      AND l_proc_description IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || l_proc_description;
                ELSIF l_token_list(i) = 'INSTRUCTION'
                      AND l_instructions IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_instructions;
                ELSIF l_token_list(i) = 'NOTES'
                      AND l_notes IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_notes;
                END IF;
            END LOOP;
            o_long_desc := o_short_desc;
        ELSE
            IF i_flg_description IS NULL
            THEN
                o_short_desc := l_proc_description || pk_prog_notes_constants.g_flg_sep || l_desc_status;
            
                o_long_desc := l_proc_description || pk_prog_notes_constants.g_flg_sep || l_desc_status ||
                               pk_prog_notes_constants.g_flg_sep || l_desc_time || CASE
                                   WHEN l_instructions IS NOT NULL THEN
                                    pk_prog_notes_constants.g_semicolon || l_instructions
                                   ELSE
                                    NULL
                               END;
            ELSE
                o_short_desc := CASE
                                    WHEN l_exec_date IS NOT NULL THEN
                                     '(' || l_exec_date || ') '
                                END || l_proc_description;
            
                o_long_desc := o_short_desc;
            END IF;
        
            IF (l_notes IS NOT NULL)
            THEN
                o_long_desc := o_long_desc || pk_prog_notes_constants.g_flg_sep ||
                               pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T022') ||
                               pk_prog_notes_constants.g_colon ||
                               REPLACE(REPLACE(l_notes,
                                               pk_prog_notes_constants.g_open_bold_html,
                                               pk_prog_notes_constants.g_space),
                                       pk_prog_notes_constants.g_close_bold_html,
                                       pk_prog_notes_constants.g_space);
            END IF;
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
                                              'get_procedures_desc',
                                              o_error);
        
            RETURN NULL;
    END get_procedures_desc;

    /**
    * Get the task description for patient education
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_interv_presc_det    patient education task ID
    * @param       o_short_desc             patient education task short description
    * @param       o_long_desc              patient education task long descripton
    *
    * @return                               sucess/error
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                10-Set-2012
    */
    FUNCTION get_pat_education_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_nurse_tea_req      IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT CLOB,
        o_long_desc             OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_edu_info     pk_types.cursor_type;
        l_id_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
        l_status           nurse_tea_req.flg_status%TYPE;
        l_desc_status      pk_translation.t_desc_translation;
        l_description      CLOB;
        l_instructions     CLOB;
        l_notes            CLOB;
        l_start_date       VARCHAR2(50 CHAR);
        l_token_list       table_varchar;
        l_add_resources    VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'CALL PK_PATIENT_EDUCATION_API_DB.GET_PAT_EDUCATION_INFO. i_id_nurse_tea_req: ' ||
                   i_id_nurse_tea_req;
        IF NOT pk_patient_education_api_db.get_pat_education_info(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_nurse_tea_req => i_id_nurse_tea_req,
                                                                  o_pat_edu_info  => l_pat_edu_info,
                                                                  o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_pat_edu_info
            INTO l_id_nurse_tea_req,
                 l_status,
                 l_desc_status,
                 l_description,
                 l_instructions,
                 l_notes,
                 l_start_date,
                 l_add_resources;
        CLOSE l_pat_edu_info;
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'START-DATE'
                   AND l_start_date IS NOT NULL
                THEN
                    IF o_short_desc IS NULL
                    THEN
                        o_short_desc := l_start_date;
                    ELSE
                        o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_start_date;
                    END IF;
                    IF i = 1
                    THEN
                        o_short_desc := o_short_desc || pk_prog_notes_constants.g_space;
                    END IF;
                ELSIF l_token_list(i) = 'DESCRIPTION'
                      AND l_description IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || l_description;
                ELSIF l_token_list(i) = 'INSTRUCTION'
                      AND l_instructions IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_instructions;
                ELSIF l_token_list(i) = 'NOTES'
                      AND l_notes IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_notes;
                ELSIF l_token_list(i) = 'ADD_RESOURCES'
                      AND l_add_resources IS NOT NULL
                THEN
                    o_short_desc := o_short_desc || pk_prog_notes_constants.g_comma || l_add_resources;
                END IF;
            END LOOP;
            o_long_desc := o_short_desc;
        ELSE
            o_short_desc := l_description || pk_prog_notes_constants.g_flg_sep || l_desc_status;
        
            o_long_desc := l_description || CASE
                               WHEN l_instructions IS NOT NULL THEN
                                pk_prog_notes_constants.g_flg_sep || l_instructions
                               ELSE
                                NULL
                           END || pk_prog_notes_constants.g_flg_sep || l_desc_status;
        
            IF (l_notes IS NOT NULL)
            THEN
                o_long_desc := o_long_desc || pk_prog_notes_constants.g_flg_sep ||
                               pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T022') ||
                               pk_prog_notes_constants.g_colon || l_notes;
            END IF;
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
                                              'GET_PAT_EDUCATION_DESC',
                                              o_error);
        
            RETURN NULL;
    END get_pat_education_desc;

    /**
    * Get the description for procedures executions
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_code_description       Code translation to the task description
    * @param       i_universal_desc_clob    Large Description created by the user
    * @param       i_code_status            Code translation for status description
    * @param       i_flg_status             Status of the execution
    * @param       i_start_date             Execution start date
    * @param       i_end_date               Execution end date
    * @param       i_dt_req                 Date in which the record was registered in the system
    * @param       i_id_task_notes          Id_epis_documentation of the notes record
    * @param       o_short_desc             patient education task short description
    * @param       o_long_desc              patient education task long descripton
    *
    * @return                               sucess/error
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                16-Nov-2012
    */
    FUNCTION get_procedures_execs_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_code_description    IN task_timeline_ea.code_description%TYPE,
        i_universal_desc_clob IN task_timeline_ea.universal_desc_clob%TYPE,
        i_code_status         IN task_timeline_ea.code_status%TYPE,
        i_flg_status          IN task_timeline_ea.flg_status_req%TYPE,
        i_start_date          IN task_timeline_ea.dt_begin%TYPE,
        i_end_date            IN task_timeline_ea.dt_end%TYPE,
        i_dt_req              IN task_timeline_ea.dt_req%TYPE,
        i_id_task_notes       IN task_timeline_ea.id_task_notes%TYPE,
        o_short_desc          OUT CLOB,
        o_long_desc           OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_short_desc := pk_translation.get_translation(i_code_mess => i_code_description, i_lang => i_lang) || --
                        pk_prog_notes_constants.g_flg_sep ||
                       -- pk_translation.get_translation(i_code_mess => i_code_status, i_lang => i_lang) || --
                        CASE
                            WHEN i_start_date IS NOT NULL THEN
                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROCEDURES_T042') ||
                             pk_prog_notes_constants.g_colon || --                        
                             pk_date_utils.date_char_tsz(i_lang, i_start_date, i_prof.institution, i_prof.software)
                            ELSE
                             ''
                        END || --
                        CASE
                            WHEN i_end_date IS NOT NULL THEN
                             pk_prog_notes_constants.g_semicolon || --
                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROCEDURES_T043') ||
                             pk_prog_notes_constants.g_colon || --
                             pk_date_utils.date_char_tsz(i_lang, i_end_date, i_prof.institution, i_prof.software)
                            ELSE
                             ''
                        END || pk_prog_notes_constants.g_semicolon ||
                        pk_sysdomain.get_domain(i_lang => i_lang, i_val => i_flg_status, i_code_dom => i_code_status);
    
        IF (i_universal_desc_clob IS NOT NULL)
        THEN
            o_long_desc := o_short_desc || pk_prog_notes_constants.g_flg_sep ||
                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T022') ||
                           pk_prog_notes_constants.g_colon || i_universal_desc_clob;
        ELSE
            o_long_desc := o_short_desc;
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
                                              'GET_PROCEDURES_EXECS_DESC',
                                              o_error);
        
            RETURN NULL;
    END get_procedures_execs_desc;

    FUNCTION get_rehab_treat_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_rehab_presc        IN rehab_presc.id_rehab_presc%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_dt_begin              IN task_timeline_ea.dt_begin%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
    
        l_description       CLOB;
        l_desc_rehab_treat  CLOB;
        l_desc_rehab_area   CLOB;
        l_desc_priority     VARCHAR2(4000);
        l_frequency_desc    CLOB;
        l_id_rehab_sch_need rehab_sch_need.id_rehab_sch_need%TYPE;
        l_no_session_desc   CLOB;
        l_dt_begin_desc     CLOB;
    
        l_status           sys_domain.desc_val%TYPE;
        l_last_session_msg VARCHAR(1000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'REP_REFERRAL_014');
        dt_exec_end        rehab_session.dt_end%TYPE;
    BEGIN
    
        l_desc_rehab_treat := pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i_code_description, NULL);
    
        SELECT rp.id_rehab_sch_need, pk_translation.get_translation(i_lang, ra.code_rehab_area)
          INTO l_id_rehab_sch_need, l_desc_rehab_area
          FROM rehab_presc rp
          JOIN rehab_sch_need rsn
            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
          JOIN rehab_area_interv rai
            ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
          JOIN rehab_area ra
            ON rai.id_rehab_area = ra.id_rehab_area
         WHERE rp.id_rehab_presc = i_id_rehab_presc;
    
        l_desc_priority   := pk_rehab.get_instructions(i_lang, i_prof, l_id_rehab_sch_need, 'P');
        l_frequency_desc  := pk_rehab.get_instructions(i_lang, i_prof, l_id_rehab_sch_need, 'F');
        l_no_session_desc := pk_rehab.get_instructions(i_lang, i_prof, l_id_rehab_sch_need, 'S');
        l_dt_begin_desc   := pk_rehab.get_instructions(i_lang, i_prof, l_id_rehab_sch_need, 'D');
    
        BEGIN
            SELECT t.dt_end
              INTO dt_exec_end
              FROM (SELECT rs.dt_end,
                           row_number() over(PARTITION BY rp.id_rehab_presc ORDER BY rs.id_rehab_session DESC) rn
                      FROM rehab_presc rp
                      LEFT JOIN rehab_session rs
                        ON rs.id_rehab_presc = rp.id_rehab_presc
                     WHERE rp.id_rehab_presc = i_id_rehab_presc
                       AND rs.flg_status NOT IN ('C')) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN OTHERS THEN
                dt_exec_end := NULL;
        END;
        IF (i_description_condition IS NOT NULL)
        THEN
            --l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            --   FOR i IN 1 .. l_tbl_desc_condition.last
            --  LOOP
            --null;
            --    END LOOP;
            NULL;
        ELSE
        
            l_description := l_desc_rehab_area || chr(10) || --
                             l_desc_rehab_treat || pk_prog_notes_constants.g_colon;
        
            IF l_desc_priority IS NOT NULL
            THEN
                --priority
                l_description := l_description || pk_prog_notes_constants.g_space || l_desc_priority ||
                                 pk_prog_notes_constants.g_semicolon;
            END IF;
            --freq
            l_description := l_description || pk_prog_notes_constants.g_space ||
                             nvl(l_frequency_desc, pk_prog_notes_constants.g_triple_colon) ||
                             pk_prog_notes_constants.g_semicolon || pk_prog_notes_constants.g_space || --
                            --session
                             nvl(l_no_session_desc, pk_prog_notes_constants.g_triple_colon) ||
                             pk_prog_notes_constants.g_semicolon || pk_prog_notes_constants.g_space || --
                            --start date
                             l_dt_begin_desc;
        
            IF dt_exec_end IS NOT NULL
            THEN
                l_description := l_description || pk_prog_notes_constants.g_semicolon ||
                                 pk_prog_notes_constants.g_space || l_last_session_msg ||
                                 pk_prog_notes_constants.g_space ||
                                 pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                    dt_exec_end,
                                                                    i_prof.institution,
                                                                    i_prof.software);
            END IF;
            l_description := l_description || pk_prog_notes_constants.g_period;
        
        END IF;
    
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rehab_treat_desc;

    FUNCTION get_rehab_icf_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_rehab_diag         IN rehab_diagnosis.id_rehab_diagnosis%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_error                 OUT t_error_out
    ) RETURN CLOB IS
    
        l_description     CLOB;
        l_desc_icf        CLOB;
        l_no_session_desc CLOB;
        l_dt_begin_desc   CLOB;
        l_ini_disab_desc  CLOB;
        l_exp_disab_desc  CLOB;
        l_curr_disab_desc CLOB;
    
        l_status_desc   CLOB;
        l_clin_indc_msg VARCHAR(1000 CHAR) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_M014');
        l_ini_disab_msg VARCHAR(1000 CHAR) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_M008');
        l_exp_disab_msg VARCHAR(1000 CHAR) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_M009');
    
        l_curr_disab_msg VARCHAR(1000 CHAR) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_M010');
        l_status_msg     VARCHAR(1000 CHAR) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_M012');
        dt_exec_end      rehab_session.dt_end%TYPE;
    BEGIN
    
        SELECT regexp_replace((SELECT REPLACE(sys_connect_by_path(i.coding, '/'), '/', '') coding
                                 FROM icf i
                                WHERE i.id_icf = rd.id_icf
                                  AND i.flg_available = pk_alert_constant.g_yes
                               CONNECT BY PRIOR i.id_icf = i.id_icf_parent
                                START WITH i.id_icf IN (SELECT id_icf
                                                          FROM icf
                                                         WHERE flg_type = pk_interv_mfr.g_flg_icf_component)) || ' - ' ||
                              pk_translation.get_translation(i_lang, 'ICF.CODE_ICF.' || rd.id_icf),
                              '^(\s-\s*)$',
                              NULL),
               pk_sysdomain.get_domain('REHAB_DIAGNOSIS.FLG_STATUS', rd.flg_status, i_lang) status,
               regexp_replace((SELECT iqsr.flg_code || iqsr.value
                                 FROM icf_qualif_scale_rel iqsr
                                WHERE iqsr.id_icf_qualification = rd.id_iq_initial_incapacity
                                  AND iqsr.id_icf_qualification_scale = rd.id_iqs_initial_incapacity) || ' ' ||
                              pk_translation.get_translation(i_lang,
                                                             'ICF_QUALIFICATION.CODE_ICF_QUALIFICATION.' ||
                                                             rd.id_iq_initial_incapacity),
                              '^(\s*)$',
                              NULL),
               regexp_replace((SELECT iqsr.flg_code || iqsr.value
                                 FROM icf_qualif_scale_rel iqsr
                                WHERE iqsr.id_icf_qualification = rd.id_iq_expected_result
                                  AND iqsr.id_icf_qualification_scale = rd.id_iqs_expected_result) || ' ' ||
                              pk_translation.get_translation(i_lang,
                                                             'ICF_QUALIFICATION.CODE_ICF_QUALIFICATION.' ||
                                                             rd.id_iq_expected_result),
                              '^(\s*)$',
                              NULL),
               regexp_replace((SELECT iqsr.flg_code || iqsr.value
                                 FROM icf_qualif_scale_rel iqsr
                                WHERE iqsr.id_icf_qualification = rd.id_iq_active_incapacity
                                  AND iqsr.id_icf_qualification_scale = rd.id_iqs_active_incapacity) || ' ' ||
                              pk_translation.get_translation(i_lang,
                                                             'ICF_QUALIFICATION.CODE_ICF_QUALIFICATION.' ||
                                                             rd.id_iq_active_incapacity),
                              '^(\s*)$',
                              NULL)
        
          INTO l_desc_icf, l_status_desc, l_ini_disab_desc, l_exp_disab_desc, l_curr_disab_desc
          FROM rehab_diagnosis rd
         WHERE rd.id_rehab_diagnosis = i_id_rehab_diag;
    
        IF (i_description_condition IS NOT NULL)
        THEN
            --l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            --   FOR i IN 1 .. l_tbl_desc_condition.last
            --  LOOP
            --null;
            --    END LOOP;
            NULL;
        ELSE
        
            l_description := l_clin_indc_msg || pk_prog_notes_constants.g_space || l_desc_icf ||
                             pk_prog_notes_constants.g_semicolon --
                             || l_ini_disab_msg || pk_prog_notes_constants.g_space ||
                             nvl(l_ini_disab_desc, pk_prog_notes_constants.g_triple_colon) ||
                             pk_prog_notes_constants.g_semicolon --
                             || l_ini_disab_msg || pk_prog_notes_constants.g_space ||
                             nvl(l_ini_disab_desc, pk_prog_notes_constants.g_triple_colon) ||
                             pk_prog_notes_constants.g_semicolon --
                             || l_exp_disab_msg || pk_prog_notes_constants.g_space ||
                             nvl(l_exp_disab_desc, pk_prog_notes_constants.g_triple_colon) ||
                             pk_prog_notes_constants.g_semicolon --
                             || l_curr_disab_msg || pk_prog_notes_constants.g_space ||
                             nvl(l_curr_disab_desc, pk_prog_notes_constants.g_triple_colon) ||
                             pk_prog_notes_constants.g_period; --
        
        END IF;
    
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rehab_icf_desc;

    /**
    * Get the task short description.
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_task_type           Task type id
    * @param       i_id_task                Task id
    * @param       i_code_description       Code translation to the task description
    * @param       i_universal_desc_clob    Large Description created by the user
    * @param       i_flg_sos                Flag SOS/PRN
    * @param       i_dt_begin               Begin Date of the task
    * @param       i_id_task_aggregator     Task Aggregator identifier
    * @param       i_id_doc_area            Documentation Area identifier
    * @param       i_flg_status             Status of the task
    * @param       i_code_desc_sample_type  Sample type code description
    *
    * @param       o_short_desc             Short description to the import last level
    * @param       o_detailed_desc          Detailed desc for more info and note
    *
    * @return      Boolean                 Success / Error
    *
    * @author                              Sofia Mendes
    * @version                             2.6.1.2
    * @since                               25-Aug-2011
    */
    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_universal_desc_clob   IN task_timeline_ea.universal_desc_clob%TYPE,
        i_flg_sos               IN task_timeline_ea.flg_sos%TYPE,
        i_dt_begin              IN task_timeline_ea.dt_begin%TYPE,
        i_id_task_aggregator    IN task_timeline_ea.id_task_aggregator%TYPE,
        i_id_doc_area           IN task_timeline_ea.id_doc_area%TYPE,
        i_code_status           IN task_timeline_ea.code_status%TYPE,
        i_flg_status            IN task_timeline_ea.flg_status_req%TYPE,
        i_end_date              IN task_timeline_ea.dt_end%TYPE,
        i_dt_req                IN task_timeline_ea.dt_req%TYPE,
        i_id_task_notes         IN task_timeline_ea.id_task_notes%TYPE,
        i_code_desc_sample_type IN task_timeline_ea.code_desc_sample_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT CLOB,
        o_detailed_desc         OUT CLOB
    ) RETURN BOOLEAN IS
        l_error          t_error_out;
        l_func_name      VARCHAR2(20) := 'get_task_description';
        l_pat_hist_diag  epis_pn_det_task.id_task%TYPE;
        l_pat_ph_ft_hist epis_pn_det_task.id_task%TYPE;
    
        l_med_desc pk_prog_notes_types.t_tasks_descs;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'get_task_description. i_id_pn_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task ||
                   ' i_code_description: ' || i_code_description;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        -- MONITORIZATION
        IF (i_id_task_type = pk_prog_notes_constants.g_task_monitoring)
        THEN
            g_error := 'CALL pk_monitorization.get_monitor_description. i_id_pn_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_monitorization.get_monitor_description(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_monitorization => i_id_task,
                                                             o_desc              => o_short_desc,
                                                             o_error             => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- PAST HISTORY
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_ph_medical_hist,
                                  pk_prog_notes_constants.g_task_ph_surgical_hist,
                                  pk_prog_notes_constants.g_task_ph_relevant_notes,
                                  pk_prog_notes_constants.g_task_ph_treatments,
                                  pk_prog_notes_constants.g_task_ph_cong_anomalies,
                                  pk_prog_notes_constants.g_task_ph_family_diag,
                                  pk_prog_notes_constants.g_task_ph_gynec_diag,
                                  pk_prog_notes_constants.g_task_ph_free_txt))
        THEN
            --41, 30, 33, 48, 32, 42
            IF (i_id_task_type = pk_prog_notes_constants.g_task_ph_free_txt)
            THEN
                l_pat_ph_ft_hist := i_id_task;
            ELSE
                l_pat_hist_diag := i_id_task;
            END IF;
        
            g_error := 'CALL pk_past_history.get_past_hist_rec_desc. i_id_pn_task_type: ' || i_id_task_type ||
                       ' i_id_pat_history_diagnosis: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_past_history.get_past_hist_rec_desc(i_lang                  => i_lang,
                                                                   i_prof                  => i_prof,
                                                                   i_pat_hist_diag         => l_pat_hist_diag,
                                                                   i_pat_ph_ft_hist        => NULL,
                                                                   i_flg_description       => i_flg_description,
                                                                   i_description_condition => i_description_condition);
            -- Lab/Exam orders
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab,
                                  pk_prog_notes_constants.g_task_lab_recur,
                                  pk_prog_notes_constants.g_task_img_exams_req,
                                  pk_prog_notes_constants.g_task_img_exam_recur,
                                  pk_prog_notes_constants.g_task_other_exams_req,
                                  pk_prog_notes_constants.g_task_other_exams_recur))
        THEN
            g_error := 'CALL get_lab_exam_order_description - i_id_task_type: ' || i_id_task_type || ' i_id_task: ' ||
                       i_id_task || ' i_id_task_aggregator: ' || i_id_task_aggregator || ' i_flg_description: ' ||
                       i_flg_description;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := get_lab_exam_order_description(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_id_task_type          => i_id_task_type,
                                                           i_id_task               => i_id_task,
                                                           i_code_description      => i_code_description,
                                                           i_flg_sos               => i_flg_sos,
                                                           i_dt_begin              => i_dt_begin,
                                                           i_id_task_aggregator    => i_id_task_aggregator,
                                                           i_code_desc_sample_type => i_code_desc_sample_type,
                                                           i_flg_description       => i_flg_description,
                                                           i_description_condition => i_description_condition);
            IF i_description_condition IS NOT NULL
            THEN
                o_detailed_desc := o_short_desc;
            END IF;
            -- Lab Orders Results
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab_results))
        THEN
            g_error := 'CALL pk_lab_tests_external_api_db.get_lab_test_result_desc - i_id_task_type: ' ||
                       i_id_task_type || ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_lab_tests_external_api_db.get_lab_test_result_desc(i_lang                   => i_lang,
                                                                         i_prof                   => i_prof,
                                                                         i_id_analysis_result_par => i_id_task,
                                                                         i_description_condition  => i_description_condition,
                                                                         i_flg_desc_for_dblock    => pk_alert_constant.g_yes,
                                                                         o_description            => o_short_desc,
                                                                         o_error                  => l_error)
            THEN
                RAISE l_exception;
            END IF;
            IF i_description_condition IS NOT NULL
            THEN
                o_detailed_desc := o_short_desc;
            END IF;
            -- Exams Results
        ELSIF (i_id_task_type IN
              (pk_prog_notes_constants.g_task_exam_results, pk_prog_notes_constants.g_task_oth_exam_results))
        THEN
            g_error := 'CALL get_exam_result_descs. i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT get_exam_result_descs(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_task               => i_id_task,
                                         i_code_description      => i_code_description,
                                         i_flg_description       => i_flg_description,
                                         i_description_condition => i_description_condition,
                                         i_flg_desc_for_dblock   => pk_prog_notes_constants.g_yes,
                                         i_flg_image_exam        => pk_prog_notes_constants.g_no,
                                         o_short_desc            => o_short_desc,
                                         o_detailed_desc         => o_detailed_desc,
                                         o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --Image exams results
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_img_exam_results))
        THEN
        
            g_error := 'CALL get_exam_result_descs. i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT get_exam_result_descs(i_lang => i_lang,
                                         
                                         i_prof                  => i_prof,
                                         i_id_task               => i_id_task,
                                         i_code_description      => i_code_description,
                                         i_flg_description       => i_flg_description,
                                         i_description_condition => i_description_condition,
                                         i_flg_desc_for_dblock   => pk_prog_notes_constants.g_yes,
                                         i_flg_image_exam        => pk_prog_notes_constants.g_yes,
                                         o_short_desc            => o_short_desc,
                                         o_detailed_desc         => o_detailed_desc,
                                         o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Chief Complaint and Anamnesis
        ELSIF (i_id_task_type IN
              (pk_prog_notes_constants.g_task_chief_complaint, pk_prog_notes_constants.g_task_chief_complaint_anm))
        THEN
            g_error := 'CALL get_complaint_description - i_id_task_type: ' || i_id_task_type || ' i_id_task: ' ||
                       i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF NOT get_complaint_description(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             i_id_task               => i_id_task,
                                             i_id_episode            => i_id_episode,
                                             i_id_task_type          => i_id_task_type,
                                             i_code_description      => i_code_description,
                                             i_flg_description       => i_flg_description,
                                             i_description_condition => i_description_condition,
                                             i_flg_desc_for_dblock   => pk_prog_notes_constants.g_yes,
                                             i_universal_desc_clob   => i_universal_desc_clob,
                                             o_description           => o_short_desc,
                                             o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
            -- epis reason
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_chief_complaint_out))
        THEN
            g_error := 'CALL pk_complaint.get_complaint_amb_description - i_id_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF NOT pk_complaint.get_complaint_amb_description(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_episode     => i_id_episode,
                                                              o_description => o_short_desc,
                                                              o_error       => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Final and Differential Diagnosis
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_diagnosis, pk_prog_notes_constants.g_task_final_diag))
        THEN
            g_error := 'CALL get_diagnosis_desc - i_id_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := get_diagnosis_desc(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_id_episode            => i_id_episode,
                                               i_id_epis_diagnosis     => i_id_task,
                                               i_flg_description       => i_flg_description,
                                               i_description_condition => i_description_condition);
        
            -- diets
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_diets
        THEN
            o_short_desc := pk_diet.get_task_description(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_edr                   => i_id_task,
                                                         i_flg_description       => i_flg_description,
                                                         i_description_condition => i_description_condition);
            -- positioning
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_positioning
        THEN
            g_error := 'PK_INP_POSITIONING.GET_DESCRIPTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_inp_positioning.get_description(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_epis_positioning => i_id_task,
                                                               i_desc_type           => pk_prog_notes_constants.g_desc_type_s);
            --problems
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems
        THEN
            g_error := 'pk_problems.get_description_phd';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_problems.get_description_phd(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_id_phd    => i_id_task,
                                                            i_desc_type => i_flg_description);
            --allergy
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_allergies
        THEN
            g_error := 'pk_allergy.get_desc_allergy';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_allergy.get_desc_allergy(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_pat_allergy => i_id_task,
                                                        i_desc_type      => pk_prog_notes_constants.g_desc_type_s);
        
            --allergy by type
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_allergies_allergy,
                                 pk_prog_notes_constants.g_task_allergies_adverse,
                                 pk_prog_notes_constants.g_task_allergies_intolerance,
                                 pk_prog_notes_constants.g_task_allergies_propensity)
        THEN
            g_error := 'pk_allergy.get_desc_allergy';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_allergy.get_desc_allergy(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_pat_allergy => i_id_task,
                                                        i_desc_type      => pk_prog_notes_constants.g_desc_type_d);
        
            --allergy unaware
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_no_known_allergies
        THEN
            g_error := 'pk_allergy.get_desc_allergy_unaware';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_allergy.get_desc_allergy_unaware(i_lang                   => i_lang,
                                                                i_prof                   => i_prof,
                                                                i_id_pat_allergy_unaware => i_id_task,
                                                                i_desc_type              => pk_prog_notes_constants.g_desc_type_s);
        
            --prob unaware
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_no_known_prob
        THEN
            g_error := 'pk_problems.get_desc_prob_unaware';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_problems.get_desc_prob_unaware(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_pat_prob_unaware => i_id_task,
                                                              i_desc_type           => pk_prog_notes_constants.g_desc_type_s);
        
            --problems_diag
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_diag
        THEN
            g_error := 'pk_problems.get_description_pp';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_problems.get_description_pp(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_id_pp     => i_id_task,
                                                           i_desc_type => pk_prog_notes_constants.g_desc_type_s);
            --surgical procedures
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_surgery
        THEN
            g_error := 'pk_sr_visit.get_desc_surg_proc';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_sr_visit.get_desc_surg_proc(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_episode     => i_id_task,
                                                           i_desc_type      => nvl(i_flg_description,
                                                                                   pk_logic_episode.g_desc_type_s),
                                                           i_desc_condition => i_description_condition);
            --future events
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_medical_appointment,
                                 pk_prog_notes_constants.g_task_nursing_appointment,
                                 pk_prog_notes_constants.g_task_nutrition_appointment,
                                 pk_prog_notes_constants.g_task_rehabilitation,
                                 pk_prog_notes_constants.g_task_social_service,
                                 pk_prog_notes_constants.g_task_psychology,
                                 pk_prog_notes_constants.g_task_speech_therapy,
                                 pk_prog_notes_constants.g_task_occupational_therapy)
        THEN
            g_error := 'pk_consult_req.GET_DESCRIPTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_consult_req.get_description(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_consult_req => i_id_task,
                                                           i_desc_type      => pk_prog_notes_constants.g_desc_type_s);
            --triage
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_triage
        THEN
            g_error := 'pk_edis_triage.get_task_description';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_edis_triage.get_task_description(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_id_epis_triage => i_id_task,
                                                                i_desc_type      => pk_edis_triage.g_desc_type_s);
            --mtos
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_mtos_score
        THEN
            g_error := 'pk_sev_scores_core.GET_DESCRIPTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_sev_scores_core.get_task_description(i_lang                  => i_lang,
                                                                    i_prof                  => i_prof,
                                                                    i_id_epis_mtos_score    => i_id_task,
                                                                    i_desc_type             => pk_sev_scores_core.g_desc_type_s,
                                                                    i_flg_description       => i_flg_description,
                                                                    i_description_condition => i_description_condition);
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_intake_output
        THEN
            o_short_desc := pk_inp_hidrics.get_task_desc(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_epis_hidrics          => i_id_task,
                                                         i_epis_type             => pk_episode.get_epis_type(i_lang    => i_lang,
                                                                                                             i_id_epis => i_id_episode),
                                                         i_flg_description       => i_flg_description,
                                                         i_description_condition => i_description_condition);
            -- Consults
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_opinion
        THEN
            g_error := 'PK_OPINION.GET_SP_DESCRIPTION - SHORT DESC';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_opinion.get_sp_consult_desc(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_opinion               => i_id_task,
                                                           i_opinion_type          => pk_ea_logic_opinion.get_id_op_type_from_id_tt(i_id_task_type),
                                                           i_flg_description       => i_flg_description,
                                                           i_description_condition => i_description_condition,
                                                           i_flg_desc_for_dblock   => pk_alert_constant.g_yes,
                                                           i_flg_short             => pk_alert_constant.g_no);
        
            -- Discharge instructions
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_disch_instructions
        THEN
            g_error := 'PK_DISCHARGE.GET_SP_DISCH_INSTR_DESC - SHORT DESC';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_discharge.get_sp_disch_instr_desc(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_disch_notes        => i_id_task,
                                                                 i_flg_short             => pk_alert_constant.g_yes,
                                                                 i_desc_type             => i_flg_description,
                                                                 i_description_condition => i_description_condition);
        
            -- inp/surg
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_inp_surg
        THEN
            g_error := 'CALL pk_admission_request.get_description';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_admission_request.get_description(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_adm_request => i_id_task,
                                                                 i_desc_type   => i_flg_description);
        
            -- only surgery without admission
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_surg
        THEN
            g_error := 'CALL  pk_surgery_request.get_surgery_description';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_surgery_request.get_surgery_description(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_schedule_sr => i_id_task,
                                                                       i_desc_type      => i_flg_description);
        
            -- Surgical procedures                                                               
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_surg_procedures
        THEN
            g_error := 'CALL  pk_surgery_request.get_surg_proc_description';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            o_short_desc := pk_surgery_request.get_surg_proc_description(i_lang                  => i_lang,
                                                                         i_prof                  => i_prof,
                                                                         i_id_sr_epis_interv     => i_id_task,
                                                                         i_desc_type             => i_flg_description,
                                                                         i_description_condition => i_description_condition);
            --procedures
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_procedures
        THEN
            g_error := 'CALL pk_prog_notes_in.get_procedures_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_in.get_procedures_desc(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_id_interv_presc_det   => i_id_task,
                                                        i_flg_description       => i_flg_description,
                                                        i_description_condition => i_description_condition,
                                                        o_short_desc            => o_short_desc,
                                                        o_long_desc             => o_detailed_desc,
                                                        o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
            --patient education
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_pat_education
        THEN
            g_error := 'CALL pk_prog_notes_in.get_pat_education_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_in.get_pat_education_desc(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_id_nurse_tea_req      => i_id_task,
                                                           i_flg_description       => i_flg_description,
                                                           i_description_condition => i_description_condition,
                                                           o_short_desc            => o_short_desc,
                                                           o_long_desc             => o_detailed_desc,
                                                           o_error                 => l_error)
            THEN
                RAISE g_exception;
            END IF;
            --cits
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_cits
        THEN
            g_error := 'CALL pk_cit.get_cit_short_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_cit.get_cit_short_desc(i_lang => i_lang, i_prof => i_prof, i_cit => i_id_task);
            -- comments
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_analysis_comments,
                                 pk_prog_notes_constants.g_task_exams_comments,
                                 pk_prog_notes_constants.g_task_medication_comments,
                                 pk_prog_notes_constants.g_task_procedures_comments)
        THEN
            o_short_desc := pk_message.get_message(i_lang      => i_lang,
                                                   i_code_mess => pk_prog_notes_constants.g_sm_comment) ||
                            pk_prog_notes_constants.g_colon || i_universal_desc_clob;
        
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_procedures_exec)
        THEN
        
            g_error := 'call get_procedures_execs_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT get_procedures_execs_desc(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_code_description    => i_code_description,
                                             i_universal_desc_clob => i_universal_desc_clob,
                                             i_code_status         => i_code_status,
                                             i_flg_status          => i_flg_status,
                                             i_start_date          => i_dt_begin,
                                             i_end_date            => i_end_date,
                                             i_dt_req              => i_dt_req,
                                             i_id_task_notes       => i_id_task_notes,
                                             o_short_desc          => o_short_desc,
                                             o_long_desc           => o_detailed_desc,
                                             o_error               => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --Emergency law
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_emergency_law
        THEN
            g_error := 'call get_procedures_execs_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_epis_er_law_api.get_description(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_epis_er_law => i_id_task,
                                                      o_description    => o_short_desc,
                                                      o_error          => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_detailed_desc := o_short_desc;
        
            --body diagram
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_body_diagram
        THEN
            g_error := 'call get_body_diagram_description';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_ea_logic_body_diagram.get_body_diagram_description(i_lang            => i_lang,
                                                                                  i_prof            => i_prof,
                                                                                  i_id_epis_diagram => i_id_task);
        
            o_detailed_desc := o_short_desc;
        
            --comunications orders
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_communications
        THEN
            g_error := 'CALL PK_COMM_ORDERS_DB.get_comm_orders_req_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_comm_orders_db.get_comm_order_req_desc(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_id_comm_order_req     => i_id_task,
                                                                      i_description_condition => i_description_condition,
                                                                      i_flg_desc_for_dblock   => pk_alert_constant.g_yes);
        
            o_detailed_desc := o_short_desc;
        
            --AIH CITS procedures
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_cits_procedures
        THEN
            g_error := 'CALL PK_';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_aih.get_aih_simple_desc(i_lang => i_lang, i_prof => i_prof, i_id_aih_simple => i_id_task);
        
            o_detailed_desc := o_short_desc;
            --AIH special CITS procedures
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_cits_procedures_special
        THEN
            g_error := 'CALL PK_';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            o_short_desc := pk_aih.get_aih_special_desc(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_aih_special => i_id_task);
        
            o_detailed_desc := o_short_desc;
        
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_referral,
                                 pk_prog_notes_constants.g_task_referral_other_exams,
                                 pk_prog_notes_constants.g_task_referral_img_exams,
                                 pk_prog_notes_constants.g_task_referral_lab,
                                 pk_prog_notes_constants.g_task_referral_rehab,
                                 pk_prog_notes_constants.g_task_referral_proc,
                                 pk_prog_notes_constants.g_task_referral_nutrition,
                                 pk_prog_notes_constants.g_task_opinion_psy)
        THEN
            o_short_desc    := pk_p1_ext_sys.get_sp_description(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_ext_req   => i_id_task,
                                                                i_desc_type => pk_logic_episode.g_desc_type_s);
            o_detailed_desc := o_short_desc;
        ELSIF i_id_task_type IN
              (pk_prog_notes_constants.g_task_reported_medic, pk_prog_notes_constants.g_task_home_med_chinese)
              AND i_description_condition IS NOT NULL
        THEN
            g_error         := 'pk_api_pfh_clindoc_in.get_single_page_med_desc';
            l_med_desc      := pk_api_pfh_clindoc_in.get_single_page_med_desc(i_lang                  => i_lang,
                                                                              i_prof                  => i_prof,
                                                                              i_id_episode            => i_id_episode,
                                                                              i_id_presc              => table_number(i_id_task),
                                                                              i_flg_complete          => NULL,
                                                                              i_flg_with_notes        => NULL,
                                                                              i_flg_with_status       => NULL,
                                                                              i_flg_with_recon_notes  => NULL,
                                                                              i_flg_description       => i_flg_description,
                                                                              i_description_condition => i_description_condition);
            o_short_desc    := l_med_desc(i_id_task).task_desc;
            o_detailed_desc := l_med_desc(i_id_task).task_desc_long;
            -- OTHERS WITH universal_desc_clob
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_medic_here
              AND i_description_condition IS NOT NULL
        THEN
            g_error         := 'pk_api_pfh_clindoc_in.get_single_page_med_desc';
            l_med_desc      := pk_api_pfh_clindoc_in.get_single_page_med_desc(i_lang                  => i_lang,
                                                                              i_prof                  => i_prof,
                                                                              i_id_episode            => i_id_episode,
                                                                              i_id_presc              => table_number(i_id_task),
                                                                              i_flg_complete          => 'N',
                                                                              i_flg_with_notes        => NULL,
                                                                              i_flg_with_status       => NULL,
                                                                              i_flg_with_recon_notes  => NULL,
                                                                              i_flg_description       => i_flg_description,
                                                                              i_description_condition => i_description_condition);
            o_short_desc    := l_med_desc(i_id_task).task_desc;
            o_detailed_desc := l_med_desc(i_id_task).task_desc_long;
        
            -- OTHERS WITH universal_desc_clob
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_episode
        THEN
            g_error := 'CALL pk_lab_tests_external.get_lab_test_order_desc - i_id_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            o_short_desc    := pk_problems.get_epis_prob_description(i_lang                  => i_lang,
                                                                     i_prof                  => i_prof,
                                                                     i_id_problems           => i_id_task,
                                                                     i_flg_desc_for_dblock   => pk_alert_constant.g_yes,
                                                                     i_flg_description       => i_flg_description,
                                                                     i_description_condition => i_description_condition);
            o_detailed_desc := o_short_desc;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_group_ass
        THEN
            g_error := 'CALL pk_lab_tests_external.get_lab_test_order_desc - i_id_task_type: ' || i_id_task_type ||
                       ' i_id_task: ' || i_id_task;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            o_short_desc    := pk_problems.get_prob_group_description(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_id_group_ass          => i_id_task,
                                                                      i_flg_desc_for_dblock   => pk_alert_constant.g_yes,
                                                                      i_flg_description       => i_flg_description,
                                                                      i_description_condition => i_description_condition);
            o_detailed_desc := o_short_desc;
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_supply))
        THEN
            o_short_desc    := pk_supplies_external_api_db.get_task_description(i_lang                  => i_lang,
                                                                                i_prof                  => i_prof,
                                                                                i_id_supply_workflow    => i_id_task,
                                                                                i_flg_description       => i_flg_description,
                                                                                i_description_condition => i_description_condition);
            o_detailed_desc := o_short_desc;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_intervention_plan
        THEN
        
            o_short_desc := pk_social.get_interv_plan_desc(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_epis_interv_plan => i_id_task,
                                                           i_flg_description     => pk_prog_notes_constants.g_desc_type_s);
        
            o_detailed_desc := pk_social.get_interv_plan_desc(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_epis_interv_plan => i_id_task,
                                                              i_flg_description     => pk_prog_notes_constants.g_desc_type_l);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_follow_up_notes
        THEN
        
            o_short_desc := pk_social.get_followup_notes_desc(i_lang                    => i_lang,
                                                              i_prof                    => i_prof,
                                                              i_id_management_follow_up => i_id_task,
                                                              i_flg_description         => pk_prog_notes_constants.g_desc_type_s);
        
            o_detailed_desc := pk_social.get_followup_notes_desc(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_id_management_follow_up => i_id_task,
                                                                 i_flg_description         => pk_prog_notes_constants.g_desc_type_l);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_pat_identification
        THEN
            o_short_desc := get_pat_identification(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_id_episode            => i_id_episode,
                                                   i_flg_description       => i_flg_description,
                                                   i_description_condition => i_description_condition);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_nurse_diagnosis
        THEN
            o_short_desc    := pk_icnp_diag.get_icnp_diagnosis_desc(i_lang                  => i_lang,
                                                                    i_prof                  => i_prof,
                                                                    i_id_episode            => i_id_episode,
                                                                    i_id_icnp_epis_diag     => i_id_task,
                                                                    i_flg_description       => i_flg_description,
                                                                    i_description_condition => i_description_condition);
            o_detailed_desc := o_short_desc;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_nurse_intervention
        THEN
            o_short_desc    := pk_icnp_interv.get_icnp_interv_desc(i_lang                  => i_lang,
                                                                   i_prof                  => i_prof,
                                                                   i_id_episode            => i_id_episode,
                                                                   i_id_icnp_epis_interv   => i_id_task,
                                                                   i_flg_description       => i_flg_description,
                                                                   i_description_condition => i_description_condition);
            o_detailed_desc := o_short_desc;
        
            --REHB TREATS
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_rehab_treatments
        THEN
            o_short_desc := get_rehab_treat_desc(i_lang                  => i_lang,
                                                 i_prof                  => i_prof,
                                                 i_id_episode            => i_id_episode,
                                                 i_id_rehab_presc        => i_id_task,
                                                 i_code_description      => i_code_description,
                                                 i_dt_begin              => i_dt_begin,
                                                 i_flg_description       => i_flg_description,
                                                 i_description_condition => i_description_condition);
        
            o_detailed_desc := o_short_desc;
        
            --ICF
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_icf
        THEN
            o_short_desc := get_rehab_icf_desc(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_id_episode            => i_id_episode,
                                               i_id_rehab_diag         => i_id_task,
                                               i_flg_description       => i_flg_description,
                                               i_description_condition => i_description_condition,
                                               o_error                 => l_error);
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_prognosis
        THEN
            o_short_desc := pk_prognosis.get_prognosis_desc(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_epis_prognosis => i_id_task);
        ELSIF (i_universal_desc_clob IS NOT NULL)
        THEN
            o_short_desc := i_universal_desc_clob;
        
            -- OTHERS WITH CODE_DESCRIPTION
        ELSIF (i_code_description IS NOT NULL)
        THEN
            o_short_desc := pk_translation.get_translation(i_code_mess => i_code_description, i_lang => i_lang);
        
            --OTHES (WHEN ERROR)
        ELSE
            o_short_desc := NULL; --'XXX';
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
                                              'GET_TASK_DESCRIPTION',
                                              l_error);
        
            RETURN FALSE;
    END get_task_description;

    /**
    * Gets the outdated parent tasks.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task                Task reference id
    * @param i_id_task_type           Task type
    * @param o_parent_tasks           List of outdated parent tasks
    * @param o_error                  Error info
    *
    * @return Boolean                Success / Error
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                09-Feb-2012
    */

    FUNCTION get_outdated_parents
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_type IN task_timeline_ea.id_tl_task%TYPE,
        o_parent_tasks OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(20 CHAR) := 'GET_OUTDATED_PARENTS';
    BEGIN
        --Functionalities that create a new ID when editing a record that are not in the EA table needs an explicit API
        -- that must be called here        
        g_error := 'GET OUTDATED PARENT TASKS. i_id_task: ' || i_id_task;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT t.id_parent_task_refid
              BULK COLLECT
              INTO o_parent_tasks
              FROM (SELECT vpt.id_parent_task_refid
                      FROM task_timeline_ea vpt
                    CONNECT BY PRIOR vpt.id_task_refid = vpt.id_parent_task_refid
                     START WITH vpt.id_task_refid = i_id_task
                            AND vpt.id_tl_task = i_id_task_type) t
             WHERE t.id_parent_task_refid IS NOT NULL
               AND t.id_parent_task_refid <> i_id_task;
        EXCEPTION
            WHEN no_data_found THEN
                o_parent_tasks := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_outdated_parents;

    /**
    * Verify if a record had already been reviewed in a given episode
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_patient      patient id
    * @param i_id_task         task reference id
    * @param i_id_task_type    Task type id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_review_cat       List of categories flg_types to consider in the check 
    *
    * @return                  Y - the record was reviewed by some professional in the given episode. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION check_reviewed_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_task      IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type IN tl_task.id_tl_task%TYPE,
        i_flg_context  IN tl_task.review_context%TYPE,
        i_review_cat   IN pn_dblock_ttp_mkt.review_cat%TYPE
    ) RETURN VARCHAR2 IS
        l_reviewed             VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_error                t_error_out;
        l_flg_rev_reconciled   VARCHAR2(1 CHAR);
        l_flg_revision_warning VARCHAR2(1 CHAR);
    BEGIN
        --Medication review
        IF (i_id_task_type = pk_prog_notes_constants.g_task_reported_medic)
        THEN
            g_error := 'CALL pk_api_pfh_in.get_recon_status_summary.';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_api_pfh_in.get_recon_status_summary(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_id_patient           => i_id_patient,
                                                          i_id_episode           => i_id_episode,
                                                          o_flg_rev_reviewed     => l_reviewed,
                                                          o_flg_rev_reconciled   => l_flg_rev_reconciled,
                                                          o_flg_revision_warning => l_flg_revision_warning)
            THEN
                RAISE g_exception;
            END IF;
        
            IF (l_flg_revision_warning = pk_alert_constant.g_yes OR l_reviewed = pk_alert_constant.g_no)
            THEN
                l_reviewed := pk_alert_constant.g_no;
            ELSE
                l_reviewed := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            --Generic review mechanism
            g_error := 'CALL pk_review.check_reviewed_record.';
            pk_alertlog.log_debug(g_error);
            l_reviewed := pk_review.check_reviewed_record(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_episode     => i_id_episode,
                                                          i_id_record_area => i_id_task,
                                                          i_flg_context    => i_flg_context,
                                                          i_cat_types      => pk_string_utils.str_split_pos(i_list        => i_review_cat,
                                                                                                            i_nr_of_chars => 1));
        END IF;
    
        RETURN l_reviewed;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_REVIEWED_RECORD',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
        
    END check_reviewed_record;

    /********************************************************************************************
    * perform an action that does not need to load a screen (only call a BD function).
    * The action to be performed is identified by the id_task_Type and the id_Action.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              episode id
    * @param       i_id_action               action id
    * @param       i_id_task_type            task type ID
    * @param       i_id_task                 task ID    
    * @param       o_flg_validated           validated flag (which indicates if an auxiliary  screen should be loaded or not)
    * @param       o_error                   error message   
    *
    * @value       o_flg_validated           {*} 'Y' validated! no user inputs are needed
    *                                        {*} 'N' not validated! user needs to validare this action
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Sofia Mendes
    * @since                                 23-Mar-2012
    ********************************************************************************************/
    FUNCTION set_action
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_action     IN action.id_action%TYPE,
        i_id_task_type  IN tl_task.id_tl_task%TYPE,
        i_id_task       IN epis_pn_det_task.id_task%TYPE,
        o_flg_validated OUT NOCOPY VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_info        pk_types.cursor_type;
        l_id_new_task NUMBER;
        l_func_name   VARCHAR2(10 CHAR) := 'SET_ACTION';
        l_id_patient  patient.id_patient%TYPE;
    
        l_id_review        PLS_INTEGER;
        l_code_review      PLS_INTEGER;
        l_task_description VARCHAR(1000 CHAR);
        l_id_prof_create   professional.id_professional%TYPE;
        l_dt_create        TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_last_update   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_info_source  CLOB;
        l_pat_not_take CLOB;
        l_pat_take     CLOB;
        l_notes        CLOB;
    BEGIN
        -- required by the flash layer
        g_error := 'set task action (id_action = ' || i_id_action || ') for i_task_type=' || i_id_task_type ||
                   ', i_id_task=' || i_id_task || ', i_episode=' || i_id_episode;
        pk_alertlog.log_debug(g_error, g_package);
    
        CASE
        -- local medication
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_medic_here THEN
                CASE
                -- resume action (may not need user interaction)
                    WHEN i_id_action = pk_prog_notes_constants.g_task_med_resume_action THEN
                        g_error := 'CALL pk_api_pfh_ordertools_in.resume_medication.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_api_pfh_ordertools_in.resume_medication(i_lang          => i_lang,
                                                                          i_prof          => i_prof,
                                                                          i_presc         => i_id_task,
                                                                          o_flg_validated => o_flg_validated,
                                                                          o_error         => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                END CASE;
                -- reported medication
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_reported_medic THEN
                CASE
                    WHEN i_id_action IN (pk_prog_notes_constants.g_task_med_set_active,
                                         pk_prog_notes_constants.g_task_med_set_inactive,
                                         pk_prog_notes_constants.g_task_med_set_unknown) THEN
                        g_error := 'CALL pk_api_pfh_clindoc_in.set_review_presc_status.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_api_pfh_clindoc_in.set_review_presc_status(i_lang       => i_lang,
                                                                             i_prof       => i_prof,
                                                                             i_id_patient => pk_episode.get_id_patient(i_episode => i_id_episode),
                                                                             i_id_episode => i_id_episode,
                                                                             i_id_presc   => table_number(i_id_task),
                                                                             i_id_action  => table_number(i_id_action),
                                                                             o_info       => l_info,
                                                                             o_error      => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    WHEN i_id_action = pk_prog_notes_constants.g_task_med_review THEN
                        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
                    
                        g_error := 'CALL pk_api_pfh_in.get_last_review.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_api_pfh_in.get_last_review(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_episode     => i_id_episode,
                                                             i_id_patient     => l_id_patient,
                                                             i_dt_begin       => NULL,
                                                             i_dt_end         => NULL,
                                                             o_id_review      => l_id_review,
                                                             o_code_review    => l_code_review,
                                                             o_review_desc    => l_task_description,
                                                             o_dt_create      => l_dt_create,
                                                             o_dt_update      => l_dt_last_update,
                                                             o_id_prof_create => l_id_prof_create,
                                                             o_info_source    => l_info_source,
                                                             o_pat_not_take   => l_pat_not_take,
                                                             o_pat_take       => l_pat_take,
                                                             o_notes          => l_notes)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        g_error := 'CALL pk_api_pfh_in.set_hm_review_global_info.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_api_pfh_in.set_hm_review_global_info(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_id_patient  => l_id_patient,
                                                                       i_id_episode  => i_id_episode,
                                                                       io_id_review  => l_id_review,
                                                                       i_code_review => l_code_review)
                        THEN
                            RAISE g_exception;
                        END IF;
                    ELSE
                        NULL;
                END CASE;
                --ambulatory medication
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_amb_medication THEN
                CASE
                --cancel ambulatory med
                    WHEN i_id_action = pk_prog_notes_constants.g_task_cancel_amb_med THEN
                        g_error := 'CALL pk_api_pfh_ordertools_in.resume_medication.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_api_pfh_in.set_cancel_presc(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_presc    => i_id_task,
                                                              i_id_reason   => NULL,
                                                              i_reason      => NULL,
                                                              i_notes       => NULL,
                                                              i_flg_confirm => NULL,
                                                              o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                END CASE;
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint THEN
                CASE
                    WHEN i_id_action = pk_complaint.g_action_copy THEN
                        g_error := 'CALL pk_complaint.set_epis_complaint.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_complaint.set_epis_complaint(i_lang                  => i_lang,
                                                               i_prof                  => i_prof,
                                                               i_prof_cat_type         => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                     i_prof => i_prof),
                                                               i_epis                  => i_id_episode,
                                                               i_complaint             => NULL,
                                                               i_patient_complaint     => NULL,
                                                               i_flg_type              => pk_complaint.g_flg_edition_type_nochanges,
                                                               i_epis_complaint_parent => i_id_task,
                                                               o_id_epis_complaint     => l_id_new_task,
                                                               o_error                 => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                END CASE;
            
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint_anm THEN
                CASE
                    WHEN i_id_action = pk_complaint.g_action_copy THEN
                        g_error := 'CALL pk_clinical_info.set_epis_anamnesis.';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_clinical_info.set_epis_anamnesis(i_lang              => i_lang,
                                                                   i_episode           => i_id_episode,
                                                                   i_prof              => i_prof,
                                                                   i_desc              => NULL,
                                                                   i_flg_type          => pk_clinical_info.g_complaint,
                                                                   i_flg_type_mode     => pk_clinical_info.g_flg_edition_type_nochanges,
                                                                   i_id_epis_anamnesis => i_id_task,
                                                                   i_id_diag           => NULL,
                                                                   i_flg_class         => NULL,
                                                                   i_prof_cat_type     => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                     i_prof => i_prof),
                                                                   o_id_epis_anamnesis => l_id_new_task,
                                                                   o_error             => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                END CASE;
            
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_templates THEN
                /*CASE
                WHEN i_id_action = pk_complaint.g_action_copy THEN*/
                g_error := 'CALL pk_hcn.cancel_eval_hcn. i_epis_documentation: ' || i_id_task;
                pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                IF NOT pk_hcn.cancel_eval_hcn(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_epis_documentation => i_id_task,
                                              o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                -- END CASE;
        /*       when i_id_task_type = pk_prog_notes_constants.g_task_nurse_intervention then 
                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                               pk_icnp_interv.set_interv_status_cancel(i_lang           => i_lang,
                                                                                                                                                                                                                                                                                    i_prof           => i_prof,
                                                                                                                                                                                                                                                                                    i_epis_interv_id =>i_id_task,
                                                                                                                                                                                                                                                                                    i_cancel_reason  => null,
                                                                                                                                                                                                                                                                                    i_cancel_notes   => null,
                                                                                                                                                                                                                                                                                    i_sysdate_tstz   => current_timestamp);
                                                                                                                                                                                                                                */
            ELSE
                NULL;
            
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_ACTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_action;

    /**
    * Verify if an aggregated task is active: verifies if all the task that belongs to the agregation 
    * record had already been reviewed in a given episode
    *
    * @param i_lang                  language id
    * @param i_id_task_type          Task type id
    * @param i_id_task_aggregator    Aggregator ID
    *
    * @return                  Y - Active aggregation. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION check_active_aggregation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_task_type       IN tl_task.id_tl_task%TYPE,
        i_id_task_aggregator IN task_timeline_ea.id_task_aggregator%TYPE
    ) RETURN VARCHAR2 IS
        l_error    t_error_out;
        l_active   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_finished VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'check_active_aggregation. i_id_task_type: ' || i_id_task_type || ' i_id_task_aggregator: ' ||
                   i_id_task_aggregator;
        pk_alertlog.log_debug(g_error);
    
        IF (i_id_task_aggregator IS NOT NULL)
        THEN
            IF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab_recur, pk_prog_notes_constants.g_task_lab))
            THEN
                g_error := 'CALL pk_lab_tests_external_api_db.is_lab_test_req_finished.';
                pk_alertlog.log_debug(g_error);
                l_finished := pk_lab_tests_external_api_db.is_lab_test_recurr_finished(i_lang             => i_lang,
                                                                                       i_prof             => i_prof,
                                                                                       i_order_recurrence => i_id_task_aggregator);
            ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_img_exam_recur,
                                      pk_prog_notes_constants.g_task_img_exams_req,
                                      pk_prog_notes_constants.g_task_other_exams_req,
                                      pk_prog_notes_constants.g_task_other_exams_recur))
            THEN
                g_error := 'CALL pk_exams_external_api_db.is_exam_req_finished.';
                pk_alertlog.log_debug(g_error);
                l_finished := pk_exams_external_api_db.is_exam_recurr_finished(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_order_recurrence => i_id_task_aggregator);
            END IF;
        
            IF (l_finished = pk_alert_constant.g_yes)
            THEN
                l_active := pk_alert_constant.g_no;
            ELSIF (l_finished = pk_alert_constant.g_no)
            THEN
                l_active := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            l_active := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_active;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_ACTIVE_AGGREGATION',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
        
    END check_active_aggregation;

    /********************************************************************************************
    * Sets the expected data for Synchronizable Areas (Expected Discharge Date, Arrival Date Time, etc.)
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_EPISODE            Episode Identifier
    * @param         I_ID_PATIENT            Patient Identifier    
    * @param         I_DT_PN_DATE            Progress Note date
    * @param         I_DATE_TYPE             DH- Date hour; D-Date    
    * @param         I_PN_NOTE_TASK          Task description
    * @param         I_FLG_ADD_REM_TASK      Array of task status (A- Active, R- Removed)
    * @param         I_ID_PN_NOTE_TYPE       Note Type Identifier
    * @param         I_ID_TASK_AGGREGATOR    For analysis and exam recurrences, an imported registry will only be uniquely 
    *                                        identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param         I_FLG_TASK_PARENT       Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param         I_ID_MULTICHOICE        Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param         i_prof_cat_type         Professional category type
    * @param         i_id_doc_area           Templates doc area ID
    * @param         i_dblock_type          Data block type
    *
    * @param         IO_ID_TASK              Task Identifier
    * @param         IO_ID_TASK_TYPE         Task type Identifier
    * @param         IO_ID_TASK_PARENT       Parent task identifier for comments functionality
    *
    * @param         O_FLG_RELOAD            Tells UX layer it It's needed the reload screen or not
    * @param         O_DT_TASK               Date in which the date was saved
    * @param         O_ERROR                 Error information
    *
    * @return                                True: Sucess, False: Fail
    *
    * @value         O_SAVE_TASK             {*} 'Y'- Yes {*} 'N'- No
    * @value         I_FLG_TASK_PARENT       {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @author                                António Neto
    * @since                                 06-Mar-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION set_synchronizable_areas
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_dt_pn_date       IN VARCHAR2,
        i_date_type        IN VARCHAR2,
        i_pn_note_task     IN epis_pn_det_task.pn_note%TYPE,
        i_flg_add_rem_task IN VARCHAR2,
        i_flg_task_parent  IN VARCHAR2,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_doc_area      IN doc_area.id_doc_area%TYPE,
        i_dblock_type      IN pn_data_block.flg_type%TYPE,
        io_id_task         IN OUT epis_pn_det_task.id_task%TYPE,
        io_id_task_type    IN OUT tl_task.id_tl_task%TYPE,
        io_id_task_parent  IN OUT epis_pn_det_task.id_parent%TYPE,
        o_flg_reload       OUT VARCHAR2,
        o_dt_task          OUT epis_pn_det_task.dt_task%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'SET_SYNCHRONIZABLE_AREAS';
        e_intake_time             EXCEPTION;
        e_discharge_schedule_date EXCEPTION;
        e_epis_recomend           EXCEPTION;
        e_epis_diag_notes         EXCEPTION;
        e_comment_on_area         EXCEPTION;
    
        l_dt_register           epis_intake_time.dt_register%TYPE;
        l_id_discharge_schedule discharge_schedule.id_discharge_schedule%TYPE;
    
        l_flg_type CONSTANT epis_recomend.flg_type%TYPE := 'L';
        l_desc epis_recomend.desc_epis_recomend_clob%TYPE;
    
        l_flg_add_rem_task VARCHAR2(1 CHAR);
    
        l_epis_pn_det_flg_status_a CONSTANT VARCHAR2(1 CHAR) := pk_prog_notes_constants.g_epis_pn_det_flg_status_a;
    
        l_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        l_id_pat_ph_ft pat_past_hist_ft_hist.id_pat_ph_ft%TYPE;
    
        l_ph_ft_hist pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
    
    BEGIN
    
        --Get the status of the task                    
        l_flg_add_rem_task := nvl(i_flg_add_rem_task, l_epis_pn_det_flg_status_a);
    
        --if it is to put active then synch with area
        IF l_flg_add_rem_task = l_epis_pn_det_flg_status_a
        THEN
            --Check if it is a synchronizable area            
        
            CASE
            --Expected Discharge Date
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_dicharge_sch THEN
                
                    g_error := 'CALL PK_DISCHARGE.SET_DISCHARGE_SCHEDULE_DATE';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_discharge.set_discharge_schedule_date(i_lang                  => i_lang,
                                                                    i_episode               => i_id_episode,
                                                                    i_patient               => i_id_patient,
                                                                    i_prof                  => i_prof,
                                                                    i_dt_discharge_schedule => i_dt_pn_date,
                                                                    i_flg_hour_origin       => i_date_type,
                                                                    o_id_discharge_schedule => l_id_discharge_schedule,
                                                                    o_error                 => o_error)
                    THEN
                        RAISE e_discharge_schedule_date;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_no;
                
            --Arrival Date Time
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_arrival_date_time THEN
                
                    g_error := 'CALL PK_EPISODE.SET_INTAKE_TIME';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_episode.set_intake_time(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_episode     => i_id_episode,
                                                      i_patient     => i_id_patient,
                                                      i_intake_time => i_dt_pn_date,
                                                      o_dt_register => l_dt_register,
                                                      o_error       => o_error)
                    THEN
                        RAISE e_intake_time;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_no;
                
            --Plan Free Text with Save
                WHEN io_id_task_type IN (pk_prog_notes_constants.g_task_plan_notes,
                                         pk_prog_notes_constants.g_task_subjective,
                                         pk_prog_notes_constants.g_task_objective,
                                         pk_prog_notes_constants.g_task_assessment)
                     AND i_dblock_type = pk_prog_notes_constants.g_dblock_free_text_w_save THEN
                
                    --if it is to put active then synch with area
                    IF i_flg_task_parent = l_yes
                    THEN
                        g_error := 'CALL PK_STRING_UTILS.CLOB_TO_SQLVARCHAR2';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        l_desc := i_pn_note_task;
                    
                        --if there is something set
                        IF l_desc IS NOT NULL
                        THEN
                        
                            g_error := 'CALL PK_DISCHARGE.SET_EPIS_RECOMEND';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                            IF NOT pk_discharge.set_epis_recomend(i_lang             => i_lang,
                                                             i_episode          => i_id_episode,
                                                             i_prof             => i_prof,
                                                             i_flg_type         => CASE
                                                                                       WHEN io_id_task_type = pk_prog_notes_constants.g_task_plan_notes THEN
                                                                                        pk_progress_notes.g_type_plan
                                                                                       WHEN io_id_task_type = pk_prog_notes_constants.g_task_subjective THEN
                                                                                        pk_progress_notes.g_type_subjective
                                                                                       WHEN io_id_task_type = pk_prog_notes_constants.g_task_objective THEN
                                                                                        pk_progress_notes.g_type_objective
                                                                                       WHEN io_id_task_type = pk_prog_notes_constants.g_task_assessment THEN
                                                                                        pk_progress_notes.g_type_assessment
                                                                                   END,
                                                             i_desc             => l_desc,
                                                             i_parent           => io_id_task,
                                                             o_id_epis_recomend => io_id_task,
                                                             o_error            => o_error)
                            THEN
                                RAISE e_epis_recomend;
                            END IF;
                        END IF;
                    
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_yes;
                
            --Diagnosis Notes Free Text with Save
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_diag_notes
                     AND i_dblock_type = pk_prog_notes_constants.g_dblock_free_text_w_save THEN
                
                    --if it is to put active then synch with area
                    IF i_flg_task_parent = l_yes
                    THEN
                        g_error := 'CALL PK_STRING_UTILS.CLOB_TO_SQLVARCHAR2';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        l_desc := i_pn_note_task;
                    
                        --if there is something set
                        IF l_desc IS NOT NULL
                        THEN
                            g_error := 'CALL PK_DIAGNOSIS_CORE.SET_EPIS_DIAG_NOTES';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                            IF NOT pk_diagnosis.set_epis_diag_notes( --
                                                                    i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_episode         => i_id_episode,
                                                                    i_epis_diag_notes => io_id_task,
                                                                    i_notes           => l_desc,
                                                                    o_epis_diag_notes => io_id_task,
                                                                    o_error           => o_error)
                            THEN
                                RAISE e_epis_diag_notes;
                            END IF;
                        END IF;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_yes;
                
            --Free text templates
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_templates THEN
                
                    --if it is to put active then synch with area
                    IF i_flg_task_parent = l_yes
                    THEN
                        --if there is something set
                        IF i_pn_note_task IS NOT NULL
                        THEN
                            g_error := 'CALL PK_TOUCH_OPTION.SET_EPIS_DOCUMENTATION';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                        
                            IF pk_touch_option.check_documentation_has_detail(i_lang                  => i_lang,
                                                                              i_prof                  => i_prof,
                                                                              i_id_epis_documentation => io_id_task) =
                               pk_alert_constant.g_no
                            THEN
                                IF NOT pk_touch_option.set_epis_documentation(i_lang                  => i_lang,
                                                                         i_prof                  => i_prof,
                                                                         i_prof_cat_type         => i_prof_cat_type,
                                                                         i_epis                  => i_id_episode,
                                                                         i_doc_area              => i_id_doc_area,
                                                                         i_doc_template          => pk_touch_option.get_doc_templ_by_epis_doc(i_lang,
                                                                                                                                              i_prof,
                                                                                                                                              io_id_task),
                                                                         i_epis_documentation    => io_id_task,
                                                                         i_flg_type              => CASE
                                                                                                        WHEN io_id_task IS NULL THEN
                                                                                                         'N'
                                                                                                        ELSE
                                                                                                         'E'
                                                                                                    END,
                                                                         i_id_documentation      => table_number(),
                                                                         i_id_doc_element        => NULL,
                                                                         i_id_doc_element_crit   => NULL,
                                                                         i_value                 => NULL,
                                                                         i_notes                 => i_pn_note_task, --13
                                                                         i_id_doc_element_qualif => table_table_number(),
                                                                         i_epis_context          => NULL,
                                                                         i_summary_and_notes     => i_pn_note_task,
                                                                         i_episode_context       => NULL,
                                                                         i_flg_table_origin      => pk_touch_option.g_flg_tab_origin_epis_doc,
                                                                         i_vs_element_list       => NULL,
                                                                         i_vs_save_mode_list     => NULL,
                                                                         i_vs_list               => NULL,
                                                                         i_vs_value_list         => NULL,
                                                                         i_vs_uom_list           => NULL,
                                                                         i_vs_scales_list        => NULL,
                                                                         i_vs_date_list          => NULL,
                                                                         i_vs_read_list          => NULL,
                                                                         o_epis_documentation    => io_id_task,
                                                                         o_error                 => o_error)
                                THEN
                                    RAISE g_exception;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_yes;
                
            --Free text past history
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_ph_free_txt
                     AND i_dblock_type = pk_prog_notes_constants.g_dblock_free_text_w_save THEN
                
                    --if it is to put active then synch with area
                    IF i_flg_task_parent = l_yes
                    THEN
                        --if there is something set
                        IF i_pn_note_task IS NOT NULL
                        THEN
                            g_error := 'CALL pk_past_history.set_past_hist_free_text. i_id_doc_area: ' || i_id_doc_area ||
                                       ' i_ph_ft_id: ' || l_id_pat_ph_ft;
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                        
                            IF NOT pk_past_history.set_past_hist_free_text(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_pat              => i_id_patient,
                                                                           i_episode          => i_id_episode,
                                                                           i_doc_area         => i_id_doc_area,
                                                                           i_ph_ft_id         => l_id_pat_ph_ft,
                                                                           i_ph_ft_text       => i_pn_note_task,
                                                                           i_id_cancel_reason => NULL,
                                                                           i_cancel_notes     => NULL,
                                                                           i_dt_register      => current_timestamp,
                                                                           i_dt_review        => current_timestamp,
                                                                           o_ph_ft_id         => io_id_task,
                                                                           o_pat_ph_ft_hist   => l_ph_ft_hist,
                                                                           o_error            => o_error)
                            THEN
                                g_error := 'set_past_hist_free_text has failed';
                                RAISE g_exception;
                            END IF;
                        
                        END IF;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_no;
                
            --Free text chief complaint
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_chief_complaint_anm
                     AND i_dblock_type = pk_prog_notes_constants.g_dblock_free_text_w_save
                    --the edition is done throught the actions button in the screen that exists to the efect
                     AND io_id_task IS NULL THEN
                
                    --if it is to put active then synch with area
                    IF i_flg_task_parent = l_yes
                    THEN
                        --if there is something set
                        IF i_pn_note_task IS NOT NULL
                        THEN
                            g_error := 'CALL pk_clinical_info.set_epis_anamnesis. io_id_task: ' || io_id_task;
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                        
                            IF NOT pk_clinical_info.set_epis_anamnesis(i_lang              => i_lang,
                                                                  i_episode           => i_id_episode,
                                                                  i_prof              => i_prof,
                                                                  i_desc              => i_pn_note_task,
                                                                  i_flg_type          => pk_save.g_complaint, --'C',
                                                                  i_flg_type_mode     => CASE
                                                                                             WHEN io_id_task IS NULL THEN
                                                                                              pk_clinical_info.g_flg_edition_type_new /*'N'*/
                                                                                             ELSE
                                                                                              pk_clinical_info.g_flg_edition_type_edit /*'E'*/
                                                                                         END, --????
                                                                  i_id_epis_anamnesis => io_id_task,
                                                                  i_id_diag           => NULL,
                                                                  i_flg_class         => NULL,
                                                                  i_prof_cat_type     => pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof),
                                                                  o_id_epis_anamnesis => io_id_task,
                                                                  o_error             => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                        END IF;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_yes;
                
            --Prognosis
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_prognosis
                     AND i_dblock_type = pk_prog_notes_constants.g_dblock_free_text_w_save THEN
                
                    g_error := 'CALL PK_PROGNOSIS.SET_EPIS_PROGNOSIS';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_prognosis.set_epis_prognosis(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_episode           => i_id_episode,
                                                           i_id_epis_prognosis => io_id_task,
                                                           i_id_prognosis      => NULL,
                                                           i_prognosis_notes   => i_pn_note_task,
                                                           o_id_epis_prognosis => io_id_task,
                                                           o_error             => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    --Tasks with tl_task flg_synch_area to 'Y' the Edit Screen doesn't need to reload
                    o_flg_reload := pk_alert_constant.g_yes;
                
                WHEN io_id_task_type = pk_prog_notes_constants.g_task_cits_procedures THEN
                
                    g_error := 'CALL PK_';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                ELSE
                    NULL;
            END CASE;
            o_dt_task := current_timestamp;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_SYNCHRONIZABLE_AREAS',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_synchronizable_areas;

    /********************************************************************************************
    * Sets in all areas which have comments action
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_EPISODE            Episode Identifier
    * @param         I_ID_EPIS_PN            Progress note detail Identifier
    * @param         I_DATE_TYPE             DH- Date hour; D-Date
    * @param         I_FLG_TASK_PARENT       Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param         I_ID_MULTICHOICE        tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param         i_tbl_tasks             Tasks strucure info
    *
    * @param         IO_ID_TASK              Task Identifier
    * @param         IO_ID_TASK_TYPE         Task type Identifier
    * @param         IO_ID_TASK_PARENT       Parent task identifier for comments functionality
    * @param         IO_PN_NOTE_TASK          Task description
    *
    * @param         O_SAVE_TASK             Flag that returns if task it's to be save on the note
    * @param         O_ERROR                 Error information
    *
    * @value         I_FLG_TASK_PARENT       {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @return                                True: Sucess, False: Fail
    *
    * @author                                António Neto
    * @since                                 26-Apr-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION set_comment_on_area
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn_det  IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_task_parent IN VARCHAR2,
        i_id_multichoice  IN NUMBER,
        i_tbl_tasks       IN pk_prog_notes_types.t_table_tasks,
        io_id_task        IN OUT epis_pn_det_task.id_task%TYPE,
        io_id_task_type   IN OUT epis_pn_det_task.id_task_type%TYPE,
        io_id_task_parent IN OUT epis_pn_det_task.id_parent%TYPE,
        io_pn_note_task   IN OUT epis_pn_det_task.pn_note%TYPE,
        o_save_task       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        e_lab_test_status_read EXCEPTION;
        e_exam_read_status     EXCEPTION;
        e_prescription_notes   EXCEPTION;
        e_treat_management     EXCEPTION;
    
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'SET_COMMENT_ON_AREA';
    
        l_desc VARCHAR2(4000);
    
        l_id_presc_notes NUMBER(24);
    
        l_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_task             epis_pn_det_task.id_task%TYPE;
        l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
    BEGIN
        --save task in the note
        o_save_task := pk_alert_constant.g_yes;
    
        CASE
        
        --Labs comment
            WHEN io_id_task_type IN
                 (pk_prog_notes_constants.g_task_analysis_comments, pk_prog_notes_constants.g_task_lab_results) THEN
            
                --don't include in the note
                o_save_task := pk_alert_constant.g_no;
            
                --if task type is Lab results then change it to comment on Lab results
                io_id_task_type := pk_prog_notes_constants.g_task_analysis_comments;
            
                --if there is something set
                IF io_pn_note_task IS NOT NULL
                   AND io_id_task_parent IS NOT NULL
                THEN
                    g_error := 'Get the ID of the task area - i_id_task_parent: ' || io_id_task_parent ||
                               ', i_id_epis_pn_det: ' || i_id_epis_pn_det || ', i_flg_task_parent: ' ||
                               i_flg_task_parent || ', io_id_task_type: ' || io_id_task_type;
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_prog_notes_utils.get_ids_from_struct(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_tbl_tasks           => i_tbl_tasks,
                                                                   i_id_task_type        => pk_prog_notes_constants.g_task_lab_results,
                                                                   i_id_epis_pn_det      => i_id_epis_pn_det,
                                                                   i_flg_task_parent     => i_flg_task_parent,
                                                                   i_id_task_parent      => io_id_task_parent,
                                                                   o_id_task             => l_id_task,
                                                                   o_id_epis_pn_det_task => l_id_epis_pn_det_task,
                                                                   o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF (l_id_epis_pn_det_task IS NULL)
                    THEN
                    
                        SELECT epndt.id_task, epndt.id_epis_pn_det_task
                          INTO l_id_task, l_id_epis_pn_det_task
                          FROM epis_pn_det_task epndt
                         WHERE
                        --if adding/changing a comment use id_epis_pn_det_task
                         (i_flg_task_parent = l_yes AND epndt.id_epis_pn_det_task = io_id_task_parent)
                         OR
                        --if importing/saving a note use id_task for the current note id_epis_pn
                         (i_flg_task_parent = l_no AND epndt.id_task = io_id_task_parent AND
                         epndt.id_epis_pn_det = i_id_epis_pn_det AND
                         epndt.id_task_type = pk_prog_notes_constants.g_task_lab_results AND
                         epndt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a);
                    
                    END IF;
                
                    IF i_flg_task_parent = l_yes
                    THEN
                    
                        g_error := 'CALL PK_STRING_UTILS.CLOB_TO_SQLVARCHAR2';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        l_desc := pk_string_utils.clob_to_sqlvarchar2(i_clob => io_pn_note_task);
                    
                        g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_STATUS_READ';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_lab_tests_api_db.set_lab_test_status_read(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_analysis_result_par => table_number(l_id_task),
                                                                            i_flg_relevant        => table_varchar(NULL),
                                                                            i_notes               => table_varchar(l_desc),
                                                                            o_error               => o_error)
                        THEN
                            RAISE e_lab_test_status_read;
                        END IF;
                    
                        io_pn_note_task := pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_prog_notes_constants.g_sm_comment) ||
                                           pk_prog_notes_constants.g_colon || io_pn_note_task;
                    END IF;
                
                    io_id_task_parent := l_id_epis_pn_det_task;
                END IF;
            
        --Exams comment
            WHEN io_id_task_type IN
                 (pk_prog_notes_constants.g_task_exams_comments, pk_prog_notes_constants.g_task_exam_results) THEN
            
                --don't include in the note
                o_save_task := pk_alert_constant.g_no;
            
                --if task type is exams results then change it to comment on exams results
                io_id_task_type := pk_prog_notes_constants.g_task_exams_comments;
            
                --if there is something set
                IF io_pn_note_task IS NOT NULL
                   AND io_id_task_parent IS NOT NULL
                THEN
                    g_error := 'CALL pk_prog_notes_utils.get_ids_from_struct';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_prog_notes_utils.get_ids_from_struct(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_tbl_tasks           => i_tbl_tasks,
                                                                   i_id_task_type        => pk_prog_notes_constants.g_task_exam_results,
                                                                   i_id_epis_pn_det      => i_id_epis_pn_det,
                                                                   i_flg_task_parent     => i_flg_task_parent,
                                                                   i_id_task_parent      => io_id_task_parent,
                                                                   o_id_task             => l_id_task,
                                                                   o_id_epis_pn_det_task => l_id_epis_pn_det_task,
                                                                   o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF (l_id_epis_pn_det_task IS NULL)
                    THEN
                    
                        g_error := 'Get the ID of the task area - i_id_task_parent: ' || io_id_task_parent ||
                                   ', i_id_epis_pn_det: ' || i_id_epis_pn_det || ', i_flg_task_parent: ' ||
                                   i_flg_task_parent || ', io_id_task_type: ' || io_id_task_type;
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        SELECT er.id_exam_req_det, epndt.id_epis_pn_det_task
                          INTO l_id_task, l_id_epis_pn_det_task
                          FROM epis_pn_det_task epndt
                         INNER JOIN exam_result er
                            ON epndt.id_task = er.id_exam_result
                         WHERE
                        --if adding/changing a comment use id_epis_pn_det_task
                         (i_flg_task_parent = l_yes AND epndt.id_epis_pn_det_task = io_id_task_parent)
                         OR
                        --if importing/saving a note use id_task for the current note id_epis_pn
                         (i_flg_task_parent = l_no AND epndt.id_task = io_id_task_parent AND
                         epndt.id_epis_pn_det = i_id_epis_pn_det AND
                         epndt.id_task_type = pk_prog_notes_constants.g_task_exam_results AND
                         epndt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a);
                    
                    END IF;
                
                    IF i_flg_task_parent = l_yes
                    THEN
                        g_error := 'CALL PK_EXAMS_API_DB.SET_EXAM_STATUS_READ';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_exams_api_db.set_exam_status_read(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_exam_req_det => table_number(l_id_task),
                                                                    i_exam_result  => table_table_number(table_number(NULL)),
                                                                    i_flg_relevant => table_table_varchar(table_varchar(NULL)),
                                                                    i_result_notes => i_id_multichoice,
                                                                    i_notes_result => io_pn_note_task,
                                                                    o_error        => o_error)
                        THEN
                            RAISE e_exam_read_status;
                        END IF;
                    
                        io_pn_note_task := pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_prog_notes_constants.g_sm_comment) ||
                                           pk_prog_notes_constants.g_colon || io_pn_note_task;
                    END IF;
                
                    io_id_task_parent := l_id_epis_pn_det_task;
                END IF;
            
        --Medications comment
            WHEN io_id_task_type IN
                 (pk_prog_notes_constants.g_task_medication_comments, pk_prog_notes_constants.g_task_medic_here) THEN
            
                --if task type is medication then change it to comment on medication
                io_id_task_type := pk_prog_notes_constants.g_task_medication_comments;
            
                --if there is something set
                IF io_pn_note_task IS NOT NULL
                   AND io_id_task_parent IS NOT NULL
                THEN
                    g_error := 'CALL pk_prog_notes_utils.get_ids_from_struct';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_prog_notes_utils.get_ids_from_struct(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_tbl_tasks           => i_tbl_tasks,
                                                                   i_id_task_type        => pk_prog_notes_constants.g_task_medic_here,
                                                                   i_id_epis_pn_det      => i_id_epis_pn_det,
                                                                   i_flg_task_parent     => i_flg_task_parent,
                                                                   i_id_task_parent      => io_id_task_parent,
                                                                   o_id_task             => l_id_task,
                                                                   o_id_epis_pn_det_task => l_id_epis_pn_det_task,
                                                                   o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF (l_id_epis_pn_det_task IS NULL)
                    THEN
                        BEGIN
                            g_error := 'Get the ID of the task area - i_id_task_parent: ' || io_id_task_parent ||
                                       ', i_id_epis_pn_det: ' || i_id_epis_pn_det || ', i_flg_task_parent: ' ||
                                       i_flg_task_parent || ', io_id_task_type: ' || io_id_task_type;
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
                            SELECT epndt.id_task, epndt.id_epis_pn_det_task
                              INTO l_id_task, l_id_epis_pn_det_task
                              FROM epis_pn_det_task epndt
                             WHERE
                            --if adding/changing a comment use id_epis_pn_det_task
                             (i_flg_task_parent = l_yes AND epndt.id_epis_pn_det_task = io_id_task_parent)
                             OR
                            --if importing/saving a note use id_task for the current note id_epis_pn
                             (i_flg_task_parent = l_no AND epndt.id_task = io_id_task_parent AND
                             epndt.id_epis_pn_det = i_id_epis_pn_det AND
                             epndt.id_task_type = pk_prog_notes_constants.g_task_medic_here AND
                             epndt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a)
                             AND rownum <= 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_task             := NULL;
                                l_id_epis_pn_det_task := NULL;
                        END;
                    END IF;
                
                    IF i_flg_task_parent = l_yes
                    THEN
                    
                        g_error := 'CALL PK_STRING_UTILS.CLOB_TO_SQLVARCHAR2';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        l_desc := pk_string_utils.clob_to_sqlvarchar2(i_clob => io_pn_note_task);
                    
                        g_error := 'CALL PK_API_PFH_IN.SET_PRESCRIPTION_NOTES';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT pk_api_pfh_in.set_prescription_notes(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_presc            => l_id_task,
                                                                    i_notes               => l_desc,
                                                                    o_id_presc_notes      => l_id_presc_notes,
                                                                    o_id_presc_notes_item => io_id_task)
                        THEN
                            RAISE e_prescription_notes;
                        END IF;
                    
                        io_pn_note_task := pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_prog_notes_constants.g_sm_comment) ||
                                           pk_prog_notes_constants.g_colon || io_pn_note_task;
                    END IF;
                
                    io_id_task_parent := l_id_epis_pn_det_task;
                END IF;
            
        --Procedures comment
            WHEN io_id_task_type IN
                 (pk_prog_notes_constants.g_task_procedures_comments, pk_prog_notes_constants.g_task_procedures) THEN
            
                --if task type is procedures then change it to comment on procedures
                io_id_task_type := pk_prog_notes_constants.g_task_procedures_comments;
            
                --if there is something set
                IF io_pn_note_task IS NOT NULL
                   AND io_id_task_parent IS NOT NULL
                THEN
                    g_error := 'CALL pk_prog_notes_utils.get_ids_from_struct';
                    pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT pk_prog_notes_utils.get_ids_from_struct(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_tbl_tasks           => i_tbl_tasks,
                                                                   i_id_task_type        => pk_prog_notes_constants.g_task_procedures,
                                                                   i_id_epis_pn_det      => i_id_epis_pn_det,
                                                                   i_flg_task_parent     => i_flg_task_parent,
                                                                   i_id_task_parent      => io_id_task_parent,
                                                                   o_id_task             => l_id_task,
                                                                   o_id_epis_pn_det_task => l_id_epis_pn_det_task,
                                                                   o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF (l_id_epis_pn_det_task IS NULL)
                    THEN
                    
                        g_error := 'Get the ID of the task area - i_id_task_parent: ' || io_id_task_parent ||
                                   ', i_id_epis_pn_det: ' || i_id_epis_pn_det || ', i_flg_task_parent: ' ||
                                   i_flg_task_parent || ', io_id_task_type: ' || io_id_task_type;
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        SELECT epndt.id_task, epndt.id_epis_pn_det_task
                          INTO l_id_task, l_id_epis_pn_det_task
                          FROM epis_pn_det_task epndt
                         WHERE
                        --if adding/changing a comment use id_epis_pn_det_task
                         (i_flg_task_parent = l_yes AND epndt.id_epis_pn_det_task = io_id_task_parent)
                         OR
                        --if importing/saving a note use id_task for the current note id_epis_pn
                         (i_flg_task_parent = l_no AND epndt.id_task = io_id_task_parent AND
                         epndt.id_epis_pn_det = i_id_epis_pn_det AND
                         epndt.id_task_type = pk_prog_notes_constants.g_task_procedures AND
                         epndt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a);
                    END IF;
                
                    IF i_flg_task_parent = l_yes
                    THEN
                    
                        g_error := 'CALL PK_STRING_UTILS.CLOB_TO_SQLVARCHAR2';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        l_desc := pk_string_utils.clob_to_sqlvarchar2(i_clob => io_pn_note_task);
                    
                        g_error := 'CALL PK_MEDICAL_DECISION.SET_TREAT_MANAGEMENT';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        IF NOT
                            pk_medical_decision.set_treat_management_no_comit(i_lang                    => i_lang,
                                                                              i_prof                    => i_prof,
                                                                              i_epis                    => i_id_episode,
                                                                              i_treatment               => l_id_task,
                                                                              i_flg_type                => pk_medical_decision.g_treat_type_interv,
                                                                              i_desc_treat_manag        => l_desc,
                                                                              o_id_treatment_management => io_id_task,
                                                                              o_error                   => o_error)
                        THEN
                            RAISE e_treat_management;
                        END IF;
                    
                        io_pn_note_task := pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_prog_notes_constants.g_sm_comment) ||
                                           pk_prog_notes_constants.g_colon || io_pn_note_task;
                    END IF;
                
                    io_id_task_parent := l_id_epis_pn_det_task;
                END IF;
            
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMMENT_ON_AREA',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_comment_on_area;

    /********************************************************************************************
    * Gets multichoice options for comments functionality
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TL_TASK            Task Type Identifier
    *
    * @param         O_DATA                  Multichoice options list
    * @param         O_ERROR                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                António Neto
    * @since                                 30-Apr-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_multichoice
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        CASE
        --Multichoice for Exams results Comments
            WHEN i_id_tl_task IN
                 (pk_prog_notes_constants.g_task_exams_comments, pk_prog_notes_constants.g_task_exam_results) THEN
            
                g_error := 'OPEN CURSOR';
                OPEN o_data FOR
                    SELECT *
                      FROM TABLE(pk_prog_notes_in.get_comment_multichoice_int(i_lang       => i_lang,
                                                                              i_prof       => i_prof,
                                                                              i_id_tl_task => i_id_tl_task)) t;
            ELSE
                pk_types.open_my_cursor(i_cursor => o_data);
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_COMMENT_MULTICHOICE',
                                              o_error);
        
            RETURN FALSE;
        
    END get_comment_multichoice;

    /********************************************************************************************
    * Gets multichoice options for comments functionality
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TL_TASK            Task Type Identifier
    *
    * @return                                Multichoice options
    *
    * @author                                António Neto
    * @since                                 09-May-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_multichoice_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE
    ) RETURN coll_multichoice
        PIPELINED IS
        l_rec_multichoice rec_multichoice;
        l_result_notes    pk_types.cursor_type;
        l_error           t_error_out;
    BEGIN
        CASE
        --Multichoice for Exams results Comments
            WHEN i_id_tl_task IN
                 (pk_prog_notes_constants.g_task_exams_comments, pk_prog_notes_constants.g_task_exam_results) THEN
                g_error := 'CALL PK_EXAMS_API_DB.GET_EXAM_RESULT_NOTES_LIST';
                IF NOT pk_exams_api_db.get_exam_result_notes_list(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  o_result_notes => l_result_notes,
                                                                  o_error        => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'FETCH CURSOR';
                pk_alertlog.log_debug(g_error);
                LOOP
                    FETCH l_result_notes
                        INTO l_rec_multichoice.data, l_rec_multichoice.label, l_rec_multichoice.flg_free_text;
                    EXIT WHEN l_result_notes%NOTFOUND;
                
                    PIPE ROW(l_rec_multichoice);
                
                END LOOP;
        END CASE;
        RETURN;
    END get_comment_multichoice_int;

    /********************************************************************************************
    * Gets the task type for the parent task of the Comment
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TASK_TYPE          Comment task type identifier
    *
    * @return                                Comment Parent Task type identifier
    *
    * @author                                António Neto
    * @since                                 07-may-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_task_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN epis_pn_det_task.id_task_type%TYPE IS
        l_id_task_type epis_pn_det_task.id_task_type%TYPE := NULL;
    BEGIN
    
        CASE
        --Lab comments
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_analysis_comments THEN
                l_id_task_type := pk_prog_notes_constants.g_task_lab_results;
                --Exams comments
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_exams_comments THEN
                l_id_task_type := pk_prog_notes_constants.g_task_exam_results;
                --Medication comments
            WHEN i_id_task_type IN (pk_prog_notes_constants.g_task_medication_comments) THEN
                l_id_task_type := pk_prog_notes_constants.g_task_medic_here;
                --Procedures comments
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_procedures_comments THEN
                l_id_task_type := pk_prog_notes_constants.g_task_procedures;
            ELSE
                l_id_task_type := NULL;
        END CASE;
    
        RETURN l_id_task_type;
    
    END get_comment_task_type;

    /********************************************************************************************
    * Returns if multichoice is needed for type of task
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TASK_TYPE          Comment task type identifier
    *
    * @return                                Y - Has multichoice, N - otherwise
    *
    * @author                                António Neto
    * @since                                 09-May-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION has_multichoice
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_has_multichoice VARCHAR2(1 CHAR);
    BEGIN
        CASE
        --Multichoice for Exams results Comments
            WHEN i_id_task_type IN
                 (pk_prog_notes_constants.g_task_exams_comments, pk_prog_notes_constants.g_task_exam_results) THEN
            
                l_has_multichoice := pk_alert_constant.g_yes;
            ELSE
                l_has_multichoice := pk_alert_constant.g_no;
        END CASE;
    
        RETURN l_has_multichoice;
    
    END has_multichoice;

    /********************************************************************************************
    * Gets the comment task type for the parent task
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TASK_TYPE          Parent task type identifier
    *
    * @return                                Comment Task type identifier
    *
    * @author                                ANTONIO.NETO
    * @since                                 10-May-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_task_type_parent
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN epis_pn_det_task.id_task_type%TYPE IS
        l_id_task_type epis_pn_det_task.id_task_type%TYPE := NULL;
    BEGIN
    
        CASE
        --Lab comments
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_lab_results THEN
                l_id_task_type := pk_prog_notes_constants.g_task_analysis_comments;
                --Exams comments
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_exam_results THEN
                l_id_task_type := pk_prog_notes_constants.g_task_exams_comments;
                --Medication comments
            WHEN i_id_task_type IN (pk_prog_notes_constants.g_task_medic_here) THEN
                l_id_task_type := pk_prog_notes_constants.g_task_medication_comments;
                --Procedures comments
            WHEN i_id_task_type = pk_prog_notes_constants.g_task_procedures THEN
                l_id_task_type := pk_prog_notes_constants.g_task_procedures_comments;
            ELSE
                l_id_task_type := NULL;
        END CASE;
    
        RETURN l_id_task_type;
    
    END get_comment_task_type_parent;

    /**
    * Review tasks
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_episode          Episode ID    
    * @param   i_id_record_area      record id
    * @param   i_flg_context         record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param   i_dt_review           date of review
    * @param   i_review_notes        review notes (optional)
    * @param   i_flg_auto            reviewed automatically (Y/N)
    * @param   i_id_task_type        Task type identifier
    * @param   i_id_patient          Patient identifier
    *
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author                        Sofia Mendes
    * @version                       2.6.1.2
    * @since                         19-Ago-2011
    */
    FUNCTION set_review_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_dt_review      IN review_detail.dt_review%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        i_id_task_type   IN epis_pn_det_task.id_task_type%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_invalid_arguments_exc EXCEPTION;
        l_ft_flg    VARCHAR2(1 CHAR);
        l_record_id review_detail.id_record_area%TYPE;
    
        l_id_review      NUMBER(24);
        l_code_review    NUMBER(24);
        l_review_desc    VARCHAR2(1000 CHAR);
        l_dt_create      TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_prof_create NUMBER(24);
        l_dt_last_update TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_info_source  CLOB;
        l_pat_not_take CLOB;
        l_pat_take     CLOB;
        l_notes        CLOB;
    BEGIN
    
        IF i_id_task_type != pk_prog_notes_constants.g_task_reported_medic
        THEN
            --others go through the review context 
            IF (i_flg_context = pk_review.get_problems_context())
            THEN
                g_error := 'CALL pk_problems.set_pat_problem_review. i_id_record_area: ' || i_id_record_area ||
                           ' i_flg_context: ' || i_flg_context;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_pat_problem => table_number(i_id_record_area),
                                                          i_flg_source     => table_varchar(i_flg_context),
                                                          i_review_notes   => i_review_notes,
                                                          i_episode        => i_episode,
                                                          i_flg_auto       => i_flg_auto,
                                                          o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSIF (i_flg_context = pk_review.get_allergies_context())
            THEN
                g_error := 'CALL pk_allergy.set_allergy_as_review. i_id_record_area: ' || i_id_record_area;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_allergy.set_allergy_as_review(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => i_episode,
                                                        i_id_pat_allergy => i_id_record_area,
                                                        i_review_notes   => i_review_notes,
                                                        o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSIF (i_flg_context = pk_review.get_habits_context())
            THEN
                g_error := 'CALL pk_patient.set_habit_review. i_id_record_area: ' || i_id_record_area;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_patient.set_habit_review(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   i_id_habit     => i_id_record_area,
                                                   i_review_notes => i_review_notes,
                                                   o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSIF (i_flg_context IN (pk_review.get_past_history_context(), pk_review.get_past_history_ft_context()))
            THEN
                IF (i_flg_context = pk_review.get_past_history_context())
                THEN
                    l_ft_flg    := pk_alert_constant.g_no;
                    l_record_id := i_id_record_area;
                ELSE
                    g_error := 'GET id_pat_ph_ft_hist. i_id_record_area: ' || i_id_record_area;
                    pk_alertlog.log_debug(g_error);
                    SELECT id_pat_ph_ft_hist
                      INTO l_record_id
                      FROM (SELECT pphfth.id_pat_ph_ft_hist
                              FROM pat_past_hist_ft_hist pphfth
                             WHERE pphfth.id_pat_ph_ft = i_id_record_area
                             ORDER BY pphfth.dt_register)
                     WHERE rownum = 1;
                
                    l_ft_flg := pk_alert_constant.g_yes;
                END IF;
            
                g_error := 'CALL pk_patient.set_past_history_review. l_record_id: ' || l_record_id ||
                           ' i_flg_context: ' || i_flg_context;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_past_history.set_past_history_review(i_lang                  => i_lang,
                                                               i_prof                  => i_prof,
                                                               i_episode               => i_episode,
                                                               i_id_past_history       => table_number(l_record_id),
                                                               i_review_notes          => i_review_notes,
                                                               i_ft_flg                => table_varchar(l_ft_flg),
                                                               i_id_epis_documentation => NULL,
                                                               o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSIF (i_flg_context = pk_review.get_template_context())
            THEN
                g_error := 'CALL pk_patient.set_past_history_review. i_id_epis_documentation: ' || i_id_record_area ||
                           ' i_flg_context: ' || i_flg_context;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_past_history.set_past_history_review(i_lang                  => i_lang,
                                                               i_prof                  => i_prof,
                                                               i_episode               => i_episode,
                                                               i_id_past_history       => table_number(),
                                                               i_review_notes          => i_review_notes,
                                                               i_ft_flg                => table_varchar(),
                                                               i_id_epis_documentation => i_id_record_area,
                                                               o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSIF i_flg_context IS NOT NULL
            THEN
                g_error := 'CALL pk_review.set_review. i_id_record_area: ' || i_id_record_area || ' i_flg_context: ' ||
                           i_flg_context;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_review.set_review(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_record_area => i_id_record_area,
                                            i_flg_context    => i_flg_context,
                                            i_dt_review      => i_dt_review,
                                            i_review_notes   => NULL,
                                            o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REVIEW_INFO',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_review_info;

    /********************************************************************************************
    * Get template scores and classifications descriptions
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_patient               Patient ID
    * @param   i_id_documentation        list od id_epis_documentation
    *
    * @return                             template scores and classifications descriptions
    *
    * @author                             Sofia Mendes
    * @version                            2.6.3
    * @since                              15-May-2013
    **********************************************************************************************/
    FUNCTION get_template_scores
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_documentation IN table_number
    ) RETURN pk_prog_notes_types.t_tab_templ_scores IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_TEMPLATE_SCORES';
        l_out_strut t_error_out;
    
        l_tab_templ_scores pk_prog_notes_types.t_tab_templ_scores;
    BEGIN
        g_error := 'GET template scores';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR rec IN (SELECT t.id_epis_documentation, t.desc_class
                      FROM TABLE(pk_scales_core.tf_scales_list(i_lang, i_prof, i_id_patient, i_id_documentation)) t
                    UNION
                    SELECT t.id_epis_documentation, t.desc_class
                      FROM TABLE(pk_risk_factor.tf_risk_total_score(i_lang, i_prof, i_id_documentation)) t
                    UNION
                    SELECT t.id_epis_documentation, t.desc_class
                      FROM TABLE(pk_hcn.tf_hcn_score(i_lang, i_prof, i_id_documentation)) t)
        LOOP
            l_tab_templ_scores(rec.id_epis_documentation) := rec.desc_class;
        END LOOP;
    
        RETURN l_tab_templ_scores;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_tab_templ_scores;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TEMPLATE_SCORES',
                                              l_out_strut);
            RETURN l_tab_templ_scores;
    END get_template_scores;

    FUNCTION get_template_clinical_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_documentation IN table_number
    ) RETURN pk_prog_notes_types.t_tab_templ_scores IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_TEMPLATE_CLINICAL_DATE';
        l_out_strut t_error_out;
    
        l_tab_templ_clinical_dt pk_prog_notes_types.t_tab_templ_scores;
        l_label                 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'DOCUMENTATION_M057');
    BEGIN
        g_error := 'GET template scores';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR rec IN (SELECT ed.id_epis_documentation,
                           pk_date_utils.date_char_tsz(i_lang, ed.dt_clinical, i_prof.institution, i_prof.software) dt_clinical_chr
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT t.column_value id
                                                          FROM TABLE(i_id_documentation) t))
        LOOP
            IF rec.dt_clinical_chr IS NOT NULL
            THEN
                l_tab_templ_clinical_dt(rec.id_epis_documentation) := l_label || ': ' || rec.dt_clinical_chr;
            END IF;
        END LOOP;
    
        RETURN l_tab_templ_clinical_dt;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_tab_templ_clinical_dt;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_out_strut);
            RETURN l_tab_templ_clinical_dt;
    END get_template_clinical_date;
    /********************************************************************************************
    * Get decriptions of the template records
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_patient               Patient ID
    * @param   i_id_documentation        list od id_epis_documentation
    *
    * @return                             templates descriptions
    *
    * @author                             Sofia Mendes
    * @version                            2.6.2
    * @since                              26-Jun-2012
    *
    **********************************************************************************************/
    FUNCTION get_templates_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_documentation IN table_number
    ) RETURN pk_prog_notes_types.t_tasks_descs IS
        l_func_name CONSTANT VARCHAR2(18 CHAR) := 'GET_TEMPLATES_DESC';
        --
        l_out_strut   t_error_out;
        l_tasks_descs pk_prog_notes_types.t_tasks_descs;
        l_desc_rec    pk_prog_notes_types.t_rec_task_desc;
    
        l_cur_templ pk_touch_option_out.t_cur_plain_text_entry;
        l_tbl_templ pk_touch_option_out.t_coll_plain_text_entry;
    
        l_tab_templ_scores      pk_prog_notes_types.t_tab_templ_scores;
        l_tab_templ_clinical_dt pk_prog_notes_types.t_tab_templ_scores;
    BEGIN
        g_error := 'CALL pk_touch_option_out.get_plain_text_entries.';
        pk_alertlog.log_debug(g_error);
        pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                   i_prof                    => i_prof,
                                                   i_epis_documentation_list => i_id_documentation,
                                                   o_entries                 => l_cur_templ);
    
        g_error := 'CALL get_template_scores';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_tab_templ_scores := get_template_scores(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_patient       => i_id_patient,
                                                  i_id_documentation => i_id_documentation);
    
        l_tab_templ_clinical_dt := get_template_clinical_date(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_patient       => i_id_patient,
                                                              i_id_documentation => i_id_documentation);
    
        LOOP
            g_error := 'FETCH TEMPLATES CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH l_cur_templ BULK COLLECT
                INTO l_tbl_templ LIMIT g_limit;
        
            FOR i IN 1 .. l_tbl_templ.count
            LOOP
                l_desc_rec.task_desc      := l_tbl_templ(i).area_name;
                l_desc_rec.task_desc_long := CASE
                                                 WHEN l_tab_templ_clinical_dt.exists(l_tbl_templ(i).id_epis_documentation) THEN
                                                  l_tab_templ_clinical_dt(l_tbl_templ(i).id_epis_documentation) || chr(10)
                                                 ELSE
                                                  NULL
                                             END || CASE
                                                 WHEN l_tab_templ_scores.exists(l_tbl_templ(i).id_epis_documentation) THEN
                                                  l_tab_templ_scores(l_tbl_templ(i).id_epis_documentation) || chr(10)
                                                 ELSE
                                                  NULL
                                             END ||
                                             TRIM(leading pk_prog_notes_constants.g_new_line FROM l_tbl_templ(i).plain_text_entry);
                l_desc_rec.task_title     := l_tbl_templ(i).template_title;
            
                l_tasks_descs(l_tbl_templ(i).id_epis_documentation) := l_desc_rec;
            
            END LOOP;
            EXIT WHEN l_cur_templ%NOTFOUND;
        END LOOP;
    
        RETURN l_tasks_descs;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_tasks_descs;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TEMPLATES_DESC',
                                              l_out_strut);
            RETURN l_tasks_descs;
    END get_templates_desc;

    /**************************************************************************
    * Gets the tasks descriptions by grouo of tasks.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID   
    * @param i_id_episode             Episode Identifier 
    * @param i_id_patient             Patient ID
    * @param i_tasks_groups_by_type   Lists of tasks by task type
    * @param o_tasks_descs_by_type    Lists of tasks descs by task type
    * @param o_error                  Error
    *
    * @value i_flg_has_notes          {*} 'Y'- Has comments {*} 'N'- otherwise
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_group_descriptions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_tasks_groups_by_type IN pk_prog_notes_types.t_tasks_groups_by_type,
        o_tasks_descs_by_type  OUT pk_prog_notes_types.t_tasks_descs_by_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GROUP_DESCRIPTIONS';
        l_tasks_descs pk_prog_notes_types.t_tasks_descs;
    BEGIN
    
        IF (i_tasks_groups_by_type.exists(pk_prog_notes_constants.g_medication))
        THEN
            g_error := 'CALL pk_api_pfh_clindoc_in.get_single_page_med_desc tasks_groups_by_type: ' ||
                       to_char(pk_prog_notes_constants.g_medication);
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_tasks_descs := pk_api_pfh_clindoc_in.get_single_page_med_desc(i_lang                 => i_lang,
                                                                            i_prof                 => i_prof,
                                                                            i_id_episode           => i_id_episode,
                                                                            i_id_presc             => i_tasks_groups_by_type(pk_prog_notes_constants.g_medication),
                                                                            i_flg_complete         => pk_alert_constant.g_no,
                                                                            i_flg_with_notes       => pk_alert_constant.g_yes,
                                                                            i_flg_with_status      => pk_alert_constant.g_yes,
                                                                            i_flg_with_recon_notes => pk_alert_constant.g_no);
        
            o_tasks_descs_by_type(pk_prog_notes_constants.g_medication) := l_tasks_descs;
        END IF;
    
        IF (i_tasks_groups_by_type.exists(pk_prog_notes_constants.g_med_rec))
        THEN
            g_error := 'CALL pk_api_pfh_clindoc_in.get_single_page_med_desctasks_groups_by_type: ' ||
                       to_char(pk_prog_notes_constants.g_med_rec);
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_tasks_descs := pk_api_pfh_clindoc_in.get_single_page_med_desc(i_lang                 => i_lang,
                                                                            i_prof                 => i_prof,
                                                                            i_id_episode           => i_id_episode,
                                                                            i_id_presc             => i_tasks_groups_by_type(pk_prog_notes_constants.g_med_rec),
                                                                            i_flg_complete         => pk_alert_constant.g_no,
                                                                            i_flg_with_notes       => pk_alert_constant.g_no,
                                                                            i_flg_with_status      => pk_alert_constant.g_no,
                                                                            i_flg_with_recon_notes => pk_alert_constant.g_yes);
        
            o_tasks_descs_by_type(pk_prog_notes_constants.g_med_rec) := l_tasks_descs;
        
        END IF;
    
        IF (i_tasks_groups_by_type.exists(pk_prog_notes_constants.g_templates))
        THEN
            g_error := 'CALL get_templates_desc';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_tasks_descs := get_templates_desc(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_patient       => i_id_patient,
                                                i_id_documentation => i_tasks_groups_by_type(pk_prog_notes_constants.g_templates));
        
            o_tasks_descs_by_type(pk_prog_notes_constants.g_templates) := l_tasks_descs;
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_group_descriptions;

    /************************************************************************************************************
    * Get the vital sign ranks to be used on single page. 
    * Rank 1: 1st value
    * Rank 2: penultimate value
    * Rank 3: last value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        Vital sign read ID
    * @param      i_scope                     Scope ID (Episode ID; Visit ID; Patient ID)
    * @param      i_flg_scope                 Scope (E- Episode, V- Visit, P- Patient)
    * @param      o_id_vital_sign_read        Vital sign read ID
    * @param      o_rank                      Rank
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_table_ranks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_scope IN VARCHAR2,
        i_scope     IN NUMBER,
        i_id_tasks  IN table_number,
        o_id_tasks  OUT NOCOPY table_number,
        o_rank      OUT NOCOPY table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(17 CHAR) := 'GET_ID_VITAL_SIGN';
    BEGIN
        g_error := 'pk_vital_signs.get_vital_signs_ranks';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_vital_sign.get_vital_signs_ranks(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_flg_scope          => i_flg_scope,
                                                   i_scope              => i_scope,
                                                   i_id_vital_sign_read => i_id_tasks,
                                                   o_id_vital_sign_read => o_id_tasks,
                                                   o_rank               => o_rank,
                                                   o_error              => o_error)
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_table_ranks;

    FUNCTION get_pat_gender_text
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_gender      VARCHAR2(1 CHAR);
        l_gender_text VARCHAR2(4000);
    
    BEGIN
        -- get gender
        l_gender      := pk_patient.get_pat_gender(i_id_patient => i_id_pat);
        l_gender_text := pk_sysdomain.get_domain_no_avail(i_code_dom => 'PATIENT.GENDER',
                                                          i_val      => l_gender,
                                                          i_lang     => i_lang);
    
        RETURN l_gender_text;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_pat_gender_text;

    FUNCTION get_pat_room_text
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_room_text VARCHAR2(4000);
    
    BEGIN
    
        SELECT coalesce(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
          INTO l_room_text
          FROM epis_info ei
          LEFT JOIN room r
            ON r.id_room = ei.id_room
         WHERE ei.id_episode = i_id_episode;
    
        RETURN l_room_text;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_pat_room_text;

    FUNCTION get_pat_bed_text
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_bed_text VARCHAR2(4000);
    BEGIN
    
        SELECT coalesce(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))
          INTO l_bed_text
          FROM epis_info ei
          LEFT JOIN bed b
            ON b.id_bed = ei.id_bed
         WHERE ei.id_episode = i_id_episode;
    
        RETURN l_bed_text;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_pat_bed_text;
    /************************************************************************************************************
    * get_visit_info_amb
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Paulo T
    * @version    2.6.2
    * @since      2012-09-25
    ***********************************************************************************************************/
    FUNCTION get_visit_info_amb
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
        
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'GET_VISIT_INFO_AMB';
        l_str                     CLOB;
        l_visit_date              sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T001');
        l_type_of_visit           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T002');
        l_attending_physician     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T003');
        l_primary_care_physician  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T004');
        l_disposition_destination sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T005');
        l_epis_type_msg           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'EHR_VST_T006');
        l_discharge_destination   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T010');
        l_discharge_date          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T008');
        l_condition_on_discharge  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'VISIT_INFO_T009');
        l_token_list              table_varchar;
    
        l_epis_type_desc    VARCHAR2(500 CHAR);
        l_discharge_cond    VARCHAR2(2000 CHAR);
        l_discharge_dest    VARCHAR2(2000 CHAR);
        l_disch_reason      translation.desc_lang_2%TYPE;
        l_disch_destination translation.desc_lang_2%TYPE;
        l_admission_dt_text VARCHAR2(4000);
        l_disch_signature   VARCHAR2(4000);
    
        l_error              t_error_out;
        l_id_prof_compl      epis_complaint.id_professional%TYPE;
        l_complaint_date     epis_complaint.adw_last_update_tstz%TYPE;
        l_type_of_visit_desc VARCHAR2(2000);
    BEGIN
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_str IS NOT NULL
                THEN
                    l_str := l_str || chr(10);
                END IF;
                IF l_token_list(i) = 'AD' --admission date
                THEN
                    --get admission date
                    SELECT pk_date_utils.date_char_tsz(i_lang,
                                                       decode(e.flg_ehr,
                                                              pk_ehr_access.g_flg_ehr_normal,
                                                              e.dt_begin_tstz,
                                                              NULL),
                                                       i_prof.institution,
                                                       i_prof.software)
                      INTO l_admission_dt_text
                      FROM episode e
                     WHERE e.id_episode = i_id_episode;
                
                    l_str := l_str || l_visit_date || pk_prog_notes_constants.g_colon ||
                             nvl(l_admission_dt_text, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'TYPE' --CONSULT TYPE
                THEN
                    l_type_of_visit_desc := pk_episode.get_appointment_type(i_lang       => i_lang,
                                                                            i_prof       => i_prof,
                                                                            i_id_episode => i_id_episode);
                    l_str                := l_str || l_type_of_visit || pk_prog_notes_constants.g_colon ||
                                            l_type_of_visit_desc;
                
                ELSIF l_token_list(i) = 'ETYPE' --episode type
                THEN
                    l_epis_type_desc := pk_episode.get_epis_type_desc(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_episode => i_id_episode);
                    l_str            := l_str || l_epis_type_msg || pk_prog_notes_constants.g_colon || l_epis_type_desc;
                
                ELSIF l_token_list(i) = 'CDISCH' --CONDITION ON DISCHARGE
                THEN
                
                    l_discharge_cond := pk_discharge.get_patient_condition(i_lang       => i_lang,
                                                                           i_prof       => i_prof,
                                                                           i_id_episode => i_id_episode);
                    l_str            := l_str || l_condition_on_discharge || pk_prog_notes_constants.g_colon ||
                                        nvl(l_discharge_cond, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'DISCH' --DISCHARGE destination
                THEN
                    IF NOT pk_discharge.get_epis_disch_rea_dest_desc(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_episode     => i_id_episode,
                                                                     o_reason      => l_disch_reason,
                                                                     o_destination => l_disch_destination,
                                                                     o_signature   => l_disch_signature,
                                                                     o_error       => l_error)
                    THEN
                        NULL;
                    END IF;
                
                    IF l_disch_reason IS NOT NULL
                    THEN
                        l_discharge_dest := l_disch_reason || ': ';
                    END IF;
                    l_discharge_dest := l_discharge_dest || l_disch_destination;
                    l_str            := l_str || l_discharge_destination || pk_prog_notes_constants.g_colon ||
                                        nvl(l_discharge_dest, pk_prog_notes_constants.g_triple_colon);
                
                END IF;
            END LOOP;
        ELSE
            SELECT l_visit_date || pk_prog_notes_constants.g_colon ||
                    nvl(t.visit_date, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_type_of_visit || pk_prog_notes_constants.g_colon || --
                    CASE
                        WHEN t.desc_dsc IS NULL
                             AND t.desc_flg_sched IS NULL THEN
                         pk_prog_notes_constants.g_triple_colon
                        WHEN t.desc_dsc IS NULL
                             AND t.desc_flg_sched IS NOT NULL THEN
                         t.desc_flg_sched
                        WHEN t.desc_dsc IS NOT NULL
                             AND t.desc_flg_sched IS NULL THEN
                         t.desc_dsc
                        ELSE
                         t.desc_dsc || pk_prog_notes_constants.g_flg_sep || t.desc_flg_sched
                    END || chr(10) || --
                    l_attending_physician || pk_prog_notes_constants.g_colon ||
                    nvl(t.desc_prof, pk_prog_notes_constants.g_triple_colon) || --
                    CASE
                        WHEN t.spec_prof IS NOT NULL THEN
                         pk_prog_notes_constants.g_open_parenthesis || t.spec_prof ||
                         pk_prog_notes_constants.g_close_parenthesis
                        ELSE
                         NULL
                    END || chr(10) || --
                    l_primary_care_physician || pk_prog_notes_constants.g_colon ||
                    nvl(t.primary_care_doc, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_disposition_destination || pk_prog_notes_constants.g_colon || --
                    CASE
                        WHEN t.discharge_dest IS NULL
                             AND t.discharge_reason IS NULL THEN
                         pk_prog_notes_constants.g_triple_colon
                        WHEN discharge_dest IS NULL
                             AND t.discharge_reason IS NOT NULL THEN
                         t.discharge_reason
                        WHEN t.discharge_dest IS NOT NULL
                             AND t.discharge_reason IS NULL THEN
                         t.discharge_dest
                        ELSE
                         t.discharge_dest || pk_prog_notes_constants.g_flg_sep || t.discharge_reason
                    END str
              INTO l_str
              FROM (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                       decode(e.flg_ehr,
                                                              pk_ehr_access.g_flg_ehr_normal,
                                                              e.dt_begin_tstz,
                                                              NULL),
                                                       i_prof.institution,
                                                       i_prof.software) visit_date,
                           (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                              FROM dep_clin_serv dcs
                              JOIN clinical_service cs
                                ON cs.id_clinical_service = dcs.id_clinical_service
                             WHERE dcs.id_dep_clin_serv = s.id_dcs_requested) desc_dsc,
                           pk_sysdomain.get_domain(pk_grid_amb.g_schdl_outp_sched_domain, sp.flg_sched, i_lang) desc_flg_sched,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(ei.id_professional, ps.id_professional)) desc_prof,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            NULL,
                                                            e.id_episode) spec_prof,
                           pk_patient.get_designated_provider(i_lang, i_prof, e.id_patient, e.id_episode) primary_care_doc,
                           decode(nvl(drd.id_discharge_dest, 0),
                                  0,
                                  decode(nvl(drd.id_dep_clin_serv, 0),
                                         0,
                                         decode(nvl(drd.id_institution, 0),
                                                0,
                                                pk_translation.get_translation(i_lang, dpt.code_department),
                                                pk_translation.get_translation(i_lang, i.code_institution)),
                                         nvl2(drd.id_department,
                                              pk_translation.get_translation(i_lang, dpt.code_department) ||
                                              pk_prog_notes_constants.g_flg_sep,
                                              '') || pk_translation.get_translation(i_lang, cs.code_clinical_service)),
                                  pk_translation.get_translation(i_lang, dd.code_discharge_dest)) discharge_dest,
                           pk_translation.get_translation(i_lang, dr.code_discharge_reason) discharge_reason,
                           row_number() over(ORDER BY nvl(nvl(nvl(nvl(d.dt_pend_tstz, d.dt_med_tstz), d.dt_nurse), d.dt_nutritionist), d.dt_therapist) DESC) linenumber
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      LEFT JOIN schedule s
                        ON s.id_schedule = ei.id_schedule
                      LEFT JOIN schedule_outp sp
                        ON sp.id_schedule = s.id_schedule
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN discharge d
                        ON d.id_episode = e.id_episode
                       AND d.flg_status NOT IN (pk_discharge.g_disch_flg_status_cancel)
                      LEFT JOIN disch_reas_dest drd
                        ON drd.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN discharge_dest dd
                        ON dd.id_discharge_dest = drd.id_discharge_dest
                      LEFT JOIN discharge_reason dr
                        ON dr.id_discharge_reason = drd.id_discharge_reason
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN department dpt
                        ON drd.id_department = dpt.id_department
                      LEFT JOIN institution i
                        ON i.id_institution = drd.id_institution
                     WHERE e.id_episode = i_id_episode) t
             WHERE t.linenumber = 1;
        END IF;
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_visit_info_amb;

    /************************************************************************************************************
    * get_visit_info_inp
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Paulo T
    * @version    2.6.2
    * @since      2012-09-25
    ***********************************************************************************************************/
    FUNCTION get_visit_info_inp
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_visit_info_inp';
        l_str CLOB;
    
        l_gender             VARCHAR2(1 CHAR);
        l_id_patient         patient.id_patient%TYPE;
        l_gender_text        VARCHAR2(4000);
        l_age_text           VARCHAR2(4000);
        l_bed_text           VARCHAR(4000);
        l_room_text          VARCHAR(4000);
        l_roombed_text       VARCHAR(4000);
        l_lofstray_text      VARCHAR2(4000);
        l_admission_dt_text  VARCHAR2(4000);
        l_discharge_dt_text  VARCHAR2(4000);
        l_desc_anamnesis     VARCHAR2(4000 CHAR);
        l_error              t_error_out;
        l_id_prof_compl      epis_complaint.id_professional%TYPE;
        l_admiss_complaint   VARCHAR2(4000 CHAR);
        l_complaint_date     epis_complaint.adw_last_update_tstz%TYPE;
        l_epis_type_desc     VARCHAR2(500 CHAR);
        l_service_desc       VARCHAR2(2000 CHAR);
        l_discharge_cond     VARCHAR2(2000 CHAR);
        l_discharge_dest     VARCHAR2(2000 CHAR);
        l_disch_reason       translation.desc_lang_2%TYPE;
        l_disch_destination  translation.desc_lang_2%TYPE;
        l_disch_signature    VARCHAR2(4000);
        l_expected_discharge VARCHAR2(200 CHAR);
    
        l_token_list table_varchar;
    
        l_admission_date         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T006');
        l_discharge_destination  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T010');
        l_service                sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T007');
        l_discharge_date         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T008');
        l_condition_on_discharge sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T009');
        l_transfer_service       sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T011');
        l_length_of_stay         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T012');
        l_gender_mess            sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'PAT_IDENT_T003');
    
        l_age_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T031');
    
        l_bedroom_mess        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T019');
        l_lostay_mess         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T020');
        l_discharge_dt_mess   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T021');
        l_admission_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T022');
        l_epis_type_msg       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'EHR_VST_T006');
        l_inp_days            sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T024');
        l_expected_disch_msg  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PN_T051');
        l_description         VARCHAR2(200 CHAR);
        l_duration            NUMBER;
    BEGIN
        -- getting id patient
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        -- get gender
        l_gender_text := get_pat_gender_text(i_lang => i_lang, i_id_pat => l_id_patient);
    
        --get pat age
        l_age_text := pk_patient.get_pat_age(i_lang => i_lang, i_id_pat => l_id_patient, i_prof => i_prof);
    
        --get room | bed
        l_room_text := get_pat_room_text(i_lang => i_lang, i_id_episode => i_id_episode);
        l_bed_text  := get_pat_bed_text(i_lang => i_lang, i_id_episode => i_id_episode);
    
        IF l_room_text IS NOT NULL
           AND l_bed_text IS NOT NULL
        THEN
            l_roombed_text := l_room_text || '/' || l_bed_text;
        ELSIF l_room_text IS NOT NULL
              AND l_bed_text IS NULL
        THEN
            l_roombed_text := l_room_text;
        ELSIF l_room_text IS NULL
              AND l_bed_text IS NOT NULL
        THEN
            l_roombed_text := l_bed_text;
        
        END IF;
    
        --get lenght of stay
        l_lofstray_text := pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => i_id_episode);
        --get admission date
        SELECT pk_date_utils.date_char_tsz(i_lang,
                                           decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_normal, e.dt_begin_tstz, NULL),
                                           i_prof.institution,
                                           i_prof.software)
          INTO l_admission_dt_text
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        --get admission complaint
        IF NOT pk_complaint.get_complaint_header(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_id_episode,
                                                 i_sep            => ', ',
                                                 o_last_complaint => l_desc_anamnesis,
                                                 o_complaints     => l_admiss_complaint,
                                                 o_professional   => l_id_prof_compl,
                                                 o_dt_register    => l_complaint_date,
                                                 o_error          => l_error)
        THEN
            l_admiss_complaint := pk_prog_notes_constants.g_triple_colon;
        END IF;
    
        --get discharge date
        l_discharge_dt_text := nvl(pk_date_utils.date_char_tsz(i_lang,
                                                               pk_discharge.get_disch_phy_adm_date(i_lang,
                                                                                                   i_prof,
                                                                                                   i_id_episode),
                                                               i_prof.institution,
                                                               i_prof.software),
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               current_timestamp,
                                                               i_prof.institution,
                                                               i_prof.software));
        l_discharge_dt_text := nvl(pk_date_utils.date_char_tsz(i_lang,
                                                               pk_discharge.get_disch_phy_adm_date(i_lang,
                                                                                                   i_prof,
                                                                                                   i_id_episode),
                                                               i_prof.institution,
                                                               i_prof.software),
                                   pk_prog_notes_constants.g_triple_colon);
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
        
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_str IS NOT NULL
                THEN
                    l_str := l_str || chr(10);
                END IF;
                IF l_token_list(i) = 'A' --age
                THEN
                    l_str := l_age_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_age_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'G' --gender  
                THEN
                    l_str := l_str || l_gender_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_gender_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'ROOMBED' --room|bed  
                THEN
                    l_str := l_str || l_bedroom_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_roombed_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'LOS' --lenght of stay 
                THEN
                
                    l_str := l_str || l_lostay_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_lofstray_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'DAYS' --INP days
                THEN
                
                    l_str := l_str || l_inp_days || pk_prog_notes_constants.g_colon ||
                             nvl(l_lofstray_text, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'AD' --admission date
                THEN
                    l_str := l_str || l_admission_date || pk_prog_notes_constants.g_colon ||
                             nvl(l_admission_dt_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'AC' --admission complaint
                THEN
                    l_str := l_str || l_admission_complaint || pk_prog_notes_constants.g_colon || l_admiss_complaint;
                ELSIF l_token_list(i) = 'DD' --dischage date
                THEN
                    l_str := l_str || l_discharge_dt_mess || pk_prog_notes_constants.g_colon || l_discharge_dt_text;
                ELSIF l_token_list(i) = 'ETYPE' --episode type
                THEN
                    l_epis_type_desc := pk_episode.get_epis_type_desc(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_episode => i_id_episode);
                    l_str            := l_str || l_epis_type_msg || pk_prog_notes_constants.g_colon || l_epis_type_desc;
                
                ELSIF l_token_list(i) = 'SERV' --SERVICE
                THEN
                
                    l_service_desc := pk_episode.get_epis_dep_cs_desc(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => i_id_episode);
                    l_str          := l_str || l_service || pk_prog_notes_constants.g_colon || l_service_desc;
                ELSIF l_token_list(i) = 'CDISCH' --CONDITION ON DISCHARGE
                THEN
                
                    l_discharge_cond := pk_discharge.get_patient_condition(i_lang       => i_lang,
                                                                           i_prof       => i_prof,
                                                                           i_id_episode => i_id_episode);
                    l_str            := l_str || l_condition_on_discharge || pk_prog_notes_constants.g_colon ||
                                        nvl(l_discharge_cond, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'DISCH' --DISCHARGE destination
                THEN
                    IF NOT pk_discharge.get_epis_disch_rea_dest_desc(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_episode     => i_id_episode,
                                                                     o_reason      => l_disch_reason,
                                                                     o_destination => l_disch_destination,
                                                                     o_signature   => l_disch_signature,
                                                                     o_error       => l_error)
                    THEN
                        NULL;
                    END IF;
                
                    IF l_disch_reason IS NOT NULL
                    THEN
                        l_discharge_dest := l_disch_reason || ': ';
                    END IF;
                    l_discharge_dest := l_discharge_dest || l_disch_destination;
                    l_str            := l_str || l_discharge_destination || pk_prog_notes_constants.g_colon ||
                                        nvl(l_discharge_dest, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'EDD' --expected discharge date
                THEN
                    l_expected_discharge := pk_discharge.get_discharge_schedule_date(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_id_episode);
                    l_str                := l_str || l_expected_disch_msg || pk_prog_notes_constants.g_colon ||
                                            nvl(l_expected_discharge, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'EVOLUTION' --expected discharge date
                THEN
                    l_duration := pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_id_episode => i_id_episode);
                
                    l_description := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'PROGRESS_NOTES_T153');
                    l_description := REPLACE(l_description, '@1', trunc(l_duration));
                    l_str         := l_str || l_description;
                
                END IF;
            END LOOP;
        
        ELSE
        
            SELECT l_length_of_stay || pk_prog_notes_constants.g_colon || l_lofstray_text || chr(10) || --
                    l_admission_date || pk_prog_notes_constants.g_colon ||
                    nvl(t.visit_date, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_service || pk_prog_notes_constants.g_colon ||
                    nvl(t.service, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_transfer_service || pk_prog_notes_constants.g_colon ||
                    nvl(service_transfer, pk_prog_notes_constants.g_triple_colon) || chr(10) || l_discharge_date ||
                    pk_prog_notes_constants.g_colon || nvl(t.discharge_date, pk_prog_notes_constants.g_triple_colon) ||
                    chr(10) || --
                    l_condition_on_discharge || pk_prog_notes_constants.g_colon ||
                    nvl(t.patient_condition, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_discharge_destination || pk_prog_notes_constants.g_colon || --
                    CASE
                        WHEN t.discharge_dest IS NULL
                             AND t.discharge_reason IS NULL THEN
                         pk_prog_notes_constants.g_triple_colon
                        WHEN t.discharge_dest IS NULL
                             AND t.discharge_reason IS NOT NULL THEN
                         t.discharge_reason
                        WHEN t.discharge_dest IS NOT NULL
                             AND t.discharge_reason IS NULL THEN
                         t.discharge_dest
                        ELSE
                         t.discharge_dest || pk_prog_notes_constants.g_flg_sep || t.discharge_reason
                    END str
              INTO l_str
              FROM (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                       decode(e.flg_ehr,
                                                              pk_ehr_access.g_flg_ehr_normal,
                                                              e.dt_begin_tstz,
                                                              NULL),
                                                       i_prof.institution,
                                                       i_prof.software) visit_date,
                           
                           (SELECT pk_translation.get_translation(i_lang, d.code_department)
                              FROM dep_clin_serv dcs
                              JOIN department d
                                ON d.id_department = dcs.id_department
                             WHERE dcs.id_dep_clin_serv = ei.id_dep_clin_serv) service,
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_discharge.get_disch_phy_adm_date(i_lang, i_prof, e.id_episode),
                                                    i_prof.institution,
                                                    i_prof.software) discharge_date,
                           pk_discharge.get_patient_condition(i_lang,
                                                              i_prof,
                                                              d.id_discharge,
                                                              dr.id_discharge_reason,
                                                              dd.flg_pat_condition) patient_condition,
                           decode(nvl(drd.id_discharge_dest, 0),
                                  0,
                                  decode(nvl(drd.id_dep_clin_serv, 0),
                                         0,
                                         decode(nvl(drd.id_institution, 0),
                                                0,
                                                pk_translation.get_translation(i_lang, dpt.code_department),
                                                pk_translation.get_translation(i_lang, i.code_institution)),
                                         nvl2(drd.id_department,
                                              pk_translation.get_translation(i_lang, dpt.code_department) ||
                                              pk_prog_notes_constants.g_flg_sep,
                                              '') || pk_translation.get_translation(i_lang, cs.code_clinical_service)),
                                  pk_translation.get_translation(i_lang, dd.code_discharge_dest)) discharge_dest,
                           pk_translation.get_translation(i_lang, dr.code_discharge_reason) discharge_reason,
                           (SELECT pk_service_transfer.get_pat_service_transfer(i_lang,
                                                                                i_prof,
                                                                                e.id_patient,
                                                                                e.id_episode)
                              FROM dual) service_transfer,
                           row_number() over(ORDER BY nvl(nvl(nvl(nvl(d.dt_pend_tstz, d.dt_med_tstz), d.dt_nurse), d.dt_nutritionist), d.dt_therapist) DESC) linenumber
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      LEFT JOIN schedule s
                        ON s.id_schedule = ei.id_schedule
                      LEFT JOIN schedule_outp sp
                        ON sp.id_schedule = s.id_schedule
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN discharge d
                        ON d.id_episode = e.id_episode
                       AND d.flg_status NOT IN (pk_discharge.g_disch_flg_status_cancel)
                      LEFT JOIN disch_reas_dest drd
                        ON drd.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN discharge_dest dd
                        ON dd.id_discharge_dest = drd.id_discharge_dest
                      LEFT JOIN discharge_reason dr
                        ON dr.id_discharge_reason = drd.id_discharge_reason
                      LEFT JOIN discharge_detail dd
                        ON dd.id_discharge = d.id_discharge
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN department dpt
                        ON drd.id_department = dpt.id_department
                      LEFT JOIN institution i
                        ON i.id_institution = drd.id_institution
                     WHERE e.id_episode = i_id_episode) t
             WHERE t.linenumber = 1;
        
        END IF;
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_visit_info_inp;

    /*
    * get_admission_days
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     varchar2
    *
    * @author     Ana Moita
    * @version    2.8.0
    * @since      2020-10-16
    */
    FUNCTION get_admission_days
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_admission_days';
        l_days_ret VARCHAR2(2000);
    
        l_days_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M020');
    BEGIN
    
        SELECT extract(DAY FROM(current_timestamp - e.dt_begin_tstz))
          INTO l_days_ret
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        l_days_ret := l_days_ret || pk_prog_notes_constants.g_space || l_days_mess;
    
        RETURN l_days_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_admission_days;
    /************************************************************************************************************
    * get_visit_info_edis
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Paulo T
    * @version    2.6.2
    * @since      2012-09-25
    ***********************************************************************************************************/
    FUNCTION get_visit_info_edis
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_visit_info_inp';
        l_str CLOB;
    
        l_gender VARCHAR2(1 CHAR);
    
        l_id_patient        patient.id_patient%TYPE;
        l_gender_text       VARCHAR2(4000);
        l_age_text          VARCHAR2(4000);
        l_bed_text          VARCHAR(4000);
        l_room_text         VARCHAR(4000);
        l_roombed_text      VARCHAR(4000);
        l_admission_dt_text VARCHAR2(4000);
        l_discharge_dt_text VARCHAR2(4000);
        l_desc_anamnesis    VARCHAR2(4000 CHAR);
        l_error             t_error_out;
        l_id_prof_compl     epis_complaint.id_professional%TYPE;
        l_admiss_complaint  VARCHAR2(4000 CHAR);
        l_complaint_date    epis_complaint.adw_last_update_tstz%TYPE;
        l_epis_type_desc    VARCHAR2(500 CHAR);
        l_discharge_cond    VARCHAR2(2000 CHAR);
        l_discharge_dest    VARCHAR2(2000 CHAR);
        l_disch_reason      translation.desc_lang_2%TYPE;
        l_disch_destination translation.desc_lang_2%TYPE;
        l_disch_signature   VARCHAR2(4000);
    
        l_token_list             table_varchar;
        l_admission_date         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T006');
        l_discharge_destination  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T010');
        l_discharge_date         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T008');
        l_condition_on_discharge sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T009');
        l_attending_physician    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T003');
        l_primary_care_physician sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'VISIT_INFO_T004');
        l_gender_mess            sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'PAT_IDENT_T003');
    
        l_age_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T031');
    
        l_bedroom_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T019');
    
        l_discharge_dt_mess   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T021');
        l_admission_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VISIT_INFO_T022');
        l_entrance_dt         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PREV_EPISODE_T594');
        l_epis_type_msg       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'EHR_VST_T006');
    BEGIN
        -- getting id patient
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        -- get gender
        l_gender_text := get_pat_gender_text(i_lang => i_lang, i_id_pat => l_id_patient);
    
        --get pat age
        l_age_text := pk_patient.get_pat_age(i_lang => i_lang, i_id_pat => l_id_patient, i_prof => i_prof);
    
        --get room | bed
        l_room_text := get_pat_room_text(i_lang => i_lang, i_id_episode => i_id_episode);
        l_bed_text  := get_pat_bed_text(i_lang => i_lang, i_id_episode => i_id_episode);
    
        IF l_room_text IS NOT NULL
           AND l_bed_text IS NOT NULL
        THEN
            l_roombed_text := l_room_text || '/' || l_bed_text;
        ELSIF l_room_text IS NOT NULL
              AND l_bed_text IS NULL
        THEN
            l_roombed_text := l_room_text;
        ELSIF l_room_text IS NULL
              AND l_bed_text IS NOT NULL
        THEN
            l_roombed_text := l_bed_text;
        END IF;
    
        --get admission date
        SELECT pk_date_utils.date_char_tsz(i_lang,
                                           decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_normal, e.dt_begin_tstz, NULL),
                                           i_prof.institution,
                                           i_prof.software)
          INTO l_admission_dt_text
          FROM episode e
         WHERE e.id_episode = i_id_episode;
        --get admission complaint
        IF NOT pk_complaint.get_complaint_header(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_id_episode,
                                                 i_sep            => ', ',
                                                 o_last_complaint => l_desc_anamnesis,
                                                 o_complaints     => l_admiss_complaint,
                                                 o_professional   => l_id_prof_compl,
                                                 o_dt_register    => l_complaint_date,
                                                 o_error          => l_error)
        THEN
            l_admiss_complaint := pk_prog_notes_constants.g_triple_colon;
        END IF;
    
        --get discharge date
        l_discharge_dt_text := nvl(pk_date_utils.date_char_tsz(i_lang,
                                                               pk_discharge.get_disch_phy_adm_date(i_lang,
                                                                                                   i_prof,
                                                                                                   i_id_episode),
                                                               i_prof.institution,
                                                               i_prof.software),
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               current_timestamp,
                                                               i_prof.institution,
                                                               i_prof.software));
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_str IS NOT NULL
                THEN
                    l_str := l_str || chr(10);
                END IF;
                IF l_token_list(i) = 'A' --age
                THEN
                    l_str := l_age_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_age_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'G' --gender  
                THEN
                    l_str := l_str || l_gender_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_gender_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'ROOMBED' --room|bed  
                THEN
                    l_str := l_str || l_bedroom_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_roombed_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'AD' --admission date
                THEN
                    l_str := l_str || l_entrance_dt || pk_prog_notes_constants.g_colon ||
                             nvl(l_admission_dt_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'AC' --admission complaint
                THEN
                    l_str := l_str || l_admission_complaint || pk_prog_notes_constants.g_colon || l_admiss_complaint;
                ELSIF l_token_list(i) = 'DD' --dischage date
                THEN
                    l_str := l_str || l_discharge_dt_mess || pk_prog_notes_constants.g_colon || l_discharge_dt_text;
                ELSIF l_token_list(i) = 'ETYPE' --episode type
                THEN
                    l_epis_type_desc := pk_episode.get_epis_type_desc(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_episode => i_id_episode);
                    l_str            := l_str || l_epis_type_msg || pk_prog_notes_constants.g_colon || l_epis_type_desc;
                
                ELSIF l_token_list(i) = 'CDISCH' --CONDITION ON DISCHARGE
                THEN
                
                    l_discharge_cond := pk_discharge.get_patient_condition(i_lang       => i_lang,
                                                                           i_prof       => i_prof,
                                                                           i_id_episode => i_id_episode);
                    l_str            := l_str || l_condition_on_discharge || pk_prog_notes_constants.g_colon ||
                                        nvl(l_discharge_cond, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'DISCH' --DISCHARGE destination
                THEN
                    IF NOT pk_discharge.get_epis_disch_rea_dest_desc(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_episode     => i_id_episode,
                                                                     o_reason      => l_disch_reason,
                                                                     o_destination => l_disch_destination,
                                                                     o_signature   => l_disch_signature,
                                                                     o_error       => l_error)
                    THEN
                        NULL;
                    END IF;
                
                    IF l_disch_reason IS NOT NULL
                    THEN
                        l_discharge_dest := l_disch_reason || ': ';
                    END IF;
                    l_discharge_dest := l_discharge_dest || l_disch_destination;
                    l_str            := l_str || l_discharge_destination || pk_prog_notes_constants.g_colon ||
                                        nvl(l_discharge_dest, pk_prog_notes_constants.g_triple_colon);
                
                END IF;
            END LOOP;
        
        ELSE
        
            SELECT l_admission_date || pk_prog_notes_constants.g_colon ||
                    nvl(t.visit_date, pk_prog_notes_constants.g_triple_colon) || chr(10) || --               
                    l_attending_physician || pk_prog_notes_constants.g_colon ||
                    nvl(t.desc_prof, pk_prog_notes_constants.g_triple_colon) || --
                    CASE
                        WHEN t.spec_prof IS NOT NULL THEN
                         pk_prog_notes_constants.g_open_parenthesis || t.spec_prof ||
                         pk_prog_notes_constants.g_close_parenthesis
                        ELSE
                         NULL
                    END || chr(10) || --
                    l_primary_care_physician || pk_prog_notes_constants.g_colon ||
                    nvl(t.primary_care_doc, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_discharge_date || pk_prog_notes_constants.g_colon ||
                    nvl(t.discharge_date, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_condition_on_discharge || pk_prog_notes_constants.g_colon ||
                    nvl(t.patient_condition, pk_prog_notes_constants.g_triple_colon) || chr(10) || --
                    l_discharge_destination || pk_prog_notes_constants.g_colon || --
                    CASE
                        WHEN t.discharge_dest IS NULL
                             AND t.discharge_reason IS NULL THEN
                         pk_prog_notes_constants.g_triple_colon
                        WHEN t.discharge_dest IS NULL
                             AND t.discharge_reason IS NOT NULL THEN
                         t.discharge_reason
                        WHEN t.discharge_dest IS NOT NULL
                             AND t.discharge_reason IS NULL THEN
                         t.discharge_dest
                        ELSE
                         t.discharge_dest || pk_prog_notes_constants.g_flg_sep || t.discharge_reason
                    END str
              INTO l_str
              FROM (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                       decode(e.flg_ehr,
                                                              pk_ehr_access.g_flg_ehr_normal,
                                                              e.dt_begin_tstz,
                                                              NULL),
                                                       i_prof.institution,
                                                       i_prof.software) visit_date,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(ei.id_professional, sr.id_professional)) desc_prof,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            nvl(ei.id_professional, sr.id_professional),
                                                            NULL,
                                                            e.id_episode) spec_prof,
                           
                           pk_patient.get_designated_provider(i_lang, i_prof, e.id_patient, e.id_episode) primary_care_doc,
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_discharge.get_discharge_date(i_lang, i_prof, e.id_episode),
                                                    i_prof.institution,
                                                    i_prof.software) discharge_date,
                           pk_discharge.get_patient_condition(i_lang,
                                                              i_prof,
                                                              d.id_discharge,
                                                              dr.id_discharge_reason,
                                                              dd.flg_pat_condition) patient_condition,
                           decode(nvl(drd.id_discharge_dest, 0),
                                  0,
                                  decode(nvl(drd.id_dep_clin_serv, 0),
                                         0,
                                         decode(nvl(drd.id_institution, 0),
                                                0,
                                                pk_translation.get_translation(i_lang, dpt.code_department),
                                                pk_translation.get_translation(i_lang, i.code_institution)),
                                         nvl2(drd.id_department,
                                              pk_translation.get_translation(i_lang, dpt.code_department) ||
                                              pk_prog_notes_constants.g_flg_sep,
                                              '') || pk_translation.get_translation(i_lang, cs.code_clinical_service)),
                                  pk_translation.get_translation(i_lang, dd.code_discharge_dest)) discharge_dest,
                           pk_translation.get_translation(i_lang, dr.code_discharge_reason) discharge_reason,
                           row_number() over(ORDER BY nvl(nvl(nvl(nvl(d.dt_pend_tstz, d.dt_med_tstz), d.dt_nurse), d.dt_nutritionist), d.dt_therapist) DESC) linenumber
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      LEFT JOIN schedule s
                        ON s.id_schedule = ei.id_schedule
                      LEFT JOIN schedule_outp sp
                        ON sp.id_schedule = s.id_schedule
                      LEFT JOIN sch_resource sr
                        ON sr.id_schedule = s.id_schedule
                       AND sr.flg_leader = pk_alert_constant.g_yes
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN discharge d
                        ON d.id_episode = e.id_episode
                       AND d.flg_status NOT IN (pk_discharge.g_disch_flg_status_cancel)
                      LEFT JOIN disch_reas_dest drd
                        ON drd.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN discharge_dest dd
                        ON dd.id_discharge_dest = drd.id_discharge_dest
                      LEFT JOIN discharge_reason dr
                        ON dr.id_discharge_reason = drd.id_discharge_reason
                      LEFT JOIN discharge_detail dd
                        ON dd.id_discharge = d.id_discharge
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN department dpt
                        ON drd.id_department = dpt.id_department
                      LEFT JOIN institution i
                        ON i.id_institution = drd.id_institution
                     WHERE e.id_episode = i_id_episode) t
             WHERE t.linenumber = 1;
        
        END IF;
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_visit_info_edis;

    /**************************************************************************
    * Get the macros defined to the list of templates
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID   
    * @param i_templates              Templates list 
    * @param io_coll_macro            Macros list
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.3.1                          
    * @since                          03-Dec-2012                               
    **************************************************************************/
    FUNCTION get_doc_area_macros
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_templates   IN t_coll_template,
        io_coll_macro IN OUT NOCOPY t_coll_macro,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_DOC_AREA_MACROS';
        l_templ_count    PLS_INTEGER;
        l_doc_macro_list pk_touch_option_out.t_cur_macro_info;
        l_tbl_macros     pk_touch_option_out.t_coll_rec_macro_info;
    
    BEGIN
        l_templ_count := i_templates.count;
    
        FOR i IN 1 .. l_templ_count
        LOOP
            g_error := 'call pk_touch_option_out.get_doc_macros_list. id_doc_area: ' || i_templates(i).id_doc_area;
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            pk_touch_option_out.get_doc_macros_list(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_doc_area       => i_templates(i).id_doc_area,
                                                    i_doc_template   => i_templates(i).id_doc_template,
                                                    o_doc_macro_list => l_doc_macro_list);
        
            LOOP
                g_error := 'FETCH MACROS CURSOR';
                pk_alertlog.log_debug(g_error);
                FETCH l_doc_macro_list BULK COLLECT
                    INTO l_tbl_macros LIMIT 1000;
            
                FOR j IN 1 .. l_tbl_macros.count
                LOOP
                    -- extend and associates the new record into actions table
                    io_coll_macro.extend;
                    io_coll_macro(io_coll_macro.last) := t_rec_macro(i_templates (i).id_doc_template,
                                                                     l_tbl_macros(j).id_doc_macro_version,
                                                                     l_tbl_macros(j).doc_macro_name,
                                                                     i_templates (i).id_doc_area,
                                                                     l_tbl_macros(j).id_doc_macro,
                                                                     l_tbl_macros(j).flg_status);
                END LOOP;
                EXIT WHEN l_doc_macro_list%NOTFOUND;
            END LOOP;
        
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_doc_area_macros;
    /********************************************************************************************
    * Gets the flash context screens
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_flg_context            flag context
    *
    * @param         O_DATA                  screen list
    * @param         O_ERROR                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Paulo teixeira
    * @since                                 06-03-2014
    * @version                               2.6.3
    ********************************************************************************************/
    FUNCTION get_swf_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN pn_context.flg_context%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get_swf_context';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT pk_progress_notes_upd.get_app_file(pnc.id_application_file) swf, pnc.flg_context
              FROM pn_context pnc
             WHERE pnc.flg_context = nvl(i_flg_context, pnc.flg_context);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_swf_context',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
        
            RETURN FALSE;
    END get_swf_context;

    /**
    * Review home medication tasks
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_episode          Episode ID
    * @param   i_id_patient          Patient identifier
    *
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         16-04-2014
    */
    FUNCTION set_review_home_med
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_review      NUMBER(24);
        l_code_review    NUMBER(24);
        l_review_desc    VARCHAR2(1000 CHAR);
        l_dt_create      TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_prof_create NUMBER(24);
        l_dt_last_update TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_info_source  CLOB;
        l_pat_not_take CLOB;
        l_pat_take     CLOB;
        l_notes        CLOB;
    BEGIN
        g_error := 'CALL PK_API_PFH_IN.GET_LAST_REVIEW';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_in.get_last_review(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_episode     => i_episode,
                                             i_id_patient     => i_id_patient,
                                             i_dt_begin       => NULL,
                                             i_dt_end         => NULL,
                                             o_id_review      => l_id_review,
                                             o_code_review    => l_code_review,
                                             o_review_desc    => l_review_desc,
                                             o_dt_create      => l_dt_create,
                                             o_dt_update      => l_dt_last_update,
                                             o_id_prof_create => l_id_prof_create,
                                             o_info_source    => l_info_source,
                                             o_pat_not_take   => l_pat_not_take,
                                             o_pat_take       => l_pat_take,
                                             o_notes          => l_notes)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_API_PFH_IN.SET_HM_REVIEW_GLOBAL_INFO. l_id_review: ' || l_id_review;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_in.set_hm_review_global_info(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_patient  => i_id_patient,
                                                       i_id_episode  => i_episode,
                                                       io_id_review  => l_id_review,
                                                       i_code_review => l_code_review)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REVIEW_HOME_MED',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_review_home_med;

    /********************************************************************************************
    * Cancel a task type record
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_id_task_type          Task Type ID
    * @param         i_id_task_refid         Record ID
    * @param         i_id_cancel_reason      Cancel Reason ID
    * @param         i_notes_cancel          Cancel notes
    *
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 07-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION cancel_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_type     IN tl_task.id_tl_task%TYPE,
        i_id_task_refid    IN task_timeline_ea.id_task_refid%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN cancel_info_det.notes_cancel_long%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'CANCEL_TASK';
        l_episode   task_timeline_ea.id_episode%TYPE;
        l_patient   task_timeline_ea.id_patient%TYPE;
        l_out_texts sys_message.desc_message%TYPE;
        l_epis_rec  epis_recomend.id_epis_recomend%TYPE;
        l_doc_area  task_timeline_ea.id_doc_area%TYPE;
    
        ---------------------------------------------
        PROCEDURE setvar IS
        BEGIN
        
            SELECT tte.id_episode, tte.id_patient, id_doc_area
              INTO l_episode, l_patient, l_doc_area
              FROM task_timeline_ea tte
             WHERE tte.id_task_refid = i_id_task_refid
               AND tte.id_tl_task = i_id_task_type;
        
        END setvar;
    
    BEGIN
    
        IF i_id_task_type IS NULL
           OR i_id_task_refid IS NULL
           OR i_id_cancel_reason IS NULL
        THEN
            g_error := 'No i_id_task_type or i_id_task_refid or i_id_cancel_reason specified';
            RAISE g_exception;
        END IF;
    
        g_error := 'CANCEL_TASK i_id_task_type: ' || i_id_task_type || ' i_id_task_refid: ' || i_id_task_refid ||
                   ' i_id_cancel_reason: ' || i_id_cancel_reason;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint
        THEN
            g_error := 'CALL PK_COMPLAINT.CANCEL_COMPAINT';
            IF NOT pk_complaint.cancel_compaint(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_epis_complaint => i_id_task_refid,
                                                i_id_cancel_reason  => i_id_cancel_reason,
                                                i_notes_cancel      => i_notes_cancel,
                                                o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint_anm
        THEN
            g_error := 'CALL PK_COMPLAINT.CANCEL_ANAMNESIS';
            IF NOT pk_complaint.cancel_anamnesis(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_epis_anamnesis => i_id_task_refid,
                                                 i_id_cancel_reason  => i_id_cancel_reason,
                                                 i_notes_cancel      => i_notes_cancel,
                                                 o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint_out
        THEN
            g_error := 'CALL PK_PROGRESS_NOTES.SET_REASON_FOR_VISIT_CANCEL';
        
            setvar();
            IF NOT pk_progress_notes.set_reason_for_visit_cancel(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_prof_cat => NULL,
                                                                 i_episode  => l_episode,
                                                                 i_patient  => l_patient,
                                                                 i_record   => i_id_task_refid,
                                                                 i_reason   => i_id_cancel_reason,
                                                                 i_notes    => i_notes_cancel,
                                                                 o_error    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_emergency_law
        THEN
        
            g_error := 'GET TASK ID_EPISODE';
            setvar();
        
            g_error := 'CALL PK_EPIS_ER_LAW_CORE.CANCEL_EPIS_ER_LAW';
            IF NOT pk_epis_er_law_core.cancel_epis_er_law(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_episode       => l_episode,
                                                          i_cancel_reason => i_id_cancel_reason,
                                                          i_cancel_notes  => i_notes_cancel,
                                                          o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_templates
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.CANCEL_EPIS_DOCUMENTATION';
            IF NOT pk_touch_option.cancel_epis_documentation(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_epis_doc   => i_id_task_refid,
                                                             i_notes         => i_notes_cancel,
                                                             i_test          => pk_alert_constant.g_no,
                                                             i_cancel_reason => i_id_cancel_reason,
                                                             o_flg_show      => l_out_texts,
                                                             o_msg_title     => l_out_texts,
                                                             o_msg_text      => l_out_texts,
                                                             o_button        => l_out_texts,
                                                             o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_subjective,
                                 pk_prog_notes_constants.g_task_objective,
                                 pk_prog_notes_constants.g_task_assessment)
        THEN
        
            g_error := 'CALL PK_DISCHARGE.SET_EPIS_RECOMEND_CANCEL_INT';
            IF NOT pk_discharge.set_epis_recomend_cancel_int(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_epis_rec => i_id_task_refid,
                                                             i_reason   => i_id_cancel_reason,
                                                             i_notes    => i_notes_cancel,
                                                             o_epis_rec => l_epis_rec,
                                                             o_error    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_prognosis
        THEN
            g_error := 'CALL PK_PROGNOSIS.CANCEL_EPIS_PROGNOSIS';
            IF NOT pk_prognosis.cancel_epis_prognosis(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_epis_prognosis => i_id_task_refid,
                                                      i_id_cancel_reason  => i_id_cancel_reason,
                                                      i_notes_cancel      => i_notes_cancel,
                                                      o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_problems_group_ass
        THEN
            g_error := 'CALL pk_problems.cancel_prob_group_assessment';
            setvar();
            IF NOT pk_problems.cancel_prob_group_assessment(i_lang                   => i_lang,
                                                            i_prof                   => i_prof,
                                                            i_episode                => l_episode,
                                                            i_id_epis_prob_group_ass => i_id_task_refid,
                                                            i_id_cancel_reason       => i_id_cancel_reason,
                                                            i_notes_cancel           => i_notes_cancel,
                                                            o_error                  => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- CMF
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_mtos_score
        THEN
        
            setvar();
            IF NOT pk_sev_scores_core.cancel_sev_score(i_lang,
                                                       i_prof,
                                                       l_episode,
                                                       i_id_task_refid,
                                                       i_id_cancel_reason,
                                                       i_notes_cancel,
                                                       o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_ph_templ
        THEN
        
            setvar();
        
            IF NOT pk_past_history.cancel_past_history(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_doc_area              => l_doc_area,
                                                       i_id_episode            => l_episode,
                                                       i_id_patient            => l_patient,
                                                       i_record_id             => NULL,
                                                       i_ph_free_text          => pk_alert_constant.g_no,
                                                       i_id_cancel_reason      => i_id_cancel_reason,
                                                       i_cancel_notes          => i_notes_cancel,
                                                       i_id_epis_documentation => i_id_task_refid,
                                                       o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_task;

    /********************************************************************************************
    * Cancel a task type record to be used when a note is deleted, to deleted referenced records on the note
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_id_task_type          Task Type IDs
    * @param         i_id_task_refid         Record IDs
    *
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 01-09-2017
    * @version                               2.7.1
    ********************************************************************************************/
    FUNCTION set_cancel_task_on_del_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN table_number,
        i_id_task_refid IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'CANCEL_TASK';
        l_nr_records   PLS_INTEGER;
        l_cancel_notes pk_translation.t_desc_translation := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_code_mess => 'AIH_M001');
    BEGIN
    
        IF i_id_task_type IS NULL
           OR i_id_task_refid IS NULL
        THEN
            g_error := 'No i_id_task_type or i_id_task_refid specified';
            RAISE g_exception;
        END IF;
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_nr_records := i_id_task_type.count;
        FOR i IN 1 .. l_nr_records
        LOOP
            IF (i_id_task_type(i) = pk_prog_notes_constants.g_task_cits_procedures)
            THEN
                g_error := 'Call pk_aih.set_cancel_aih_simple';
                IF NOT pk_aih.set_cancel_aih_simple(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_aih_simple   => i_id_task_refid(i),
                                                    i_notes_cancel => l_cancel_notes,
                                                    o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSIF (i_id_task_type(i) = pk_prog_notes_constants.g_task_cits_procedures_special)
            THEN
                g_error := 'Call pk_aih.set_cancel_aih_simple';
                IF NOT pk_aih.set_cancel_aih_special(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_aih_special  => i_id_task_refid(i),
                                                     i_notes_cancel => l_cancel_notes,
                                                     o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                NULL;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_cancel_task_on_del_note;

    FUNCTION get_summ_sections_block
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_sblock    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE DEFAULT NULL,
        o_sections        OUT pk_summary_page.t_cur_section,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sections pk_summary_page.t_coll_section;
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SUMM_SECTIONS_BLOCK';
        l_id_doc_area table_number;
        l_id_market   market.id_market%TYPE;
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF i_id_doc_area IS NOT NULL
        THEN
            l_id_doc_area := table_number();
            l_id_doc_area.extend;
            l_id_doc_area(l_id_doc_area.last) := i_id_doc_area;
        ELSE
            SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
             id_doc_area
              BULK COLLECT
              INTO l_id_doc_area
              FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof             => i_prof,
                                                              i_market           => l_id_market,
                                                              i_department       => NULL,
                                                              i_dcs              => NULL,
                                                              i_id_pn_note_type  => i_id_pn_note_type,
                                                              i_id_episode       => i_id_episode,
                                                              i_id_pn_data_block => NULL,
                                                              i_software         => NULL)) t
             WHERE t.id_pn_soap_block = i_id_pn_sblock;
        END IF;
        -- documentation areas for functional evaluations
        g_error := 'CALL pk_summary_page.get_summary_page_sections (FE)';
        IF NOT pk_summary_page.get_summary_page_sections(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_summary_page  => i_id_summary_page,
                                                         i_pat              => i_patient,
                                                         i_complete_epi_rep => FALSE,
                                                         i_doc_areas_ex     => NULL,
                                                         i_doc_areas_in     => l_id_doc_area,
                                                         o_sections         => o_sections,
                                                         o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_summ_sections_block;

    FUNCTION get_summ_sections_exclude
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_category IN doc_category.id_doc_category%TYPE,
        o_sections        OUT pk_summary_page.t_cur_section,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        -- l_sections pk_summary_page.t_coll_section;
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_summ_sections_exclude';
        l_id_doc_area_ex table_number;
        l_id_market      market.id_market%TYPE;
        l_sections       pk_summary_page.t_cur_section;
        l_sections_aux   pk_summary_page.t_coll_section;
        c_sections       pk_summary_page.t_cur_section;
        l_tbl_section    pk_summary_page.t_coll_section;
        l_rec_section    pk_summary_page.t_rec_section;
        l_id_doc_area_in table_number;
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        --get the doc ares to exclude
        SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
         id_doc_area
          BULK COLLECT
          INTO l_id_doc_area_ex
          FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof             => i_prof,
                                                          i_market           => l_id_market,
                                                          i_department       => NULL,
                                                          i_dcs              => NULL,
                                                          i_id_pn_note_type  => i_id_pn_note_type,
                                                          i_id_episode       => i_id_episode,
                                                          i_id_pn_data_block => NULL,
                                                          i_software         => NULL)) t
         WHERE t.id_summary_page = i_id_summary_page
           AND id_doc_area IS NOT NULL;
        --get the doc_areas of the id_doc_category
        IF i_id_doc_category IS NOT NULL
        THEN
            l_id_doc_area_in := pk_summary_page.get_doc_area_by_cat(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_id_doc_category => i_id_doc_category);
        END IF;
        -- documentation areas for functional evaluations
        g_error := 'CALL pk_summary_page.get_summary_page_sections (FE)';
        IF NOT pk_summary_page.get_summary_page_sections(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_summary_page  => i_id_summary_page,
                                                         i_pat              => i_patient,
                                                         i_complete_epi_rep => FALSE,
                                                         i_doc_areas_ex     => l_id_doc_area_ex,
                                                         i_doc_areas_in     => l_id_doc_area_in,
                                                         o_sections         => o_sections,
                                                         o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_summ_sections_exclude;

    -- CALERT-213 ( CALERT-1822)
    FUNCTION get_severity_score_block
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_sblock    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_scores          OUT pk_sev_scores_core.p_sev_scores_param_cur,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_severity_score_block';
        l_id_market     market.id_market%TYPE;
        l_id_mtos_score table_number;
        g_error         VARCHAR2(1000 CHAR);
    
    BEGIN
        g_error := 'get_severity_score_block, i_id_pn_sblock: ' || i_id_pn_sblock || ', i_id_pn_note_type: ' ||
                   ', i_id_episode: ' || i_id_episode || ', i_patient: ' || i_patient;
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package,
                              sub_object_name => l_func_name,
                              owner           => g_owner);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT id_mtos_score
          BULK COLLECT
          INTO l_id_mtos_score
          FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof             => i_prof,
                                                          i_market           => l_id_market,
                                                          i_department       => NULL,
                                                          i_dcs              => NULL,
                                                          i_id_pn_note_type  => i_id_pn_note_type,
                                                          i_id_episode       => i_id_episode,
                                                          i_id_pn_data_block => NULL,
                                                          i_software         => NULL)) t
         WHERE t.id_pn_soap_block = i_id_pn_sblock;
    
        g_error := 'l_id_mtos_score: ';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package,
                              sub_object_name => l_func_name,
                              owner           => g_owner);
    
        IF NOT pk_sev_scores_core.get_sev_scores_list(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_patient    => i_patient,
                                                      i_id_episode => i_id_episode,
                                                      i_mtos_score => l_id_mtos_score,
                                                      o_scores     => o_scores,
                                                      o_error      => o_error)
        THEN
        
            o_error := NULL;
            pk_sev_scores_core.open_my_cursor(o_scores);
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_M080');
            o_msg       := pk_message.get_message(i_lang, 'TRAUMA_T040');
            o_button    := 'R';
        
        END IF;
    
        RETURN TRUE;
    END get_severity_score_block;

    /************************************************************************************************************
    * get_pat_identification
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Vítor Sá
    * @version    2.7.5.3
    * @since      2019-04-24
    ***********************************************************************************************************/
    FUNCTION get_pat_identification
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN CLOB IS
        l_error t_error_out;
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_pat_identification';
        l_str        CLOB;
        l_id_patient patient.id_patient%TYPE;
        l_id_market  market.id_market%TYPE;
    
        l_name_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T001');
    
        l_date_birth_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T002');
    
        l_gender_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T003');
    
        l_pregnant_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T004');
    
        l_nationality_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T005');
    
        l_language_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T006');
    
        l_marital_state_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T007');
    
        l_address_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T008');
    
        l_religion_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T019');
    
        l_insurance_company_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'ID_PATIENT_INSURANCE_COMPANY');
        l_scholarship_mess       sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         i_prof,
                                                                                         'PAT_IDENT_T009');
    
        l_guardian_mess           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'PAT_IDENT_T010');
        l_place_birth_mess        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'PAT_IDENT_T011');
        l_occupation_mess         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'IDENT_PATIENT_T020');
        l_phone_number_mess       sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'PAT_IDENT_T012');
        l_emerg_contact_name_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'PAT_IDENT_T013');
    
        l_worker_msg      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T014');
        l_dependent_msg   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PAT_IDENT_T015');
        l_race_mess       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T045');
        l_job_status_mess sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T028');
        l_company_mess    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                  i_prof,
                                                                                  'ID_PATIENT_JOB_COMPANY');
    
        l_name           VARCHAR2(1000);
        l_date_birth     VARCHAR2(1000);
        l_gender         VARCHAR2(1 CHAR);
        l_gender_text    VARCHAR2(1000);
        l_pregnant       VARCHAR(1 CHAR);
        l_pregnant_text  VARCHAR2(1000);
        l_nationality    VARCHAR2(4000);
        l_language       VARCHAR2(1000);
        l_marital_state  VARCHAR2(4000);
        l_address        VARCHAR2(4000);
        l_religion       VARCHAR2(4000);
        l_hplan          VARCHAR2(4000);
        l_hpentity       VARCHAR2(4000);
        l_scholarship    VARCHAR2(4000);
        l_legal_guardian VARCHAR2(4000);
        l_place_birth    VARCHAR2(4000);
        l_occupation     VARCHAR2(4000);
        l_phone_number   VARCHAR2(4000);
        l_emerg_cnt_name VARCHAR2(4000);
        l_race           VARCHAR2(4000);
        l_job_status     VARCHAR2(4000);
        l_company        VARCHAR2(4000);
        l_token_list     table_varchar;
    BEGIN
        -- getting id patient
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        l_id_market  := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        -- getting patient name
        l_name := pk_patient.get_pat_name(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          i_patient => l_id_patient,
                                          i_episode => i_id_episode);
    
        l_name := nvl(substr(l_name, 1, instr(l_name, '/') - 1), l_name);
    
        -- getting date birth
        /*l_date_birth := pk_date_utils.date_char(i_lang => i_lang,
        i_date => pk_patient.get_pat_dt_birth(i_lang, i_prof, l_id_patient),
        i_inst => i_prof.institution,
        i_soft => i_prof.software);*/
    
        l_date_birth := pk_date_utils.dt_chr(i_lang => i_lang,
                                             i_date => pk_patient.get_pat_dt_birth(i_lang, i_prof, l_id_patient),
                                             i_prof => i_prof);
    
        -- get gender
        l_gender := pk_patient.get_pat_gender(i_id_patient => l_id_patient);
        IF l_gender = 'F'
        THEN
            l_gender_text := pk_message.get_message(i_lang, 'GENDER_001');
        ELSIF l_gender = 'M'
        THEN
            l_gender_text := pk_message.get_message(i_lang, 'GENDER_002');
        ELSE
            l_gender_text := NULL;
        END IF;
    
        -- case it's female, see if it's pregnant
        IF l_gender = 'F'
        THEN
            IF NOT pk_woman_health.is_woman_pregnant(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_patient      => l_id_patient,
                                                     o_flg_pregnant => l_pregnant,
                                                     o_error        => l_error)
            THEN
                NULL;
            END IF;
        
            IF l_pregnant = 'Y'
            THEN
                l_pregnant_text := pk_message.get_message(i_lang, 'P1_COMMON_T003');
            
            ELSIF l_pregnant = 'N'
            THEN
                l_pregnant_text := pk_message.get_message(i_lang, 'P1_COMMON_T002');
            ELSE
                l_pregnant_text := pk_message.get_message(i_lang, 'PREGNANCY_003');
            END IF;
        END IF;
    
        -- nationality
        l_nationality := pk_adt.get_nationality(i_lang => i_lang, i_prof => i_prof, i_id_patient => l_id_patient);
    
        -- language
        l_language := pk_adt.get_preferred_language(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
    
        --marital state
        l_marital_state := pk_patient.get_pat_marital_state(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => l_id_patient);
    
        -- address
        l_address := pk_patient.get_pat_address(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
    
        --religion
        l_religion := pk_patient.get_pat_religion(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
    
        -- patient phone number
        IF NOT pk_adt.get_main_contact(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_id_patient        => l_id_patient,
                                       i_id_contact_method => 1,
                                       o_contact           => l_phone_number,
                                       o_error             => l_error)
        THEN
            l_phone_number := NULL;
        END IF;
    
        -- building final string
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'PATNAME' --patient name
                THEN
                    l_str := l_name_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_name, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'DBIRTH' --date of birth
                THEN
                    l_str := l_str || chr(10) || l_date_birth_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_date_birth, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'G' --gender  
                THEN
                    l_str := l_str || chr(10) || l_gender_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_gender_text, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'NAC' --nacionality
                THEN
                    l_str := l_str || chr(10) || l_nationality_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_nationality, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'LANG' --language
                THEN
                    l_str := l_str || chr(10) || l_language_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_language, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'SCHOL' --scholarship
                THEN
                    -- scholarship        
                    l_scholarship := pk_patient.get_pat_scholarship(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_scholarship_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_scholarship, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'GUARDIAN' --legal guardian name
                THEN
                    -- legal guardian     
                    l_legal_guardian := pk_adt.get_legal_guardian(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_guardian_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_legal_guardian, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'REL' --religion
                THEN
                    l_str := l_str || chr(10) || l_religion_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_religion, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'ADRS' --adress
                THEN
                    l_str := l_str || chr(10) || l_address_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_address, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'MS' --Marital Status
                THEN
                    l_str := l_str || chr(10) || l_marital_state_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_marital_state, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'PBIRTH' --place of birth (label) /  country of birth (content)
                THEN
                    --country of birth
                    l_place_birth := pk_patient.get_pat_country_birth(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_place_birth_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_place_birth, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'OCC' -- occupation
                THEN
                    --occupation
                    l_occupation := pk_patient.get_pat_occupation(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_occupation_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_occupation, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'TPH' -- patient telephone number
                THEN
                    l_str := l_str || chr(10) || l_phone_number_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_phone_number, pk_prog_notes_constants.g_triple_colon);
                
                ELSIF l_token_list(i) = 'ECN' -- emergency contact name
                THEN
                    -- emergency contact name "relative''s name"
                    l_emerg_cnt_name := pk_adt.get_emergency_contact_name(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_emerg_contact_name_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_emerg_cnt_name, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'RACE' -- RACE
                THEN
                    --race
                    l_race := pk_patient.get_pat_race(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
                
                    l_str := l_str || l_race_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_race, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'JOB' -- job
                THEN
                    --job status
                    l_job_status := pk_patient.get_pat_job_status(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_job_status_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_job_status, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'COMPANY' -- company
                THEN
                    --job status
                    l_company := pk_patient.get_pat_job_company(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_patient => l_id_patient);
                
                    l_str := l_str || chr(10) || l_company_mess || pk_prog_notes_constants.g_colon ||
                             nvl(l_company, pk_prog_notes_constants.g_triple_colon);
                ELSIF l_token_list(i) = 'WORKER' -- WORKER_COMPANY
                THEN
                    --LABELS WORDKER -- DEPENDENT                                  
                    l_str := l_str || chr(10) || l_worker_msg || pk_prog_notes_constants.g_colon ||
                             pk_prog_notes_constants.g_triple_colon || pk_prog_notes_constants.g_space ||
                             pk_prog_notes_constants.g_space || l_dependent_msg || pk_prog_notes_constants.g_colon ||
                             pk_prog_notes_constants.g_triple_colon;
                END IF;
            END LOOP;
        
        ELSE
            --building final string
            l_str := l_name_mess || pk_prog_notes_constants.g_colon || l_name || chr(10) || --
                     l_date_birth_mess || pk_prog_notes_constants.g_colon || l_date_birth || chr(10) || --
                     l_gender_mess || pk_prog_notes_constants.g_colon || l_gender_text;
        
            IF l_pregnant IS NOT NULL
            THEN
                l_str := l_str || chr(10) || --
                         l_pregnant_mess || pk_prog_notes_constants.g_colon || l_pregnant_text;
            END IF;
        
            l_str := l_str || chr(10) || --
                     l_nationality_mess || pk_prog_notes_constants.g_colon || l_nationality || chr(10) || --
                     l_language_mess || pk_prog_notes_constants.g_colon || l_language || chr(10) || --
                     l_marital_state_mess || pk_prog_notes_constants.g_colon || l_marital_state || chr(10) || --
                     l_address_mess || pk_prog_notes_constants.g_colon || l_address;
        
            IF l_id_market = 16
            THEN
                --getting health plan
                l_hplan := pk_patient.get_pat_health_plan(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
            
                l_hpentity := pk_patient.get_pat_hplan_entity(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_patient => l_id_patient);
            
                l_str := l_str || chr(10) || --
                         l_religion_mess || pk_prog_notes_constants.g_colon || l_religion || chr(10) || --
                         l_insurance_company_mess || pk_prog_notes_constants.g_colon || l_hpentity;
                IF l_hpentity IS NOT NULL
                THEN
                    l_str := l_str || pk_prog_notes_constants.g_flg_sep || l_hplan;
                END IF;
            END IF;
        END IF;
    
        RETURN l_str;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_identification;

    FUNCTION get_intensity_hhc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_tbl_id_request IN table_number,
        i_flg_report     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_data           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc VARCHAR2(100 CHAR);
        l_exception EXCEPTION;
        l_tab_templ_scores pk_prog_notes_types.t_tab_templ_scores;
        l_id_epis_hhc      epis_hhc_req.id_epis_hhc%TYPE;
    
    BEGIN
        pk_types.open_my_cursor(o_data);
    
        FOR r IN i_tbl_id_request.first() .. i_tbl_id_request.last()
        LOOP
            l_id_epis_hhc := pk_hhc_core.get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_tbl_id_request(r));
        
            --get last doc_area
            IF NOT pk_touch_option_core.get_last_doc_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_scope              => l_id_epis_hhc,
                                                          i_scope_type         => pk_alert_constant.g_scope_type_episode, --E
                                                          i_doc_area           => pk_alert_constant.g_doc_area_intensity_hhc,
                                                          i_doc_template       => NULL,
                                                          o_last_epis_doc      => l_last_epis_doc,
                                                          o_last_date_epis_doc => l_last_date_epis_doc,
                                                          o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
            IF l_last_epis_doc IS NOT NULL
            THEN
                pk_touch_option_core.get_plain_text_entries_type(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_patient            => i_id_patient,
                                                                 i_id_epis_documentation => l_last_epis_doc,
                                                                 i_id_request            => i_tbl_id_request(r),
                                                                 i_flg_report            => i_flg_report,
                                                                 o_entries               => o_data);
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_intensity_hhc;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_prog_notes_in;
/
