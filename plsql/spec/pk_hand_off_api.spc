/*-- Last Change Revision: $Rev: 2028709 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hand_off_api IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 01-10-2010 09:15:09
    -- Purpose : Hand off API

    -- Public function and procedure declarations

    /**
    * Get responsability icons
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_handoff_type Hand-off type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 Array with the responsability icons
    *
    * @raises                 g_resp_type_exception Error when getting responsability type for the episode/i_prof
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_icons
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_handoff_type IN sys_config.value%TYPE
    ) RETURN table_varchar;

    /**
    * Checks if current episode has and needs a overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   o_flg_show_error  Is or isn't to show error message
    * @param   o_error_title     Error title
    * @param   o_error_message   Error message
    * @param   o_error           Error information
    *
    * @value   o_flg_show_error  {*} 'Y' Yes
    *                            {*} 'N' No
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION check_overall_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_flg_show_error OUT VARCHAR2,
        o_error_title    OUT sys_message.desc_message%TYPE,
        o_error_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_number;

    /**
    * Get all episodes where i_profs are responsible (Used on search criteria)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_prof_cat        Professional category    
    * @param   i_hand_off_type   Type of hand-off (N) Normal (M) Multiple
    * @param   i_profs           Array with id_prof's
    *
    * @return                 Array with id_episode's
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_prof_episodes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_profs         IN table_number
    ) RETURN table_number;

    /**********************************************************************************************
    * Creates a new request for EPISODE responsability (transfer responsability).
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_prof_to                Destination professional
    * @param i_episode                Episode ID
    * @param i_cs                     Destination clinical service
    * @param i_dept                   Destination department
    * @param i_notes                  Transfer notes
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_flg_profile            Type of profile (when applicable): (S)pecialist (R)esident (I)ntern (N)urse
    * @param i_id_speciality          Destination speciality ID (when applicable)
    * @param i_dt_reg                 Record date (current date if NULL)
    * @param o_epis_prof_resp         Created record ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION create_request_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_to        IN epis_prof_resp.id_prof_to%TYPE,
        i_episode        IN epis_prof_resp.id_episode%TYPE,
        i_cs             IN NUMBER,
        i_dept           IN NUMBER,
        i_notes          IN epis_prof_resp.notes_clob%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile    IN profile_template.flg_profile%TYPE,
        i_id_speciality  IN epis_multi_prof_resp.id_speciality%TYPE,
        i_dt_reg         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_epis_prof_resp OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a SPECIALIST PHYSICIAN responsability record that is in "finalized" state.
    * Used by INTER-
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_professional         Specialist physician ID
    * @param i_notes                   Cancellation notes
    * @param i_id_cancel_reason        Cancel reason ID
    * @param i_dt_cancel               Cancellation date
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           13-Jul-2011
    *
    **********************************************************************************************/
    FUNCTION cancel_responsability_spec
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a responsability request.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   i_dt_reg                   Record date (current date if NULL)
    * @param   o_error                    Error message
    *                        
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION cancel_request_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_reg           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Accept request for episode responsability
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_prof_resp         Record ID
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_notes                  Accpet notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION set_accept_request_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_clob%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Reject request for episode responsability
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_prof_resp         Record ID
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_notes                  Accpet notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION set_reject_request_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Sets the overall responsability for the episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional that insert current record
    * @param I_ID_PROF_ADMITTING      New responsable professional of information
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_CLINICAL_SERVICE    CLINICAL_SERVICE identifier that should be associated with the episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated
    * @param I_DT_REG                 Record date (current date if NULL)
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        0.1
    * @since                          18-Jan-2011
    * @dependents                     PK_INP_EPISODE
    *******************************************************************************************************************************************/
    FUNCTION set_overall_responsability
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_admitting   IN profissional,
        i_id_dep_clin_serv    IN epis_info.id_dep_clin_serv%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE DEFAULT NULL,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_reg              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_sbar_note           IN CLOB DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the current ongoing responsibility transfer ID for a given episode
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode ID
    *
    * @return                 Episode responsibility ID
    *
    * @author  José Silva
    * @version v2.6.0.5
    * @since   07-09-2011
    */
    FUNCTION get_epis_prof_resp_id
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_prof_resp.id_epis_prof_resp%TYPE;

    g_cr_id_content CONSTANT cancel_reason.id_content%TYPE := 'TMP99.652';

    /*******************************************************************************************************************************************
    * Sets the overall responsability for the episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional that insert current record
    * @param I_ID_EPISODE             EPISODE identifier that should be associated
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param I_ID_PROF_ADMITTING      Array with list responsable professional
    * @param I_id_clinical_service       Array with CLINICAL_SERVICE identifier that should be associated with the episode
    * @param I_DT_REG                 Array with responsable record date (current date if NULL)
    * @param i_id_priority            Array with priority 
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          13-Nov-2017
    *******************************************************************************************************************************************/
    FUNCTION set_episode_responsability
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_id_prof_admitting   IN table_number,
        i_id_clinical_service IN table_number,
        i_dt_reg              IN table_varchar, -- TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_priority         IN table_number,
        i_sbar_note           IN CLOB DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_resp_icon
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;


END pk_hand_off_api;
/
