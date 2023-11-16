/*-- Last Change Revision: $Rev: 2027622 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_reminder_core IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REM_PROF_TEMP_VARS';
        --
        l_zero CONSTANT PLS_INTEGER := 0;
        l_one  CONSTANT PLS_INTEGER := 1;
        l_two  CONSTANT PLS_INTEGER := 2;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL CFG_VARS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            SELECT t.id_institution, t.id_software, t.id_profile_template
              INTO o_institution, o_software, o_profile_template
              FROM (SELECT rpt.id_institution,
                           rpt.id_software,
                           rpt.id_profile_template,
                           row_number() over(ORDER BY decode(rpt.id_institution, i_prof.institution, l_one, l_two), decode(rpt.id_software, i_prof.software, l_one, l_two), decode(rpt.id_profile_template, i_profile_template, l_one, l_two)) line_number
                      FROM reminder_prof_temp rpt
                     WHERE rpt.id_reminder_param = i_reminder_param
                       AND rpt.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND rpt.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND rpt.id_profile_template IN (pk_alert_constant.g_profile_template_all, i_profile_template)) t
             WHERE t.line_number = l_one;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'REMINDER_PROF_TEMP NOT CONFIGURED';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                o_profile_template := l_zero;
                o_institution      := l_zero;
                o_software         := l_zero;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rem_prof_temp_vars;

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
    ) RETURN reminder.id_reminder%TYPE IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ID_REMINDER';
        --
        l_error t_error_out;
        l_ret   reminder.id_reminder%TYPE;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_REMINDER OF "' || i_internal_name || '"';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT r.id_reminder
          INTO l_ret
          FROM reminder r
         WHERE r.internal_name = i_internal_name
           AND r.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'REMINDER "' || i_internal_name || '" NOT CONFIGURED, SO THERE IS NOTHING TO DO';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_id_reminder;

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
    ) RETURN reminder_param.id_reminder_param%TYPE IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ID_REMINDER_PARAM';
        --
        l_error t_error_out;
        l_ret   reminder_param.id_reminder_param%TYPE;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_REMINDER OF "' || i_internal_name || '"';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT r.id_reminder_param
          INTO l_ret
          FROM reminder_param r
         WHERE r.internal_name = i_internal_name
           AND r.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'REMINDER_PARAM "' || i_internal_name || '" NOT CONFIGURED, SO THERE IS NOTHING TO DO';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_id_reminder_param;

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
        l_func_name CONSTANT VARCHAR2(30) := 'TF_REMINDER_PARAMS';
        --
        l_ret t_table_reminder_param;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'FILL TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT t_rec_reminder_param(rp.id_reminder,
                                    rp.id_reminder_param,
                                    rp.internal_name,
                                    pk_translation.get_translation(i_lang, rp.code_reminder_param),
                                    rp.id_sys_list_group,
                                    rp.rank) BULK COLLECT
          INTO l_ret
          FROM reminder_param rp
         WHERE rp.id_reminder = i_id_reminder
         ORDER BY rp.rank;
    
        RETURN l_ret;
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
        l_func_name CONSTANT VARCHAR2(30) := 'TF_REMINDER_PARAMS';
        --
        l_reminder reminder.id_reminder%TYPE;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_REMINDER OF "' || i_internal_name || '"';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_reminder := pk_reminder_core.get_id_reminder(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_internal_name => i_internal_name);
    
        g_error := 'CALL TF_REMINDER_PARAMS - ID_REMINDER: ' || l_reminder;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.tf_reminder_params(i_lang => i_lang, i_prof => i_prof, i_id_reminder => l_reminder);
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
        l_func_name CONSTANT VARCHAR2(30) := 'TF_REMINDER_PROF_TEMP';
        --
        l_profile_template reminder_prof_temp.id_profile_template%TYPE;
        l_institution      reminder_prof_temp.id_institution%TYPE;
        l_software         reminder_prof_temp.id_software%TYPE;
        --
        l_error t_error_out;
        l_ret   t_table_reminder_prof_temp;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL GET_REM_PROF_TEMP_VARS FOR: ' || i_id_reminder_param;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_reminder_core.get_rem_prof_temp_vars(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_reminder_param   => i_id_reminder_param,
                                                       i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof),
                                                       o_profile_template => l_profile_template,
                                                       o_institution      => l_institution,
                                                       o_software         => l_software,
                                                       o_error            => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FILL TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT /*+opt_estimate(table syslst rows=1)*/
         t_rec_reminder_prof_temp(rpp.id_reminder_param,
                                  rpp.id_profile_template,
                                  syslst.flg_context,
                                  rpp.id_recurr_option,
                                  rpp.value) BULK COLLECT
          INTO l_ret
          FROM reminder_prof_temp rpp
          JOIN reminder_param rp
            ON rp.id_reminder_param = rpp.id_reminder_param
          LEFT JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, rp.id_sys_list_group)) syslst
            ON syslst.id_sys_list = rpp.id_sys_list
         WHERE rpp.id_reminder_param = i_id_reminder_param
           AND rpp.id_institution = l_institution
           AND rpp.id_software = l_software
              --ATTENTION: Only create recurrence plans to profiles equal to the episode software, 
              --           this automatically excludes parametrization records with id_profile_template = 0
           AND rpp.id_profile_template IN
               (SELECT pt.id_profile_template
                  FROM profile_template pt
                 WHERE pt.id_software = (SELECT ei.id_software
                                           FROM epis_info ei
                                          WHERE ei.id_episode = i_id_episode)
                   AND pt.flg_available = pk_alert_constant.g_yes)
           AND rpp.id_profile_template IN
               (SELECT ptm.id_profile_template
                  FROM profile_template_market ptm
                 WHERE ptm.id_market IN ((SELECT i.id_market
                                           FROM institution i
                                          WHERE i.id_institution = i_prof.institution),
                                         pk_alert_constant.g_id_market_all));
    
        RETURN l_ret;
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
        l_func_name CONSTANT VARCHAR2(30) := 'TF_REMINDER_PROF_TEMP';
        --
        l_reminder_param reminder_param.id_reminder_param%TYPE;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_REMINDER_PARAM OF "' || i_internal_name || '"';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_reminder_param := pk_reminder_core.get_id_reminder_param(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_internal_name => i_internal_name);
    
        g_error := 'CALL TF_REMINDER_PROF_TEMP - ID_REMINDER_PARAM: ' || l_reminder_param;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_reminder_core.tf_reminder_prof_temp(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_reminder_param => l_reminder_param,
                                                      i_id_episode        => i_id_episode);
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
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_TEMP_SELECTED_VALUE';
        --
        l_profile_template reminder_prof_temp.id_profile_template%TYPE;
        l_institution      reminder_prof_temp.id_institution%TYPE;
        l_software         reminder_prof_temp.id_software%TYPE;
        --
        l_error t_error_out;
        l_ret   t_rec_reminder_prof_temp;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL GET_REM_PROF_TEMP_VARS FOR: ' || i_id_reminder_param;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_reminder_core.get_rem_prof_temp_vars(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_reminder_param   => i_id_reminder_param,
                                                       i_profile_template => nvl(i_id_prof_template,
                                                                                 pk_prof_utils.get_prof_profile_template(i_prof)),
                                                       o_profile_template => l_profile_template,
                                                       o_institution      => l_institution,
                                                       o_software         => l_software,
                                                       o_error            => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FILL RETURN RECORD';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT /*+opt_estimate(table syslst rows=1)*/
         t_rec_reminder_prof_temp(rpp.id_reminder_param,
                                  rpp.id_profile_template,
                                  syslst.flg_context,
                                  rpp.id_recurr_option,
                                  rpp.value)
          INTO l_ret
          FROM reminder_prof_temp rpp
          JOIN reminder_param rp
            ON rp.id_reminder_param = rpp.id_reminder_param
          LEFT JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, rp.id_sys_list_group)) syslst
            ON syslst.id_sys_list = rpp.id_sys_list
         WHERE rpp.id_reminder_param = i_id_reminder_param
           AND rpp.id_profile_template = l_profile_template
           AND rpp.id_institution = l_institution
           AND rpp.id_software = l_software;
    
        RETURN l_ret;
    EXCEPTION
        WHEN l_exception THEN
            RETURN NULL;
        WHEN no_data_found THEN
            g_error := 'NO_DATA_FOUND - ID_REMINDER_PARAM: ' || i_id_reminder_param || '; ID_PROFILE_TEMPLATE:' ||
                       l_profile_template || '; ID_INSTITUTION:' || l_institution || '; ID_SOFTWARE:' || l_software;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
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
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_TEMP_SELECTED_VALUE';
        --
        l_reminder_param   reminder_param.id_reminder_param%TYPE;
        l_profile_template reminder_prof_temp.id_profile_template%TYPE;
        l_institution      reminder_prof_temp.id_institution%TYPE;
        l_software         reminder_prof_temp.id_software%TYPE;
        --
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_REMINDER_PARAM OF "' || i_internal_name || '"';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_reminder_param := pk_reminder_core.get_id_reminder_param(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_internal_name => i_internal_name);
    
        RETURN pk_reminder_core.get_prof_temp_selected_value(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_reminder_param => l_reminder_param,
                                                             i_id_prof_template  => i_id_prof_template);
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'REMINDER "' || i_internal_name || '" NOT CONFIGURED, SO THERE IS NOTHING TO DO';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
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
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REMINDER_ROW';
        --
        l_ret   reminder%ROWTYPE;
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := '';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT r.*
          INTO l_ret
          FROM reminder r
         WHERE r.id_reminder = i_id_reminder;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
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
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REMINDER_ROW';
        --
        l_id_reminder reminder.id_reminder%TYPE;
        --
        l_error t_error_out;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ID_REMINDER OF "' || i_internal_name || '"';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_id_reminder := pk_reminder_core.get_id_reminder(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_internal_name => i_internal_name);
    
        RETURN pk_reminder_core.get_reminder_row(i_lang => i_lang, i_prof => i_prof, i_id_reminder => l_id_reminder);
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'REMINDER "' || i_internal_name || '" NOT CONFIGURED, SO THERE IS NOTHING TO DO';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
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
        l_func_name CONSTANT VARCHAR2(30) := 'SET_PROF_TEMP_REMINDER';
        --
        l_rem_param_active     CONSTANT reminder_param.id_reminder_param%TYPE := 1;
        l_rem_param_recurrence CONSTANT reminder_param.id_reminder_param%TYPE := 2;
        --
        l_sys_lst_yes CONSTANT sys_list.id_sys_list%TYPE := 4007;
        l_sys_lst_no  CONSTANT sys_list.id_sys_list%TYPE := 4008;
        --
        PROCEDURE insert_into_reminder_prof_temp
        (
            i_reminder_param   IN reminder_prof_temp.id_reminder_param%TYPE,
            i_profile_template IN reminder_prof_temp.id_profile_template%TYPE,
            i_institution      IN reminder_prof_temp.id_institution%TYPE,
            i_software         IN reminder_prof_temp.id_software%TYPE,
            i_sys_list         IN reminder_prof_temp.id_sys_list%TYPE,
            i_recurr_option    IN reminder_prof_temp.id_recurr_option%TYPE,
            i_value            IN reminder_prof_temp.value%TYPE
        ) IS
        BEGIN
            INSERT INTO reminder_prof_temp
                (id_reminder_param,
                 id_profile_template,
                 id_institution,
                 id_software,
                 id_sys_list,
                 id_recurr_option,
                 VALUE)
            VALUES
                (i_reminder_param, i_profile_template, i_institution, i_software, i_sys_list, i_recurr_option, i_value);
        END insert_into_reminder_prof_temp;
    
        PROCEDURE validate_input_args IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'VALIDATE_INPUT_ARGS';
        BEGIN
            IF i_profile_template IS NULL
               OR i_institution IS NULL
               OR i_software IS NULL
            THEN
                g_error := 'ERROR: ID_PROFILE_TEMPLATE, ID_INSTITUTION AND ID_SOFTWARE are required.';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                raise_application_error(-20001, g_error);
            END IF;
        
            IF i_flg_is_reminder_active = pk_alert_constant.g_yes
               AND i_recurr_option IS NULL
               AND i_value IS NULL
            THEN
                g_error := 'ERROR: You must provide a recurcive option (i.e. I_RECURR_OPTION with a possible value defined in ORDER_RECURR_OPTION table) or set I_VALUE = "BY_EPISODE".';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                raise_application_error(-20002, g_error);
            END IF;
        
            IF i_recurr_option IS NOT NULL
               AND i_value IS NOT NULL
            THEN
                g_error := 'ERROR: Both parameters I_RECURR_OPTION and I_VALUE are filled, please fill only one of them according to the recursive option that you want.';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                raise_application_error(-20003, g_error);
            END IF;
        
            IF i_value IS NOT NULL
               AND i_value != 'BY_EPISODE'
            THEN
                g_error := 'ERROR: I_VALUE not supported, currently only BY_EPISODE value is available.';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                raise_application_error(-20003, g_error);
            END IF;
        END validate_input_args;
    BEGIN
        g_error := 'CALL VALIDATE_INPUT_ARGS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        validate_input_args;
    
        g_error := 'DELETE CURRENT PARAMETRIZATION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        DELETE FROM reminder_prof_temp rpf
         WHERE rpf.id_profile_template = i_profile_template
           AND rpf.id_institution = i_institution
           AND rpf.id_software = i_software;
    
        g_error := 'SETS THE AVAILABILITY OF THE REMINDER FOR THE GIVEN PROFILE TEMPLATE - ' ||
                   i_flg_is_reminder_active;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        insert_into_reminder_prof_temp(i_reminder_param   => l_rem_param_active,
                                       i_profile_template => i_profile_template,
                                       i_institution      => i_institution,
                                       i_software         => i_software,
                                       i_sys_list         => CASE i_flg_is_reminder_active
                                                                 WHEN pk_alert_constant.g_yes THEN
                                                                  l_sys_lst_yes
                                                                 ELSE
                                                                  l_sys_lst_no
                                                             END,
                                       i_recurr_option    => NULL,
                                       i_value            => NULL);
    
        IF i_flg_is_reminder_active = pk_alert_constant.g_yes
        THEN
            g_error := 'SETS THE RECURSIVE OPTION - I_RECURR_OPTION: ' || i_recurr_option || '; I_VALUE: ' || i_value;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            insert_into_reminder_prof_temp(i_reminder_param   => l_rem_param_recurrence,
                                           i_profile_template => i_profile_template,
                                           i_institution      => i_institution,
                                           i_software         => i_software,
                                           i_sys_list         => NULL,
                                           i_recurr_option    => i_recurr_option,
                                           i_value            => i_value);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 2,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_prof_temp_reminder;
BEGIN
    -- Initialization
    g_sysdate_tstz := current_timestamp;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_reminder_core;
/
