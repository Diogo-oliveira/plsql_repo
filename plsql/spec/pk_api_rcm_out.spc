/*-- Last Change Revision: $Rev: 1653180 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-10-28 16:21:35 +0000 (ter, 28 out 2014) $*/

CREATE OR REPLACE PACKAGE pk_api_rcm_out IS

    /**
    * Inserts new patient clinical recommendations (batch process)
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm_tab               Array of recommendation identifiers
    * @param   i_rcm_text_tab             Array of text recommendation text   
    * @param   i_id_rcm_orig_value        Origin value to be stored in rcm module
    * @param   o_id_rcm_det_tab           Array of recommendation details identifier    
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-04-2012
    */
    PROCEDURE create_pat_clin_rcm_cdr
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_rcm_det.id_patient%TYPE,
        i_id_episode        IN pat_rcm_h.id_epis_created%TYPE,
        i_id_rcm_tab        IN table_number,
        i_rcm_text_tab      IN table_clob,
        i_id_rcm_orig_value IN pat_rcm_det.id_rcm_orig_value%TYPE,
        o_id_rcm_det_tab    OUT table_number
    );

    /**
    * Inserts new patient reminders (batch process)
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_episode_tab           Array of episode identifiers
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_orig_value        Origin value to be stored in rcm module
    * @param   o_id_rcm_det_tab           Array of recommendation details identifier
    * @param   o_error                    Error information    
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   08-02-2012
    */
    /*
    PROCEDURE create_pat_reminder_alerts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient_tab    IN table_number,
        i_id_episode_tab    IN table_number,
        i_id_rcm            IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_orig_value IN pat_rcm_det.id_rcm_orig_value%TYPE,
        o_id_rcm_det_tab    OUT table_number,
        o_error             OUT t_error_out
    );
    */

    /**
    * Updates recommendation status
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recommendation detail identifier
    * @param   i_id_workflow_action       Workflow action
    * @param   i_id_status_end            Status end
    * @param   i_rcm_notes                Notes related to the status change
    * @param   o_error                    Error information    
    *
    * @return  TRUE if sucess, FALSE otherwise
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-04-2012
    */
    FUNCTION set_pat_rcm_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_rcm             IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det         IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow_action IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_end      IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes          IN pat_rcm_h.notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Ssearch patients who are under the conditions of the reminder rules 
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   11-04-2012
    */
    PROCEDURE generate_reminders;

    /**
    * Function to be called from reset, to generate reminders for patients in the institution specified 
    *
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_institution           Institution identifier
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *   
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-09-2012
    */
    FUNCTION generate_reminders_pat
    (
        i_id_patient_tab IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set RCM status, based on CRM notification status
    * Called by job 
    *
    * @author Joana Barroso
    * @since  19-Apr-2012
    **/
    PROCEDURE set_rcm_notif_status;

    /**
    * Sends message to the crm
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identifier and its context (institution and software)
    * @param   i_ws_name         Webservice name to be called
    * @param   i_msg_tokens      Tokens needed to the message
    * @param   o_ws_response     Web service response   
    * @param   o_error           Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION send_message_to_crm
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ws_name     IN VARCHAR2,
        i_msg_tokens  IN pk_rcm_constant.t_ibt_desc_value,
        o_ws_response OUT CLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Interprets webservice response and gets the value of CRM key (same as execution request key)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identifier and its context (institution and software)
    * @param   i_msg_tokens      Tokens needed to the message
    * @param   o_ws_response     Web service response   
    * @param   o_error           Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_crm_key
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ws_response IN CLOB,
        o_crm_key     OUT pat_rcm_h.crm_key%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Interprets webservice response and gets the status of CRM key (same as execution request key)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identifier and its context (institution and software)
    * @param   i_msg_tokens      Tokens needed to the message
    * @param   o_ws_response     Web service response   
    * @param   o_error           Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_crm_key_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ws_response    IN CLOB,
        o_crm_key_status OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get CRM notification status
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_crm_key                  CRM id 
    * @param   o_notif_status             {*} 'Y' - Notified
    *                                     {*} 'N' - Unnotified
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 1.0
    * @since   19-04-2012
    */
    FUNCTION get_notification_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_crm_key      IN pat_rcm_h.crm_key%TYPE,
        o_notif_status OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function deletes all data related to recommendations
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient_tab           Array of patient identifiers
    * @param   i_id_institution           Institution identifier
    * @param   i_id_episode_tab           Array of episode identifiers
    * @param   i_id_software              Software identifier
    * @param   o_error                    Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   28-08-2012
    */
    FUNCTION rcm_reset
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient_tab IN table_number,
        i_id_institution IN pat_rcm_det.id_institution%TYPE,
        i_id_episode_tab IN table_number,
        i_id_software    IN software.id_software%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

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
END pk_api_rcm_out;
/
