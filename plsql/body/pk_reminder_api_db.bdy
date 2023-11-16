/*-- Last Change Revision: $Rev: 2027618 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_reminder_api_db IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

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
    ) RETURN t_table_reminder_param IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'TF_REMINDER_PARAMS';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.TF_REMINDER_PARAMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.tf_reminder_params(i_lang => i_lang, i_prof => i_prof, i_id_reminder => i_id_reminder);
    END tf_reminder_params;

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
    ) RETURN t_table_reminder_param IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'TF_REMINDER_PARAMS';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.TF_REMINDER_PARAMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.tf_reminder_params(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_internal_name => i_internal_name);
    END tf_reminder_params;

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
    ) RETURN t_table_reminder_prof_temp IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'TF_REMINDER_PROF_TEMP';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.TF_REMINDER_PROF_TEMP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.tf_reminder_prof_temp(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_reminder_param => i_id_reminder_param,
                                                      i_id_episode        => i_id_episode);
    END tf_reminder_prof_temp;

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
    ) RETURN t_table_reminder_prof_temp IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'TF_REMINDER_PROF_TEMP';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.TF_REMINDER_PROF_TEMP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.tf_reminder_prof_temp(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_internal_name => i_internal_name,
                                                      i_id_episode    => i_id_episode);
    END tf_reminder_prof_temp;

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
    ) RETURN t_rec_reminder_prof_temp IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_PROF_TEMP_SELECTED_VALUE';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.GET_PROF_TEMP_SELECTED_VALUE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.get_prof_temp_selected_value(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_reminder_param => i_id_reminder_param,
                                                             i_id_prof_template  => i_id_prof_template);
    END get_prof_temp_selected_value;

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
    ) RETURN t_rec_reminder_prof_temp IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_PROF_TEMP_SELECTED_VALUE';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.GET_PROF_TEMP_SELECTED_VALUE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.get_prof_temp_selected_value(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_internal_name    => i_internal_name,
                                                             i_id_prof_template => i_id_prof_template);
    END get_prof_temp_selected_value;

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
    ) RETURN reminder%ROWTYPE IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_REMINDER_ROW';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.GET_REMINDER_ROW';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.get_reminder_row(i_lang => i_lang, i_prof => i_prof, i_id_reminder => i_id_reminder);
    END get_reminder_row;

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
    ) RETURN reminder%ROWTYPE IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_REMINDER_ROW';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.GET_REMINDER_ROW';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.get_reminder_row(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_internal_name => i_internal_name);
    END get_reminder_row;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_PROF_TEMP_REMINDER';
    BEGIN
        g_error := 'CALL PK_REMINDER_CORE.SET_PROF_TEMP_REMINDER';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.set_prof_temp_reminder(i_profile_template       => i_profile_template,
                                                       i_flg_is_reminder_active => i_flg_is_reminder_active,
                                                       i_recurr_option          => i_recurr_option,
                                                       i_value                  => i_value,
                                                       i_institution            => i_institution,
                                                       i_software               => i_software,
                                                       o_error                  => o_error);
    END set_prof_temp_reminder;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_reminder_api_db;
/
