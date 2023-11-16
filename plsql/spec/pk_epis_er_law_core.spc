/*-- Last Change Revision: $Rev: 2028679 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_epis_er_law_core IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 27-10-2011 08:32:40
    -- Purpose : Logic of emergency law

    -- Public type declarations

    -- Public constant declarations
    g_fast_track_er_law CONSTANT fast_track.id_fast_track%TYPE := 3;

    g_flg_er_law_status_a CONSTANT epis_er_law.flg_er_law_status%TYPE := 'A'; --Activated
    g_flg_er_law_status_i CONSTANT epis_er_law.flg_er_law_status%TYPE := 'I'; --Inactivated

    g_ges_sys_alert CONSTANT sys_alert.id_sys_alert%TYPE := 110; --GES_UNNOT_PATHOLOGIES
    g_ges_todo_task CONSTANT todo_task.flg_task%TYPE := 'GS'; --GES

    g_ges_flg_orig_d CONSTANT epis_ges_msg.flg_origin%TYPE := 'D'; -- Differential diagnosis
    g_ges_flg_orig_f CONSTANT epis_ges_msg.flg_origin%TYPE := 'F'; -- Final diagnosis
    g_ges_flg_orig_m CONSTANT epis_ges_msg.flg_origin%TYPE := 'M'; -- Past medical history
    g_ges_flg_orig_s CONSTANT epis_ges_msg.flg_origin%TYPE := 'S'; -- Past surgical history
    g_ges_flg_orig_p CONSTANT epis_ges_msg.flg_origin%TYPE := 'P'; -- Problems

    g_ges_flg_msg_status_s CONSTANT epis_ges_msg.flg_msg_status%TYPE := 'S'; -- Message sent to external system
    g_ges_flg_msg_status_r CONSTANT epis_ges_msg.flg_msg_status%TYPE := 'R'; -- Message received from the external system

    g_ges_flg_status_a CONSTANT epis_ges_msg.flg_msg_status%TYPE := pk_alert_constant.g_active;
    g_ges_flg_status_o CONSTANT epis_ges_msg.flg_msg_status%TYPE := pk_alert_constant.g_outdated;
    g_ges_flg_status_c CONSTANT epis_ges_msg.flg_msg_status%TYPE := pk_alert_constant.g_cancelled;

    --Action Ids
    g_action_edit   CONSTANT PLS_INTEGER := 1;
    g_action_cancel CONSTANT PLS_INTEGER := 2;

    g_ges_exception EXCEPTION;

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Create/Update episode emergency law record
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_dt_activation             Date of activation
    * @param   i_dt_inactivation           Date of inactivation
    * @param   i_flg_er_law_status         Emergency law status
    * @param   i_flg_commit                TRUE to commit; Otherwise FALSE
    * @param   o_epis_er_law               Created/updated record PK id
    * @param   o_error                     Error information
    *
    * @values  i_flg_er_law_status         A - Active
    *                                      I - Inactive
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION set_epis_er_law
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN epis_er_law.id_episode%TYPE,
        i_dt_activation     IN VARCHAR2,
        i_dt_inactivation   IN VARCHAR2,
        i_flg_er_law_status IN epis_er_law.flg_er_law_status%TYPE,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_epis_er_law       OUT epis_er_law.id_epis_er_law%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel episode emergency law record
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_cancel_notes              Cancel notes
    * @param   i_flg_commit                TRUE to commit; Otherwise FALSE
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION cancel_epis_er_law
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN epis_er_law.id_episode%TYPE,
        i_cancel_reason IN epis_er_law.id_cancel_reason%TYPE,
        i_cancel_notes  IN epis_er_law.notes_cancel%TYPE,
        i_flg_commit    IN BOOLEAN DEFAULT FALSE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get list of episode emergency law
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_lst_epis_er_law           List of episode emergency law
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_lst_epis_er_law
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN epis_er_law.id_episode%TYPE,
        o_lst_epis_er_law OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get episode emergency law record
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_er_law               Episode emergency law id
    * @param   o_epis_er_law               Episode emergency law record
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_epis_er_law
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_epis_er_law OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get fast track id if available for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_fast_track                Fast track id
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_fast_track_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN epis_er_law.id_episode%TYPE,
        o_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get fast track id if available for the given episode
    *
    * @param   i_episode                   Episode id
    * @param   i_fast_track                Fast track id
    *
    * @return  Fast track id
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_fast_track_id
    (
        i_episode    IN epis_er_law.id_episode%TYPE,
        i_fast_track IN fast_track.id_fast_track%TYPE
    ) RETURN fast_track.id_fast_track%TYPE;

    /**
    * Get emergency law date limits
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_limits                    List of date limits
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_date_limits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_er_law.id_episode%TYPE,
        o_limits  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sends a new message to the GES external system
    * This function is called by all functions that create diagnosis
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_pat_history_diagnosis     Patient history diagnosis id
    * @param   i_flg_origin                Area where diagnosis was registered
    * @param   i_flg_commit                TRUE to commit; Otherwise FALSE
    * @param   o_epis_ges_msg              Created/updated record PK id
    * @param   o_error                     Error information
    *
    * @values  i_flg_origin                D - Differential diagnosis
    *                                      F - Final diagnosis
    *                                      M - Past medical history
    *                                      S - Past surgical history
    *                                      P - Problems
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION create_epis_ges_msg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN epis_ges_msg.id_episode%TYPE,
        i_pat_history_diagnosis IN epis_ges_msg.id_pat_history_diagnosis%TYPE,
        i_epis_diagnosis        IN epis_ges_msg.id_epis_diagnosis%TYPE,
        i_flg_origin            IN epis_ges_msg.flg_origin%TYPE,
        i_flg_commit            IN BOOLEAN DEFAULT FALSE,
        o_epis_ges_msg          OUT epis_ges_msg.id_epis_ges_msg%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Mark the message sent to GES as being answered
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_ges_msg              Epis GES message id
    * @param   i_flg_commit                TRUE to commit; Otherwise FALSE
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION set_epis_ges_response
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_ges_msg IN epis_ges_msg.id_epis_ges_msg%TYPE,
        i_flg_commit   IN BOOLEAN DEFAULT FALSE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates/removes the GES sys_alert and todo list item
    * When the total unnotified pathologies is greather then 0 the alert is created, otherwise and if exists is removed
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_total_unnot_pathologies   Total unnotified pathologies
    * @param   i_flg_commit                TRUE to commit; Otherwise FALSE
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION set_epis_ges_alert
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_total_unnot_pathologies IN NUMBER,
        i_flg_commit              IN BOOLEAN DEFAULT FALSE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get total unnotified pathologies
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_total_unnot_pathologies   Total unnotified pathologies
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_total_unnot_path
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN epis_ges_msg.id_episode%TYPE,
        o_total_unnot_pathologies OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get GES discharge message
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_flg_type                  Message type
    * @param   o_url                       URL to the external GES system
    * @param   o_total_unnot_pathologies   Total unnotified pathologies
    * @param   o_error                     Error information
    *
    * @values  o_flg_type                  N - No message to display
    *                                      W - Warning
    *                                      C - Confirmation
    *                                      E - Error
    *                                      WC - Warning and confirmation
    *                                      WE - Warning and error
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_ges_discharge_msg
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN epis_ges_msg.id_episode%TYPE,
        o_flg_type                OUT VARCHAR2,
        o_url                     OUT VARCHAR2,
        o_total_unnot_pathologies OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get GES URL
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    *
    * @return  GES URL or NULL if not available
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_ges_url
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/11/23
    ********************************************************************************************/
    FUNCTION match_er_ges
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * gets the actions available in emergency law
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_epis_er_law             epis_er_law ID
    * @param      o_actions                    cursor with all actions
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Vanessa Barsottelli
    * @since                                   16-Set-2014
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get emergency law description for single page
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_epis_er_law             epis_er_law ID
    * @param      o_description                cursor with description
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Vanessa Barsottelli
    * @since                                   16-Set-2014
    ********************************************************************************************/
    FUNCTION get_description
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_description    OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_epis_er_law_core;
/
