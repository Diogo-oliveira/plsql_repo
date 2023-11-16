/*-- Last Change Revision: $Rev: 2044184 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2022-08-05 10:56:47 +0100 (sex, 05 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_workflow AS

    g_error_dummy t_error_out;

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_found  BOOLEAN;
    g_retval BOOLEAN;
    g_error  VARCHAR2(1000 CHAR);
    g_exception EXCEPTION;

    TYPE t_wf_action_cur IS REF CURSOR RETURN wf_action%ROWTYPE;

    /**
    * Get status color
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    * @param   i_field                Color field
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE,
        i_field     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(50 CHAR);
        l_colors table_varchar;
    BEGIN
        g_error := 'Call get_color / i_color_str=' || i_color_str || ' i_field=' || i_field;
        IF i_color_str IS NOT NULL
        THEN
            SELECT pk_utils.str_split_c(p_list => i_color_str, p_delim => ':')
              INTO l_colors
              FROM dual;
        
            CASE i_field
                WHEN 'GRID_BG_COLOR' THEN
                    l_result := l_colors(1);
                WHEN 'GRID_FG_COLOR' THEN
                    l_result := l_colors(2);
                WHEN 'OTHER_BG_COLOR' THEN
                    l_result := l_colors(3);
                WHEN 'OTHER_FG_COLOR' THEN
                    l_result := l_colors(4);
                ELSE
                    NULL;
            END CASE;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_color / ' || 'i_color_str=' || i_color_str || ' i_field=' || i_field || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_color;

    /**
    * Get grid backgroud color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */

    FUNCTION get_grid_bg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'Call get_grid_bg_color / i_color_str=' || i_color_str;
        RETURN get_color(i_lang => i_lang, i_prof => i_prof, i_color_str => i_color_str, i_field => 'GRID_BG_COLOR');
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_grid_bg_color / ' || 'i_color_str=' || i_color_str || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_grid_bg_color;

    /**
    * Get grid foreground color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_grid_fg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'Call get_grid_fg_color / i_color_str=' || i_color_str;
        RETURN get_color(i_lang => i_lang, i_prof => i_prof, i_color_str => i_color_str, i_field => 'GRID_FG_COLOR');
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_grid_fg_color / ' || 'i_color_str=' || i_color_str || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_grid_fg_color;

    /**
    * Get other backgroud color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_other_bg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'Call get_other_bg_color / i_color_str=' || i_color_str;
        RETURN get_color(i_lang => i_lang, i_prof => i_prof, i_color_str => i_color_str, i_field => 'OTHER_BG_COLOR');
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_other_bg_color / ' || 'i_color_str=' || i_color_str || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_other_bg_color;

    /**
    * Get other foreground color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_other_fg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'Call get_other_fg_color / i_color_str=' || i_color_str;
        RETURN get_color(i_lang => i_lang, i_prof => i_prof, i_color_str => i_color_str, i_field => 'OTHER_FG_COLOR');
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_other_fg_color / ' || 'i_color_str=' || i_color_str || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_other_fg_color;

    /**
    * Checks if transition is available and returns transition info (used internally)
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Initial Transition status
    * @param   i_id_status_end        End Transition status
    * @param   i_id_workflow_action   Transition action   
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_flg_available        Returns transition availability: {*} Y - transition available {*} N - otherwise
    * @param   o_transition_info      Transition info
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-03-2009
    */
    FUNCTION check_transition_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition_config.id_status_end%TYPE,
        i_id_workflow_action  IN wf_transition_config.id_workflow_action%TYPE, -- ACM, 2010-10-12: ALERT-75390
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_flg_available       OUT NOCOPY VARCHAR2,
        o_transition_info     OUT NOCOPY t_rec_wf_trans_config,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_transition_config IS
            SELECT *
              FROM (SELECT *
                      FROM wf_transition_config wtc
                     WHERE wtc.id_software IN (0, i_prof.software)
                       AND wtc.id_institution IN (0, i_prof.institution)
                       AND wtc.id_category IN (0, i_id_category)
                       AND wtc.id_profile_template IN (0, i_id_profile_template)
                       AND wtc.id_functionality IN (0, i_id_functionality)
                       AND wtc.id_status_begin = i_id_status_begin
                       AND wtc.id_status_end = i_id_status_end
                       AND wtc.id_workflow_action = i_id_workflow_action
                       AND wtc.id_workflow = i_id_workflow
                     ORDER BY id_institution      DESC,
                              id_software         DESC,
                              id_category         DESC,
                              id_profile_template DESC,
                              id_functionality    DESC)
             WHERE rownum = 1;
    
        l_transition_config_row c_transition_config%ROWTYPE;
    
        l_func   VARCHAR2(1000 CHAR);
        l_sql    VARCHAR2(32767);
        l_cursor pk_types.cursor_type;
    BEGIN
    
        g_error := 'Init check_transition_int / WF=' || i_id_workflow || ' BEG=' || i_id_status_begin || ' END=' ||
                   i_id_status_end || ' ACTION=' || i_id_workflow_action || ' CAT=' || i_id_category || ' PRF_TEMPL=' ||
                   i_id_profile_template || ' FUNC=' || i_id_functionality || ' PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
    
        o_flg_available := pk_alert_constant.g_no;
    
        -- checking valid transitions for professional
        g_error := 'OPEN c_transition_config';
        OPEN c_transition_config;
    
        g_error := 'FETCH c_transition_config';
        FETCH c_transition_config
            INTO l_transition_config_row;
        g_found := c_transition_config%FOUND;
    
        g_error := 'CLOSE c_transition_config';
        CLOSE c_transition_config;
    
        IF NOT g_found
        THEN
            -- transition not allowed for professional
            g_error := 'Transition not allowed. WF=' || i_id_workflow || ' BEG=' || i_id_status_begin || ' END=' ||
                       i_id_status_end || ' ACTION=' || i_id_workflow_action || ' CAT=' || i_id_category ||
                       ' PRF_TEMPL=' || i_id_profile_template || ' FUNC=' || i_id_functionality || ' PARAM=' ||
                       pk_utils.to_string(i_param);
            pk_alertlog.log_info(g_error);
        ELSE
        
            IF l_transition_config_row.function IS NULL
            THEN
            
                IF l_transition_config_row.flg_permission = g_transition_allow
                THEN
                    -- transition allowed for professional
                    g_error         := 'FUNCTION IS NULL';
                    o_flg_available := pk_alert_constant.g_yes;
                
                    o_transition_info.id_status_begin     := l_transition_config_row.id_status_begin;
                    o_transition_info.id_status_end       := l_transition_config_row.id_status_end;
                    o_transition_info.id_workflow_action  := l_transition_config_row.id_workflow_action;
                    o_transition_info.id_workflow         := l_transition_config_row.id_workflow;
                    o_transition_info.id_software         := l_transition_config_row.id_software;
                    o_transition_info.id_institution      := l_transition_config_row.id_institution;
                    o_transition_info.id_profile_template := l_transition_config_row.id_profile_template;
                    o_transition_info.id_functionality    := l_transition_config_row.id_functionality;
                    o_transition_info.function            := l_transition_config_row.function;
                    o_transition_info.rank                := l_transition_config_row.rank;
                    o_transition_info.flg_permission      := l_transition_config_row.flg_permission;
                    o_transition_info.icon                := l_transition_config_row.icon;
                    o_transition_info.flg_visible         := l_transition_config_row.flg_visible;
                ELSE
                    -- transition not allowed for professional
                    g_error := 'Transition not allowed (2). WF=' || i_id_workflow || ' BEG=' || i_id_status_begin ||
                               ' END=' || i_id_status_end || ' ACTION=' || i_id_workflow_action || ' CAT=' ||
                               i_id_category || ' PRF_TEMPL=' || i_id_profile_template || ' FUNC=' ||
                               i_id_functionality || ' PARAM=' || pk_utils.to_string(i_param);
                    pk_alertlog.log_info(g_error);
                END IF;
            
            ELSIF l_transition_config_row.function IS NOT NULL
            THEN
                -- evaluating FUNCTION [must return VARCHAR2: (A)llow, (D)eny]
                -- PK_PACKAGE.function_name(@LANG, profissional(@PROFESSIONAL,@INSTITUTION,@SOFTWARE),@WORKFLOW,@BEGIN,@END,@ACTION,
                --@CAT,@PROF_TEMPL,@FUNC,@PARAM)
            
                g_error := 'l_func';
                l_func  := l_transition_config_row.function;
                l_func  := REPLACE(l_func, '@LANG', ':1');
                l_func  := REPLACE(l_func, '@PROFESSIONAL', ':2');
                l_func  := REPLACE(l_func, '@INSTITUTION', ':3');
                l_func  := REPLACE(l_func, '@SOFTWARE', ':4');
                l_func  := REPLACE(l_func, '@WORKFLOW', ':5');
                l_func  := REPLACE(l_func, '@BEGIN', ':6');
                l_func  := REPLACE(l_func, '@END', ':7');
                l_func  := REPLACE(l_func, '@ACTION', ':8');
                l_func  := REPLACE(l_func, '@CAT', ':9');
                l_func  := REPLACE(l_func, '@PROF_TEMPL', ':10');
                l_func  := REPLACE(l_func, '@FUNC', ':11');
            
                g_error := 'l_param';
                l_func  := REPLACE(l_func, '@PARAM', ':12');
            
                g_error := 'l_sql:' || l_func;
                l_sql   := 'SELECT ' || l_func || ' FROM dual';
            
                OPEN l_cursor FOR l_sql
                    USING to_char(i_lang), -- LANG
                to_char(i_prof.id), -- PROFESSIONAL
                to_char(i_prof.institution), -- INSTITUTION
                to_char(i_prof.software), -- SOFTWARE
                to_char(i_id_workflow), -- WORKFLOW
                to_char(i_id_status_begin), -- BEGIN
                to_char(i_id_status_end), -- END
                to_char(i_id_workflow_action), -- ACTION
                to_char(i_id_category), --CAT
                to_char(i_id_profile_template), -- PROF_TEMPL
                to_char(i_id_functionality), -- FUNC
                i_param -- PARAM
                ;
            
                g_error := 'FETCH l_cursor';
                FETCH l_cursor
                    INTO l_transition_config_row.flg_permission;
                CLOSE l_cursor;
            
                IF l_transition_config_row.flg_permission = g_transition_allow
                THEN
                    -- transition allowed for professional
                    g_error         := 'FUNCTION IS NOT NULL';
                    o_flg_available := pk_alert_constant.g_yes;
                
                    o_transition_info.id_workflow         := l_transition_config_row.id_workflow;
                    o_transition_info.id_status_begin     := l_transition_config_row.id_status_begin;
                    o_transition_info.id_status_end       := l_transition_config_row.id_status_end;
                    o_transition_info.id_workflow_action  := l_transition_config_row.id_workflow_action;
                    o_transition_info.id_software         := l_transition_config_row.id_software;
                    o_transition_info.id_institution      := l_transition_config_row.id_institution;
                    o_transition_info.id_profile_template := l_transition_config_row.id_profile_template;
                    o_transition_info.id_functionality    := l_transition_config_row.id_functionality;
                    o_transition_info.function            := l_transition_config_row.function;
                    o_transition_info.rank                := l_transition_config_row.rank;
                    o_transition_info.flg_permission      := l_transition_config_row.flg_permission;
                    o_transition_info.icon                := l_transition_config_row.icon;
                    o_transition_info.flg_visible         := l_transition_config_row.flg_visible;
                ELSE
                    -- transition not allowed for professional
                    pk_alertlog.log_debug(l_sql);
                    g_error := 'Transition not allowed (3). WF=' || i_id_workflow || ' BEG=' || i_id_status_begin ||
                               ' ACTION=' || i_id_workflow_action || ' CAT=' || i_id_category || ' PRF=' ||
                               i_id_profile_template || ' FUNC=' || i_id_functionality;
                    pk_alertlog.log_info(g_error);
                END IF;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_TRANSITION_INT',
                                              o_error    => o_error);
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            IF c_transition_config%ISOPEN
            THEN
                CLOSE c_transition_config;
            END IF;
            RETURN FALSE;
    END check_transition_int;

    /**
    * Get status information without evaluating function
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier  
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   o_status_config_info   WF_STATUS_CONFIG data
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_config
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        o_status_config_info  OUT NOCOPY t_rec_wf_status_info,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_id_market market.id_market%TYPE;
    BEGIN
        g_error := 'Init get_status_config / ID_WF=' || i_id_workflow || ' ID_STATUS=' || i_id_status ||
                   ' ID_CATEGORY=' || i_id_category || ' ID_PROFILE_TEMPLATE=' || i_id_profile_template ||
                   ' ID_FUNCTIONALITY=' || i_id_functionality || ' I_PROF.INSTITUTION=' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
        o_status_config_info := t_rec_wf_status_info();
    
        g_error     := 'Call pk_utils.get_institution_market / ID_INSTITUTION=' || i_prof.institution;
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'SELECT wf_status_config';
        SELECT id_workflow,
               id_status,
               icon,
               color,
               rank,
               pk_translation.get_translation(i_lang, code_status),
               flg_insert,
               flg_update,
               flg_delete,
               flg_read,
               FUNCTION
          INTO o_status_config_info.id_workflow,
               o_status_config_info.id_status,
               o_status_config_info.icon,
               o_status_config_info.color,
               o_status_config_info.rank,
               o_status_config_info.desc_status,
               o_status_config_info.flg_insert,
               o_status_config_info.flg_update,
               o_status_config_info.flg_delete,
               o_status_config_info.flg_read,
               o_status_config_info.function
          FROM (SELECT wsc.id_workflow,
                       wsc.id_status,
                       nvl(wsc.icon, s.icon) icon,
                       nvl(wsc.color, s.color) color,
                       nvl(wsc.rank, s.rank) rank,
                       s.code_status code_status,
                       wsc.flg_insert,
                       wsc.flg_update,
                       wsc.flg_delete,
                       wsc.flg_read,
                       wsc.function
                  FROM wf_status_config wsc
                  JOIN wf_status_workflow ws
                    ON (ws.id_workflow = wsc.id_workflow AND ws.id_status = wsc.id_status)
                  JOIN wf_status s
                    ON (s.id_status = ws.id_status)
                  JOIN wf_workflow_market wwm
                    ON (wwm.id_workflow = ws.id_workflow)
                 WHERE wsc.id_software IN (0, i_prof.software)
                   AND wsc.id_institution IN (0, i_prof.institution)
                   AND wsc.id_category IN (0, i_id_category)
                   AND wsc.id_profile_template IN (0, i_id_profile_template)
                   AND wsc.id_functionality IN (0, i_id_functionality)
                   AND ws.flg_available = pk_alert_constant.g_yes
                   AND ws.id_status = i_id_status
                   AND ws.id_workflow = i_id_workflow
                   AND s.flg_available = pk_alert_constant.g_yes
                   AND wwm.id_market IN (0, l_id_market)
                 ORDER BY id_market           DESC, -- ACM, 2010-04-05: ALERT-171098
                          id_institution      DESC,
                          id_software         DESC,
                          id_category         DESC,
                          id_profile_template DESC,
                          id_functionality    DESC)
         WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_CONFIG',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_status_config;

    /**
    * Get status information (pipelined function)
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    *
    FUNCTION get_status_info_p
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN t_coll_wf_status_info
        PIPELINED IS
        l_status_info t_rec_wf_status_info;
        l_error       t_error_out;
    BEGIN
    
        g_error := 'Calling get_status_info / WF=' || i_id_workflow || '|STATUS=' || i_id_status || '|CATEGORY=' ||
                   i_id_category || '|PROFILE=' || i_id_profile_template || '|FUNC=' || i_id_functionality;
        pk_alertlog.log_debug(g_error);
        g_retval := get_status_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => i_id_workflow,
                                    i_id_status           => i_id_status,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_status_info         => l_status_info,
                                    o_error               => l_error);
    
        IF NOT g_retval
        THEN
            g_error := g_error || ' / ERR=' || l_error.err_desc;
            RETURN;
        END IF;
    
        PIPE ROW(l_status_info);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_STATUS_INFO_P');
                pk_alertlog.log_error(g_error);
                RETURN;
            END;
    END get_status_info_p;
    
    /**
    * Get status information
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_status_info          Status information
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        o_status_info         OUT NOCOPY t_rec_wf_status_info,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template wf_status_config.id_profile_template%TYPE;
        l_id_functionality    wf_status_config.id_functionality%TYPE;
        l_id_category         category.id_category%TYPE;
    
        l_status_config_row t_rec_wf_status_info;
        l_func              VARCHAR2(1000 CHAR);
        l_sql               VARCHAR2(32767);
    BEGIN
        g_error := 'Init get_status_info / ID_WF=' || i_id_workflow || ' ID_STS=' || i_id_status || ' ID_CAT=' ||
                   i_id_category || ' ID_PRF_TEMPL=' || i_id_profile_template || ' ID_FUNC=' || i_id_functionality ||
                   ' I_PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
    
        o_status_info := t_rec_wf_status_info();
    
        g_error               := 'l_id_profile_template';
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        g_error       := 'l_id_category';
        l_id_category := nvl(i_id_category, 0);
    
        g_error            := 'l_id_functionality';
        l_id_functionality := nvl(i_id_functionality, 0);
    
        g_error  := 'get_status_config / ID_WF=' || i_id_workflow || ' ID_STS=' || i_id_status || ' ID_CAT=' ||
                    l_id_category || ' ID_PRF_TEMPL=' || l_id_profile_template || ' ID_FUNC=' || l_id_functionality;
        g_retval := get_status_config(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_workflow         => i_id_workflow,
                                      i_id_status           => i_id_status,
                                      i_id_category         => l_id_category,
                                      i_id_profile_template => l_id_profile_template,
                                      i_id_functionality    => l_id_functionality,
                                      o_status_config_info  => l_status_config_row,
                                      o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_status_config_row.id_status IS NOT NULL
        THEN
        
            IF l_status_config_row.function IS NULL
            THEN
            
                g_error       := 'o_status_info';
                o_status_info := l_status_config_row;
            ELSE
            
                -- returning result of l_status_config_row.FUNCTION
                -- PK_PACKAGE.function_name(@LANG, profissional(@PROFESSIONAL,@INSTITUTION,@SOFTWARE),@CAT,@PROF_TEMPL,@FUNC,@REC_TYPE,@PARAM)            
                g_error := 'l_func';
                l_func  := l_status_config_row.function;
                l_func  := REPLACE(l_func, '@LANG', ':1');
                l_func  := REPLACE(l_func, '@PROFESSIONAL', ':2');
                l_func  := REPLACE(l_func, '@INSTITUTION', ':3');
                l_func  := REPLACE(l_func, '@SOFTWARE', ':4');
                l_func  := REPLACE(l_func, '@PROF_TEMPL', ':5');
                l_func  := REPLACE(l_func, '@CAT', ':6');
                l_func  := REPLACE(l_func, '@FUNC', ':7');
            
                l_func := REPLACE(l_func,
                                  '@REC_TYPE',
                                  't_rec_wf_status_info(:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,NULL)');
            
                g_error := 'l_param';
                l_func  := REPLACE(l_func, '@PARAM', ':18');
            
                --pk_alertlog.log_debug('FUNC=' || l_func);
            
                g_error := 'l_sql';
                l_sql   := 'SELECT t.sts.id_workflow,
                           t.sts.id_status,
                           t.sts.icon,
                           t.sts.color,
                           t.sts.rank,
                           t.sts.desc_status,
                           t.sts.flg_insert,
                           t.sts.flg_update,
                           t.sts.flg_delete,
                           t.sts.flg_read
                      FROM ( SELECT ' || l_func || ' sts from dual) t';
            
                /*
                g_error := 'l_sql';
                l_sql   := 'SELECT id_workflow,
                           id_status,
                           icon,
                           color,
                           rank,
                           desc_status,
                           flg_insert,
                           flg_update,
                           flg_delete,
                           flg_read
                      FROM dual
                      FROM TABLE(CAST(' || l_func || ' AS t_coll_wf_status_info))';
                      */
            
                ------------------------------------------------
                --pk_alertlog.log_debug('--------------------' || l_sql);
                ------------------------------------------------
            
                g_error := 'OPEN o_status_info 2';
                EXECUTE IMMEDIATE l_sql
                    INTO o_status_info.id_workflow, o_status_info.id_status, o_status_info.icon, o_status_info.color, o_status_info.rank, o_status_info.desc_status, o_status_info.flg_insert, o_status_info.flg_update, o_status_info.flg_delete, o_status_info.flg_read
                    USING to_char(i_lang), -- LANG
                to_char(i_prof.id), -- PROFESSIONAL
                to_char(i_prof.institution), -- INSTITUTION
                to_char(i_prof.software), -- SOFTWARE
                to_char(l_id_category), --CAT
                to_char(l_id_profile_template), -- PROF_TEMPL
                to_char(l_id_functionality), -- FUNC
                -- REC_TYPE
                l_status_config_row.id_workflow, l_status_config_row.id_status, l_status_config_row.icon, l_status_config_row.color, l_status_config_row.rank, l_status_config_row.desc_status, l_status_config_row.flg_insert, l_status_config_row.flg_update, l_status_config_row.flg_delete, l_status_config_row.flg_read, i_param -- PARAM
                ;
            
                /* pk_alertlog.log_debug('WF=' || o_status_info.id_workflow || '|STS=' || o_status_info.id_status ||
                '|ICON=' || o_status_info.icon || '|COLOR=' || o_status_info.color ||
                '|RANK=' || o_status_info.rank || '|DESC=' || o_status_info.desc_status ||
                '|FLG_I=' || o_status_info.flg_insert || '|FLG_U=' ||
                o_status_info.flg_update || '|FLG_D=' || o_status_info.flg_delete ||
                '|FLG_R=' || o_status_info.flg_read);*/
            END IF;
        
        ELSE
            g_error := 'ID_STATUS not found';
            pk_alertlog.log_warn(g_error || ' ID_STATUS=' || i_id_status || '|WF=' || i_id_workflow);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := 'get_status_info / ' || 'WF=' || i_id_workflow || '|STS=' || i_id_status || '|CAT=' ||
                       i_id_category || '|PRF=' || i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' ||
                       SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_INFO',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_status_info;

    /**
    * Get status information
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  Status information
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   15-03-2011
    */
    FUNCTION get_status_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN t_rec_wf_status_info IS
        l_result t_rec_wf_status_info;
        l_error  t_error_out;
    BEGIN
        g_error := '-->Init get_status_info / ID_WF=' || i_id_workflow || ' ID_STS=' || i_id_status || ' ID_CAT=' ||
                   i_id_category || ' ID_PRF_TEMPL=' || i_id_profile_template || ' ID_FUNC=' || i_id_functionality ||
                   ' I_PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_status_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => i_id_workflow,
                                    i_id_status           => i_id_status,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_status_info         => l_result,
                                    o_error               => l_error);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := 'get_status_info / ' || 'WF=' || i_id_workflow || '|STS=' || i_id_status || '|CAT=' ||
                       i_id_category || '|PRF=' || i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' ||
                       SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_INFO',
                                              o_error    => l_error);
            RETURN NULL;
    END get_status_info;

    /**
    * Get status icon
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  ICON name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_icon
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error           t_error_out;
        l_status_info_row t_rec_wf_status_info := t_rec_wf_status_info();
    BEGIN
    
        g_error := 'Init get_status_icon / Calling get_status_info / WF=' || i_id_workflow || ' ID_STATUS=' ||
                   i_id_status || ' ID_CATEGORY=' || i_id_category || ' ID_PROFILE_TEMPLATE=' || i_id_profile_template ||
                   ' ID_FUNCTIONALITY=' || i_id_functionality || ' I_PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
        g_retval := get_status_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => i_id_workflow,
                                    i_id_status           => i_id_status,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_status_info         => l_status_info_row,
                                    o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_status_info_row.icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_status_icon / ' || 'WF=' || i_id_workflow || '|STS=' || i_id_status || '|PRF=' ||
                       i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_status_icon;

    /**
    * Get status color
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_color
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error           t_error_out;
        l_status_info_row t_rec_wf_status_info := t_rec_wf_status_info();
    BEGIN
        g_error := 'Init get_status_color / Calling get_status_info / WF=' || i_id_workflow || ' ID_STATUS=' ||
                   i_id_status || ' ID_CATEGORY=' || i_id_category || ' ID_PROFILE_TEMPLATE=' || i_id_profile_template ||
                   ' ID_FUNCTIONALITY=' || i_id_functionality || ' I_PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
        g_retval := get_status_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => i_id_workflow,
                                    i_id_status           => i_id_status,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_status_info         => l_status_info_row,
                                    o_error               => l_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_status_info_row.color;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_status_icon / ' || 'WF=' || i_id_workflow || '|STS=' || i_id_status || '|PRF=' ||
                       i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_status_color;

    /**
    * Get status rank
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  status rank
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN NUMBER IS
        l_error           t_error_out;
        l_status_info_row t_rec_wf_status_info := t_rec_wf_status_info();
    BEGIN
        g_error := 'Init get_status_rank / Calling get_status_info / WF=' || i_id_workflow || ' ID_STATUS=' ||
                   i_id_status || ' ID_CATEGORY=' || i_id_category || ' ID_PROFILE_TEMPLATE=' || i_id_profile_template ||
                   ' ID_FUNCTIONALITY=' || i_id_functionality || ' I_PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
        g_retval := get_status_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => i_id_workflow,
                                    i_id_status           => i_id_status,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_status_info         => l_status_info_row,
                                    o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_status_info_row.rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_status_rank / ' || 'WF=' || i_id_workflow || '|STS=' || i_id_status || '|PRF=' ||
                       i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
        
    END get_status_rank;

    /**
    * Get status description
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  status description
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION get_status_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error           t_error_out;
        l_status_info_row t_rec_wf_status_info := t_rec_wf_status_info();
    BEGIN
        g_error := 'Init get_status_desc / Calling get_status_info / WF=' || i_id_workflow || ' ID_STATUS=' ||
                   i_id_status || ' ID_CATEGORY=' || i_id_category || ' ID_PROFILE_TEMPLATE=' || i_id_profile_template ||
                   ' ID_FUNCTIONALITY=' || i_id_functionality || ' I_PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
        g_retval := get_status_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_workflow         => i_id_workflow,
                                    i_id_status           => i_id_status,
                                    i_id_category         => i_id_category,
                                    i_id_profile_template => i_id_profile_template,
                                    i_id_functionality    => i_id_functionality,
                                    i_param               => i_param,
                                    o_status_info         => l_status_info_row,
                                    o_error               => l_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_status_info_row.desc_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_status_icon / ' || 'WF=' || i_id_workflow || '|STS=' || i_id_status || '|PRF=' ||
                       i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_status_desc;

    /**
    * Get the begining status of workflow
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */
    FUNCTION get_status_begin
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN wf_status_workflow.id_workflow%TYPE,
        o_status_begin OUT NOCOPY wf_status_workflow.id_status%TYPE,
        o_error        OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_status_begin := get_status_begin(i_id_workflow => i_id_workflow);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_status_icon / WF=' || i_id_workflow || ' STATUS_BEGIN=' || o_status_begin || ' / ' ||
                       SQLERRM;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_BEGIN',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_status_begin;

    /**
    * Get the begining status of workflow
    *
    * @param   i_id_workflow          Workflow identifier
    *
    * @RETURN  Begin status identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-06-2013
    */
    FUNCTION get_status_begin(i_id_workflow IN wf_status_workflow.id_workflow%TYPE)
        RETURN wf_status_workflow.id_status%TYPE IS
        l_result wf_status_workflow.id_status%TYPE;
    BEGIN
    
        SELECT id_status
          INTO l_result
          FROM wf_status_workflow w
         WHERE w.id_workflow = i_id_workflow
           AND w.flg_begin = pk_alert_constant.g_yes
           AND flg_available = pk_alert_constant.g_yes;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_status_icon / WF=' || i_id_workflow || ' STATUS_BEGIN=' || l_result || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN l_result;
    END get_status_begin;

    /**
    * Get transitions available starting from i_id_status_begin status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Status identifier
    * @param   i_id_workflow_action   Workflow action identifier. If null, all workflow actions are considered.
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   i_flg_auto_transition  Indicates whether we want automatic transitions. 
    *                                           {*} Y - automatic transitions returned
    *                                           {*} N - non-autiomatic transitions returned
    *                                           {*} <null>  - all transitions returned (automatic or not)
    * @param   o_transitions          Transitions information
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-03-2009
    */
    FUNCTION get_transitions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition.id_status_begin%TYPE,
        i_id_workflow_action  IN wf_transition.id_workflow_action%TYPE DEFAULT NULL,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_flg_auto_transition IN wf_transition.flg_auto_transition%TYPE,
        o_transitions         OUT NOCOPY t_coll_wf_transition,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template wf_transition_config.id_profile_template%TYPE;
        l_id_functionality    wf_transition_config.id_functionality%TYPE;
        l_id_market           market.id_market%TYPE;
    
        CURSOR c_transition
        (
            x_market             IN market.id_market%TYPE,
            x_id_workflow_action IN wf_workflow_action.id_workflow_action%TYPE
        ) IS -- JB 2010-04-14 ALERT-88852
            SELECT wt.*, wa.icon icon_action, wa.code_action
              FROM wf_transition wt
              JOIN wf_workflow_market wwm
                ON (wwm.id_workflow = wt.id_workflow)
              JOIN wf_workflow_action wa
                ON (wt.id_workflow_action = wa.id_workflow_action)
             WHERE wt.id_workflow = i_id_workflow
               AND wt.id_status_begin = i_id_status_begin
                  -- ACM, 2011-04-05: ALERT-171098
               AND wwm.id_market = nvl((SELECT wwmi.id_market
                                         FROM wf_workflow_market wwmi
                                        WHERE wwmi.id_workflow = wwm.id_workflow
                                          AND wwmi.id_market = x_market),
                                       pk_alert_constant.g_id_market_all)
               AND wa.id_workflow_action = nvl(x_id_workflow_action, wa.id_workflow_action)
               AND wt.flg_available = pk_alert_constant.g_yes
               AND wa.flg_available = pk_alert_constant.g_yes
               AND wt.flg_auto_transition = nvl(i_flg_auto_transition, wt.flg_auto_transition);
    
        TYPE t_transition IS TABLE OF c_transition%ROWTYPE INDEX BY PLS_INTEGER;
        l_transition_tab t_transition;
    
        l_flg_available   VARCHAR2(1 CHAR);
        l_transition_info t_rec_wf_trans_config;
        l_id_category     category.id_category%TYPE;
    BEGIN
    
        g_error := 'Init get_transitions / ID_WF=' || i_id_workflow || ' ID_STATUS_BEGIN=' || i_id_status_begin ||
                   ' ID_CATEGORY=' || i_id_category || ' ID_PROFILE_TEMPLATE=' || i_id_profile_template ||
                   ' ID_FUNCTIONALITY=' || i_id_functionality || ' I_PROF.INSTITUTION=' || i_prof.institution ||
                   ' ID_WORKFLOW_ACTION=' || i_id_workflow_action;
        pk_alertlog.log_debug(g_error);
    
        o_transitions := t_coll_wf_transition();
    
        g_error               := 'l_id_profile_template';
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        g_error       := 'l_id_category';
        l_id_category := nvl(i_id_category, 0);
    
        g_error            := 'l_id_functionality';
        l_id_functionality := nvl(i_id_functionality, 0);
    
        -- ACM, 2010-06-10: tuning
        g_error     := 'Call pk_utils.get_institution_market / ID_INSTITUTION=' || i_prof.institution;
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'OPEN c_transition / l_id_market=' || l_id_market || ' i_id_workflow_action=' ||
                   i_id_workflow_action;
        OPEN c_transition(l_id_market, i_id_workflow_action);
    
        g_error := 'FETCH c_transition';
        FETCH c_transition BULK COLLECT
            INTO l_transition_tab;
        CLOSE c_transition;
    
        FOR i IN 1 .. l_transition_tab.count
        LOOP
        
            g_error         := 'l_flg_available NULL';
            l_flg_available := NULL; -- cleaning var
        
            g_error := 'Calling check_transition_int / WF=' || i_id_workflow || ' STS_BEG=' || l_transition_tab(i)
                      .id_status_begin || ' STS_END=' || l_transition_tab(i).id_status_end || ' ACTION=' || l_transition_tab(i)
                      .id_workflow_action || ' ID_CAT=' || l_id_category || ' ID_PROF_TEMPL=' || l_id_profile_template ||
                       ' ID_FUNC=' || l_id_functionality;
            pk_alertlog.log_debug(g_error);
            g_retval := check_transition_int(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_workflow         => i_id_workflow,
                                             i_id_status_begin     => l_transition_tab(i).id_status_begin,
                                             i_id_status_end       => l_transition_tab(i).id_status_end,
                                             i_id_workflow_action  => l_transition_tab(i).id_workflow_action,
                                             i_id_category         => l_id_category,
                                             i_id_profile_template => l_id_profile_template,
                                             i_id_functionality    => l_id_functionality,
                                             i_param               => i_param,
                                             o_flg_available       => l_flg_available,
                                             o_transition_info     => l_transition_info,
                                             o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'l_flg_available';
            IF l_flg_available = pk_alert_constant.g_yes
            THEN
                -- transition allowed for professional            
                g_error := 'o_transitions.EXTEND WF=' || i_id_workflow || '|BEG=' || l_transition_tab(i)
                          .id_status_begin || '|ACTION=' || l_transition_tab(i).id_workflow_action || '|PRF=' ||
                           l_id_profile_template || '|FUNC=' || l_id_functionality;
                --pk_alertlog.log_debug(g_error);
            
                o_transitions.extend;
                o_transitions(o_transitions.last) := t_rec_wf_transition();
                o_transitions(o_transitions.last).id_workflow := l_transition_info.id_workflow;
                o_transitions(o_transitions.last).id_status_begin := l_transition_info.id_status_begin;
                o_transitions(o_transitions.last).id_status_end := l_transition_info.id_status_end;
                o_transitions(o_transitions.last).id_workflow_action := l_transition_info.id_workflow_action;
                o_transitions(o_transitions.last).id_status_end := l_transition_tab(i).id_status_end;
                o_transitions(o_transitions.last).rank := l_transition_info.rank;
                o_transitions(o_transitions.last).flg_auto_transition := l_transition_info.flg_auto_transition;
            
                -- icon precedence: WF_TRANSITION_CONFIG -> WF_TRANSITION -> WF_WORKFLOW_ACTION
                o_transitions(o_transitions.last).icon := nvl(nvl(l_transition_info.icon, l_transition_tab(i).icon),
                                                              l_transition_tab(i).icon_action);
                o_transitions(o_transitions.last).desc_transition := pk_translation.get_translation(i_lang,
                                                                                                    l_transition_tab(i)
                                                                                                    .code_action);
                o_transitions(o_transitions.last).flg_visible := l_transition_info.flg_visible;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := 'GET_TRANSITIONS / WF=' || i_id_workflow || '|STS=' || i_id_status_begin || '|PRF=' ||
                       i_id_profile_template || '|FUNC=' || i_id_functionality || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TRANSITIONS',
                                              o_error    => o_error);
            IF c_transition%ISOPEN
            THEN
                CLOSE c_transition;
            END IF;
        
            RETURN FALSE;
    END get_transitions;

    /**
    * Get software status default info
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software   
    * @param   i_id_market            Market identifier
    * @param   o_status_info          Status information [ID_STATUS|DESC_STATUS|ICON|COLOR|RANK|CODE_STATUS]
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  Return table (t_coll_wf_status_info_def) pipelined. Status information [ID_STATUS|DESC_STATUS|ICON|COLOR|RANK|CODE_STATUS]
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-03-2009
    */

    FUNCTION get_status_software
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_market IN market.id_market%TYPE
    ) RETURN t_coll_wf_status_info_def
        PIPELINED IS
        l_cursor pk_types.cursor_type;
        l_rec    t_rec_wf_status_info_def := t_rec_wf_status_info_def();
    BEGIN
        OPEN l_cursor FOR
            SELECT DISTINCT wss.id_status,
                            wss.description,
                            --pk_translation.get_translation(i_lang, wss.code_status) desc_status,
                            wss.icon,
                            wss.color,
                            wss.rank,
                            wss.code_status
              FROM wf_workflow_software ws
              JOIN wf_workflow w
                ON w.id_workflow = ws.id_workflow
              JOIN wf_status_workflow wsw
                ON w.id_workflow = wsw.id_workflow
              JOIN wf_status wss
                ON wss.id_status = wsw.id_status
              JOIN wf_workflow_market wwm
                ON wwm.id_workflow = w.id_workflow -- JB 14-04-2010 ALERT-88852
             WHERE wsw.flg_available = pk_alert_constant.g_yes
               AND wss.flg_available = pk_alert_constant.g_yes
               AND ws.id_software = i_prof.software
               AND wwm.id_market IN (0, i_id_market);
    
        LOOP
            FETCH l_cursor
                INTO l_rec.id_status, l_rec.desc_status, l_rec.icon, l_rec.color, l_rec.rank, l_rec.code_status;
            EXIT WHEN l_cursor%NOTFOUND;
            PIPE ROW(l_rec);
        
        END LOOP;
    
        CLOSE l_cursor;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_STATUS_SOFTWARE');
                pk_alertlog.log_error(g_error);
                RETURN;
            END;
    END get_status_software;

    /**
    * Checks if transition is available (id_workflow, i_id_status_begin, i_id_workflow_action) and returns transition data
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Begin status identifier
    * @param   i_id_status_end        End status identifier
    * @param   i_id_workflow_action   Action identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_flg_available        Returns transition availability: {*} Y - transition available {*} N - otherwise
    * @param   o_transition_info      Transition info
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2010
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition.id_status_end%TYPE,
        i_id_workflow_action  IN wf_transition.id_workflow_action%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_flg_available       OUT NOCOPY VARCHAR2,
        o_transition_info     OUT NOCOPY t_rec_wf_trans_config,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template wf_transition_config.id_profile_template%TYPE;
        l_id_functionality    wf_transition_config.id_functionality%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_market           market.id_market%TYPE;
    
        CURSOR c_transition IS
            SELECT wt.*, wa.icon icon_action, wa.code_action
              FROM wf_transition wt
              JOIN wf_workflow_market wwm
                ON (wwm.id_workflow = wt.id_workflow)
              JOIN wf_workflow_action wa
                ON (wt.id_workflow_action = wa.id_workflow_action)
             WHERE wt.id_workflow = i_id_workflow
               AND wt.id_status_begin = i_id_status_begin
               AND wt.id_workflow_action = i_id_workflow_action
               AND wwm.id_market IN (0, l_id_market)
                  -- ACM, 2011-04-05: ALERT-171098
                  --AND wwm.id_market IN (0, l_id_market)
               AND wwm.id_market = nvl((SELECT wwmi.id_market
                                         FROM wf_workflow_market wwmi
                                        WHERE wwmi.id_workflow = wwm.id_workflow
                                          AND wwmi.id_market = l_id_market),
                                       pk_alert_constant.g_id_market_all)
               AND wt.flg_available = pk_alert_constant.g_yes
               AND wa.flg_available = pk_alert_constant.g_yes;
    
        l_transition_rec c_transition%ROWTYPE;
    
    BEGIN
        g_error := 'Init check_transition / i_prof=' || pk_utils.to_string(i_prof) || ' WF=' || i_id_workflow ||
                   ' STS_BEG=' || i_id_status_begin || ' STS_END=' || i_id_status_end || ' ACTION=' ||
                   i_id_workflow_action || ' CAT=' || i_id_category || ' PRF_TEMPL=' || i_id_profile_template ||
                   ' FUNC=' || i_id_functionality || ' PARAM=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
    
        g_error               := 'l_id_profile_template';
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        g_error            := 'l_id_functionality';
        l_id_functionality := nvl(i_id_functionality, 0);
    
        g_error       := 'l_id_category';
        l_id_category := nvl(i_id_category, 0);
    
        g_error     := 'Call pk_utils.get_institution_market / ID_INSTITUTION=' || i_prof.institution;
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error         := 'init o_flg_available';
        o_flg_available := pk_alert_constant.g_no;
    
        g_error  := 'Calling check_transition_int / WF=' || i_id_workflow || ' STS_BEG=' || i_id_status_begin ||
                    ' STS_END=' || i_id_status_end || ' ACTION=' || i_id_workflow_action || ' ID_CAT=' || l_id_category ||
                    ' ID_PROF_TEMPL=' || l_id_profile_template || ' ID_FUNC=' || l_id_functionality;
        g_retval := check_transition_int(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_workflow         => i_id_workflow,
                                         i_id_status_begin     => i_id_status_begin,
                                         i_id_status_end       => i_id_status_end,
                                         i_id_workflow_action  => i_id_workflow_action,
                                         i_id_category         => l_id_category,
                                         i_id_profile_template => l_id_profile_template,
                                         i_id_functionality    => l_id_functionality,
                                         i_param               => i_param,
                                         i_validate_trans      => i_validate_trans,
                                         o_flg_available       => o_flg_available,
                                         o_transition_info     => o_transition_info,
                                         o_error               => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        IF o_flg_available = pk_alert_constant.g_yes
        THEN
            -- transition allowed for professional            
            g_error := 'OPEN c_transition';
            OPEN c_transition;
            FETCH c_transition
                INTO l_transition_rec;
            CLOSE c_transition;
        
            g_error := 'Fill o_transition_info';
            -- icon precedence: WF_TRANSITION_CONFIG -> WF_TRANSITION -> WF_WORKFLOW_ACTION
            o_transition_info.icon                := nvl(nvl(o_transition_info.icon, l_transition_rec.icon),
                                                         l_transition_rec.icon_action);
            o_transition_info.desc_transition     := pk_translation.get_translation(i_lang,
                                                                                    l_transition_rec.code_action);
            o_transition_info.flg_auto_transition := l_transition_rec.flg_auto_transition;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_TRANSITION',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_transition;

    /**
    * Checks if transition is available (id_workflow, i_id_status_begin, i_id_status_end)
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Begin status identifier
    * @param   i_id_status_begin      End status identifier
    * @param   i_id_workflow_action   Action identifier   
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_flg_available        Returns transition availability: {*} Y - transition available {*} N - otherwise
    * @param   o_transition           Transition identifier   
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-03-2009
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition.id_status_end%TYPE,
        i_id_workflow_action  IN wf_transition.id_workflow_action%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_flg_available       OUT NOCOPY VARCHAR2,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_transition_info t_rec_wf_trans_config;
    BEGIN
        g_error := 'Init check_transition 2 / WF=' || i_id_workflow || ' STS_BEG=' || i_id_status_begin || ' STS_END=' ||
                   i_id_status_end || ' ACTION=' || i_id_workflow_action || ' ID_CAT=' || i_id_category ||
                   ' ID_PROF_TEMPL=' || i_id_profile_template || ' ID_FUNC=' || i_id_functionality || ' PARAM=' ||
                   pk_utils.to_string(i_param);
    
        RETURN check_transition(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_id_workflow         => i_id_workflow,
                                i_id_status_begin     => i_id_status_begin,
                                i_id_status_end       => i_id_status_end,
                                i_id_workflow_action  => i_id_workflow_action,
                                i_id_category         => i_id_category,
                                i_id_profile_template => i_id_profile_template,
                                i_id_functionality    => i_id_functionality,
                                i_param               => i_param,
                                i_validate_trans      => i_validate_trans,
                                o_flg_available       => o_flg_available,
                                o_transition_info     => l_transition_info,
                                o_error               => o_error);
    EXCEPTION
        WHEN g_exception THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_TRANSITION',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_transition;

    /**
    * Checks if this status is available for this workflow
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier   
    *
    * @RETURN  {*} Y- status available for this workflow {*} N- otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-05-2013
    */
    FUNCTION check_wf_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN wf_status_config.id_workflow%TYPE,
        i_id_status   IN wf_status_config.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_count  PLS_INTEGER;
        l_result VARCHAR2(1 CHAR);
    BEGIN
        l_result := pk_ref_constant.g_no;
        g_error  := 'Init check_wf_status / i_id_workflow=' || i_id_workflow || ' i_id_status=' || i_id_status;
    
        IF i_id_workflow IS NOT NULL
           AND i_id_status IS NOT NULL
        THEN
        
            SELECT COUNT(1)
              INTO l_count
              FROM wf_status_workflow s
             WHERE s.id_workflow = i_id_workflow
               AND s.id_status = i_id_status
               AND s.flg_available = pk_ref_constant.g_yes;
        
            IF l_count > 0
            THEN
                l_result := pk_ref_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN l_result;
    END check_wf_status;

    /**
    * Checks if this status is final
    *
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier   
    *
    * @RETURN  {*} Y- status is final for this workflow {*} N- otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-06-2013
    */
    FUNCTION check_status_final
    (
        i_id_workflow IN wf_status_config.id_workflow%TYPE,
        i_id_status   IN wf_status_config.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(1 CHAR);
    BEGIN
        l_result := pk_ref_constant.g_no;
        g_error  := 'Init check_wf_status / i_id_workflow=' || i_id_workflow || ' i_id_status=' || i_id_status;
    
        SELECT w.flg_final
          INTO l_result
          FROM wf_status_workflow w
         WHERE w.id_workflow = i_id_workflow
           AND w.id_status = i_id_status
           AND flg_available = pk_alert_constant.g_yes;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN l_result;
    END check_status_final;

    /**
    * Enables or Disables workflow configuration
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_flg_available        {*} Y - enable workflow {*} N - disable workflow
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */

    FUNCTION set_workflow
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_flg_available IN VARCHAR2,
        o_error         OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- WF_STATUS_WORKFLOW
        UPDATE wf_status_workflow
           SET flg_available = i_flg_available
         WHERE id_workflow = i_id_workflow;
    
        -- WF_TRANSITION
        UPDATE wf_transition
           SET flg_available = i_flg_available
         WHERE id_workflow = i_id_workflow;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_WORKFLOW',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_workflow;

    /**
    * Enables or Disables status workflow configuration
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier   
    * @param   i_flg_available        {*} Y - enable workflow {*} N - disable workflow
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */
    FUNCTION set_status_workflow
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_id_status     IN wf_status_workflow.id_status%TYPE,
        i_flg_available IN VARCHAR2,
        o_error         OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- WF_STATUS_WORKFLOW
        UPDATE wf_status_workflow
           SET flg_available = i_flg_available
         WHERE id_workflow = i_id_workflow
           AND id_status = i_id_status;
    
        -- WF_TRANSITION
        UPDATE wf_transition
           SET flg_available = i_flg_available
         WHERE id_workflow = i_id_workflow
           AND (id_status_begin = i_id_status OR id_status_end = i_id_status);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_STATUS_WORKFLOW',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_status_workflow;

    /**
    * Getting transitions for one action/workflow/status_begin
    *
    * @param   I_LANG            Language associated to the professional executing the request
    * @param   I_PROF            Professional, institution and software ids
    * @param   I_ACTION          Action identifier. Mandatory.   
    * @param   I_ID_WORKFLOW     Workflow identifier. Optional.     
    * @param   I_ID_STATUS_BEGIN Begin status identifier. Optional.
    * @param   O_TRANS_DATA      Transitions data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_wf_action_trans
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_action          IN wf_action.id_action%TYPE,
        i_id_workflow     IN wf_action.id_workflow%TYPE,
        i_id_status_begin IN wf_action.id_status_begin%TYPE,
        o_trans_data      OUT t_wf_action_cur
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init get_wf_action_trans / i_prof=' || pk_utils.to_string(i_prof) || ' i_action=' || i_action ||
                   ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin;
        pk_alertlog.log_debug(g_error);
    
        OPEN o_trans_data FOR
            SELECT wa.*
              FROM wf_action wa
             WHERE wa.id_action = i_action
               AND (wa.id_workflow = i_id_workflow OR i_id_workflow IS NULL)
               AND (wa.id_status_begin = i_id_status_begin OR i_id_status_begin IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WF_ACTION_TRANS',
                                              o_error    => g_error_dummy);
            RETURN FALSE;
    END get_wf_action_trans;

    /**
    * Getting transitions for one action/workflow/status_begin
    *
    * @param   I_LANG            Language associated to the professional executing the request
    * @param   I_PROF            Professional, institution and software ids
    * @param   I_ACTION          Action identifier. Mandatory.   
    * @param   I_ID_WORKFLOW     Workflow identifier. Optional.     
    * @param   I_ID_STATUS_BEGIN Begin status identifier. Optional.
    * @param   O_TRANS_DATA      Transitions data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   25-02-2014
    */
    FUNCTION get_wf_action_trans
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_action          IN wf_action.id_action%TYPE,
        i_id_workflow     IN wf_action.id_workflow%TYPE,
        i_id_status_begin IN wf_action.id_status_begin%TYPE
    ) RETURN t_coll_wf_action IS
        l_result t_coll_wf_action;
    BEGIN
        g_error := 'Init get_wf_action_trans / i_prof=' || pk_utils.to_string(i_prof) || ' i_action=' || i_action ||
                   ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin;
        pk_alertlog.log_debug(g_error);
    
        SELECT t_rec_wf_action(wa.id_action,
                               wa.id_workflow,
                               wa.id_status_begin,
                               wa.id_status_end,
                               wa.code_wf_action,
                               wa.id_wf_action,
                               wa.id_workflow_action)
          BULK COLLECT
          INTO l_result
          FROM wf_action wa
         WHERE wa.id_action = i_action
           AND (wa.id_workflow = i_id_workflow OR i_id_workflow IS NULL)
           AND (wa.id_status_begin = i_id_status_begin OR i_id_status_begin IS NULL);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WF_ACTION_TRANS',
                                              o_error    => g_error_dummy);
            RETURN NULL;
    END get_wf_action_trans;

    /**
    * Returns information about valid transitions associated to one action
    *
    * @param   I_LANG                  Language associated to the professional executing the request
    * @param   I_PROF                  Professional, institution and software ids
    * @param   I_ID_ACTION             Action identifier
    * @param   I_ID_WORKFLOW           Workflow identifier
    * @param   I_ID_STATUS_BEGIN       Begin status identifier
    * @param   I_ID_CATEGORY           Professional category
    * @param   I_ID_PROFILE_TEMPLATE   Professional profile template identifier
    * @param   I_ID_FUNCTIONALITY      Professional functionality
    * @param   I_PARAM                 Parameter for workflow framework
    * @param   I_BEHAVIOUR             Function behaviour: {*} 1- returns after having verified that the first transition is enabled    
                                                           {*} 0- returns after having verified all (default)
    * @param   O_ENABLED               Flag inddicating if this action/workflow/begin status is enabled   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_action_trans_valid
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_action           IN action.id_action%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_behaviour           IN PLS_INTEGER DEFAULT 0,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_enabled             OUT VARCHAR2,
        o_in_status           OUT VARCHAR2,
        o_transition_info     OUT t_coll_wf_transition
    ) RETURN BOOLEAN IS
        l_wf_action_cur t_wf_action_cur;
    
        TYPE t_wf_action IS TABLE OF wf_action%ROWTYPE;
        l_wf_action_tab t_wf_action;
    
        l_transition_info pk_workflow.t_rec_wf_trans_config;
    
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init get_action_trans_valid / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_action=' ||
                   i_id_action || ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin ||
                   ' i_id_category=' || i_id_category || ' i_id_profile_template=' || i_id_profile_template ||
                   ' i_id_functionality=' || i_id_functionality || ' i_param=' || pk_utils.to_string(i_param) ||
                   ' i_behaviour=' || i_behaviour;
        pk_alertlog.log_debug(g_error);
        o_enabled         := pk_alert_constant.g_no;
        o_in_status       := pk_alert_constant.g_no;
        o_transition_info := t_coll_wf_transition();
    
        ----------------------
        -- FUNC
        ----------------------                
    
        -- getting all transitions related to this action
        g_error := 'Call get_wf_action_trans / i_action=' || i_id_action || ' i_id_workflow=' || i_id_workflow ||
                   ' i_id_status_begin=' || i_id_status_begin;
        pk_alertlog.log_debug(g_error);
        IF NOT get_wf_action_trans(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_action          => i_id_action,
                                   i_id_workflow     => i_id_workflow,
                                   i_id_status_begin => i_id_status_begin,
                                   o_trans_data      => l_wf_action_cur)
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_wf_action_cur';
        FETCH l_wf_action_cur BULK COLLECT
            INTO l_wf_action_tab;
        CLOSE l_wf_action_cur;
    
        <<transition_loop>>
        FOR idx_trans IN 1 .. l_wf_action_tab.count
        LOOP
        
            -- check if at least one transition is valid
            g_error := 'Call pk_workflow.check_transition / i_prof=' || pk_utils.to_string(i_prof) || ' WF=' || l_wf_action_tab(idx_trans)
                      .id_workflow || ' BEG=' || l_wf_action_tab(idx_trans).id_status_begin || ' END=' || l_wf_action_tab(idx_trans)
                      .id_status_end || ' ID_ACTION=' || l_wf_action_tab(idx_trans).id_workflow_action || ' CAT=' ||
                       i_id_category || ' PROF_TEMPL=' || i_id_profile_template || ' FUNC=' || i_id_functionality ||
                       ' I_PARAM=' || pk_utils.to_string(i_param);
        
            pk_alertlog.log_debug(g_error);
        
            IF l_wf_action_tab(idx_trans).id_status_begin = i_id_status_begin
            THEN
                o_in_status := pk_alert_constant.get_yes;
                IF NOT pk_workflow.check_transition(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_workflow         => l_wf_action_tab(idx_trans).id_workflow,
                                                    i_id_status_begin     => l_wf_action_tab(idx_trans).id_status_begin,
                                                    i_id_status_end       => l_wf_action_tab(idx_trans).id_status_end,
                                                    i_id_workflow_action  => l_wf_action_tab(idx_trans).id_workflow_action,
                                                    i_id_category         => i_id_category,
                                                    i_id_profile_template => i_id_profile_template,
                                                    i_id_functionality    => i_id_functionality,
                                                    i_param               => i_param,
                                                    i_validate_trans      => i_validate_trans,
                                                    o_flg_available       => o_enabled,
                                                    o_transition_info     => l_transition_info,
                                                    o_error               => g_error_dummy)
                THEN
                    g_error := 'ERROR: ' || g_error;
                    RAISE g_exception;
                END IF;
            
                g_error := 'enabled=' || o_enabled;
                pk_alertlog.log_debug(g_error);
            
                IF o_enabled = pk_alert_constant.g_yes
                THEN
                
                    o_transition_info.extend;
                    o_transition_info(o_transition_info.last) := t_rec_wf_transition();
                    o_transition_info(o_transition_info.last).id_workflow := l_transition_info.id_workflow;
                    o_transition_info(o_transition_info.last).id_status_begin := l_transition_info.id_status_begin;
                    o_transition_info(o_transition_info.last).id_status_end := l_transition_info.id_status_end;
                    o_transition_info(o_transition_info.last).id_workflow_action := l_transition_info.id_workflow_action;
                    o_transition_info(o_transition_info.last).desc_transition := pk_translation.get_translation(i_lang      => i_lang,
                                                                                                                i_code_mess => l_wf_action_tab(idx_trans)
                                                                                                                               .code_wf_action);
                    o_transition_info(o_transition_info.last).rank := l_transition_info.rank;
                
                    IF i_behaviour = 1
                    THEN
                        EXIT transition_loop;
                    END IF;
                END IF;
            END IF;
        END LOOP transition_loop;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTION_TRANS_VALID',
                                              o_error    => g_error_dummy);
            RETURN FALSE;
    END get_action_trans_valid;

    /**
    * Checks if this action is enabled or disabled
    *
    * @param   I_LANG                  Language associated to the professional executing the request
    * @param   I_PROF                  Professional, institution and software ids
    * @param   I_ID_ACTION             Action identifier
    * @param   I_ID_WORKFLOW           Workflow identifier
    * @param   I_ID_STATUS_BEGIN       Begin status identifier
    * @param   I_ID_CATEGORY           Professional category
    * @param   I_ID_PROFILE_TEMPLATE   Professional profile template identifier
    * @param   I_ID_FUNCTIONALITY      Professional functionality
    * @param   I_PARAM                 Parameter for workflow framework
    * @param   O_ENABLED               Flag inddicating if this action/workflow/begin status is enabled   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION check_action_enabled
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_action           IN action.id_action%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_enabled             OUT VARCHAR2,
        o_in_status           OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_transition_info t_coll_wf_transition;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_action_enabled / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_action=' ||
                   i_id_action || ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin ||
                   ' i_id_category=' || i_id_category || ' i_id_profile_template=' || i_id_profile_template ||
                   ' i_id_functionality=' || i_id_functionality || ' i_param=' || pk_utils.to_string(i_param);
        pk_alertlog.log_debug(g_error);
        o_enabled := pk_alert_constant.g_no;
    
        ----------------------
        -- FUNC
        ----------------------
        g_error  := 'Call get_action_trans_valid';
        g_retval := get_action_trans_valid(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_action           => i_id_action,
                                           i_id_workflow         => i_id_workflow,
                                           i_id_status_begin     => i_id_status_begin,
                                           i_id_category         => i_id_category,
                                           i_id_profile_template => i_id_profile_template,
                                           i_id_functionality    => i_id_functionality,
                                           i_param               => i_param,
                                           i_behaviour           => 1, -- returns if the first transition is enabled
                                           i_validate_trans      => i_validate_trans,
                                           o_enabled             => o_enabled,
                                           o_in_status           => o_in_status,
                                           o_transition_info     => l_transition_info);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_ACTION_ENABLED',
                                              o_error    => g_error_dummy);
            RETURN FALSE;
    END check_action_enabled;

    /********************************************************************************************
    * Gets actions available for a given status of a given workflow
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_ID_WORKFLOW      Workflow identifier
    * @param   I_ID_STATUS_BEGIN  Begin action state 
    * @param   I_PARAMS           Params table_varchar for validateing transitions     
    * @param   O_ACTIONS          actions
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Nelson Canastro
    * @version 2.6
    * @since   14-01-2011
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin      IN wf_status.id_status%TYPE,
        i_params               IN table_varchar,
        i_validate_trans       IN VARCHAR2,
        i_show_disable         IN VARCHAR2,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT t_coll_action
    ) RETURN BOOLEAN IS
        l_action_cur pk_action.p_action_cur;
    
        TYPE t_tab_action IS TABLE OF pk_action.p_action_rec;
        l_action_tab  t_tab_action;
        l_flg_enabled VARCHAR2(1 CHAR);
    
        l_tab_action t_coll_action;
        l_rec_action t_rec_action;
    
        l_id_profile_template wf_transition_config.id_profile_template%TYPE;
        l_id_functionality    wf_transition_config.id_functionality%TYPE;
        l_id_category         wf_transition_config.id_category%TYPE;
        l_in_status           VARCHAR2(1 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init get_actions / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow ||
                   ' i_id_status_begin=' || i_id_status_begin;
        pk_alertlog.log_debug(g_error);
    
        l_tab_action := t_coll_action();
        l_rec_action := t_rec_action();
    
        ----------------------
        -- FUNC
        ---------------------- 
    
        g_error               := 'Calling pk_tools.get_prof_profile_template';
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        l_id_functionality := 0;
    
        g_error       := 'Call pk_prof_utils.get_id_category / ID_PROF=' || i_prof.id;
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        g_error       := 'I_PROF=' || pk_utils.to_string(i_prof) || ' / ID_PROFILE_TEMPLATE=' || l_id_profile_template ||
                         ' ID_FUNC=' || l_id_functionality || ' ID_CAT=' || l_id_category;
        pk_alertlog.log_debug(g_error);
    
        -- 1- getting actions available in table ACTION
        g_error := 'Call pk_actions.get_actions / i_id_workflow=' || i_id_workflow;
        IF NOT pk_action.get_actions(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_id_workflow          => i_id_workflow,
                                     i_class_origin         => i_class_origin,
                                     i_class_origin_context => i_class_origin_context,
                                     o_actions              => l_action_cur,
                                     o_error                => g_error_dummy)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_action_cur';
        FETCH l_action_cur BULK COLLECT
            INTO l_action_tab;
        CLOSE l_action_cur;
    
        <<action_loop>>
        FOR idx_action IN 1 .. l_action_tab.count
        LOOP
        
            -- 2- check if this action is valid (at least one transition available)        
            g_error := 'Call check_action_enabled / ID_ACTION=' || l_action_tab(idx_action).id_action || ' WF=' ||
                       i_id_workflow || ' STS_ID_BEG=' || i_id_status_begin || ' ID_CAT=' || l_id_category ||
                       ' PRF_TEMPL=' || l_id_profile_template || ' FUNC=' || l_id_functionality || ' I_PARAM=' ||
                       pk_utils.to_string(i_params);
            pk_alertlog.log_debug(g_error);
            IF NOT check_action_enabled(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_action           => l_action_tab(idx_action).id_action,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_category         => l_id_category,
                                        i_id_profile_template => l_id_profile_template,
                                        i_id_functionality    => l_id_functionality,
                                        i_param               => i_params,
                                        i_validate_trans      => i_validate_trans,
                                        o_enabled             => l_flg_enabled,
                                        o_in_status           => l_in_status)
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception;
            END IF;
        
            IF i_show_disable = pk_alert_constant.g_yes
               OR l_in_status = pk_alert_constant.g_yes
            THEN
                -- fill l_tab_action array        
                g_error := 'ID_ACTION=' || l_action_tab(idx_action).id_action || ' ID_PARENT=' || l_action_tab(idx_action)
                          .id_parent || ' LEVEL=' || l_action_tab(idx_action).level || ' FROM_STATE=' || l_action_tab(idx_action)
                          .to_state || ' TO_STATE=' || l_action_tab(idx_action).to_state || ' ICON=' || l_action_tab(idx_action).icon ||
                           ' FLG_DEFAULT=' || l_action_tab(idx_action).flg_default || ' FLG_STATUS=' || l_action_tab(idx_action)
                          .flg_status || ' INTERNAL_NAME=' || l_action_tab(idx_action).internal_name || ' FLG_ACTIVE=' ||
                           l_flg_enabled;
                pk_alertlog.log_debug(g_error);
            
                l_rec_action.id_action   := l_action_tab(idx_action).id_action;
                l_rec_action.id_parent   := l_action_tab(idx_action).id_parent;
                l_rec_action.level_nr    := l_action_tab(idx_action).level;
                l_rec_action.from_state  := l_action_tab(idx_action).from_state;
                l_rec_action.to_state    := l_action_tab(idx_action).to_state;
                l_rec_action.desc_action := l_action_tab(idx_action).desc_action;
                l_rec_action.icon        := l_action_tab(idx_action).icon;
                l_rec_action.flg_default := l_action_tab(idx_action).flg_default;
                --l_rec_action.flg_status    := l_action_tab(idx_action).flg_status;
                l_rec_action.action := l_action_tab(idx_action).internal_name;
            
                IF l_flg_enabled = pk_alert_constant.g_yes
                THEN
                    l_rec_action.flg_active := pk_alert_constant.g_active;
                ELSE
                    l_rec_action.flg_active := pk_alert_constant.g_inactive;
                END IF;
            
                l_tab_action.extend;
                l_tab_action(l_tab_action.last) := l_rec_action;
            END IF;
        END LOOP action_loop;
    
        -- 3- Returns action data, indicating a new column: FLG_ENABLED        
        o_actions := l_tab_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            IF l_action_cur%ISOPEN
            THEN
                CLOSE l_action_cur;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTIONS',
                                              o_error    => g_error_dummy);
        
            IF l_action_cur%ISOPEN
            THEN
                CLOSE l_action_cur;
            END IF;
            RETURN FALSE;
    END get_actions;

    /********************************************************************************************
    * Gets actions available for a given status of a given workflow
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_ID_WORKFLOW      Workflow identifier
    * @param   I_ID_STATUS_BEGIN  Begin action state 
    * @param   I_PARAMS           Params table_varchar for validateing transitions     
    * @param   O_ACTIONS          actions
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Nelson Canastro
    * @version 2.6
    * @since   14-01-2011
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin      IN wf_status.id_status%TYPE,
        i_params               IN table_varchar,
        i_validate_trans       IN VARCHAR2,
        i_show_disable         IN VARCHAR2,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        l_action_cur pk_action.p_action_cur;
    
        TYPE t_tab_action IS TABLE OF pk_action.p_action_rec;
        l_action_tab  t_tab_action;
        l_flg_enabled VARCHAR2(1 CHAR);
    
        l_tab_action t_coll_action;
    BEGIN
    
        IF NOT get_actions(i_lang                 => i_lang,
                           i_prof                 => i_prof,
                           i_id_workflow          => i_id_workflow,
                           i_id_status_begin      => i_id_status_begin,
                           i_params               => i_params,
                           i_validate_trans       => i_validate_trans,
                           i_show_disable         => i_show_disable,
                           i_class_origin         => i_class_origin,
                           i_class_origin_context => i_class_origin_context,
                           o_actions              => l_tab_action)
        THEN
            RAISE g_exception;
        END IF;
    
        -- 3- Returns action data, indicating a new column: FLG_ENABLED        
        OPEN o_actions FOR
            SELECT *
              FROM TABLE(CAST(l_tab_action AS t_coll_action));
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTIONS',
                                              o_error    => g_error_dummy);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    /********************************************************************************************
    * Get actions based on the subject and workflow
    *
    * @param  i_lang              The language ID
    * @param  i_prof              The professional array
    * @param  i_subject           Action Subject
    * @param  i_id_workflow       Workflow ID
    * @param  i_id_status_begin   Workflow Status
    * @param  i_params
    * @param  i_validate_trans    Flag that indicates if trans is to be validated
    * @param  i_show_disable      Flag indicating if disabled status is to be shown
    * @param  o_actions           Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    FUNCTION get_actions_subject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_subject         IN action.subject%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        i_params          IN table_varchar,
        i_validate_trans  IN VARCHAR2,
        i_show_disable    IN VARCHAR2,
        o_actions         OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        l_action_cur pk_action.p_action_cur;
    
        TYPE t_tab_action IS TABLE OF pk_action.p_action_rec;
        l_action_tab  t_tab_action;
        l_flg_enabled VARCHAR2(1 CHAR);
    
        l_tab_action t_coll_action;
        l_rec_action t_rec_action;
    
        l_id_profile_template wf_transition_config.id_profile_template%TYPE;
        l_id_functionality    wf_transition_config.id_functionality%TYPE;
        l_id_category         wf_transition_config.id_category%TYPE;
        l_in_status           VARCHAR2(1 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init get_actions / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow ||
                   ' i_id_status_begin=' || i_id_status_begin;
        pk_alertlog.log_debug(g_error);
    
        l_tab_action := t_coll_action();
        l_rec_action := t_rec_action();
    
        ----------------------
        -- FUNC
        ---------------------- 
    
        g_error               := 'Calling pk_tools.get_prof_profile_template';
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        l_id_functionality := 0;
    
        g_error       := 'Call pk_prof_utils.get_id_category / ID_PROF=' || i_prof.id;
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        g_error       := 'I_PROF=' || pk_utils.to_string(i_prof) || ' / ID_PROFILE_TEMPLATE=' || l_id_profile_template ||
                         ' ID_FUNC=' || l_id_functionality || ' ID_CAT=' || l_id_category;
        pk_alertlog.log_debug(g_error);
    
        -- 1- getting actions available in table ACTION
        g_error := 'Call pk_actions.get_actions / i_id_workflow=' || i_id_workflow;
        IF NOT pk_action.get_actions(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_subject     => i_subject,
                                     i_id_workflow => i_id_workflow,
                                     o_actions     => l_action_cur,
                                     o_error       => g_error_dummy)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_action_cur';
        FETCH l_action_cur BULK COLLECT
            INTO l_action_tab;
        CLOSE l_action_cur;
    
        <<action_loop>>
        FOR idx_action IN 1 .. l_action_tab.count
        LOOP
        
            -- 2- check if this action is valid (at least one transition available)        
            g_error := 'Call check_action_enabled / ID_ACTION=' || l_action_tab(idx_action).id_action || ' WF=' ||
                       i_id_workflow || ' STS_ID_BEG=' || i_id_status_begin || ' ID_CAT=' || l_id_category ||
                       ' PRF_TEMPL=' || l_id_profile_template || ' FUNC=' || l_id_functionality || ' I_PARAM=' ||
                       pk_utils.to_string(i_params);
            pk_alertlog.log_debug(g_error);
            IF NOT check_action_enabled(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_action           => l_action_tab(idx_action).id_action,
                                        i_id_workflow         => i_id_workflow,
                                        i_id_status_begin     => i_id_status_begin,
                                        i_id_category         => l_id_category,
                                        i_id_profile_template => l_id_profile_template,
                                        i_id_functionality    => l_id_functionality,
                                        i_param               => i_params,
                                        i_validate_trans      => i_validate_trans,
                                        o_enabled             => l_flg_enabled,
                                        o_in_status           => l_in_status)
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception;
            END IF;
        
            IF i_show_disable = pk_alert_constant.g_yes
               OR l_in_status = pk_alert_constant.g_yes
            THEN
                -- fill l_tab_action array        
                g_error := 'ID_ACTION=' || l_action_tab(idx_action).id_action || ' ID_PARENT=' || l_action_tab(idx_action)
                          .id_parent || ' LEVEL=' || l_action_tab(idx_action).level || ' FROM_STATE=' || l_action_tab(idx_action)
                          .to_state || ' TO_STATE=' || l_action_tab(idx_action).to_state || ' ICON=' || l_action_tab(idx_action).icon ||
                           ' FLG_DEFAULT=' || l_action_tab(idx_action).flg_default || ' FLG_STATUS=' || l_action_tab(idx_action)
                          .flg_status || ' INTERNAL_NAME=' || l_action_tab(idx_action).internal_name || ' FLG_ACTIVE=' ||
                           l_flg_enabled;
                pk_alertlog.log_debug(g_error);
            
                l_rec_action.id_action   := l_action_tab(idx_action).id_action;
                l_rec_action.id_parent   := l_action_tab(idx_action).id_parent;
                l_rec_action.level_nr    := l_action_tab(idx_action).level;
                l_rec_action.from_state  := l_action_tab(idx_action).from_state;
                l_rec_action.to_state    := l_action_tab(idx_action).to_state;
                l_rec_action.desc_action := l_action_tab(idx_action).desc_action;
                l_rec_action.icon        := l_action_tab(idx_action).icon;
                l_rec_action.flg_default := l_action_tab(idx_action).flg_default;
                --l_rec_action.flg_status    := l_action_tab(idx_action).flg_status;
                l_rec_action.action := l_action_tab(idx_action).internal_name;
            
                IF l_flg_enabled = pk_alert_constant.g_yes
                THEN
                    --l_rec_action.flg_active := pk_alert_constant.g_active;
                    l_rec_action.flg_active := l_action_tab(idx_action).flg_status;
                ELSE
                    l_rec_action.flg_active := pk_alert_constant.g_inactive;
                END IF;
            
                -- temporary code for MU
                -- to be updated: exluce de limitation of inactive status and PRESC_GROUP_PRINT subject
                IF l_rec_action.flg_active != pk_alert_constant.g_active
                   AND i_subject = 'PRESC_GROUP_PRINT'
                THEN
                    -- se acção não estiver active e for para impressão então não acrescenta à lista
                    NULL;
                ELSE
                    l_tab_action.extend;
                    l_tab_action(l_tab_action.last) := l_rec_action;
                END IF;
            END IF;
        END LOOP action_loop;
    
        -- 3- Returns action data, indicating a new column: FLG_ENABLED        
        OPEN o_actions FOR
            SELECT *
              FROM TABLE(CAST(l_tab_action AS t_coll_action));
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_actions);
            IF l_action_cur%ISOPEN
            THEN
                CLOSE l_action_cur;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_ACTIONS',
                                              o_error    => g_error_dummy);
            pk_types.open_my_cursor(o_actions);
            IF l_action_cur%ISOPEN
            THEN
                CLOSE l_action_cur;
            END IF;
            RETURN FALSE;
    END get_actions_subject;

    /********************************************************************************************
    * Get actions based on the multiple subject and workflow
    * the inactive records are dominant and overlap active records (for the same ID_ACTION)
    *
    * @param  i_lang              The language ID
    * @param  i_prof              The professional array
    * @param  i_subject           Action Subject
    * @param  i_id_workflow       Workflow ID
    * @param  i_id_status_begin   Workflow Status
    * @param  i_params
    * @param  i_validate_trans    Flag that indicates if trans is to be validated
    * @param  i_show_disable      Flag indicating if disabled status is to be shown
    * @param  o_actions           Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    FUNCTION get_actions_subject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_subject         IN action.subject%TYPE,
        i_id_workflow     IN table_number,
        i_id_status_begin IN table_number,
        i_params          IN table_varchar,
        i_validate_trans  IN VARCHAR2,
        i_show_disable    IN VARCHAR2,
        i_force_inactive  IN VARCHAR2,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_actions pk_types.cursor_type;
    
        l_table_actions table_table_varchar := table_table_varchar();
    
        l_id_action   table_number := table_number();
        l_id_parent   table_number := table_number();
        l_level_nr    table_number := table_number();
        l_desc_action table_varchar := table_varchar();
        l_icon        table_varchar := table_varchar();
        l_action      table_varchar := table_varchar();
        l_flg_active  table_varchar := table_varchar();
    
    BEGIN
        -- extend table_table by 10 because it's the number of fields of the cursor o_actions
        l_table_actions.extend(10);
    
        -- verify if inputs are ok
        IF i_id_workflow.count != i_id_status_begin.count
           OR i_id_workflow.count = 0
        THEN
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        END IF;
    
        -- loop through input table fields
        FOR idx IN i_id_workflow.first .. i_id_workflow.last
        LOOP
            -- get actions for the specific workflow and status
            IF NOT get_actions_subject(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_subject         => i_subject,
                                       i_id_workflow     => i_id_workflow(idx),
                                       i_id_status_begin => i_id_status_begin(idx),
                                       i_params          => i_params,
                                       i_validate_trans  => i_validate_trans,
                                       i_show_disable    => i_show_disable,
                                       o_actions         => l_actions)
            THEN
                pk_types.open_my_cursor(o_actions);
                RETURN FALSE;
            ELSE
                FETCH l_actions BULK COLLECT
                    INTO l_table_actions(1), -- ID_ACTION
                         l_table_actions(2), -- ID_PARENT
                         l_table_actions(3), -- LEVEL_NR
                         l_table_actions(4), -- FROM_STATE
                         l_table_actions(5), -- TO_STATE
                         l_table_actions(6), -- DESC_ACTION
                         l_table_actions(7), -- ICON
                         l_table_actions(8), -- FLG_DEFAULT
                         l_table_actions(9), -- ACTION
                         l_table_actions(10); -- FLG_ACTIVE
                CLOSE l_actions;
            END IF;
        
            -- add returned values from the cursor into associated fields
            IF l_table_actions(1).count != 0
            THEN
                FOR t_idx IN l_table_actions(1).first .. l_table_actions(1).last
                LOOP
                    l_id_action.extend;
                    l_id_parent.extend;
                    l_level_nr.extend;
                    l_desc_action.extend;
                    l_icon.extend;
                    l_action.extend;
                    l_flg_active.extend;
                
                    l_id_action(l_id_action.last) := l_table_actions(1) (t_idx);
                    l_id_parent(l_id_parent.last) := l_table_actions(2) (t_idx);
                    l_level_nr(l_level_nr.last) := l_table_actions(3) (t_idx);
                    l_desc_action(l_desc_action.last) := l_table_actions(6) (t_idx);
                    l_icon(l_icon.last) := l_table_actions(7) (t_idx);
                    l_action(l_action.last) := l_table_actions(9) (t_idx);
                    l_flg_active(l_flg_active.last) := l_table_actions(10) (t_idx);
                END LOOP;
            END IF;
        END LOOP;
    
        -- compose the output cursor
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   level_nr,
                   desc_action,
                   icon,
                   action,
                   decode(i_force_inactive, pk_alert_constant.g_yes, pk_alert_constant.g_inactive, flg_active) flg_active
              FROM (SELECT t1.column_value id_action,
                           t2.column_value id_parent,
                           t3.column_value level_nr,
                           t4.column_value desc_action,
                           t5.column_value icon,
                           t6.column_value action,
                           t7.column_value flg_active,
                           row_number() over(PARTITION BY t1.column_value ORDER BY decode(t7.column_value, 'I', 1, 2)) rn
                      FROM (SELECT rownum rnum, column_value
                              FROM TABLE(l_id_action)) t1,
                           (SELECT rownum rnum, column_value
                              FROM TABLE(l_id_parent)) t2,
                           (SELECT rownum rnum, column_value
                              FROM TABLE(l_level_nr)) t3,
                           (SELECT rownum rnum, column_value
                              FROM TABLE(l_desc_action)) t4,
                           (SELECT rownum rnum, column_value
                              FROM TABLE(l_icon)) t5,
                           (SELECT rownum rnum, column_value
                              FROM TABLE(l_action)) t6,
                           (SELECT rownum rnum, column_value
                              FROM TABLE(l_flg_active)) t7
                     WHERE t1.rnum = t2.rnum
                       AND t1.rnum = t3.rnum
                       AND t1.rnum = t4.rnum
                       AND t1.rnum = t5.rnum
                       AND t1.rnum = t6.rnum
                       AND t1.rnum = t7.rnum)
             WHERE rn = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTIONS_SUBJECT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions_subject;

    /********************************************************************
    ********************************************************************/
    FUNCTION is_action_valid
    (
        i_id_workflow  IN wf_workflow.id_workflow%TYPE,
        i_id_wf_status IN wf_status.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_active wf_status_workflow.flg_active%TYPE;
    BEGIN
        SELECT wsw.flg_active
          INTO l_flg_active
          FROM wf_status_workflow wsw
         WHERE wsw.id_workflow = i_id_workflow
           AND wsw.id_status = i_id_wf_status;
    
        RETURN l_flg_active;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_flg_active;
    END is_action_valid;

    FUNCTION get_wf_stat_col_by_action
    (
        i_id_action IN wf_action.id_action%TYPE,
        i_workflows IN table_number
    ) RETURN table_varchar2 IS
        l_ret table_varchar2;
    BEGIN
        SELECT concat(a.id_workflow, concat('|', a.id_status_begin))
          BULK COLLECT
          INTO l_ret
          FROM wf_action a
         WHERE a.id_action = i_id_action
           AND a.id_workflow IN (SELECT column_value
                                   FROM TABLE(i_workflows));
        RETURN l_ret;
    END get_wf_stat_col_by_action;

    /********************************************************************************************
    * Same as get_wf_stat_col_by_action but also takes into account the status of the WF_TRANSITION
    *
    * @param  i_id_action         Action to validate
    * @param  i_workflows         Workflows to validate
    *
    *
    * @author Pedro Teixeira
    * @since  03/05/2011
    *
    ********************************************************************************************/
    FUNCTION get_wf_stat_act_by_action
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN wf_action.id_action%TYPE,
        i_workflows IN table_number
    ) RETURN table_varchar2 IS
        l_ret table_varchar2;
        --l_id_market market.id_market%TYPE;    
        l_id_profile_template wf_status_config.id_profile_template%TYPE;
        l_id_functionality    wf_status_config.id_functionality%TYPE;
        l_id_category         category.id_category%TYPE;
    BEGIN
    
        g_error               := 'l_id_profile_template';
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error       := 'l_id_category';
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error            := 'l_id_functionality';
        l_id_functionality := 0;
    
        --l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        SELECT concat(id_workflow, concat('|', id_status_begin))
          BULK COLLECT
          INTO l_ret
          FROM (SELECT a.id_workflow,
                       a.id_status_begin,
                       wtc.flg_permission,
                       row_number() over(PARTITION BY a.id_workflow, a.id_status_begin ORDER BY id_institution DESC, id_software DESC, id_category DESC, id_profile_template DESC, id_functionality DESC) rn
                  FROM wf_action a
                  JOIN wf_transition wt
                    ON (wt.id_workflow = a.id_workflow AND wt.id_status_begin = a.id_status_begin AND
                       wt.id_status_end = a.id_status_end AND wt.id_workflow_action = a.id_workflow_action)
                  JOIN wf_transition_config wtc
                
                    ON (wt.id_workflow = wtc.id_workflow AND wt.id_status_begin = wtc.id_status_begin AND
                       wt.id_status_end = wtc.id_status_end AND wt.id_workflow_action = wtc.id_workflow_action)
                
                 WHERE a.id_action = i_id_action
                   AND a.id_workflow IN (SELECT column_value
                                           FROM TABLE(i_workflows))
                   AND wt.flg_available = pk_alert_constant.g_yes
                      --configurations
                   AND wtc.id_software IN (0, i_prof.software)
                   AND wtc.id_institution IN (0, i_prof.institution)
                   AND wtc.id_category IN (0, l_id_category)
                   AND wtc.id_profile_template IN (0, l_id_profile_template)
                   AND wtc.id_functionality IN (0, l_id_functionality))
         WHERE rn = 1
           AND flg_permission = g_transition_allow;
    
        RETURN l_ret;
    END get_wf_stat_act_by_action;
    /********************************************************************
    ********************************************************************/

    PROCEDURE get_all_actions_by_wf_col
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) IS
        l_act_col t_coll_action;
    BEGIN
        --Get all the actions for the given workflows
        l_act_col := pk_action.tf_get_actions_by_wf_col(i_lang                 => i_lang,
                                                        i_prof                 => i_prof,
                                                        i_workflows            => i_workflows,
                                                        i_class_origin         => i_class_origin,
                                                        i_class_origin_context => i_class_origin_context);
    
        --Add a collection of id_workflow|id_status of possible from_states per action
        OPEN o_actions FOR
            SELECT a.*, get_wf_stat_col_by_action(a.id_action, i_workflows) active_states
              FROM TABLE(l_act_col) a;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ALL_ACTIONS_BY_WF_COL',
                                              o_error    => g_error_dummy);
            pk_types.open_my_cursor(o_actions);
    END get_all_actions_by_wf_col;

    PROCEDURE get_act_wf_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_actions              IN table_number,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2 DEFAULT NULL,
        i_class_origin_context IN VARCHAR2 DEFAULT NULL,
        o_actions              OUT pk_types.cursor_type
    ) IS
        l_col_action t_coll_action;
    BEGIN
        --Gets actions information for the given action ID's set
        l_col_action := pk_action.tf_get_actions_by_id_col(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_actions              => i_actions,
                                                           i_class_origin         => i_class_origin,
                                                           i_class_origin_context => i_class_origin_context);
    
        --Add a collection of id_workflow|id_status of possible from_states per action
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr,
                   a.from_state,
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   a.flg_active,
                   a.action,
                   nvl2(i_class_origin,
                        pk_navigation.get_action_flg_mutiple(i_lang                 => i_lang,
                                                             i_prof                 => i_prof,
                                                             i_class_origin         => i_class_origin,
                                                             i_class_origin_context => i_class_origin_context,
                                                             i_id_action            => id_action),
                        NULL) flg_multiple,
                   get_wf_stat_act_by_action(i_lang, i_prof, a.id_action, i_workflows) AS active_states
              FROM TABLE(l_col_action) a;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACT_WF_LIST',
                                              o_error    => g_error_dummy);
            pk_types.open_my_cursor(o_actions);
    END get_act_wf_list;

    PROCEDURE get_wf_trans_status_end
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_wf_action    IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        o_id_status_end   OUT wf_status.id_status%TYPE
    ) IS
        l_id_market market.id_market%TYPE;
    
        l_id_profile_template wf_status_config.id_profile_template%TYPE;
        l_id_functionality    wf_status_config.id_functionality%TYPE;
        l_id_category         category.id_category%TYPE;
    BEGIN
    
        g_error               := 'l_id_profile_template';
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error       := 'l_id_category';
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error            := 'l_id_functionality';
        l_id_functionality := 0;
    
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        SELECT id_status_end
          INTO o_id_status_end
          FROM wf_transition wt
          JOIN wf_workflow_market wwm
            ON (wwm.id_workflow = wt.id_workflow)
          JOIN wf_workflow_action wa
            ON (wt.id_workflow_action = wa.id_workflow_action)
           AND wwm.id_market = nvl((SELECT wwmi.id_market
                                     FROM wf_workflow_market wwmi
                                    WHERE wwmi.id_workflow = wwm.id_workflow
                                      AND wwmi.id_market = l_id_market),
                                   pk_alert_constant.g_id_market_all)
           AND wt.flg_available = pk_alert_constant.g_yes
           AND wa.flg_available = pk_alert_constant.g_yes
           AND (wt.id_workflow, wt.id_status_begin, wt.id_status_end, wt.id_workflow_action) IN
               (SELECT id_workflow, id_status_begin, id_status_end, id_workflow_action
                  FROM (SELECT id_workflow,
                               id_status_begin,
                               id_status_end,
                               id_workflow_action,
                               row_number() over(PARTITION BY wtc.id_status_end ORDER BY id_institution DESC, id_software DESC, id_category DESC, id_profile_template DESC, id_functionality DESC) rn
                          FROM wf_transition_config wtc
                         WHERE wtc.id_software IN (0, i_prof.software)
                           AND wtc.id_institution IN (0, i_prof.institution)
                           AND wtc.id_category IN (0, l_id_category)
                           AND wtc.id_profile_template IN (0, l_id_profile_template)
                           AND wtc.id_functionality IN (0, l_id_functionality)
                           AND wtc.id_status_begin = i_id_status_begin
                           AND wtc.id_workflow_action = i_id_wf_action
                           AND wtc.id_workflow = i_id_workflow)
                 WHERE rn = 1);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WF_TRANS_STATUS',
                                              o_error    => g_error_dummy);
            RAISE;
    END get_wf_trans_status_end;

    FUNCTION get_actions_by_wf
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_actions FOR
            SELECT v.id_action,
                   v.id_parent,
                   v.level_nr,
                   v.from_state,
                   v.to_state,
                   pk_message.get_message(i_lang, i_prof, v.code_action) AS desc_action,
                   v.icon,
                   v.flg_default,
                   v.flg_active,
                   v.action,
                   flg_multiple,
                   (SELECT pk_workflow.get_wf_stat_act_by_action(i_lang, i_prof, v.id_action, i_workflows)
                      FROM dual) active_states
            
              FROM (SELECT t.code_action,
                           t.id_action,
                           t.id_parent,
                           1 level_nr,
                           t.from_state,
                           t.to_state,
                           t.icon,
                           t.flg_default,
                           t.flg_active,
                           t.flg_flash_action_type || '|' || CASE
                                WHEN t.flg_flash_action_type IN ('M', 'D') THEN
                                 t.flash_method_name
                                WHEN t.flg_flash_action_type IN ('T') THEN
                                 (SELECT pk_navigation.get_screen_key(i_lang,
                                                                      i_prof,
                                                                      i_class_origin,
                                                                      i_class_origin_context,
                                                                      t.id_action)
                                    FROM dual)
                            END AS action,
                           (SELECT pk_navigation.get_action_flg_mutiple(i_lang                 => i_lang,
                                                                        i_prof                 => i_prof,
                                                                        i_class_origin         => i_class_origin,
                                                                        i_class_origin_context => i_class_origin_context,
                                                                        i_id_action            => t.id_action)
                              FROM dual) flg_multiple
                    
                      FROM (SELECT DISTINCT a.code_action,
                                            a.id_action,
                                            a.id_parent,
                                            a.from_state,
                                            a.to_state,
                                            a.icon,
                                            a.flg_default,
                                            a.flg_status AS flg_active,
                                            a.flg_flash_action_type,
                                            a.flash_method_name
                              FROM wf_transition_config wftc
                             INNER JOIN wf_workflow_action wfwa
                                ON (wfwa.id_workflow_action = wftc.id_workflow_action)
                             INNER JOIN wf_action wfa
                                ON (wfa.id_workflow_action = wfwa.id_workflow_action)
                             INNER JOIN action a
                                ON (a.id_action = wfa.id_action)
                             WHERE wftc.id_workflow IN (SELECT /*+opt_estimate(table, tmp, rows=1)*/
                                                         *
                                                          FROM TABLE(i_workflows) tmp)) t) v;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTIONS_BY_WF',
                                              o_error    => g_error_dummy);
            pk_types.open_my_cursor(o_actions);
        
            RAISE;
    END get_actions_by_wf;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_workflow;
/
