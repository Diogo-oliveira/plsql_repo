/*-- Last Change Revision: $Rev: 1537511 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2013-12-16 16:25:45 +0000 (seg, 16 dez 2013) $*/

CREATE OR REPLACE PACKAGE pk_ref_tr_status IS

    -- Author  : ANA.MONTEIRO
    -- Created : 31-05-2013 10:59:27
    -- Purpose : 

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
    ) RETURN table_varchar;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /**
    * Gets status configuration depending on software, institution, profile and professional functionality
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids   
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identification        
    * @param   i_func               Functionality identification
    * @param   i_status_info        Status information configured in table WF_STATUS_CONFIG
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
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
    ) RETURN t_rec_wf_status_info;

END pk_ref_tr_status;
/
