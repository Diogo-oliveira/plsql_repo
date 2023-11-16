/*-- Last Change Revision: $Rev: 1653180 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-10-28 16:21:35 +0000 (ter, 28 out 2014) $*/

CREATE OR REPLACE PACKAGE pk_rcm_core IS

    /**
    * Inserts a new patient recommendation
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_episode_tab           Array of episode identifiers
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_orig              Origin recomendation identifier
    * @param   i_id_rcm_orig_value        Origin recomendation value (cdr_instance when origin=CDS)
    * @param   i_rcm_text_tab             Array of recommendation texts
    * @param   i_rcm_notes_tab            Array of notes associated to each recommendation
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional functionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_id_rcm_det_tab           Array of recommendation details identifiers
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @value   o_flg_show                 {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   08-02-2012
    */
    FUNCTION create_pat_rcm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient_tab      IN table_number,
        i_id_episode_tab      IN table_number,
        i_id_rcm              IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_orig         IN pat_rcm_det.id_rcm_orig%TYPE,
        i_id_rcm_orig_value   IN pat_rcm_det.id_rcm_orig_value%TYPE,
        i_rcm_text_tab        IN table_clob,
        i_rcm_notes_tab       IN table_varchar,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_param               IN table_varchar DEFAULT table_varchar(),
        o_id_rcm_det_tab      OUT table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Process the current status change of this recommendation
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recomendation detail identifier
    * @param   i_id_workflow              Workflow identifier
    * @param   i_id_workflow_action       Workflow action identifier
    * @param   i_id_status_begin          Reccomendation status begin
    * @param   i_id_status_end            Reccomendation status end
    * @param   i_rcm_notes                Notes associated to this recommendation
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional functionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   05-04-2012
    */
    FUNCTION set_pat_rcm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rcm              IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det          IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow         IN pat_rcm_h.id_workflow%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_begin     IN pat_rcm_h.id_status%TYPE,
        i_id_status_end       IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes           IN pat_rcm_h.notes%TYPE,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_functionality    IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_param               IN table_varchar DEFAULT table_varchar(),
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get value of chr_val (Recommendations Property )
    *
    * @param  i_id_rcm          Recommendation identifier
    * @param  i_prop            Property identifier
    *
    * @return  Varchar
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-04-2012
    */

    FUNCTION get_rcm_prop_val_chr
    (
        i_rcm  IN rcm_prop.id_rcm%TYPE,
        i_prop IN rcm_prop.id_prop%TYPE
    ) RETURN rcm_prop.chr_val%TYPE;

    /**
    * Get value of num_val (Recommendations Property )
    *
    * @param  i_id_rcm          Recommendation identifier
    * @param  i_prop            Property identifier
    *
    * @return  Number
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-04-2012
    */

    FUNCTION get_rcm_prop_val_num
    (
        i_rcm  IN rcm_prop.id_rcm%TYPE,
        i_prop IN rcm_prop.id_prop%TYPE
    ) RETURN rcm_prop.num_val%TYPE;

    /**
    * Get value of dte_val (Recommendations Property )
    *
    * @param  i_id_rcm          Recommendation identifier
    * @param  i_prop            Property identifier
    *
    * @return  TIMESTAMP(6) WITH LOCAL TIME ZONE
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-04-2012
    */

    FUNCTION get_rcm_prop_val_dte
    (
        i_rcm  IN rcm_prop.id_rcm%TYPE,
        i_prop IN rcm_prop.id_prop%TYPE
    ) RETURN rcm_prop.dte_val%TYPE;

    /**
    * Gets tokens needed to send message to the patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)
    * @param   i_id_patient         Patient identifier
    * @param   i_id_rcm             Recommendation identifier
    * @param   o_tokens             Tokens needed to the message
    * @param   o_error              Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_msg_tokens
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        o_tokens     OUT pk_rcm_constant.t_ibt_desc_value,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets actual and historic data of this recommendation detail
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier
    * @param   o_rcm_data     Recommendation info
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   24-04-2012
    */
    FUNCTION get_pat_rcm_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_rcm_det.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_rcm_data   OUT pk_rcm_constant.t_cur_rcm_info,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if is the professional configured in SYS_CONFIG with code ID_PROF_BACKGROUND
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-05-2012
    */
    FUNCTION check_prof_background
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
    * Gets patient reminders for Instructions CDA section
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_pat_rcm_instr         Cursor with infomation about patient reminders for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        CRISTINA.OLIVEIRA
    * @version                       2.6.4
    * @since                         2014/10/28 
    */
    FUNCTION get_pat_rcm_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_rcm_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
END pk_rcm_core;
/
