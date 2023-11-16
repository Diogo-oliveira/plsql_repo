/*-- Last Change Revision: $Rev: 1994816 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-07-21 11:46:01 +0100 (qua, 21 jul 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_cancel_reason IS
    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area.
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/27
    *
    * @changed  Sergio Dias
    * @version  2.6.1
    * @since    2011/01/17
    */
    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN cancel_rea_area.intern_name%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(64) := 'GET_CANCEL_REASON_LIST';
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'GET_CANCEL_REASON_LIST GET_TEMPLATE';
        pk_alertlog.log_debug(g_error);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
        g_error               := 'GET REASONS';
        pk_alertlog.log_debug(g_error);
        OPEN o_reasons FOR
            SELECT id_cancel_reason, cancel_reason_desc, notes_mandatory
              FROM (SELECT cr.id_cancel_reason id_cancel_reason,
                           nvl2(rsi.desc_synonym,
                                rsi.desc_synonym,
                                pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason_desc,
                           cr.flg_notes_mandatory notes_mandatory,
                           rank() over(PARTITION BY crsi.id_cancel_reason ORDER BY crsi.id_profile_template DESC, crsi.id_institution DESC, crsi.id_software DESC) origin_rank
                      FROM cancel_reason cr
                      LEFT JOIN reason_synonym_inst rsi
                        ON rsi.id_reason = cr.id_cancel_reason
                       AND rsi.id_institution = i_prof.institution
                      JOIN reason_action_relation rar
                        ON rar.id_reason = cr.id_cancel_reason
                      JOIN reason_action ra
                        ON ra.id_action = rar.id_action
                       AND ra.flg_type = c_reason_action_cancel
                      JOIN cancel_rea_soft_inst crsi
                        ON crsi.id_cancel_reason = cr.id_cancel_reason
                      JOIN cancel_rea_area cra
                        ON cra.id_cancel_rea_area = crsi.id_cancel_rea_area
                     WHERE upper(cra.intern_name) = upper(i_area)
                       AND crsi.id_profile_template IN (0, l_id_profile_template)
                       AND crsi.id_software IN (0, i_prof.software)
                       AND crsi.id_institution IN (0, i_prof.institution)
                       AND crsi.flg_available = pk_alert_constant.get_yes
                     ORDER BY crsi.rank ASC, cr.rank ASC, cancel_reason_desc ASC)
             WHERE origin_rank = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cancel_reason_list;

    /**
    * Gets the description of a specific cancel reason identifier.
    * Avoid using this function inside a query!
    * It's better to get the description using the code_cancel_reason field
    *
    * @param i_lang             Language identifier.
    * @param i_id_cancel_reason The cancel reason area.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/27
    *
    * @changed  Sergio Dias
    * @version  2.6.1
    * @since    2011/01/17
    */
    FUNCTION get_cancel_reason_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_cancel_reason_desc';
        l_result pk_translation.t_desc_translation;
    
    BEGIN
        l_result := NULL;
        IF i_id_cancel_reason IS NOT NULL
           AND i_id_cancel_reason <> 0
        THEN
            g_error := 'SELECT FROM cancel_reason';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
            SELECT nvl2(rsi.desc_synonym,
                        rsi.desc_synonym,
                        pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason_desc
              INTO l_result
              FROM cancel_reason cr
              LEFT JOIN reason_synonym_inst rsi
                ON rsi.id_reason = cr.id_cancel_reason
               AND rsi.id_institution = i_prof.institution
             WHERE cr.id_cancel_reason = i_id_cancel_reason;
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'No cancel reason was found with ID_CANCEL_REASON = ' || to_char(i_id_cancel_reason) || chr(10);
            g_error := g_error || 'Input arguments:';
            g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
            g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
            g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
            g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
            g_error := g_error || ' i_id_cancel_reason = ' || coalesce(to_char(i_id_cancel_reason), '<null>');
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
            -- Unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => k_function_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            RETURN NULL;
    END get_cancel_reason_desc;

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area.
    * @param i_flg_action_type   Reason type, values: C - cancel, S - suspend, R - refuse, O - other, D - discontinue, T - return
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sergio Dias
    * @version  2.6.1.
    * @since    8-04-2011
    */
    FUNCTION get_reason_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_area            IN cancel_rea_area.intern_name%TYPE,
        i_flg_action_type IN reason_action.flg_type%TYPE,
        o_reasons         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_REASON_LIST';
    BEGIN
    
        RETURN get_reason_list_by_id(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_area            => i_area,
                                     i_flg_action_type => i_flg_action_type,
                                     i_id_reason       => NULL,
                                     o_reasons         => o_reasons,
                                     o_error           => o_error);
    END get_reason_list;

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang              Language identifier.
    * @param i_prof              The professional record.
    * @param i_area              The cancel reason area.
    * @param i_flg_action_type   Reason type, values: C - cancel, S - suspend, R - refuse, O - other, D - discontinue, T - return
    * @param i_id_reason         List of reason ids
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sergio Dias
    * @version  2.6.1.
    * @since    8-04-2011
    */
    FUNCTION get_reason_list_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_area            IN cancel_rea_area.intern_name%TYPE,
        i_flg_action_type IN reason_action.flg_type%TYPE,
        i_id_reason       IN table_number DEFAULT NULL,
        o_reasons         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(64) := 'GET_REASON_LIST';
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error := 'GET_REASON_LIST GET_PROF_TEMPLATE';
        pk_alertlog.log_debug(g_error);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'GET REASONS';
        pk_alertlog.log_debug(g_error);
        OPEN o_reasons FOR
            SELECT id_reason, reason_desc, notes_mandatory, flg_error
              FROM (SELECT cr.id_cancel_reason id_reason,
                           nvl2(rsi.desc_synonym,
                                rsi.desc_synonym,
                                pk_translation.get_translation(i_lang, cr.code_cancel_reason)) reason_desc,
                           cr.flg_notes_mandatory notes_mandatory,
                           rank() over(PARTITION BY crsi.id_cancel_reason ORDER BY crsi.id_profile_template DESC, crsi.id_institution DESC, crsi.id_software DESC) origin_rank,
                           crsi.flg_error
                      FROM cancel_reason cr
                      LEFT JOIN reason_synonym_inst rsi
                        ON rsi.id_reason = cr.id_cancel_reason
                       AND rsi.id_institution = i_prof.institution
                      JOIN reason_action_relation rar
                        ON rar.id_reason = cr.id_cancel_reason
                      JOIN reason_action ra
                        ON ra.id_action = rar.id_action
                       AND ra.flg_type = i_flg_action_type
                      JOIN cancel_rea_soft_inst crsi
                        ON crsi.id_cancel_reason = cr.id_cancel_reason
                      JOIN cancel_rea_area cra
                        ON cra.id_cancel_rea_area = crsi.id_cancel_rea_area
                     WHERE upper(cra.intern_name) = upper(i_area)
                       AND crsi.id_profile_template IN (0, l_id_profile_template)
                       AND crsi.id_software IN (0, i_prof.software)
                       AND crsi.id_institution IN (0, i_prof.institution)
                       AND crsi.flg_available = pk_alert_constant.get_yes
                       AND (i_id_reason IS NULL OR
                            cr.id_cancel_reason IN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                                                     column_value AS cv
                                                      FROM TABLE(i_id_reason) t))
                     ORDER BY nvl(crsi.rank, 0) ASC, nvl(cr.rank, 0) ASC, reason_desc ASC)
             WHERE origin_rank = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_reason_list_by_id;

    FUNCTION get_id_by_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_cnt  IN cancel_reason.id_content%TYPE
    ) RETURN cancel_reason.id_cancel_reason%TYPE IS
        l_ret cancel_reason.id_cancel_reason%TYPE;
    BEGIN
        SELECT cr.id_cancel_reason
          INTO l_ret
          FROM cancel_reason cr
         WHERE cr.id_content = i_cnt;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_by_content;

    FUNCTION get_content_by_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE
    ) RETURN cancel_reason.id_content%TYPE IS
        l_ret cancel_reason.id_content%TYPE;
    BEGIN
        SELECT cr.id_content
          INTO l_ret
          FROM cancel_reason cr
         WHERE cr.id_cancel_reason = i_id_cancel_reason;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_content_by_id;

    /**
    * Gets existing cancel configurations by task_type
    * 
    * @param i_lang                          Language identifier.
    * @param i_prof                          The professional record.
    * @param i_task_type                     The task type related with area.
    * @param o_flg_cancel_reas_mandatory     Cancel reason configuration value (Y- cancel reason will be shown, N-Otherwise). 
    * @param o_flg_priority_mandatory        Priority configuration value (Y- priority will be shown , N-Otherwise)
    * @param o_priority_default_value        Default priority value (Y- Checked, N- Otherwise). 
    * @param o_error                         Message to be shown to the user.
    *
    * @return  Y - Cancel reason is mandatory, will be shown in cancel screen; N - Isn't mandatory. 
    *
    * @author   Gisela Couto
    * @version  2.6.4.3
    * @since    27-11-2014
    */
    FUNCTION get_cancel_configurations
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_task_type                 IN task_type.id_task_type%TYPE,
        i_action                    IN NUMBER DEFAULT NULL,
        o_flg_cancel_reas_mandatory OUT VARCHAR2, --i_field_01
        o_flg_priority_mandatory    OUT VARCHAR2, --i_field_02
        o_priority_default_value    OUT VARCHAR2, --i_field_03
        o_flg_date_visible          OUT VARCHAR2, --i_field_04
        o_date_mandatory            OUT VARCHAR2, --i_field_05 
        o_min_date                  OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_func_name           VARCHAR2(100) := 'GET_CANCEL_CONFIGURATIONS';
        l_id_task_type_action task_type_actions.id_task_type_action%TYPE;
        l_id_action           action.id_action%TYPE;
    
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_episode,
                                                o_dt_begin   => o_min_date,
                                                o_error      => o_error)
            THEN
                g_error                     := 'NO DATA FOUNDED';
                o_flg_cancel_reas_mandatory := pk_alert_constant.g_yes;
                o_flg_priority_mandatory    := pk_alert_constant.g_no;
                o_priority_default_value    := NULL;
                o_flg_date_visible          := pk_alert_constant.g_no;
                o_date_mandatory            := NULL;
                RETURN TRUE;
            END IF;
        END IF;
        IF i_action IS NULL
        THEN
            BEGIN
                SELECT tta.id_task_type_action
                  INTO l_id_task_type_action
                  FROM task_type_actions tta
                 WHERE tta.id_task_type = i_task_type
                   AND tta.id_action IN (pk_cancel_reason.c_id_action_default,
                                         pk_cancel_reason.c_id_action_com_order,
                                         pk_cancel_reason.c_id_action_med);
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_task_type_action := 0;
            END;
        ELSE
            BEGIN
                SELECT tta.id_task_type_action
                  INTO l_id_task_type_action
                  FROM task_type_actions tta
                 WHERE tta.id_task_type = i_task_type
                   AND tta.id_action = i_action;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_task_type_action := 0;
            END;
        END IF;
        g_error := 'GETTING CONFIGURATIONS BY PK_CORE_CONFIG.TF_CONFIG';
        BEGIN
            SELECT flg_cancel_reas_mandatory,
                   flg_priority_mandatory,
                   priority_default_value,
                   flg_date_visble,
                   date_mandatory
              INTO o_flg_cancel_reas_mandatory,
                   o_flg_priority_mandatory,
                   o_priority_default_value,
                   o_flg_date_visible,
                   o_date_mandatory
              FROM (SELECT cfg.field_01 flg_cancel_reas_mandatory,
                           cfg.field_02 flg_priority_mandatory,
                           cfg.field_03 priority_default_value,
                           nvl(cfg.field_04, pk_alert_constant.g_no) flg_date_visble,
                           cfg.field_05 date_mandatory,
                           row_number() over(PARTITION BY cfg.id_config ORDER BY cfg.id_record DESC) row_number
                      FROM TABLE(pk_core_config.tf_config(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_config_table => c_canc_reas_conf_tab)) cfg
                     WHERE cfg.id_record IN (0, nvl(l_id_task_type_action, 0)))
             WHERE row_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                g_error                     := 'NO DATA FOUNDED';
                o_flg_cancel_reas_mandatory := pk_alert_constant.g_yes;
                o_flg_priority_mandatory    := pk_alert_constant.g_no;
                o_priority_default_value    := NULL;
                o_flg_date_visible          := pk_alert_constant.g_no;
                o_date_mandatory            := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            o_flg_cancel_reas_mandatory := pk_alert_constant.g_yes;
            o_flg_priority_mandatory    := pk_alert_constant.g_no;
            o_priority_default_value    := NULL;
            o_flg_date_visible          := pk_alert_constant.g_no;
            o_date_mandatory            := NULL;
        
            RETURN FALSE;
    END get_cancel_configurations;

    /**
    * Gets existing cancel configurations by task_type
    * 
    * @param i_lang                          Language identifier.
    * @param i_prof                          The professional record.
    * @param i_tbl_task_type                 The array of task types related with the areas.
    * @param o_flg_cancel_reas_mandatory     Cancel reason configuration value (Y- cancel reason will be shown, N-Otherwise). 
    * @param o_flg_priority_mandatory        Priority configuration value (Y- priority will be shown , N-Otherwise)
    * @param o_priority_default_value        Default priority value (Y- Checked, N- Otherwise). 
    * @param o_error                         Message to be shown to the user.
    *
    * @return  Y - Cancel reason is mandatory, will be shown in cancel screen; N - Isn't mandatory. 
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    16-03-2015
    * based on get_cancel_configurations but receiving an array of task types
    */
    FUNCTION get_cancel_configurations
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_tbl_task_type             IN table_number,
        i_action                    IN NUMBER DEFAULT NULL,
        o_flg_cancel_reas_mandatory OUT VARCHAR2, --i_field_01
        o_flg_priority_mandatory    OUT VARCHAR2, --i_field_02
        o_priority_default_value    OUT VARCHAR2, --i_field_03
        o_flg_date_visible          OUT VARCHAR2, --i_field_04
        o_date_mandatory            OUT VARCHAR2, --i_field_05
        o_min_date                  OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_func_name                VARCHAR2(100) := 'GET_CANCEL_CONFIGURATIONS';
        l_flg_cancel_reas_mand_tab table_varchar := table_varchar();
        l_flg_priority_mand_tab    table_varchar := table_varchar();
        l_priority_default_val_tab table_varchar := table_varchar();
        l_date_mandatory           table_varchar := table_varchar();
        l_flg_date_visible         table_varchar := table_varchar();
        l_id_task_type_action      table_number;
    BEGIN
    
        -- get episode begin date
        IF i_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_episode,
                                                o_dt_begin   => o_min_date,
                                                o_error      => o_error)
            THEN
                g_error                     := 'NO DATA FOUNDED';
                o_flg_cancel_reas_mandatory := pk_alert_constant.g_yes;
                o_flg_priority_mandatory    := pk_alert_constant.g_no;
                o_priority_default_value    := NULL;
                o_flg_date_visible          := pk_alert_constant.g_no;
                o_date_mandatory            := NULL;
                RETURN TRUE;
            END IF;
        END IF;
        IF i_action IS NULL -- if id_action is null 
        THEN
            SELECT tta.id_task_type_action
              BULK COLLECT
              INTO l_id_task_type_action
              FROM task_type_actions tta
             WHERE tta.id_task_type IN (SELECT column_value
                                          FROM TABLE(i_tbl_task_type))
               AND tta.id_action IN (pk_cancel_reason.c_id_action_default,
                                     pk_cancel_reason.c_id_action_com_order,
                                     pk_cancel_reason.c_id_action_med);
        ELSE
            -- get task type action for a given id_action 
            SELECT tta.id_task_type_action
              BULK COLLECT
              INTO l_id_task_type_action
              FROM task_type_actions tta
             WHERE tta.id_task_type IN (SELECT column_value
                                          FROM TABLE(i_tbl_task_type))
               AND tta.id_action = i_action;
        
        END IF;
        g_error := 'GETTING CONFIGURATIONS BY PK_CORE_CONFIG.TF_CONFIG';
        BEGIN
            SELECT flg_cancel_reas_mandatory,
                   flg_priority_mandatory,
                   priority_default_value,
                   flg_date_visible,
                   flg_date_mandatory
              BULK COLLECT
              INTO l_flg_cancel_reas_mand_tab,
                   l_flg_priority_mand_tab,
                   l_priority_default_val_tab,
                   l_flg_date_visible,
                   l_date_mandatory
              FROM (SELECT cfg.field_01 flg_cancel_reas_mandatory,
                           cfg.field_02 flg_priority_mandatory,
                           cfg.field_03 priority_default_value,
                           nvl(cfg.field_04, pk_alert_constant.g_no) flg_date_visible,
                           cfg.field_05 flg_date_mandatory,
                           row_number() over(PARTITION BY cfg.id_config ORDER BY cfg.id_record DESC) row_number
                      FROM TABLE(pk_core_config.tf_config(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_config_table => c_canc_reas_conf_tab)) cfg
                     WHERE cfg.id_record IN (SELECT 0
                                               FROM dual
                                             UNION ALL
                                             SELECT column_value
                                               FROM TABLE(l_id_task_type_action)))
             WHERE row_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                g_error                     := 'NO DATA FOUNDED';
                o_flg_cancel_reas_mandatory := pk_alert_constant.g_yes;
                o_flg_priority_mandatory    := pk_alert_constant.g_no;
                o_priority_default_value    := NULL;
                o_flg_date_visible          := pk_alert_constant.g_no;
                o_date_mandatory            := NULL;
            
                RETURN TRUE;
        END;
    
        -- Check if some of the task types has cancel reasons as mandatory
        BEGIN
            SELECT t.column_value
              INTO o_flg_cancel_reas_mandatory
              FROM TABLE(l_flg_cancel_reas_mand_tab) t
             WHERE t.column_value = pk_alert_constant.g_yes
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_cancel_reas_mandatory := pk_alert_constant.g_no;
        END;
    
        -- Check if some of the task types has priority as mandatory
        BEGIN
            SELECT t.column_value
              INTO o_flg_priority_mandatory
              FROM TABLE(l_flg_priority_mand_tab) t
             WHERE t.column_value = pk_alert_constant.g_yes
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_priority_mandatory := pk_alert_constant.g_no;
        END;
    
        -- Check if some of the task types has a priority as mandatory
        IF o_flg_priority_mandatory = pk_alert_constant.g_no
        THEN
            o_priority_default_value := NULL;
        ELSE
            BEGIN
                SELECT t.column_value
                  INTO o_priority_default_value
                  FROM TABLE(l_priority_default_val_tab) t
                 WHERE t.column_value = pk_alert_constant.g_yes
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_priority_default_value := pk_alert_constant.g_no;
            END;
        END IF;
    
        -- Check if some of the task types has date as visible
        BEGIN
            SELECT t.column_value
              INTO o_flg_date_visible
              FROM TABLE(l_flg_date_visible) t
             WHERE t.column_value = pk_alert_constant.g_yes
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_date_visible := pk_alert_constant.g_no;
        END;
    
        -- Check if some of the task types has a priority as mandatory
        IF o_flg_date_visible = pk_alert_constant.g_no
        THEN
            o_date_mandatory := NULL;
        ELSE
            BEGIN
                SELECT t.column_value
                  INTO o_date_mandatory
                  FROM TABLE(l_date_mandatory) t
                 WHERE t.column_value = pk_alert_constant.g_yes
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_date_mandatory := pk_alert_constant.g_no;
            END;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            o_flg_cancel_reas_mandatory := pk_alert_constant.g_yes;
            o_flg_priority_mandatory    := pk_alert_constant.g_no;
            o_flg_date_visible          := pk_alert_constant.g_no;
            o_date_mandatory            := NULL;
        
            RETURN FALSE;
    END get_cancel_configurations;

    /**
    * Saves information about cancel reason configuration.
    *
    * @param i_id_config                   Config table identifier (config_table).
    * @param i_task_type                   The task type related with area.
    * @param i_id_inst_owner               Institution identifier.
    * @param i_flg_add_remove              Flag add/remove.
    * @param i_flg_cancel_reas_mandatory   Cancel reason configuration value. 
    * @param i_flg_priority_mandatory      Priority configuration value.
    * @param i_priority_default_value      Default priority value (Y- Checked, N- Otherwise). 
    *
    * @value i_flg_cancel_reas_mandatory   Y - Cancel reason field will be shown
    *                                      N - Otherwise
    * @value i_flg_priority_mandatory      Y - Priority field will be shown
    *                                      N - Otherwise
    * @value i_priority_default_value      Y - Priority field checked
    *                                      N - Otherwise
    *
    * @value i_flg_discontinue_date        Y - Discontinue date  field will be shown
    *                                      N - Otherwise
    *
    
    * @author   Gisela Couto
    * @version  2.6.4.3
    * @since    27-11-2014
    */
    PROCEDURE insert_cancel_reason_config
    (
        i_id_config                 IN NUMBER,
        i_task_type                 IN task_type.id_task_type%TYPE,
        i_action                    IN action.id_action%TYPE DEFAULT NULL,
        i_id_inst_owner             IN institution.id_institution%TYPE DEFAULT pk_alert_constant.g_inst_all,
        i_flg_add_remove            IN VARCHAR2 DEFAULT pk_alert_constant.g_active,
        i_flg_cancel_reas_mandatory IN VARCHAR2, --i_field_01
        i_flg_priority_mandatory    IN VARCHAR2, --i_field_02
        i_priority_default_value    IN VARCHAR2 DEFAULT NULL, --i_field_03
        i_flg_date_visible          IN VARCHAR2 DEFAULT NULL, -- i_field_4
        i_date_mandatory            IN VARCHAR2 DEFAULT NULL -- i_field_5
    ) IS
        l_priority_default_value VARCHAR(1 CHAR);
        l_date_mandatory         VARCHAR(1 CHAR);
        --
        l_func_name           VARCHAR2(100) := 'INSERT_CANCEL_REASON_CONFIG';
        l_id_task_type_action task_type_actions.id_task_type_action%TYPE;
        l_id_action           action.id_action%TYPE;
    
    BEGIN
    
        l_priority_default_value := i_priority_default_value;
        l_date_mandatory         := i_date_mandatory;
    
        g_error := 'VALIDATE CONFIGURATION DATA';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        IF i_flg_cancel_reas_mandatory NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20003,
                                    'I_FLG_CANCEL_REAS_MANDATORY POSSIBLE VALUES ARE: "' || pk_alert_constant.g_yes ||
                                    '", "' || pk_alert_constant.g_no || '"');
        ELSIF i_flg_priority_mandatory NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
              OR i_priority_default_value NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20003,
                                    'I_FLG_PRIORITY_MANDATORY,I_PRIORITY_DEFAULT_VALUE  POSSIBLE VALUES ARE: "' ||
                                    pk_alert_constant.g_yes || '", "' || pk_alert_constant.g_no || '"');
        END IF;
    
        IF i_flg_priority_mandatory = pk_alert_constant.g_yes
           AND i_priority_default_value NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20003,
                                    'I_FLG_PRIORITY_MANDATORY VALUE IS YES. THE I_PRIORITY_DEFAULT_VALUE MUST BE "' ||
                                    pk_alert_constant.g_yes || '", "' || pk_alert_constant.g_no || '" - CHECKED OR NOT');
        
        ELSIF i_flg_priority_mandatory = pk_alert_constant.g_no
              AND i_priority_default_value IS NOT NULL
        THEN
            l_priority_default_value := NULL;
        END IF;
    
        IF i_flg_date_visible = pk_alert_constant.g_yes
           AND i_date_mandatory NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20003,
                                    'I_FLG_DATE_VISIBLE VALUE IS YES. THE I_DATE_MANDATORY MUST BE "' ||
                                    pk_alert_constant.g_yes || '", "' || pk_alert_constant.g_no || '" - CHECKED OR NOT');
        
        ELSIF i_flg_date_visible = pk_alert_constant.g_no
              AND i_date_mandatory IS NOT NULL
        THEN
            l_date_mandatory := NULL;
        END IF;
    
        IF i_action IS NULL
        THEN
            BEGIN
                SELECT tta.id_task_type_action
                  INTO l_id_task_type_action
                  FROM task_type_actions tta
                 WHERE tta.id_task_type = i_task_type
                   AND tta.id_action IN (pk_cancel_reason.c_id_action_default,
                                         pk_cancel_reason.c_id_action_com_order,
                                         pk_cancel_reason.c_id_action_med);
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_task_type_action := 0;
            END;
        ELSE
            BEGIN
                SELECT tta.id_task_type_action
                  INTO l_id_task_type_action
                  FROM task_type_actions tta
                 WHERE tta.id_task_type = i_task_type
                   AND tta.id_action = i_action;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_task_type_action := 0;
            END;
        END IF;
        g_error := 'CALL PK_CORE_CONFIG.INSERT_INTO_CONFIG_TABLE';
        pk_core_config.insert_into_config_table(i_config_table   => c_canc_reas_conf_tab,
                                                i_id_record      => l_id_task_type_action,
                                                i_id_inst_owner  => i_id_inst_owner,
                                                i_id_config      => i_id_config,
                                                i_flg_add_remove => i_flg_add_remove,
                                                i_field_01       => i_flg_cancel_reas_mandatory,
                                                i_field_02       => i_flg_priority_mandatory,
                                                i_field_03       => i_priority_default_value,
                                                i_field_04       => i_flg_date_visible,
                                                i_field_05       => l_date_mandatory);
    END insert_cancel_reason_config;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_cancel_reason;
/
