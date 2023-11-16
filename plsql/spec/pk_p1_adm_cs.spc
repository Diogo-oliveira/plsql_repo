/*-- Last Change Revision: $Rev: 2028826 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_adm_cs AS

    /****************************************************************************************
    PROJECT         : ALERT-P1
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ),
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ),
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : CARLOS FERREIRA
    PK DATE CREATION: 07-2005
    PK GOAL         : THIS PACKAGE TAKES CARE OF ALL FUNCTIONS REGARDING THE CLERK ( ADMINISTRATIVE )
                      LOCATED AT THE HEALTHCARE CENTER ( CENTRO DE SAUDE ).
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Update status of tasks for the request (replaces UPD_TASKS_DONE)
    *
    * @param   I_LANG  language
    * @param   I_PROF  profissional, institution, software
    * @param   i_id_external_request Referral identifier
    * @param   I_ID_TASKS array of tasks ids
    * @param   I_FLG_STATUS_INI array tasks initial status
    * @param   I_FLG_STATUS_FIN array tasks final status
    * @param   i_notes notes     
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION update_tasks_done_internal
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_id_tasks            IN table_number,
        i_flg_status_ini      IN table_varchar,
        i_flg_status_fin      IN table_varchar,
        i_notes               IN p1_detail.text%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Lists all tasks related to referral by doctor
    *
    * @param   I_LANG  language
    * @param   I_PROF  profissional, institution, software
    * @param   i_id_external_request Referral identifier
    * @param   I_ID_TASKS array of tasks ids
    * @param   I_FLG_STATUS_INI array tasks initial status
    * @param   I_FLG_STATUS_FIN array tasks final status
    * @param   i_notes notes    
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION get_tasks_done
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        o_tasks    OUT pk_types.cursor_type,
        o_info     OUT pk_types.cursor_type,
        o_notes    OUT pk_types.cursor_type,
        o_editable OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the options for the administrative.
    *
    * @param   I_LANG  language
    * @param   i_prof                Profissional, institution, software
    * @param   i_id_ext_req          Referral identifier    
    * @param   I_DT_MODIFIED last modified date as provided by get_p1_detail
    * @param   O_STATUS options list
    * @param   O_FLG_SHOW {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE message title
    * @param   O_MSG message text
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates request status.
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_id_p1           Referral identifier    
    * @param   i_status          Action to be done
    * @param   i_reason_code     Reason code when requesting a referral cancellation
    * @param   i_notes           Notes
    * @param   i_date            Operation date
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION set_status_internal
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_p1       IN p1_external_request.id_external_request%TYPE,
        i_status      IN VARCHAR2,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN VARCHAR2,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_p1_adm_cs;
/
