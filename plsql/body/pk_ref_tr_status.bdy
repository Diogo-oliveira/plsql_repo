/*-- Last Change Revision: $Rev: 1714849 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2015-11-06 14:39:15 +0000 (sex, 06 nov 2015) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_tr_status IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    --g_sysdate_tstz TIMESTAMP(6)  WITH LOCAL TIME ZONE;
    g_retval BOOLEAN;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    /**
    * Initializes table_varchar as input of workflow transition function
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids        
    * @param   i_id_trans_resp           Hand off identifier
    * @param   i_id_ref                  Referral identifier
    * @param   i_id_prof_transf_owner    Hand off owner
    * @param   i_id_tr_prof_dest         Professional to which the referral was forward (hand off dest professional)
    * @param   i_id_tr_inst_orig         Hand off origin institution identifier
    * @param   i_id_tr_inst_dest         Hand off dest institution identifier
    *
    * @RETURN  table_varchar as input of workflow transition function
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-05-2013   
    */
    FUNCTION init_tr_param_tab
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_trans_resp        IN ref_trans_responsibility.id_trans_resp%TYPE,
        i_id_ref               IN p1_external_request.id_external_request%TYPE,
        i_id_prof_transf_owner IN ref_trans_responsibility.id_prof_transf_owner%TYPE,
        i_id_tr_prof_dest      IN ref_trans_responsibility.id_prof_dest%TYPE,
        i_id_tr_inst_orig      IN ref_trans_responsibility.id_inst_orig_tr%TYPE,
        i_id_tr_inst_dest      IN ref_trans_responsibility.id_inst_dest_tr%TYPE,
        i_user_answer          IN VARCHAR2
    ) RETURN table_varchar IS
        l_result table_varchar;
    BEGIN
        l_result := table_varchar();
        l_result.extend(7);
    
        l_result(pk_ref_constant.g_idx_tr_id_tr) := i_id_trans_resp;
        l_result(pk_ref_constant.g_idx_tr_id_ref) := i_id_ref;
        l_result(pk_ref_constant.g_idx_tr_id_prof_owner) := i_id_prof_transf_owner;
        l_result(pk_ref_constant.g_idx_tr_id_prof_dest) := i_id_tr_prof_dest;
        l_result(pk_ref_constant.g_idx_tr_id_inst_orig) := i_id_tr_inst_orig;
        l_result(pk_ref_constant.g_idx_tr_id_inst_dest) := i_id_tr_inst_dest;
        l_result(pk_ref_constant.g_idx_tr_user_answ) := i_user_answer;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END init_tr_param_tab;

    /**
    * Gets parameter values of framework workflow into separate variables
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_param                   Referral information
    * @param   o_id_ref                  Referral identifier
    * @param   o_id_prof_transf_owner    Hand off owner
    * @param   o_id_tr_prof_dest         Professional to which the referral was forward (hand off dest professional)
    * @param   o_id_tr_inst_orig         New origin institution identifier    
    * @param   o_error                   An error message, set when return=false
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-05-2013
    */
    FUNCTION get_tr_param_values
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_param                IN table_varchar,
        o_id_trans_resp        OUT ref_trans_responsibility.id_trans_resp%TYPE,
        o_id_ref               OUT p1_external_request.id_external_request%TYPE,
        o_id_prof_transf_owner OUT ref_trans_responsibility.id_prof_transf_owner%TYPE,
        o_id_tr_prof_dest      OUT ref_trans_responsibility.id_prof_dest%TYPE,
        o_id_tr_inst_orig      OUT ref_trans_responsibility.id_inst_orig_tr%TYPE,
        o_id_tr_inst_dest      OUT ref_trans_responsibility.id_inst_dest_tr%TYPE,
        o_user_answ            OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_tr_param_values / i_param=' || pk_utils.to_string(i_param);
    
        -- getting values from i_param
        IF i_param.exists(pk_ref_constant.g_idx_tr_id_tr)
        THEN
            -- id_trans_resp
            o_id_trans_resp := to_number(i_param(pk_ref_constant.g_idx_tr_id_tr));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_tr_id_ref)
        THEN
            -- id_external_request
            o_id_ref := to_number(i_param(pk_ref_constant.g_idx_tr_id_ref));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_tr_id_prof_owner)
        THEN
            -- id_prof_transf_owner
            o_id_prof_transf_owner := to_number(i_param(pk_ref_constant.g_idx_tr_id_prof_owner));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_tr_id_prof_dest)
        THEN
            -- id_prof_dest
            o_id_tr_prof_dest := to_number(i_param(pk_ref_constant.g_idx_tr_id_prof_dest));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_tr_id_inst_orig)
        THEN
            -- id_inst_orig_tr
            o_id_tr_inst_orig := to_number(i_param(pk_ref_constant.g_idx_tr_id_inst_orig));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_tr_id_inst_dest)
        THEN
            -- id_inst_dest_tr
            o_id_tr_inst_dest := to_number(i_param(pk_ref_constant.g_idx_tr_id_inst_dest));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_tr_user_answ)
        THEN
            -- user_answ
            o_user_answ := i_param(pk_ref_constant.g_idx_tr_user_answ);
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
                                              i_function => 'GET_TR_PARAM_VALUES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_tr_param_values;

    /**
    * Checks if the professional can accept referral hand off (from another institution)
    * Function used in table wf_transition_config
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_workflow          Workflow identifier
    * @param   i_status_begin      Status begin identifier
    * @param   i_status_end        Status end identifier
    * @param   i_workflow_action   Workflow action identifier
    * @param   i_category          Category identifier
    * @param   i_profile           Profile identifier
    * @param   i_func              Professional functionality identifier
    * @param   i_param             Array of parameters
    *
    * @return  Y- can be accepted, N- otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_handoff_resp_accept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_responsible          VARCHAR2(1 CHAR);
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
        l_params               VARCHAR2(1000 CHAR);
    BEGIN
        -- check sys_functionality of hand off approval in the institution
        l_params := 'WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end || ' ACTION=' ||
                    i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' || i_func ||
                    ' PARAM=' || pk_utils.to_string(i_param);
        g_error  := 'Init check_handoff_resp_accept / ' || l_params;
    
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_tr_inst_dest != i_prof.institution
        THEN
            -- must be in the institution
            g_error := 'Professional ' || i_prof.id || ' must be in the institution ' || l_id_tr_inst_dest || ' / ' ||
                       l_params;
            RAISE g_exception;
        END IF;
    
        l_responsible := pk_ref_change_resp.check_func_handoff_app(i_prof => i_prof);
    
        IF l_responsible = pk_ref_constant.g_yes
           AND l_user_answ = pk_ref_constant.g_yes
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_transition_deny;
    END check_handoff_resp_accept;

    /**
    * Checks if the professional can reject referral hand off (from another institution)
    * Function used in table wf_transition_config
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_workflow          Workflow identifier
    * @param   i_status_begin      Status begin identifier
    * @param   i_status_end        Status end identifier
    * @param   i_workflow_action   Workflow action identifier
    * @param   i_category          Category identifier
    * @param   i_profile           Profile identifier
    * @param   i_func              Professional functionality identifier
    * @param   i_param             Array of parameters
    *
    * @return  Y- can be rejected, N- otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_handoff_resp_reject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_responsible          VARCHAR2(1 CHAR);
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
        l_params               VARCHAR2(1000 CHAR);
    BEGIN
        -- check sys_functionality of hand off approval in the institution
        l_params := 'WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end || ' ACTION=' ||
                    i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' || i_func ||
                    ' PARAM=' || pk_utils.to_string(i_param);
        g_error  := 'Init check_handoff_resp_accept / ' || l_params;
    
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_tr_inst_dest != i_prof.institution
        THEN
            -- must be in the institution
            g_error := 'Professional ' || i_prof.id || ' must be in the institution ' || l_id_tr_inst_dest || ' / ' ||
                       l_params;
            RAISE g_exception;
        END IF;
    
        l_responsible := pk_ref_change_resp.check_func_handoff_app(i_prof => i_prof);
    
        IF l_responsible = pk_ref_constant.g_yes
           AND l_user_answ = pk_ref_constant.g_no
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_transition_deny;
    END check_handoff_resp_reject;

    /**
    * Checks if the professional can cancel hand off
    * Function used in table wf_transition_config
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_workflow          Workflow identifier
    * @param   i_status_begin      Status begin identifier
    * @param   i_status_end        Status end identifier
    * @param   i_workflow_action   Workflow action identifier
    * @param   i_category          Category identifier
    * @param   i_profile           Profile identifier
    * @param   i_func              Professional functionality identifier
    * @param   i_param             Array of parameters
    *
    * @return  Y- can be cancelled, N- otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-05-2013
    */
    FUNCTION check_can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
    BEGIN
    
        g_error  := 'Init check_can_cancel / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                    ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                    i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_prof.id = l_id_prof_transf_owner
           AND l_user_answ = 'C' -- flash answer
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_cancel;

    /**
    * Checks if the professional can accept the referral hand off
    * Function used in table wf_transition_config
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_workflow          Workflow identifier
    * @param   i_status_begin      Status begin identifier
    * @param   i_status_end        Status end identifier
    * @param   i_workflow_action   Workflow action identifier
    * @param   i_category          Category identifier
    * @param   i_profile           Profile identifier
    * @param   i_func              Professional functionality identifier
    * @param   i_param             Array of parameters
    *
    * @return  Y- can be accepted, N- otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_can_accept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
    BEGIN
    
        g_error  := 'Init check_can_accept / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                    ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                    i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_prof.id = l_id_tr_prof_dest
           AND l_user_answ = pk_ref_constant.g_yes -- flash answer 
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_accept;

    /**
    * Checks if the professional can reject the referral hand off
    * Function used in table wf_transition_config
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_workflow          Workflow identifier
    * @param   i_status_begin      Status begin identifier
    * @param   i_status_end        Status end identifier
    * @param   i_workflow_action   Workflow action identifier
    * @param   i_category          Category identifier
    * @param   i_profile           Profile identifier
    * @param   i_func              Professional functionality identifier
    * @param   i_param             Array of parameters
    *
    * @return  Y- can be denied, N- otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_can_reject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
    BEGIN
    
        g_error  := 'Init check_can_deny / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                    ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                    i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_prof.id = l_id_tr_prof_dest
           AND l_user_answ = pk_ref_constant.g_no -- flash answer 
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_reject;

    /**
    * Checks if the professional is dest professional of the hand off
    * Function used in table wf_transition_config
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_workflow          Workflow identifier
    * @param   i_status_begin      Status begin identifier
    * @param   i_status_end        Status end identifier
    * @param   i_workflow_action   Workflow action identifier
    * @param   i_category          Category identifier
    * @param   i_profile           Profile identifier
    * @param   i_func              Professional functionality identifier
    * @param   i_param             Array of parameters
    *
    * @return  Y- can be cancelled, N- otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-05-2013
    *
    FUNCTION check_is_prof_dest
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
    BEGIN
    
        g_error  := 'Init check_is_prof_dest / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                    i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_prof.id = l_id_tr_prof_dest
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_ref_constant.g_transition_deny;
    END check_is_prof_dest;
    
    /**
    * Changes hand off status. This is a base function. 
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_prof_data               Profile_template, functionality, and category ids   
    * @param   i_id_trans_resp           Hand off identifier
    * @param   i_id_external_request     Referral that is being hand off
    * @param   i_id_workflow             Hand off workflow identifier
    * @param   i_id_status_begin         Hand off status begin identifier
    * @param   i_id_status_end           Hand off status end identifier
    * @param   i_id_workflow_action      Workflow action identifier                    
    * @param   i_notes                   Status change notes
    * @param   i_id_reason_code          Status change reason code identifier
    * @param   i_reason_code_text        Status change reason code text
    * @param   i_id_prof_dest            Dest professional of the hand off
    * @param   i_id_inst_orig_tr         Hand off origin institution identifier
    * @param   i_id_inst_dest_tr         Hand off dest institution identifier
    * @param   i_op_date                 Status change date
    * @param   io_param                  Parameters for framework workflows evaluation
    * @param   o_id_trans_resp_hist      Identifier of the first transition
    * @param   o_error                   An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-05-2013
    */
    FUNCTION set_tr_base
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_data           IN t_rec_prof_data,
        i_id_trans_resp       IN ref_trans_responsibility.id_trans_resp%TYPE,
        i_id_external_request IN ref_trans_responsibility.id_external_request%TYPE,
        i_id_workflow         IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_status_begin     IN ref_trans_responsibility.id_status%TYPE,
        i_id_status_end       IN ref_trans_responsibility.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_notes               IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        i_notes_nin           IN BOOLEAN := TRUE,
        i_id_reason_code      IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        i_reason_code_text    IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        i_id_prof_dest        IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        i_id_prof_dest_nin    IN BOOLEAN := TRUE,
        i_id_inst_orig_tr     IN ref_trans_responsibility.id_inst_orig_tr%TYPE DEFAULT NULL,
        i_id_inst_dest_tr     IN ref_trans_responsibility.id_inst_dest_tr%TYPE DEFAULT NULL,
        i_op_date             IN ref_trans_responsibility.update_time%TYPE DEFAULT NULL,
        io_param              IN OUT NOCOPY table_varchar,
        o_id_trans_resp_hist  OUT ref_trans_resp_hist.id_trans_resp_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        --l_op_date       ref_trans_responsibility.update_time%TYPE;
        l_flg_available VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'Init set_tr_base / I_PROF=' || pk_utils.to_string(i_prof) || ' PROF_PRF_TEMPL=' ||
                    i_prof_data.id_profile_template || ' CAT=' || i_prof_data.id_category || ' FUNC=' ||
                    i_prof_data.id_functionality || ' ID_REF=' || i_id_external_request || ' ID_TRANS_RESP=' ||
                    i_id_trans_resp || ' ID_STATUS=' || i_id_status_begin || ' WF=' || i_id_workflow ||
                    ' i_id_status_end=' || i_id_status_end || ' i_id_workflow_action=' || i_id_workflow_action ||
                    ' i_id_reason_code=' || i_id_reason_code || ' i_id_prof_dest=' || i_id_prof_dest ||
                    ' i_id_inst_orig_tr=' || i_id_inst_orig_tr || ' i_id_inst_dest_tr=' || i_id_inst_dest_tr;
        g_error  := 'Init set_tr_base / ' || l_params;
        --l_op_date := nvl(i_op_date, current_timestamp);
    
        -- checking transition availability
        g_error  := 'Calling pk_workflow.check_transition / ' || l_params;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => i_id_workflow,
                                                 i_id_status_begin     => i_id_status_begin,
                                                 i_id_status_end       => i_id_status_end,
                                                 i_id_workflow_action  => i_id_workflow_action,
                                                 i_id_category         => i_prof_data.id_category,
                                                 i_id_profile_template => i_prof_data.id_profile_template,
                                                 i_id_functionality    => i_prof_data.id_functionality,
                                                 i_param               => io_param,
                                                 o_flg_available       => l_flg_available,
                                                 o_error               => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            -- returns error, no transition available
            g_error      := 'No transition valid for action ' || i_id_workflow_action || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'Call pk_ref_trans_responsibility.upd / ' || l_params;
        pk_ref_trans_responsibility.upd(id_trans_resp_in       => i_id_trans_resp,
                                        id_status_in           => i_id_status_end,
                                        id_workflow_in         => i_id_workflow,
                                        id_external_request_in => i_id_external_request,
                                        id_reason_code_in      => i_id_reason_code,
                                        reason_code_text_in    => i_reason_code_text,
                                        notes_in               => i_notes,
                                        notes_nin              => i_notes_nin,
                                        id_prof_dest_in        => i_id_prof_dest,
                                        id_prof_dest_nin       => i_id_prof_dest_nin,
                                        id_professional_in     => i_prof.id,
                                        id_institution_in      => i_prof.institution,
                                        id_workflow_action_in  => i_id_workflow_action);
    
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
                                              i_function    => 'SET_TR_BASE',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_tr_base;

    /**
    * Process hand off status change 
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_prof_data           Profile_template, functionality, and category ids   
    * @param   i_id_trans_resp       Hand off identifier
    * @param   i_id_external_request Referral that is being hand off
    * @param   i_id_workflow         Hand off workflow identifier
    * @param   i_id_status_begin     Hand off status begin identifier
    * @param   i_id_status_end       Hand off status end identifier
    * @param   i_id_workflow_action  Workflow action identifier
    * @param   i_date                Status change date
    * @param   i_notes               Status change notes
    * @param   i_id_reason_code      Status change reason code identifier
    * @param   i_reason_code_text    Status change reason code text
    * @param   i_id_prof_dest        Dest professional of the hand off
    * @param   io_param              Parameters for framework workflows evaluation
    * @param   o_id_trans_resp_hist  Identifier of the first transition
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-05-2013
    */
    FUNCTION process_tr_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_data           IN t_rec_prof_data,
        i_id_trans_resp       IN ref_trans_responsibility.id_trans_resp%TYPE,
        i_id_external_request IN ref_trans_responsibility.id_external_request%TYPE,
        i_id_workflow         IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_status_begin     IN ref_trans_responsibility.id_status%TYPE,
        i_id_status_end       IN ref_trans_responsibility.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_notes               IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        i_id_reason_code      IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        i_reason_code_text    IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        i_id_prof_dest        IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        io_param              IN OUT NOCOPY table_varchar,
        o_id_trans_resp_hist  OUT ref_trans_resp_hist.id_trans_resp_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date   ref_trans_responsibility.dt_update%TYPE;
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_trans_resp=' || i_id_trans_resp ||
                    ' i_id_status_begin=' || i_id_status_begin || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_external_request=' || i_id_external_request || ' i_id_prof_dest=' || i_id_prof_dest ||
                    ' i_id_reason_code=' || i_id_reason_code || ' i_id_status_end=' || i_id_status_end ||
                    ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_reason_code=' || i_id_reason_code ||
                    ' i_id_prof_dest=' || i_id_prof_dest || ' io_param=' || pk_utils.to_string(io_param);
    
        g_error := 'Init set_tr_status / ' || l_params;
        pk_alertlog.log_debug(g_error);
        l_date := nvl(i_date, pk_ref_utils.get_sysdate);
    
        CASE i_id_workflow_action
            WHEN pk_ref_constant.g_ref_tr_approved THEN
            
                g_error  := 'Calling set_tr_base / ' || l_params;
                g_retval := set_tr_base(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_prof_data           => i_prof_data,
                                        i_id_trans_resp       => i_id_trans_resp,
                                        i_id_external_request => i_id_external_request,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_status_end       => i_id_status_end,
                                        i_id_workflow_action  => i_id_workflow_action,
                                        i_notes               => i_notes,
                                        i_notes_nin           => FALSE, -- sets notes to NULL if i_notes is null
                                        i_op_date             => l_date,
                                        io_param              => io_param,
                                        o_id_trans_resp_hist  => o_id_trans_resp_hist,
                                        o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            WHEN pk_ref_constant.g_ref_tr_rejected THEN
            
                g_error  := 'Calling set_tr_base / ' || l_params;
                g_retval := set_tr_base(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_prof_data           => i_prof_data,
                                        i_id_trans_resp       => i_id_trans_resp,
                                        i_id_external_request => i_id_external_request,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_status_end       => i_id_status_end,
                                        i_id_workflow_action  => i_id_workflow_action,
                                        i_notes               => i_notes,
                                        i_notes_nin           => FALSE, -- sets notes to NULL if i_notes is null
                                        i_op_date             => l_date,
                                        io_param              => io_param,
                                        o_id_trans_resp_hist  => o_id_trans_resp_hist,
                                        o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            WHEN pk_ref_constant.g_ref_tr_cancelled THEN
                -- 33
            
                g_error  := 'Calling set_tr_base / ' || l_params;
                g_retval := set_tr_base(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_prof_data           => i_prof_data,
                                        i_id_trans_resp       => i_id_trans_resp,
                                        i_id_external_request => i_id_external_request,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_status_end       => i_id_status_end,
                                        i_id_workflow_action  => i_id_workflow_action,
                                        i_op_date             => l_date,
                                        i_notes               => NULL,
                                        i_notes_nin           => FALSE, -- there is no notes to be set, cleans the previous one
                                        io_param              => io_param,
                                        o_id_trans_resp_hist  => o_id_trans_resp_hist,
                                        o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            WHEN pk_ref_constant.g_ref_tr_declined THEN
                -- 39
            
                g_error  := 'Calling set_tr_base / ' || l_params;
                g_retval := set_tr_base(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_prof_data           => i_prof_data,
                                        i_id_trans_resp       => i_id_trans_resp,
                                        i_id_external_request => i_id_external_request,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_status_end       => i_id_status_end,
                                        i_id_workflow_action  => i_id_workflow_action,
                                        i_id_prof_dest        => NULL, -- removes the previous value
                                        i_id_prof_dest_nin    => FALSE, -- sets id_prof_dest to NULL
                                        i_notes               => i_notes,
                                        i_notes_nin           => FALSE, -- sets notes to NULL if i_notes is null
                                        i_op_date             => l_date,
                                        io_param              => io_param,
                                        o_id_trans_resp_hist  => o_id_trans_resp_hist,
                                        o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            WHEN pk_ref_constant.g_ref_tr_approved_inst THEN
            
                IF i_id_prof_dest IS NULL
                THEN
                    g_error      := 'Dest professional is null / ' || l_params;
                    g_error_code := pk_ref_constant.g_ref_error_1005;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                g_error  := 'Calling set_tr_base / ' || l_params;
                g_retval := set_tr_base(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_prof_data           => i_prof_data,
                                        i_id_trans_resp       => i_id_trans_resp,
                                        i_id_external_request => i_id_external_request,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_status_end       => i_id_status_end,
                                        i_id_workflow_action  => i_id_workflow_action,
                                        i_id_prof_dest        => i_id_prof_dest,
                                        i_notes               => i_notes,
                                        i_notes_nin           => FALSE, -- sets notes to NULL if i_notes is null
                                        i_op_date             => l_date,
                                        io_param              => io_param,
                                        o_id_trans_resp_hist  => o_id_trans_resp_hist,
                                        o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
        END CASE;
    
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
                                              i_function    => 'PROCESS_TR_TRANSITION',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END process_tr_transition;

    /**
    * Process hand off alerts related to the transition
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_prof_data           Profile_template, functionality, and category ids   
    * @param   i_id_external_request Referral that is being hand off
    * @param   i_id_patient          Patient identifier
    * @param   i_id_dep_clin_serv    Dep_clin_serv identifier
    * @param   i_id_episode          Episode identifier   
    * @param   i_id_inst_orig_tr     Referral hand off origin institution
    * @param   i_id_workflow         Hand off workflow identifier
    * @param   i_id_status_begin     Hand off status begin identifier
    * @param   i_id_status_end       Hand off status end identifier
    * @param   i_id_workflow_action  Workflow action identifier
    * @param   i_date                Status change date
    * @param   io_param              Parameters for framework workflows evaluation
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2013
    */
    FUNCTION process_tr_transition_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_data           IN t_rec_prof_data,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_id_patient          IN p1_external_request.id_patient%TYPE,
        i_id_dep_clin_serv    IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_episode          IN p1_external_request.id_episode%TYPE,
        i_id_inst_orig_tr     IN ref_trans_responsibility.id_inst_orig_tr%TYPE,
        i_id_workflow         IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_status_begin     IN ref_trans_responsibility.id_status%TYPE,
        i_id_status_end       IN ref_trans_responsibility.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        io_param              IN OUT NOCOPY table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date            ref_trans_responsibility.dt_update%TYPE;
        l_params          VARCHAR2(1000 CHAR);
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_replace1        sys_alert_event.replace1%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_prof_data=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin ||
                    ' i_id_inst_orig_tr=' || i_id_inst_orig_tr || ' i_id_status_end=' || i_id_status_end ||
                    ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_external_request=' ||
                    i_id_external_request || ' i_id_patient=' || i_id_patient || ' i_id_dep_clin_serv=' ||
                    i_id_dep_clin_serv || ' i_id_episode=' || i_id_episode || ' io_param=' ||
                    pk_utils.to_string(io_param);
    
        g_error := 'Init set_tr_status / ' || l_params;
        pk_alertlog.log_debug(g_error);
        l_date := nvl(i_date, pk_ref_utils.get_sysdate);
    
        -- todo: API para fazer get dos alertas associados a esta transicao
    
        -- remove alerts
        IF i_id_status_end != pk_ref_constant.g_tr_status_declined
        THEN
            l_sys_alert_event.id_sys_alert := pk_ref_constant.g_sa_handoff_declined; -- todo: substituir pela configuracao da tabela de alertas
        
            g_retval := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_sys_alert => l_sys_alert_event.id_sys_alert,
                                                         i_id_record    => i_id_external_request,
                                                         o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- add alerts       
        IF i_id_status_end = pk_ref_constant.g_tr_status_declined
        THEN
        
            -- todo: substituir pela configuracao da tabela de alertas
            l_replace1                     := '@SM[' || pk_ref_constant.g_sm_ref_transfresp_t051 || ']: @TR[' ||
                                              pk_ref_constant.g_workflow_status_code || i_id_status_end || ']';
            l_replace1                     := l_replace1 || chr(10) || '@SM[' ||
                                              pk_ref_constant.g_sm_ref_transfresp_t013 || ']: ' ||
                                              i_id_external_request;
            l_sys_alert_event.id_sys_alert := pk_ref_constant.g_sa_handoff_declined;
            -- todo: substituir pela configuracao da tabela de alertas
        
            l_sys_alert_event.id_software      := i_prof.software;
            l_sys_alert_event.id_institution   := i_id_inst_orig_tr; -- institution where the alert will be visible
            l_sys_alert_event.id_patient       := i_id_patient;
            l_sys_alert_event.id_record        := i_id_external_request;
            l_sys_alert_event.dt_record        := l_date;
            l_sys_alert_event.id_professional  := i_prof.id;
            l_sys_alert_event.id_dep_clin_serv := i_id_dep_clin_serv;
            l_sys_alert_event.id_episode       := nvl(i_id_episode, -1);
            l_sys_alert_event.id_visit         := pk_episode.get_id_visit(l_sys_alert_event.id_episode);
            l_sys_alert_event.flg_visible      := pk_ref_constant.g_yes;
            l_sys_alert_event.replace1         := l_replace1;
        
            g_retval := pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_sys_alert_event => l_sys_alert_event,
                                                         o_error           => o_error);
        
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
                                              i_function    => 'PROCESS_TR_TRANSITION_ALERTS',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END process_tr_transition_alerts;

    /**
    * Cleans all referral hand off alerts
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_external_request Referral that is being hand off
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2013
    */
    FUNCTION clean_handoff_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_external_request=' || i_id_external_request;
        g_error  := 'Init set_tr_status / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        -- remove alerts
        g_retval := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_sys_alert => pk_ref_constant.g_sa_handoff_declined,
                                                     i_id_record    => i_id_external_request,
                                                     o_error        => o_error);
    
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
                                              i_function    => 'CLEAN_HANDOFF_ALERTS',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END clean_handoff_alerts;

    /**
    * Gets status configuration depending on software, institution, profile and professional functionality
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids   
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identification        
    * @param   i_func               Functionality identification
    * @param   i_status_info        Status information configured in table WF_STATUS_CONFIG
    * @param   i_param              Hand off information
    *
    * @RETURN  status info
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   09-02-2011
    */
    FUNCTION get_wf_status_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_category    IN wf_status_config.id_category%TYPE,
        i_profile     IN wf_status_config.id_profile_template%TYPE,
        i_func        IN wf_status_config.id_functionality%TYPE,
        i_status_info IN t_rec_wf_status_info,
        i_param       IN table_varchar
    ) RETURN t_rec_wf_status_info IS
        l_rec_wf_status_info   t_rec_wf_status_info := t_rec_wf_status_info();
        l_params               VARCHAR2(1000 CHAR);
        l_id_trans_resp        ref_trans_responsibility.id_trans_resp%TYPE;
        l_id_ref               p1_external_request.id_external_request%TYPE;
        l_id_prof_transf_owner ref_trans_responsibility.id_prof_transf_owner%TYPE;
        l_id_tr_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE;
        l_id_tr_inst_orig      ref_trans_responsibility.id_inst_orig_tr%TYPE;
        l_id_tr_inst_dest      ref_trans_responsibility.id_inst_dest_tr%TYPE;
        l_user_answ            VARCHAR2(1 CHAR);
        l_error                t_error_out;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' ID_WF=' || i_status_info.id_workflow || ' ID_STATUS=' ||
                    i_status_info.id_status || ' i_param=' || pk_utils.to_string(i_param);
        g_error  := 'Init get_wf_status_info / ' || l_params;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- assigning default values (from table WF_STATUS_CONFIG)
        g_error              := 'I_STATUS_INFO / ' || l_params;
        l_rec_wf_status_info := i_status_info;
    
        g_retval := get_tr_param_values(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_param                => i_param,
                                        o_id_trans_resp        => l_id_trans_resp,
                                        o_id_ref               => l_id_ref,
                                        o_id_prof_transf_owner => l_id_prof_transf_owner,
                                        o_id_tr_prof_dest      => l_id_tr_prof_dest,
                                        o_id_tr_inst_orig      => l_id_tr_inst_orig,
                                        o_id_tr_inst_dest      => l_id_tr_inst_dest,
                                        o_user_answ            => l_user_answ,
                                        o_error                => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CASE / ' || l_params;
        CASE
            WHEN l_rec_wf_status_info.id_status IN
                 (pk_ref_constant.g_tr_status_inst_app, pk_ref_constant.g_tr_status_declined_inst) THEN
            
                -- check if has functionality of 'Handoff approval'
                IF pk_ref_change_resp.check_func_handoff_app(i_prof => i_prof) = pk_ref_constant.g_yes
                   AND i_prof.institution = l_id_tr_inst_dest
                THEN
                    l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                END IF;
            
            WHEN l_rec_wf_status_info.id_status = pk_ref_constant.g_tr_status_pend_app THEN
            
                IF i_prof.id = l_id_tr_prof_dest
                   AND (l_rec_wf_status_info.id_workflow = pk_ref_constant.g_wf_transfresp OR
                   (i_prof.institution = l_id_tr_inst_dest AND
                   l_rec_wf_status_info.id_workflow = pk_ref_constant.g_wf_transfresp_inst))
                THEN
                    l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                END IF;
                -- else is default, already in the table                            
        END CASE;
    
        RETURN l_rec_wf_status_info;
    
    END get_wf_status_info;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_tr_status;
/
