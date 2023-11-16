/*-- Last Change Revision: $Rev: 2028928 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_reminder_core IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 30-05-2011 12:05:10
    -- Purpose : Reminder functionality logic

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Gets the correct configuration filter variables 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_reminder_param      Reminder param id
    * @param   i_profile_template    Profile template id
    * @param   o_profile_template    Profile template id
    * @param   o_institution         Institution id
    * @param   o_software            Software id
    * @param   o_error               Error information
    *
    * @return  TRUE if succeded, otherwise FALSE
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_rem_prof_temp_vars
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_reminder_param   IN reminder_prof_temp.id_reminder_param%TYPE,
        i_profile_template IN reminder_prof_temp.id_profile_template%TYPE,
        o_profile_template OUT reminder_prof_temp.id_profile_template%TYPE,
        o_institution      OUT reminder_prof_temp.id_institution%TYPE,
        o_software         OUT reminder_prof_temp.id_software%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets reminder id for the given internal name 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_internal_name       Reminder internal name
    *
    * @return  Reminder id
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_id_reminder
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN reminder.internal_name%TYPE
    ) RETURN reminder.id_reminder%TYPE;

    /**
    * Gets reminder param id for the given internal name 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_internal_name       Reminder internal name
    *
    * @return  Reminder id
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_id_reminder_param
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN reminder_param.internal_name%TYPE
    ) RETURN reminder_param.id_reminder_param%TYPE;

    /**
    * Gets all available reminder params 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_reminder         Reminder id
    *
    * @return  Table function with all available reminder params
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION tf_reminder_params
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_reminder IN reminder.id_reminder%TYPE
    ) RETURN t_table_reminder_param;

    /**
    * Gets all available reminder params 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_internal_name       Reminder internal name
    *
    * @return  Table function with all available reminder params
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION tf_reminder_params
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN reminder.internal_name%TYPE
    ) RETURN t_table_reminder_param;

    /**
    * Gets all prof temp records for the given episode software and reminder param.
    * Filtered by default inst and soft configuration or by specific inst and soft (if available)
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_reminder_param   Reminder param id
    * @param   i_id_episode          Episode id
    *
    * @return  Table function with all available reminder params
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION tf_reminder_prof_temp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_reminder_param IN reminder_param.id_reminder_param%TYPE,
        i_id_episode        IN episode.id_episode%TYPE
    ) RETURN t_table_reminder_prof_temp;

    /**
    * Gets all prof temp records for the given episode software and reminder param internal name.
    * Filtered by default inst and soft configuration or by specific inst and soft (if available)
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_internal_name       Reminder param internal name
    * @param   i_id_episode          Episode id
    *
    * @return  Table function with all available reminder params
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION tf_reminder_prof_temp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN reminder_param.internal_name%TYPE,
        i_id_episode    IN episode.id_episode%TYPE
    ) RETURN t_table_reminder_prof_temp;

    /**
    * Get reminder param select value for the current prof profile template 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_reminder_param   Reminder param id
    * @param   i_id_prof_template    Profile template id
    *
    * @return  Reminder prof temp record
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_prof_temp_selected_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_reminder_param IN reminder_prof_temp.id_reminder_param%TYPE,
        i_id_prof_template  IN reminder_prof_temp.id_profile_template%TYPE DEFAULT NULL
    ) RETURN t_rec_reminder_prof_temp;

    /**
    * Get reminder param select value for the current prof profile template 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_internal_name       Reminder param internal name
    * @param   i_id_prof_template    Profile template id
    *
    * @return  Reminder prof temp record
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_prof_temp_selected_value
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_internal_name    IN reminder_param.internal_name%TYPE,
        i_id_prof_template IN reminder_prof_temp.id_profile_template%TYPE DEFAULT NULL
    ) RETURN t_rec_reminder_prof_temp;

    /**
    * Get reminder record by id
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_reminder            Reminder id
    *
    * @return  Reminder prof temp record
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_reminder_row
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_reminder IN reminder.id_reminder%TYPE
    ) RETURN reminder%ROWTYPE;

    /**
    * Get reminder record by internal name
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_internal_name       Reminder internal name
    *
    * @return  Reminder prof temp record
    *
    * @author  ALEXANDRE.SANTOS
    * @version 2.6.1.1
    * @since   30-05-2011
    */
    FUNCTION get_reminder_row
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN reminder.internal_name%TYPE
    ) RETURN reminder%ROWTYPE;

    /**
    * Sets the profile template recursive option, validating the input fields.
    *
    * @param   i_profile_template        Profile template id
    * @param   i_flg_is_reminder_active  Will the reminder be active? Y - Yes; N - Otherwise
    * @param   i_recurr_option           Id of the recursive option; I_VALUE must be NULL when I_RECURR_OPTION is filled
    * @param   i_value                   If recursive option is by episode set this value to "BY_EPISODE"; I_RECURR_OPTION must be NULL when I_VALUE is filled
    * @param   i_institution             Institution id
    * @param   i_software                Software id
    * @param   o_error                   Error information
    *
    * @return  TRUE if succeded, otherwise FALSE
    *
    * @author  Alexandre Santos
    * @version 2.6.3.7
    * @since   26-08-2013
    */
    FUNCTION set_prof_temp_reminder
    (
        i_profile_template       IN profile_template.id_profile_template%TYPE,
        i_flg_is_reminder_active IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_recurr_option          IN reminder_prof_temp.id_recurr_option%TYPE DEFAULT NULL,
        i_value                  IN reminder_prof_temp.value%TYPE DEFAULT NULL,
        i_institution            IN institution.id_institution%TYPE DEFAULT pk_alert_constant.g_inst_all,
        i_software               IN software.id_software%TYPE DEFAULT pk_alert_constant.g_soft_all,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
END pk_reminder_core;
/
