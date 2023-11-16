/*-- Last Change Revision: $Rev: 2027569 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_change_resp IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_retval       BOOLEAN;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    /**
    * Gets active hand off identifier
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_ref_det       Referral detail
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_active_handoff(i_id_ref IN ref_trans_responsibility.id_external_request%TYPE)
        RETURN ref_trans_responsibility.id_trans_resp%TYPE IS
        l_params VARCHAR2(1000 CHAR);
        l_result ref_trans_responsibility.id_trans_resp%TYPE;
    BEGIN
        l_params := 'i_id_ref=' || i_id_ref;
        g_error  := 'Init get_active_handoff / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        SELECT r.id_trans_resp /*, r.id_prof_transf_owner*/
          INTO l_result
          FROM ref_trans_responsibility r
         WHERE r.id_external_request = i_id_ref
           AND r.flg_active = pk_ref_constant.g_yes;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_active_handoff;

    /**
    * Check if this professional can request hand off for this referral
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_ref       Referral identifier           
    * @param   i_id_inst_orig Referral origin institution identifier
    * @param   i_id_prof_requested   Professional that requested the referral
    * @param   o_error        An error message, set when return=false    
    *
    * @RETURN  'Y'- hand off can be created for this referral 'N'- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_handoff_creation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_ref            IN ref_trans_responsibility.id_external_request%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE
    ) RETURN VARCHAR2 IS
        l_params               VARCHAR2(1000 CHAR);
        l_ref_transf_row       ref_trans_responsibility%ROWTYPE;
        l_result               VARCHAR2(1 CHAR);
        l_error                t_error_out;
        l_flg_status_begin     ref_trans_responsibility.id_status%TYPE;
        l_flg_check_status_end VARCHAR2(1 CHAR);
        l_is_clin_dir          VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_prof_requested=' || i_id_prof_requested;
        g_error  := 'Init check_handoff_creation / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        IF i_id_inst_orig = i_prof.institution
        THEN
        
            -- check if professional can create referral hand off
            IF i_id_prof_requested != i_prof.id
            THEN
                g_error       := 'Call pk_ref_core.validate_clin_dir / ' || l_params;
                l_is_clin_dir := pk_ref_core.validate_clin_dir(i_lang => i_lang, i_prof => i_prof);
            
                IF l_is_clin_dir = pk_ref_constant.g_no
                THEN
                    -- professional hasn't requested the referral nor is the clinical director, cannot create hand off
                    RETURN pk_ref_constant.g_no;
                END IF;
            END IF;
        
            -- check if this referral has hand off request in 
            g_retval := pk_ref_trans_responsibility.get_active_trans_resp_row(i_lang                => i_lang,
                                                                              i_prof                => i_prof,
                                                                              i_id_external_request => i_id_ref,
                                                                              o_row                 => l_ref_transf_row,
                                                                              o_error               => l_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_params := l_params || ' ID_WF=' || l_ref_transf_row.id_workflow || ' ID_STATUS=' ||
                        l_ref_transf_row.id_status;
        
            g_error := 'CASE / ' || l_params;
            CASE
                WHEN l_ref_transf_row.id_workflow IS NULL THEN
                    -- referral do not have any hand off request
                    l_result := pk_ref_constant.g_yes;
                WHEN l_ref_transf_row.id_workflow = pk_ref_constant.g_wf_transfresp THEN
                    l_result := pk_ref_constant.g_yes;
                WHEN l_ref_transf_row.id_workflow = pk_ref_constant.g_wf_transfresp_inst THEN
                
                    -- check hand off status (can be initial or final status)            
                    l_flg_status_begin     := pk_workflow.get_status_begin(i_id_workflow => l_ref_transf_row.id_workflow);
                    l_flg_check_status_end := pk_workflow.check_status_final(i_id_workflow => l_ref_transf_row.id_workflow,
                                                                             i_id_status   => l_ref_transf_row.id_status);
                
                    g_error := 'l_flg_status_begin=' || l_flg_status_begin || ' l_flg_check_status_end=' ||
                               l_flg_check_status_end || ' / ' || l_params;
                    IF l_flg_status_begin = l_ref_transf_row.id_status -- this is begin status
                       OR l_flg_check_status_end = pk_ref_constant.g_yes -- or this status can be end status
                    THEN
                    
                        l_result := pk_ref_constant.g_yes;
                    ELSE
                        -- previous hand off is pending
                        l_result := pk_ref_constant.g_no;
                    END IF;
                
                ELSE
                    l_result := pk_ref_constant.g_no;
            END CASE;
        
        END IF;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_handoff_creation;

    /**
    * Check parameters for the hand off creation
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_workflow        Hand off workflow identifier
    * @param   i_id_prof_dest       Professional to which the referral is being hand off
    * @param   i_id_inst_dest_tr    Institution to where the referral is being hand off
    *
    * @RETURN  'Y'- parameters are ok 'N'- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-06-2013
    */
    FUNCTION check_handoff_creation_param
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_workflow     IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_prof_dest    IN ref_trans_responsibility.id_prof_dest%TYPE,
        i_id_inst_dest_tr IN ref_trans_responsibility.id_inst_dest_tr%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1 CHAR);
        l_config VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow || ' i_id_prof_dest=' ||
                    i_id_prof_dest || ' i_id_inst_dest_tr=' || i_id_inst_dest_tr;
        g_error  := 'Init check_handoff_creation_param / ' || l_params;
        l_result := pk_ref_constant.g_yes;
    
        -- check parameters       
        CASE i_id_workflow
            WHEN pk_ref_constant.g_wf_transfresp THEN
                -- internal
            
                IF i_id_prof_dest IS NULL
                THEN
                    l_result := pk_ref_constant.g_no;
                END IF;
            
            WHEN pk_ref_constant.g_wf_transfresp_inst THEN
                -- institution
            
                l_config := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_handoff_inst_enabled,
                                                    i_prof    => i_prof);
                IF l_config = pk_ref_constant.g_yes
                THEN
                    IF i_id_inst_dest_tr IS NULL
                       OR i_id_prof_dest IS NOT NULL
                    THEN
                        l_result := pk_ref_constant.g_no;
                    END IF;
                END IF;
            
            ELSE
                l_result := pk_ref_constant.g_no;
        END CASE;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_handoff_creation_param;

    /**
    * Check if this professional is responsible to manage hand off
    *
    * @param   i_prof              Professional id, institution and software    
    *
    * @return  Y- can manage hand off, N- otherwise 
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_func_handoff_app(i_prof IN profissional) RETURN VARCHAR2 IS
        l_func_inst_tab table_number;
        l_idx           PLS_INTEGER;
    BEGIN
        g_error         := 'Init check_func_handoff_app / i_prof=' || pk_utils.to_string(i_prof);
        l_func_inst_tab := pk_ref_core.get_prof_func_inst(i_lang => NULL, i_prof => i_prof);
        l_idx           := pk_utils.search_table_number(i_table  => l_func_inst_tab,
                                                        i_search => pk_ref_constant.g_func_ref_handoff_app);
    
        IF l_idx != -1
        THEN
            RETURN pk_ref_constant.g_yes;
        END IF;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_no;
    END check_func_handoff_app;

    /**
    * Checks if this professional can analyze hand off
    *
    * @param   i_prof              Professional id, institution and software
    * @param   i_tr_id_workflow    Hand off workflow identifier
    * @param   i_tr_id_status      Status identifier
    * @param   i_tr_id_prof_dest   Professional that is requesting hand off    
    *
    * @return  Y- can request hand off, N- otherwise 
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION can_analyze
    (
        i_prof            IN profissional,
        i_tr_id_workflow  IN wf_workflow.id_workflow%TYPE,
        i_tr_id_status    IN wf_status.id_status%TYPE,
        i_tr_id_prof_dest IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_result           VARCHAR(1 CHAR);
        l_params           VARCHAR2(1000 CHAR);
        l_flg_status_final VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_tr_id_workflow=' || i_tr_id_workflow ||
                    ' i_tr_id_status=' || i_tr_id_status || ' i_tr_id_prof_dest=' || i_tr_id_prof_dest;
        g_error  := 'Init can_analyze / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        l_flg_status_final := pk_workflow.check_status_final(i_id_workflow => i_tr_id_workflow,
                                                             i_id_status   => i_tr_id_status);
    
        IF i_tr_id_prof_dest = i_prof.id
           AND l_flg_status_final = pk_ref_constant.g_no
        THEN
            l_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_no;
    END can_analyze;

    /**
    * Checks if this professional can analyze exernal hand off
    *
    * @param   i_prof              Professional id, institution and software
    * @param   i_tr_id_workflow    Hand off workflow identifier    
    * @param   i_tr_id_status      Status identifier
    * @param   i_tr_id_inst_dest    Hand off dest institution identifier
    *
    * @return  Y- can analyze external hand off , N- otherwise 
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   22-08-2013
    */
    FUNCTION can_analyze_inst
    (
        i_prof            IN profissional,
        i_tr_id_workflow  IN ref_trans_responsibility.id_workflow%TYPE,
        i_tr_id_status    IN wf_status.id_status%TYPE,
        i_tr_id_inst_dest IN ref_trans_responsibility.id_inst_dest_tr%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR(1 CHAR);
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_tr_id_workflow=' || i_tr_id_workflow ||
                    ' i_tr_id_inst_dest=' || i_tr_id_inst_dest;
        g_error  := 'Init can_analyze_inst / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        IF i_tr_id_workflow = pk_ref_constant.g_wf_transfresp_inst
           AND i_tr_id_inst_dest = i_prof.institution
           AND i_tr_id_status IN (pk_ref_constant.g_tr_status_inst_app, pk_ref_constant.g_tr_status_declined_inst)
        THEN
            l_result := check_func_handoff_app(i_prof => i_prof);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_no;
    END can_analyze_inst;

    /**
    * Checks if this professional can cancel hand off
    *
    * @param   i_prof              Professional id, institution and software
    * @param   i_tr_id_workflow    Hand off workflow identifier
    * @param   i_tr_id_status      Status identifier
    * @param   i_tr_id_prof_owner  Professional that created referral handoff    
    *
    * @return  Y- can cancel hand off, N- otherwise 
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-06-2013
    */
    FUNCTION can_cancel
    (
        i_prof             IN profissional,
        i_tr_id_workflow   IN ref_trans_responsibility.id_workflow%TYPE,
        i_tr_id_status     IN ref_trans_responsibility.id_status%TYPE,
        i_tr_id_prof_owner IN ref_trans_responsibility.id_prof_transf_owner%TYPE
    ) RETURN VARCHAR2 IS
        l_result           VARCHAR(1 CHAR);
        l_params           VARCHAR2(1000 CHAR);
        l_flg_status_final VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_tr_id_workflow=' || i_tr_id_workflow ||
                    ' i_tr_id_status=' || i_tr_id_status || ' i_tr_id_prof_owner=' || i_tr_id_prof_owner;
        g_error  := 'Init can_cancel / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        l_flg_status_final := pk_workflow.check_status_final(i_id_workflow => i_tr_id_workflow,
                                                             i_id_status   => i_tr_id_status);
    
        IF i_tr_id_prof_owner = i_prof.id
           AND l_flg_status_final = pk_ref_constant.g_no
        -- ALERT-272292 -- AND i_tr_id_status != pk_ref_constant.g_tr_status_inst_app -- nao pode cancelar quando está
        THEN
            l_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_no;
    END can_cancel;

    /**
    * Gets the string with dest hand off (used in grids)
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_workflow   Hand off workflow identifier
    * @param   i_id_prof_dest  Dest professional identifier
    * @param   i_id_inst_dest  Dest institution identifier
    *
    * @RETURN  dest hand off string
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   29-08-2013
    */
    FUNCTION get_handoff_dest_string
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_prof_dest IN ref_trans_responsibility.id_prof_dest%TYPE,
        i_id_inst_dest IN ref_trans_responsibility.id_inst_dest_tr%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow || ' i_id_prof_dest=' ||
                    i_id_prof_dest || ' i_id_inst_dest=' || i_id_inst_dest;
        g_error  := 'Init get_handoff_dest_string / ' || l_params;
        CASE i_id_workflow
        
            WHEN pk_ref_constant.g_wf_transfresp THEN
                l_result := pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof_dest);
            
            WHEN pk_ref_constant.g_wf_transfresp_inst THEN
            
                l_result := pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || i_id_inst_dest);
            
                IF i_id_prof_dest IS NOT NULL
                THEN
                    g_error  := 'i_id_prof_dest / ' || l_params;
                    l_result := l_result || chr(10) || pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof_dest);
                END IF;
            
            ELSE
                g_error := 'CASE not found / i_id_workflow=' || i_id_workflow || ' / ' || l_params;
                pk_alertlog.log_warn(g_error);
                l_result := NULL;
        END CASE;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_handoff_dest_string;

    /**
    * Changes this transf resp to the next status
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_transf_resp  Row data related to the transf resp
    * @param   i_params       
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION change_to_next_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_transf_resp IN ref_trans_responsibility%ROWTYPE,
        i_params      IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_my_data              t_rec_prof_data;
        l_t_coll_wf_transition t_coll_wf_transition;
        l_params               VARCHAR2(1000 CHAR);
        l_id_trans_resp_hist   ref_trans_resp_hist.id_trans_resp_hist%TYPE;
        l_wf_transition_info   table_varchar;
        l_ref_row              p1_external_request%ROWTYPE;
        l_flg_status_final     VARCHAR2(1 CHAR);
        l_track_tab            table_number;
    BEGIN
        l_params             := 'i_prof=' || pk_utils.to_string(i_prof) || ' id_trans_resp=' ||
                                i_transf_resp.id_trans_resp || ' id_status=' || i_transf_resp.id_status ||
                                ' id_workflow=' || i_transf_resp.id_workflow || ' id_external_request=' ||
                                i_transf_resp.id_external_request || ' id_prof_ref_owner=' ||
                                i_transf_resp.id_prof_ref_owner || ' id_prof_transf_owner=' ||
                                i_transf_resp.id_prof_transf_owner || ' id_prof_dest=' || i_transf_resp.id_prof_dest ||
                                ' id_reason_code=' || i_transf_resp.id_reason_code || ' id_inst_orig_tr=' ||
                                i_transf_resp.id_inst_orig_tr || ' id_inst_dest_tr=' || i_transf_resp.id_inst_dest_tr ||
                                ' i_params=' || pk_utils.to_string(i_params);
        l_wf_transition_info := i_params;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_transf_resp.id_external_request;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_transf_resp.id_external_request,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' id_profile_template=' || l_my_data.id_profile_template || ' id_functionality=' ||
                    l_my_data.id_functionality || ' id_category=' || l_my_data.id_category || ' flg_category=' ||
                    l_my_data.flg_category;
    
        g_error  := 'Call pk_workflow.get_transitions / ' || l_params;
        g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => i_transf_resp.id_workflow,
                                                i_id_status_begin     => i_transf_resp.id_status,
                                                i_id_category         => l_my_data.id_category,
                                                i_id_profile_template => l_my_data.id_profile_template,
                                                i_id_functionality    => l_my_data.id_functionality,
                                                i_param               => l_wf_transition_info,
                                                i_flg_auto_transition => pk_ref_constant.g_no,
                                                o_transitions         => l_t_coll_wf_transition,
                                                o_error               => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_t_coll_wf_transition.count = 0
        THEN
            g_error      := 'No transitions available / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF l_t_coll_wf_transition.count > 1
        THEN
            g_error      := 'Too much transitions available: ' || l_t_coll_wf_transition.count || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' ID_STATUS_END=' || l_t_coll_wf_transition(1).id_status_end || ' ID_WORKFLOW_ACTION=' || l_t_coll_wf_transition(1)
                   .id_workflow_action || ' user_answ=' || l_wf_transition_info(pk_ref_constant.g_idx_tr_user_answ);
    
        g_error  := 'Call pk_ref_tr_status.process_tr_transition / ' || l_params;
        g_retval := pk_ref_tr_status.process_tr_transition(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_prof_data           => l_my_data,
                                                           i_id_trans_resp       => i_transf_resp.id_trans_resp,
                                                           i_id_external_request => i_transf_resp.id_external_request,
                                                           i_id_workflow         => i_transf_resp.id_workflow,
                                                           i_id_status_begin     => i_transf_resp.id_status,
                                                           i_id_status_end       => l_t_coll_wf_transition(1)
                                                                                    .id_status_end,
                                                           i_id_workflow_action  => l_t_coll_wf_transition(1)
                                                                                    .id_workflow_action,
                                                           i_date                => NULL,
                                                           i_notes               => i_transf_resp.notes,
                                                           i_id_reason_code      => i_transf_resp.id_reason_code,
                                                           i_reason_code_text    => i_transf_resp.reason_code_text,
                                                           i_id_prof_dest        => i_transf_resp.id_prof_dest,
                                                           io_param              => l_wf_transition_info,
                                                           o_id_trans_resp_hist  => l_id_trans_resp_hist,
                                                           o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- process hand off alerts        
        g_error  := 'Call pk_ref_tr_status.process_tr_transition_alerts / ' || l_params;
        g_retval := pk_ref_tr_status.process_tr_transition_alerts(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_prof_data           => l_my_data,
                                                                  i_id_external_request => l_ref_row.id_external_request,
                                                                  i_id_inst_orig_tr     => i_transf_resp.id_inst_orig_tr, -- origin institution
                                                                  i_id_patient          => l_ref_row.id_patient,
                                                                  i_id_dep_clin_serv    => l_ref_row.id_dep_clin_serv,
                                                                  i_id_episode          => l_ref_row.id_episode,
                                                                  i_id_workflow         => i_transf_resp.id_workflow,
                                                                  i_id_status_begin     => i_transf_resp.id_status,
                                                                  i_id_status_end       => l_t_coll_wf_transition(1)
                                                                                           .id_status_end,
                                                                  i_id_workflow_action  => l_t_coll_wf_transition(1)
                                                                                           .id_workflow_action,
                                                                  i_date                => NULL,
                                                                  io_param              => l_wf_transition_info,
                                                                  o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error            := 'Call pk_workflow.check_status_final / ' || l_params;
        l_flg_status_final := pk_workflow.check_status_final(i_id_workflow => i_transf_resp.id_workflow,
                                                             i_id_status   => l_t_coll_wf_transition(1).id_status_end);
    
        g_error := 'l_flg_status_final=' || l_flg_status_final || ' / ' || l_params;
        IF l_flg_status_final = pk_ref_constant.g_yes
           AND l_wf_transition_info.exists(pk_ref_constant.g_idx_tr_user_answ)
           AND l_wf_transition_info(pk_ref_constant.g_idx_tr_user_answ) = pk_ref_constant.g_yes
        THEN
            g_error  := 'Call change_responsibility / ' || l_params;
            g_retval := change_responsibility(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_external_request => i_transf_resp.id_external_request,
                                              i_id_prof             => i_prof.id,
                                              i_id_prof_request     => i_transf_resp.id_prof_transf_owner,
                                              i_id_reason_code      => i_transf_resp.id_reason_code,
                                              i_notes               => i_transf_resp.notes,
                                              i_id_inst_dest_tr     => i_transf_resp.id_inst_dest_tr,
                                              o_track               => l_track_tab,
                                              o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'change_to_next_status',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END change_to_next_status;

    /**
    * Transfers referral responsibility to professional i_id_prof
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_external_request    Referral identifier
    * @param   i_id_prof                Professional identifier to which the referral is being transfered
    * @param   i_id_prof_request        Professional identifier that is transfering the referral
    * @param   i_id_reason_code         Reason code identifier
    * @param   i_notes                  Notes
    * @param   i_id_inst_dest_tr        Referral new origin institution identifier (dest hand off)
    * @param   i_date                   Operation date
    * @param   o_track                  Array of ID_TRACKING transitions
    * @param   o_error                  An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION change_responsibility
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_id_prof             IN professional.id_professional%TYPE,
        i_id_prof_request     IN professional.id_professional%TYPE,
        i_id_reason_code      IN p1_reason_code.id_reason_code%TYPE,
        i_notes               IN VARCHAR2,
        i_id_inst_dest_tr     IN ref_trans_responsibility.id_inst_dest_tr%TYPE,
        i_date                IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track               OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row      p1_tracking%ROWTYPE;
        l_detail_row     p1_detail%ROWTYPE;
        l_var            p1_detail.id_detail%TYPE;
        l_prof           profissional;
        l_param          table_varchar;
        l_ref_row        p1_external_request%ROWTYPE;
        l_params         VARCHAR2(1000 CHAR);
        l_id_workflow    p1_external_request.id_workflow%TYPE;
        l_flg_can_change VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'ID_REF=' || i_id_external_request || ' i_id_prof=' || i_id_prof || ' i_id_prof_request=' ||
                    i_id_prof_request || ' i_id_reason_code=' || i_id_reason_code || ' i_id_inst_dest_tr=' ||
                    i_id_inst_dest_tr;
    
        g_error := 'Init change_responsibility / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        l_prof         := profissional(i_id_prof_request, i_prof.institution, i_prof.software); -- professional requesting the transf resp
        o_track        := table_number();
    
        g_error  := 'Call pk_p1_external_request.get_flg_status / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_external_request,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' FLG_STATUS=' || l_ref_row.flg_status || ' ID_INST_ORIG=' || l_ref_row.id_inst_orig;
    
        g_error := 'Call pk_ref_core.init_param_tab / ' || l_params;
        l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_ext_req            => l_ref_row.id_external_request,
                                              i_id_patient         => l_ref_row.id_patient,
                                              i_id_inst_orig       => l_ref_row.id_inst_orig,
                                              i_id_inst_dest       => l_ref_row.id_inst_dest,
                                              i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                              i_id_speciality      => l_ref_row.id_speciality,
                                              i_flg_type           => l_ref_row.flg_type,
                                              i_decision_urg_level => l_ref_row.decision_urg_level,
                                              i_id_prof_requested  => l_ref_row.id_prof_requested,
                                              i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                              i_id_prof_status     => l_ref_row.id_prof_status,
                                              i_external_sys       => l_ref_row.id_external_sys,
                                              i_flg_status         => l_ref_row.flg_status);
    
        g_error                         := 'P1_Tracking / ' || l_params;
        l_track_row.id_external_request := i_id_external_request;
        l_track_row.ext_req_status      := l_ref_row.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_t;
        l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        l_track_row.id_prof_dest        := i_id_prof;
        l_track_row.id_reason_code      := i_id_reason_code;
    
        IF i_id_inst_dest_tr != l_ref_row.id_inst_orig
        THEN
            l_params                 := l_params || ' NEW id_inst_orig=' || i_id_inst_dest_tr || ' OLD id_inst_orig=' ||
                                        l_ref_row.id_inst_orig;
            g_error                  := l_params;
            l_track_row.id_inst_orig := i_id_inst_dest_tr;
        
            -- getting new id_workflow
            l_id_workflow := pk_ref_utils.get_workflow(i_prof         => i_prof,
                                                       i_lang         => i_lang,
                                                       i_id_ext_sys   => l_ref_row.id_external_sys,
                                                       i_id_inst_orig => i_id_inst_dest_tr, -- new id_inst_orig
                                                       i_id_inst_dest => l_ref_row.id_inst_dest,
                                                       i_detail       => NULL -- used only for pk_ref_constant.g_ext_sys_pas
                                                       );
        
            IF l_id_workflow != l_ref_row.id_workflow
            THEN
                l_params := l_params || ' NEW id_workflow=' || l_id_workflow || ' OLD id_workflow=' ||
                            l_ref_row.id_workflow;
            
                -- check if can change to this workflow
                g_error  := 'Call pk_ref_change_resp.check_workflow_change / ' || l_params;
                g_retval := pk_ref_status.check_workflow_change(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_wf_old  => l_ref_row.id_workflow,
                                                                i_id_wf_new  => l_id_workflow,
                                                                i_flg_status => l_ref_row.flg_status,
                                                                o_can_change => l_flg_can_change,
                                                                o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF l_flg_can_change = pk_ref_constant.g_no
                THEN
                    g_error := 'Cannot change referral workflow / ' || l_params;
                    RAISE g_exception;
                END IF;
            
                l_track_row.id_workflow := l_id_workflow;
            END IF;
        
        END IF;
    
        g_error  := 'Call pk_ref_status.update_status / ' || l_params;
        g_retval := pk_ref_status.update_status(i_lang      => i_lang,
                                                i_prof      => l_prof,
                                                i_track_row => l_track_row,
                                                io_param    => l_param,
                                                o_track     => o_track,
                                                o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_track_row.id_tracking := o_track(1); -- first iteration
    
        g_error                          := 'Fill detail row / ' || l_params || ' / ID_TRACKING=' ||
                                            l_track_row.id_tracking;
        l_detail_row.id_external_request := i_id_external_request;
        l_detail_row.id_tracking         := l_track_row.id_tracking;
        l_detail_row.flg_type            := pk_ref_constant.g_detail_type_transresp;
        l_detail_row.id_professional     := i_id_prof_request;
        l_detail_row.id_institution      := i_prof.institution;
        l_detail_row.dt_insert_tstz      := g_sysdate_tstz;
        l_detail_row.text                := i_notes;
        l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
    
        g_error  := 'Call pk_ref_api.set_p1_detail / ' || l_params;
        g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_p1_detail => l_detail_row,
                                             o_id_detail => l_var,
                                             o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'Change_responsibility',
                                              o_error    => o_error);
            RETURN FALSE;
    END change_responsibility;

    /**
    * Create a new request to hand off referral
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_transf_resp  Data related to transferring responsibility
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION req_new_responsibility
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_transf_resp IN ref_trans_responsibility%ROWTYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params            VARCHAR2(1000 CHAR);
        l_flg               VARCHAR2(1 CHAR);
        l_id_prof_requested p1_external_request.id_prof_requested%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_STATUS=' || i_transf_resp.id_status || ' ID_WF=' ||
                    i_transf_resp.id_workflow || ' ID_REF=' || i_transf_resp.id_external_request ||
                    ' id_prof_ref_owner=' || i_transf_resp.id_prof_ref_owner || ' id_prof_transf_owner=' ||
                    i_transf_resp.id_prof_transf_owner || ' id_prof_dest=' || i_transf_resp.id_prof_dest ||
                    ' id_reason_code=' || i_transf_resp.id_reason_code || ' flg_active=' || i_transf_resp.flg_active ||
                    ' id_inst_orig_tr=' || i_transf_resp.id_inst_orig_tr || ' id_inst_dest_tr=' ||
                    i_transf_resp.id_inst_dest_tr;
        g_error  := 'Init req_new_responsibility / ' || l_params;
    
        -- check parameters 
        l_flg := check_handoff_creation_param(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_workflow     => i_transf_resp.id_workflow,
                                              i_id_prof_dest    => i_transf_resp.id_prof_dest,
                                              i_id_inst_dest_tr => i_transf_resp.id_inst_dest_tr);
    
        IF l_flg = pk_ref_constant.g_no
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check permissions
        g_error  := 'Call pk_p1_external_request.get_id_prof_requested / ' || l_params;
        g_retval := pk_p1_external_request.get_id_prof_requested(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_id_ref            => i_transf_resp.id_external_request,
                                                                 o_id_prof_requested => l_id_prof_requested,
                                                                 o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call check_handoff_creation / ' || l_params;
        l_flg   := check_handoff_creation(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_ref            => i_transf_resp.id_external_request,
                                          i_id_inst_orig      => i_transf_resp.id_inst_orig_tr,
                                          i_id_prof_requested => l_id_prof_requested);
    
        IF l_flg = pk_ref_constant.g_no
        THEN
            g_error := 'Referral ' || i_transf_resp.id_external_request || ' has a pending hand off / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- create hand off
        pk_ref_trans_responsibility.upd_by_id_external_request(id_external_request_in => i_transf_resp.id_external_request,
                                                               flg_active_in          => pk_ref_constant.g_no,
                                                               id_professional_in     => i_prof.id,
                                                               id_institution_in      => i_prof.institution);
    
        pk_ref_trans_responsibility.ins(id_trans_resp_in        => pk_ref_trans_responsibility.next_key,
                                        id_status_in            => i_transf_resp.id_status,
                                        id_workflow_in          => i_transf_resp.id_workflow,
                                        id_external_request_in  => i_transf_resp.id_external_request,
                                        id_prof_ref_owner_in    => i_transf_resp.id_prof_ref_owner,
                                        id_prof_transf_owner_in => i_transf_resp.id_prof_transf_owner,
                                        id_prof_dest_in         => i_transf_resp.id_prof_dest,
                                        dt_created_in           => i_transf_resp.dt_created,
                                        id_reason_code_in       => i_transf_resp.id_reason_code,
                                        reason_code_text_in     => i_transf_resp.reason_code_text,
                                        flg_active_in           => i_transf_resp.flg_active,
                                        notes_in                => i_transf_resp.notes,
                                        id_professional_in      => i_prof.id,
                                        id_institution_in       => i_prof.institution,
                                        id_inst_orig_tr_in      => i_transf_resp.id_inst_orig_tr,
                                        id_inst_dest_tr_in      => i_transf_resp.id_inst_dest_tr);
    
        -- clean alerts
        g_error  := 'Call pk_ref_tr_status.clean_handoff_alerts / ';
        g_retval := pk_ref_tr_status.clean_handoff_alerts(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_external_request => i_transf_resp.id_external_request,
                                                          o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'req_new_responsibility',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END req_new_responsibility;

    /**
    * Opens a cursor with a dynamic query
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_tab_name     Table name
    * @param   i_column       Column name
    * @param   i_field_name   Field name
    * @param   i_val          Value
    * @param   o_crs          Cursor returned
    * @param   o_error        Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    PROCEDURE dyn_sel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tab_name   IN VARCHAR2,
        i_column     IN VARCHAR2,
        i_field_name IN VARCHAR2,
        i_val        IN VARCHAR2,
        o_crs        IN OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) IS
        l_stmt VARCHAR2(4000 CHAR);
    BEGIN
        l_stmt := 'select DISTINCT ' || i_column || ' from ' || i_tab_name || ' where ' || i_field_name || ' in (' ||
                  i_val || ') ';
    
        OPEN o_crs FOR l_stmt;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'dyn_sel',
                                              o_error    => o_error);
    END dyn_sel;

    /**
    * Validates that this professional is allowed to search for several physicians
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   o_multi        {*} Y- is allowed {*} N- otherwise
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION tr_is_multi_prof
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_multi OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_my_data     t_rec_prof_data;
        o_master_prof profile_template.id_profile_template%TYPE;
    BEGIN
        g_error  := 'Init tr_is_multi_prof / i_prof=' || pk_utils.to_string(i_prof);
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_core.get_profile_owner / i_prof=' || pk_utils.to_string(i_prof);
        g_retval := pk_ref_core.get_profile_owner(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_profile     => l_my_data.id_profile_template,
                                                  o_master_prof => o_master_prof,
                                                  o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'o_master_prof=' || o_master_prof || ' l_my_data.id_profile_template=' ||
                   l_my_data.id_profile_template || ' l_my_data.id_functionality=' || l_my_data.id_functionality;
        IF (o_master_prof = pk_ref_constant.g_profile_med_cs OR o_master_prof = pk_ref_constant.g_profile_med_hs)
           AND (pk_ref_core.validate_clin_dir(i_lang => i_lang, i_prof => i_prof) = pk_ref_constant.g_yes)
        THEN
            o_multi := pk_ref_constant.g_yes;
        ELSE
            o_multi := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'tr_is_multi_prof',
                                              o_error    => o_error);
            RETURN FALSE;
    END tr_is_multi_prof;

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   03-09-2010
    */
    FUNCTION row_valid_to_show
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_workflow    IN wf_workflow.id_workflow%TYPE,
        i_id_status      IN wf_status.id_status%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_dt_update      IN ref_trans_responsibility.dt_update%TYPE
    ) RETURN VARCHAR2 IS
        o_error t_error_out;
    BEGIN
    
        IF pk_workflow.check_status_final(i_id_workflow => i_id_workflow, i_id_status => i_id_status) =
           pk_ref_constant.g_yes
        THEN
            IF current_timestamp <=
               (i_dt_update + to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                                    i_id_institution,
                                                                                                    i_id_software),
                                                                    i_id_sys_config => i_id_sys_config)))
            THEN
                RETURN pk_ref_constant.g_yes;
            ELSE
                RETURN pk_ref_constant.g_no;
            END IF;
        END IF;
        RETURN pk_ref_constant.g_yes;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'row_valid_to_show',
                                              o_error    => o_error);
            RETURN pk_ref_constant.g_no;
    END row_valid_to_show;

    /**
    * Return the distinct value of an array, or returns the string default (if multiple values)
    *
    * @param   i_val_tab       Array of values to check
    * @param   i_str_default   Default string to be returned if there are multiple values
    *
    * @RETURN  value to be returned
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_value
    (
        i_val_tab     IN table_varchar,
        i_str_default IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_count  PLS_INTEGER;
        l_result VARCHAR2(1000 CHAR);
    BEGIN
        SELECT COUNT(DISTINCT column_value)
          INTO l_count
          FROM TABLE(CAST(i_val_tab AS table_varchar));
    
        IF l_count > 1
        THEN
            l_result := i_str_default;
        ELSE
            l_result := i_val_tab(1);
        END IF;
    
        RETURN l_result;
    END get_value;

    /**
    * Gets hand off detail
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_tr_tab     Array of hand off identifiers
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_short_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_tr_tab   IN table_number,
        o_tr_orig_det OUT pk_types.cursor_type,
        o_tr_dest_det OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params      VARCHAR2(1000 CHAR);
        l_prof_data   t_rec_prof_data;
        l_str_default VARCHAR2(1000 CHAR);
    
        -- orig
        l_rc_orig             pk_ref_list.t_cur_handoff_orig;
        l_coll_id_workflow    table_number;
        l_coll_inst_orig      table_varchar;
        l_coll_prof_ref_owner table_varchar;
        l_coll_prof_dest      table_varchar;
        l_coll_hand_off_to    table_varchar;
        l_coll_reason_desc    table_varchar;
        l_coll_notes          table_varchar;
        l_coll_dt_status      table_varchar;
        l_coll_prof_status    table_varchar;
    
        -- dest
        l_rc_dest             pk_ref_list.t_cur_handoff_dest;
        l_coll_desc_status    table_varchar;
        l_coll_prof_name_dest table_varchar;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_tr_tab.count=' || i_id_tr_tab.count;
        g_error  := 'Init get_short_detail / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_str_default := pk_message.get_message(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_code_mess => pk_ref_constant.g_sm_ref_transfresp_t042); -- Multiple
    
        -- Hand off orig data
        g_error  := 'Call pk_ref_list.get_handoff_detail_orig / ' || l_params;
        g_retval := pk_ref_list.get_handoff_detail_orig(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_tr_tab   => i_id_tr_tab,
                                                        o_tr_orig_det => l_rc_orig,
                                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_rc_orig BULK COLLECT / ' || l_params;
        FETCH l_rc_orig BULK COLLECT
            INTO l_coll_id_workflow,
                 l_coll_inst_orig,
                 l_coll_prof_ref_owner,
                 l_coll_prof_dest,
                 l_coll_hand_off_to,
                 l_coll_reason_desc,
                 l_coll_notes,
                 l_coll_dt_status,
                 l_coll_prof_status;
        CLOSE l_rc_orig;
    
        g_error := 'OPEN o_tr_orig_det FOR / ' || l_params;
        OPEN o_tr_orig_det FOR
            SELECT get_value(i_val_tab => l_coll_inst_orig, i_str_default => l_str_default) tr_inst_orig_desc,
                   get_value(i_val_tab => l_coll_prof_ref_owner, i_str_default => l_str_default) prof_requested,
                   get_value(i_val_tab => l_coll_hand_off_to, i_str_default => l_str_default) hand_off_to,
                   get_value(i_val_tab => l_coll_reason_desc, i_str_default => l_str_default) reason_desc,
                   get_value(i_val_tab => l_coll_notes, i_str_default => l_str_default) notes,
                   get_value(i_val_tab => l_coll_dt_status, i_str_default => l_str_default) dt_status,
                   get_value(i_val_tab => l_coll_prof_status, i_str_default => l_str_default) prof_status
              FROM dual;
    
        -- Hand off dest data (only if ID_WF=11)
        IF l_coll_id_workflow(1) = pk_ref_constant.g_wf_transfresp
        THEN
            pk_types.open_my_cursor(o_tr_dest_det);
        ELSE
            g_error  := 'Call pk_ref_list.get_handoff_detail_dest / ' || l_params;
            g_retval := pk_ref_list.get_handoff_detail_dest(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_prof_data   => l_prof_data,
                                                            i_id_tr_tab   => i_id_tr_tab,
                                                            o_tr_dest_det => l_rc_dest,
                                                            o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'FETCH l_rc_orig BULK COLLECT / ' || l_params;
            FETCH l_rc_dest BULK COLLECT
                INTO l_coll_id_workflow,
                     l_coll_desc_status,
                     l_coll_prof_name_dest,
                     l_coll_prof_dest,
                     l_coll_notes,
                     l_coll_dt_status,
                     l_coll_prof_status;
            CLOSE l_rc_dest;
        
            g_error := 'OPEN o_tr_dest_det FOR / ' || l_params;
            OPEN o_tr_dest_det FOR
                SELECT get_value(i_val_tab => l_coll_desc_status, i_str_default => l_str_default) desc_status,
                       get_value(i_val_tab => l_coll_prof_name_dest, i_str_default => l_str_default) prof_name_dest,
                       get_value(i_val_tab => l_coll_notes, i_str_default => l_str_default) notes,
                       get_value(i_val_tab => l_coll_dt_status, i_str_default => l_str_default) dt_status,
                       get_value(i_val_tab => l_coll_prof_status, i_str_default => l_str_default) prof_status
                  FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_tr_orig_det);
            pk_types.open_my_cursor(o_tr_dest_det);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SHORT_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_tr_orig_det);
            pk_types.open_my_cursor(o_tr_dest_det);
            RETURN FALSE;
    END get_short_detail;

    /**
    * Gets hand off detail
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_ref_det       Referral detail
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   29-05-2013
    */
    FUNCTION get_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN ref_trans_responsibility.id_external_request%TYPE,
        o_ref_det     OUT pk_types.cursor_type,
        o_tr_orig_det OUT pk_types.cursor_type,
        o_tr_dest_det OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params    VARCHAR2(1000 CHAR);
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
        -- sys_messages
        l_code_msg_arr         table_varchar;
        l_desc_message_ibt     pk_ref_constant.ibt_varchar_varchar;
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
    BEGIN
        l_params := 'i_id_ref=' || i_id_ref;
        g_error  := 'Init get_detail / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        -- getting sys_messages
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_ref_transfresp_t023, -- Notas
                                        pk_ref_constant.g_sm_ref_transfresp_t016, -- Estado
                                        pk_ref_constant.g_sm_ref_transfresp_t021, -- Motivo do pedido
                                        pk_ref_constant.g_sm_ref_transfresp_t022, -- Profissional de destino
                                        pk_ref_constant.g_sm_ref_transfresp_t054, -- Profissional responsável pelo pedido
                                        pk_ref_constant.g_sm_ref_transfresp_t055, -- Profissional que pediu a transferência
                                        pk_ref_constant.g_ref_mark_req_t010); -- Instituição de origem
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / l_code_msg_arr.COUNT=' || l_code_msg_arr.count || ' / ' ||
                    l_params;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' WF=' || l_ref_row.id_workflow || ' FLG_STATUS=' || l_ref_row.flg_status || ' DCS=' ||
                    l_ref_row.id_dep_clin_serv;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ID_CAT=' || l_prof_data.id_category || ' ID_PROF_TEMPL=' ||
                    l_prof_data.id_profile_template || ' ID_FUNC=' || l_prof_data.id_functionality;
    
        -- get active hand off identifier
        --g_error         := 'Call get_active_handoff / ' || l_params;
        --l_id_trans_resp := get_active_handoff(i_id_ref => l_ref_row.id_external_request);
    
        -- get active hand off identifier and professional owner
        SELECT r.id_trans_resp, r.id_prof_transf_owner
          INTO l_id_trans_resp, l_id_prof_transf_owner
          FROM ref_trans_responsibility r
         WHERE r.id_external_request = l_ref_row.id_external_request
           AND r.flg_active = pk_ref_constant.g_yes;
    
        -- referral detail
        g_error  := 'Call pk_ref_list.get_referral_detail_short / ' || l_params;
        g_retval := pk_ref_list.get_referral_detail_short(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_prof_data => l_prof_data,
                                                          i_ref_row   => l_ref_row,
                                                          i_param     => NULL, -- set inside this function
                                                          o_ref_data  => o_ref_det,
                                                          o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Hand off active detail orig
        g_error  := 'Call pk_ref_list.get_handoff_detail_orig / ' || l_params;
        g_retval := pk_ref_list.get_handoff_detail_orig(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_tr_tab   => table_number(l_id_trans_resp),
                                                        o_tr_orig_det => o_tr_orig_det,
                                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Hand off active detail dest
        g_error  := 'Call pk_ref_list.get_handoff_detail_dest / ' || l_params;
        g_retval := pk_ref_list.get_handoff_detail_dest(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_prof_data   => l_prof_data,
                                                        i_id_tr_tab   => table_number(l_id_trans_resp),
                                                        o_tr_dest_det => o_tr_dest_det,
                                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_prof_transf_owner = i_prof.id
        THEN
            -- this is the professional that has the alert event, remove the alert (he has already seen this detail)
            g_error  := 'Call pk_alerts.delete_sys_alert_event / i_id_sys_alert=' ||
                        pk_ref_constant.g_sa_handoff_declined || ' i_id_record=' || i_id_ref;
            g_retval := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_sys_alert => pk_ref_constant.g_sa_handoff_declined,
                                                         i_id_record    => i_id_ref,
                                                         o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_ref_det);
            pk_types.open_my_cursor(o_tr_orig_det);
            pk_types.open_my_cursor(o_tr_dest_det);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref_det);
            pk_types.open_my_cursor(o_tr_orig_det);
            pk_types.open_my_cursor(o_tr_dest_det);
            RETURN FALSE;
    END get_detail;

    /**
    * Gets hand off historic data
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_hist_data     Hand off historic data
    * @param   o_hist_data     Hand off historic detail data
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   05-06-2013
    */
    FUNCTION get_detail_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN ref_trans_responsibility.id_external_request%TYPE,
        o_hist_data     OUT pk_types.cursor_type,
        o_hist_data_det OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params    VARCHAR2(1000 CHAR);
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
    
        --l_tr_hist_tab  pk_ref_trans_resp_hist.ref_trans_resp_hist_tc;
        --l_tr_hist_crit table_table_number;
    
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    BEGIN
        l_params := 'i_id_ref=' || i_id_ref;
        g_error  := 'Init get_detail_hist / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' WF=' || l_ref_row.id_workflow || ' FLG_STATUS=' || l_ref_row.flg_status || ' DCS=' ||
                    l_ref_row.id_dep_clin_serv;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting sys_messages
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_ref_transfresp_t002,
                                        pk_ref_constant.g_sm_ref_transfresp_t016,
                                        pk_ref_constant.g_sm_ref_transfresp_t017,
                                        pk_ref_constant.g_sm_ref_transfresp_t021,
                                        pk_ref_constant.g_sm_ref_transfresp_t023,
                                        pk_ref_constant.g_sm_ref_transfresp_t071,
                                        pk_ref_constant.g_sm_ref_transfresp_t068,
                                        pk_ref_constant.g_sm_ref_transfresp_t069);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / l_code_msg_arr.COUNT=' || l_code_msg_arr.count || ' / ' ||
                    l_params;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ID_CAT=' || l_prof_data.id_category || ' ID_PROF_TEMPL=' ||
                    l_prof_data.id_profile_template || ' ID_FUNC=' || l_prof_data.id_functionality;
    
        g_error := 'OPEN o_hist_data FOR / ' || l_params;
        OPEN o_hist_data FOR
            SELECT CASE t.id_status
                       WHEN pk_workflow.get_status_begin(t.id_workflow) THEN
                        l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t068)
                       ELSE
                        l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t071)
                   END label, -- hand_off_to
                   t.id_trans_resp_hist,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_tr, i_prof) dt_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_status
              FROM (SELECT rh.id_trans_resp_hist,
                           rh.id_status,
                           rh.id_workflow,
                           nvl(rh.dt_update, rh.dt_created) dt_tr,
                           rh.id_professional
                      FROM ref_trans_resp_hist rh
                     WHERE rh.id_external_request = i_id_ref
                       AND rh.flg_active = pk_ref_constant.g_yes) t
             ORDER BY dt_tr DESC;
    
        g_error := 'OPEN o_hist_data FOR / ' || l_params;
        OPEN o_hist_data_det FOR
            SELECT rank, id_trans_resp_hist, title, text
              FROM (
                    -- Transferir para
                    SELECT 10 rank,
                            t.id_trans_resp_hist,
                            l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t002) title,
                            CASE t.id_workflow
                                WHEN pk_ref_constant.g_wf_transfresp THEN
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest)
                                WHEN pk_ref_constant.g_wf_transfresp_inst THEN
                                 pk_translation.get_translation(i_lang      => i_lang,
                                                                i_code_mess => pk_ref_constant.g_institution_code ||
                                                                               t.id_inst_dest_tr)
                            END text
                      FROM (SELECT rh.id_trans_resp_hist, rh.id_workflow, rh.id_prof_dest, rh.id_inst_dest_tr
                               FROM ref_trans_resp_hist rh
                              WHERE rh.id_external_request = i_id_ref
                                AND rh.flg_active = pk_ref_constant.g_yes
                                AND rh.id_status = pk_workflow.get_status_begin(i_id_workflow => rh.id_workflow)) t
                    UNION ALL
                    -- Motivo do pedido
                    SELECT 20 rank,
                            t.id_trans_resp_hist,
                            l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t021) title,
                            nvl(t.reason_code_text,
                                pk_translation.get_translation(i_lang, pk_ref_constant.g_p1_reason_code || t.id_reason_code)) text
                      FROM (SELECT rh.id_trans_resp_hist, rh.reason_code_text, rh.id_prof_dest, rh.id_reason_code
                               FROM ref_trans_resp_hist rh
                              WHERE rh.id_external_request = i_id_ref
                                AND rh.flg_active = pk_ref_constant.g_yes
                                AND (reason_code_text IS NOT NULL OR id_reason_code IS NOT NULL)) t
                    UNION ALL
                    -- Analise do pedido
                    SELECT 30 rank,
                            t.id_trans_resp_hist,
                            l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t069) title,
                            pk_translation.get_translation(i_lang,
                                                           pk_ref_constant.g_workflow_action_code || t.id_workflow_action) text
                      FROM (SELECT rh.id_trans_resp_hist, rh.id_workflow_action
                               FROM ref_trans_resp_hist rh
                              WHERE rh.id_external_request = i_id_ref
                                AND rh.flg_active = pk_ref_constant.g_yes) t
                     WHERE pk_translation.get_translation(i_lang,
                                                          pk_ref_constant.g_workflow_action_code || t.id_workflow_action) IS NOT NULL
                    UNION ALL
                    -- Estado
                    SELECT 35 rank,
                            t.id_trans_resp_hist,
                            l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t016) title,
                            pk_workflow.get_status_desc(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_workflow         => t.id_workflow,
                                                        i_id_status           => t.id_status,
                                                        i_id_category         => l_prof_data.id_category,
                                                        i_id_profile_template => l_prof_data.id_profile_template,
                                                        i_id_functionality    => l_prof_data.id_functionality,
                                                        i_param               => pk_ref_tr_status.init_tr_param_tab(i_lang                 => i_lang,
                                                                                                                    i_prof                 => i_prof,
                                                                                                                    i_id_trans_resp        => t.id_trans_resp,
                                                                                                                    i_id_ref               => t.id_external_request,
                                                                                                                    i_id_prof_transf_owner => t.id_prof_transf_owner,
                                                                                                                    i_id_tr_prof_dest      => t.id_prof_dest,
                                                                                                                    i_id_tr_inst_orig      => t.id_inst_orig_tr,
                                                                                                                    i_id_tr_inst_dest      => t.id_inst_dest_tr,
                                                                                                                    i_user_answer          => NULL)) text
                      FROM (SELECT rh.id_trans_resp_hist,
                                    rh.id_status,
                                    rh.id_workflow,
                                    rh.id_trans_resp,
                                    rh.id_external_request,
                                    rh.id_prof_transf_owner,
                                    rh.id_prof_dest,
                                    rh.id_inst_orig_tr,
                                    rh.id_inst_dest_tr
                               FROM ref_trans_resp_hist rh
                              WHERE rh.id_external_request = i_id_ref
                                AND rh.flg_active = pk_ref_constant.g_yes) t
                    UNION ALL
                    -- Profissional de destino
                    SELECT 40 rank,
                            t.id_trans_resp_hist,
                            l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t017) title,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest) text
                      FROM (SELECT rh.id_trans_resp_hist, rh.id_prof_dest
                               FROM ref_trans_resp_hist rh
                              WHERE rh.id_external_request = i_id_ref
                                AND rh.flg_active = pk_ref_constant.g_yes
                                AND rh.id_prof_dest IS NOT NULL) t
                    UNION ALL
                    -- Notas
                    SELECT 90 rank,
                            t.id_trans_resp_hist,
                            l_desc_message_ibt(pk_ref_constant.g_sm_ref_transfresp_t023) title,
                            t.notes text
                      FROM (SELECT rh.id_trans_resp_hist, rh.notes
                               FROM ref_trans_resp_hist rh
                              WHERE rh.id_external_request = i_id_ref
                                AND rh.flg_active = pk_ref_constant.g_yes
                                AND notes IS NOT NULL) t)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_hist_data);
            pk_types.open_my_cursor(o_hist_data_det);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DETAIL_HIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist_data);
            pk_types.open_my_cursor(o_hist_data_det);
            RETURN FALSE;
    END get_detail_hist;

    /**
    * Returns the domain of hand off status filtered by id_market
    * Used by id_criteria=217
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    *
    * @RETURN  Return table (t_coll_wf_status_info_def) pipelined
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-01-2013
    */
    FUNCTION get_search_tr_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_wf_status_info_def
        PIPELINED IS
    
        l_error            t_error_out;
        l_prof_data        t_rec_prof_data;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_functionality    sys_functionality.id_functionality%TYPE;
        l_category         category.id_category%TYPE;
        l_rec              t_rec_wf_status_info_def;
    
        CURSOR c_tr_status IS
            SELECT DISTINCT pk_translation.get_translation(i_lang, s.code_status) desc_status,
                            sc.id_status,
                            sc.icon,
                            sc.color,
                            sc.rank,
                            s.code_status
              FROM wf_status s
              JOIN wf_status_config sc
                ON (sc.id_status = s.id_status)
             WHERE sc.id_workflow IN (pk_ref_constant.g_wf_transfresp, pk_ref_constant.g_wf_transfresp_inst)
               AND s.flg_available = pk_ref_constant.g_yes
               AND sc.id_software IN (i_prof.software, 0)
               AND sc.id_institution IN (i_prof.institution, 0)
               AND sc.id_profile_template IN (l_profile_template, 0)
               AND sc.id_functionality IN (l_functionality, 0)
               AND sc.id_category IN (l_category, 0)
             ORDER BY 1;
    BEGIN
        g_error  := 'Init get_search_tr_status';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        l_profile_template := nvl(l_prof_data.id_profile_template, 0);
        l_functionality    := nvl(l_prof_data.id_functionality, 0);
        l_category         := nvl(l_prof_data.id_category, 0);
    
        FOR l_row IN c_tr_status
        LOOP
        
            g_error           := 't_rec_wf_status_info_def()';
            l_rec             := t_rec_wf_status_info_def();
            l_rec.id_status   := l_row.id_status;
            l_rec.desc_status := l_row.desc_status;
            l_rec.icon        := l_row.icon;
            l_rec.color       := l_row.color;
            l_rec.rank        := l_row.rank;
            l_rec.code_status := l_row.code_status;
        
            PIPE ROW(l_rec);
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN;
    END get_search_tr_status;

    /**
    * Returns the list of transitions available from the action previously selected
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_id_workflow           Workflow identifier
    * @param   i_id_status             Actual status identifier
    * @param   o_options               Options available
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_tr_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_status   IN ref_trans_responsibility.id_status%TYPE,
        o_options     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow || ' i_id_status=' ||
                    i_id_status;
        g_error  := 'Init get_tr_options / ' || l_params;
    
        ----------------------
        -- FUNC
        ----------------------
        OPEN o_options FOR
            SELECT pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => t.action_code) action_desc,
                   t.action_value
              FROM (SELECT pk_ref_constant.g_sm_ref_transfresp_t072 action_code, pk_ref_constant.g_yes action_value
                      FROM dual -- Accept
                    UNION ALL
                    SELECT pk_ref_constant.g_sm_ref_transfresp_t073 action_code, pk_ref_constant.g_no action_value
                      FROM dual -- Decline (Rejeitar)
                     WHERE (i_id_workflow = pk_ref_constant.g_wf_transfresp_inst AND
                           i_id_status IN
                           (pk_ref_constant.g_tr_status_inst_app, pk_ref_constant.g_tr_status_declined_inst))
                        OR (i_id_workflow = pk_ref_constant.g_wf_transfresp AND
                           i_id_status = pk_ref_constant.g_tr_status_pend_app)
                    UNION ALL
                    SELECT pk_ref_constant.g_sm_ref_transfresp_t075 action_code, pk_ref_constant.g_no action_value
                      FROM dual -- Return (Devolver)
                     WHERE i_id_workflow = pk_ref_constant.g_wf_transfresp_inst
                       AND i_id_status = pk_ref_constant.g_tr_status_pend_app) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TR_OPTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_tr_options;

    /**
    * Get the description of hand off workflow status
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   o_status_desc    Workflow status description
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2013
    */
    FUNCTION get_handoff_status_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_status_desc OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
        g_error  := 'Init get_handoff_status_desc / ' || l_params;
    
        OPEN o_status_desc FOR
            SELECT DISTINCT pk_translation.get_translation(i_lang, t.code_status) status_desc,
                            t.id_status,
                            t.icon,
                            t.rank
              FROM (SELECT wss.id_status, wss.icon, wss.rank, wss.code_status
                      FROM wf_status_workflow wsw
                      JOIN wf_status wss
                        ON wss.id_status = wsw.id_status
                     WHERE wsw.flg_available = pk_alert_constant.g_yes
                       AND wss.flg_available = pk_alert_constant.g_yes
                       AND wsw.id_workflow IN (pk_ref_constant.g_wf_transfresp, pk_ref_constant.g_wf_transfresp_inst)
                       AND wsw.id_status != pk_ref_constant.g_tr_status_declined_inst -- referral hand off must not be created when there is an existing hand off in this state
                    ) t
             ORDER BY 1;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_status_desc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HANDOFF_STATUS_DESC',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_status_desc);
            RETURN FALSE;
    END get_handoff_status_desc;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);

END pk_ref_change_resp;
/
