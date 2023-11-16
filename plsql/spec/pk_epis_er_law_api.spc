/*-- Last Change Revision: $Rev: 2028678 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_epis_er_law_api IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 27-10-2011 08:32:40
    -- Purpose : Emergency law APIs

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

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
        o_epis_ges_msg          OUT epis_ges_msg.id_epis_ges_msg%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

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

END pk_epis_er_law_api;
/
