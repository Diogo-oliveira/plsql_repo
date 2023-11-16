/*-- Last Change Revision: $Rev: 2027210 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ia_util_url IS

    FUNCTION get_app_url
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_app_name   IN sys_config.id_sys_config%TYPE,
        i_id_episode IN NUMBER,
        o_url        OUT VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sql         VARCHAR2(4000);
        l_url         VARCHAR2(2000);
        l_system_exec VARCHAR2(1);
        l_app_name    sys_config.value%TYPE;
    
        l_error VARCHAR2(2000);
    
    BEGIN
    
        o_flg_show := 'N';
    
        g_error    := 'CALL TO pk_sysconfig.get_config';
        l_app_name := pk_sysconfig.get_config(i_code_cf => i_app_name, i_prof => i_prof);
    
        IF l_app_name IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := 'Y';
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
            g_error := 'CALL TO pk_ia_alert.get_app_url';
            l_sql   := 'BEGIN pk_ia_alert.get_app_url(:1, :2, :3, :4, :5, :6, :7, :8); END;';
            EXECUTE IMMEDIATE l_sql
                USING IN l_app_name, IN i_id_episode, IN i_prof.id, IN i_prof.software, IN i_prof.institution, OUT l_url, OUT l_system_exec, OUT l_error;
        
            g_error := 'EXTERNAL ERROR';
            IF nvl(l_error, '#') != '#'
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'No URL';
            IF nvl(l_url, '#') = '#'
            THEN
                o_url       := 'N';
                o_flg_show  := 'Y';
                o_button    := 'R';
                o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
            ELSE
                o_url := l_url;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_app_url;

    FUNCTION get_context_url
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_app_name   IN sys_config.id_sys_config%TYPE,
        i_id_episode IN NUMBER,
        o_url        OUT VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sql         VARCHAR2(4000);
        l_url         VARCHAR2(2000);
        l_system_exec VARCHAR2(1);
        l_error       VARCHAR2(2000);
    
    BEGIN
    
        o_flg_show := 'N';
    
        IF i_app_name IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := 'Y';
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
            g_error := 'CALL TO pk_ia_alert.get_app_url';
            l_sql   := 'BEGIN pk_ia_alert.get_app_url(:1, :2, :3, :4, :5, :6, :7, :8); END;';
            EXECUTE IMMEDIATE l_sql
                USING IN i_app_name, IN i_id_episode, IN i_prof.id, IN i_prof.software, IN i_prof.institution, OUT l_url, OUT l_system_exec, OUT l_error;
        
            g_error := 'EXTERNAL ERROR';
            IF nvl(l_error, '#') != '#'
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'No URL';
            IF nvl(l_url, '#') = '#'
            THEN
                o_url       := 'N';
                o_flg_show  := 'Y';
                o_button    := 'R';
                o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
            ELSE
                o_url := l_url;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONTEXT_URL',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_context_url;

    FUNCTION get_adw_url
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_adw_open_browser(i_lang      => i_lang,
                                    i_prof      => i_prof,
                                    i_url_name  => i_url_name,
                                    i_url_prof  => pk_alert_constant.g_yes,
                                    o_url       => o_url,
                                    o_flg_show  => o_flg_show,
                                    o_button    => o_button,
                                    o_msg_title => o_msg_title,
                                    o_msg       => o_msg,
                                    o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADW_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adw_url;

    FUNCTION get_adw_open_browser
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_adw_open_browser(i_lang      => i_lang,
                                    i_prof      => i_prof,
                                    i_url_name  => i_url_name,
                                    i_url_prof  => pk_alert_constant.g_no,
                                    o_url       => o_url,
                                    o_flg_show  => o_flg_show,
                                    o_button    => o_button,
                                    o_msg_title => o_msg_title,
                                    o_msg       => o_msg,
                                    o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADW_OPEN_BROWSER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adw_open_browser;

    FUNCTION get_adw_open_browser
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        i_url_prof  IN VARCHAR2,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url_name sys_config.value%TYPE;
    
    BEGIN
    
        o_flg_show := 'N';
    
        g_error    := 'CALL TO pk_sysconfig.get_config';
        l_url_name := pk_sysconfig.get_config(i_code_cf => i_url_name, i_prof => i_prof);
    
        IF l_url_name IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := 'Y';
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
            g_error := 'CALL TO pk_ia_alert.get_app_url';
            IF (i_url_prof = pk_alert_constant.g_yes)
            THEN
                o_url := l_url_name || i_prof.id;
            ELSE
                o_url := l_url_name;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADW_OPEN_BROWSER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adw_open_browser;

    FUNCTION get_app_url_iav3
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_app_cfg   IN sys_config.id_sys_config%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_app_name sys_config.value%TYPE;
        l_hashmap  pk_ia_external_info.tt_table_varchar;
        l_url      VARCHAR2(4000);
    
        function_call_excep EXCEPTION;
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
    
        o_flg_show := pk_alert_constant.g_no;
    
        g_error    := 'CALL TO pk_sysconfig.get_config';
        l_app_name := pk_sysconfig.get_config(i_code_cf => i_app_cfg, i_prof => i_prof);
    
        IF l_app_name IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := pk_alert_constant.g_yes;
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
            g_error := 'Building hashmap parameters';
            l_hashmap('id_professional') := table_varchar(to_char(i_prof.id));
            l_hashmap('id_institution') := table_varchar(to_char(i_prof.institution));
            l_hashmap('id_software') := table_varchar(to_char(i_prof.software));
            l_hashmap('id_episode') := table_varchar(to_char(i_episode));
            l_hashmap('id_patient') := table_varchar(to_char(i_patient));
            l_hashmap('app_name') := table_varchar(l_app_name);
        
            g_error := 'CALL TO pk_ia_external_info.get_app_url';
            l_ret   := pk_ia_external_info.get_app_url(i_prof    => i_prof,
                                                       i_hashmap => l_hashmap,
                                                       o_url     => l_url,
                                                       o_error   => l_error);
        
            IF l_ret = FALSE
            THEN
                RAISE function_call_excep;
            END IF;
        
            g_error := 'No URL';
            IF l_url IS NULL
            THEN
                o_url       := 'N';
                o_flg_show  := pk_alert_constant.g_yes;
                o_button    := 'R';
                o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
            ELSE
                o_url := l_url;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'Error trying to fetch URL from external systems through INTER-ALERT',
                                              'GET_APP_URL_IAV3',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'GET_APP_URL_IAV3',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_app_url_iav3;

    FUNCTION get_context_url_iav3
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_app_cfg   IN links.context_link%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hashmap pk_ia_external_info.tt_table_varchar;
        l_url     VARCHAR2(4000);
    
        function_call_excep EXCEPTION;
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
    
        o_flg_show := pk_alert_constant.g_no;
    
        IF i_app_cfg IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := pk_alert_constant.g_yes;
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
        
            g_error := 'Building hashmap parameters';
            l_hashmap('id_professional') := table_varchar(to_char(i_prof.id));
            l_hashmap('id_institution') := table_varchar(to_char(i_prof.institution));
            l_hashmap('id_software') := table_varchar(to_char(i_prof.software));
            l_hashmap('id_episode') := table_varchar(to_char(i_episode));
            l_hashmap('id_patient') := table_varchar(to_char(i_patient));
            l_hashmap('app_name') := table_varchar(i_app_cfg);
        
            g_error := 'CALL TO pk_ia_external_info.get_app_url';
            l_ret   := pk_ia_external_info.get_app_url(i_prof     => i_prof,
                                                       i_hashmap  => l_hashmap,
                                                       i_app_name => i_app_cfg,
                                                       o_url      => l_url,
                                                       o_error    => l_error);
        
            IF l_ret = FALSE
            THEN
                RAISE function_call_excep;
            END IF;
        
            g_error := 'No URL';
            IF l_url IS NULL
            THEN
                o_url       := 'N';
                o_flg_show  := pk_alert_constant.g_yes;
                o_button    := 'R';
                o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
            ELSE
                o_url := l_url;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'Error trying to fetch URL from external systems through INTER-ALERT',
                                              'GET_CONTEXT_URL_IAV3',
                                              g_package_owner,
                                              g_package_name,
                                              'get_context_url_iav3',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_context_url_iav3',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_context_url_iav3;

    FUNCTION get_app_url_info_button
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_app_cfg               IN sys_config.id_sys_config%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_patient               IN patient.id_patient%TYPE,
        i_code                  table_varchar,
        i_standard              table_varchar,
        i_description           table_varchar,
        i_age                   IN patient.age%TYPE,
        i_gender                IN patient.gender%TYPE,
        i_information_recipient IN VARCHAR2,
        i_url                   IN links.normal_link%TYPE,
        o_url                   OUT VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hashmap pk_ia_external_info.tt_table_varchar;
        l_url     VARCHAR2(4000);
    
        function_call_excep EXCEPTION;
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
    
        o_flg_show := pk_alert_constant.g_no;
        g_error    := 'CALL TO pk_sysconfig.get_config';
    
        IF i_app_cfg IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := pk_alert_constant.g_yes;
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
        
            g_error := 'Building hashmap parameters';
            l_hashmap('id_professional') := table_varchar(to_char(i_prof.id));
            l_hashmap('id_institution') := table_varchar(to_char(i_prof.institution));
            l_hashmap('id_software') := table_varchar(to_char(i_prof.software));
            l_hashmap('id_episode') := table_varchar(to_char(i_episode));
            l_hashmap('id_patient') := table_varchar(to_char(i_patient));
        
            l_hashmap('app_name') := table_varchar(i_app_cfg); -- 'INFO_BUTTON' ?
        
            l_hashmap('code') := i_code; -- hl7
            l_hashmap('standard') := i_standard; -- terminology
            l_hashmap('description') := i_description; -- description           
        
            l_hashmap('age') := table_varchar(to_char(i_age)); -- age in years
        
            IF to_char(i_age) IS NOT NULL
            THEN
                l_hashmap('age_unit') := table_varchar('d'); --  years (a), months (mo), weeks (wk), days (d), or hours (h).
            END IF;
        
            l_hashmap('gender') := table_varchar(i_gender); --  gender            
            l_hashmap('information_recipient') := table_varchar(i_information_recipient); --  information recipient (PAT OR PROV (patient or provider))                         
        
            l_hashmap('url') := table_varchar(i_url); --  url       
            l_hashmap('srcsys') := table_varchar(pk_sysconfig.get_config(i_code_cf => 'SRCSYS', i_prof => i_prof)); -- UpToDate account identifier            
        
            g_error := 'CALL TO pk_ia_external_info.get_app_url';
            l_ret   := pk_ia_external_info.get_app_url(i_prof     => i_prof,
                                                       i_hashmap  => l_hashmap,
                                                       i_app_name => i_app_cfg,
                                                       o_url      => l_url,
                                                       o_error    => l_error);
        
            IF l_ret = FALSE
            THEN
                RAISE function_call_excep;
            END IF;
        
            g_error := 'No URL';
            IF l_url IS NULL
            THEN
                o_url       := 'N';
                o_flg_show  := pk_alert_constant.g_yes;
                o_button    := 'R';
                o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
            ELSE
                o_url := l_url;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'Error trying to fetch URL from external systems through INTER-ALERT',
                                              'GET_APP_URL_INFO_BUTTON',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'GET_APP_URL_INFO_BUTTON',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_app_url_info_button;

    FUNCTION get_app_url_replace
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_app_cfg    IN sys_config.id_sys_config%TYPE,
        i_replace    IN table_varchar,
        i_url        IN VARCHAR2,
        i_id_content IN VARCHAR2,
        i_begin_tag  IN VARCHAR2 DEFAULT '{_',
        i_end_tag    IN VARCHAR2 DEFAULT '_}',
        o_url        OUT VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url       VARCHAR2(4000);
        l_begin_tag VARCHAR2(10) := '{_';
        l_end_tag   VARCHAR(10) := '_}';
    
        function_call_excep EXCEPTION;
    
        l_ret   BOOLEAN;
        l_error t_error_out;
    
    BEGIN
    
        IF (i_url IS NULL AND i_id_content IS NULL)
           OR (i_url IS NULL AND i_id_content IS NULL)
        THEN
            RAISE function_call_excep;
        END IF;
    
        IF i_id_content IS NOT NULL
        THEN
            l_url := pk_links.get_links_val(i_lang, i_prof, i_id_content);
        ELSIF i_url IS NOT NULL
        THEN
            l_url := i_url;
        END IF;
    
        FOR i IN i_replace.first .. i_replace.last
        LOOP
            l_url := REPLACE(l_url, nvl(i_begin_tag, l_begin_tag) || i || nvl(i_end_tag, l_end_tag), i_replace(i));
        END LOOP;
    
        g_error := 'No URL';
        IF l_url IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := pk_alert_constant.g_yes;
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
            o_url := l_url;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'ONLY I_URL OR I_ID_LINKS BAD BEHAVIOR',
                                              'GET_APP_URL_INFO_BUTTON',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'GET_APP_URL_INFO_BUTTON_VIDAL',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APP_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_app_url_replace;

    FUNCTION get_buy_portal_url
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        i_url_hash  IN VARCHAR2,
        i_area      IN VARCHAR2,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url_name sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'INIT get_buy_portal_url';
    
        o_flg_show := 'N';
        l_url_name := pk_sysconfig.get_config(i_code_cf => i_url_name, i_prof => i_prof);
    
        IF l_url_name IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := 'Y';
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
        
            IF i_area = g_buy_type_prof
            THEN
                o_url := l_url_name || 'id_user=' || i_prof.id || '&id_institution=' || i_prof.institution || '&vf=' ||
                         i_url_hash;
            ELSIF i_area = g_buy_type_inst
            THEN
                o_url := l_url_name || 'id_institution=' || i_prof.institution || '&vf=' || i_url_hash;
            ELSE
                g_error := 'INVALIDE I_AREA';
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BUY_PORTAL_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_buy_portal_url;

    FUNCTION get_adw_presc_url
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        i_area      IN VARCHAR2,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url_name sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'INIT get_adw_presc_url';
    
        o_flg_show := 'N';
        l_url_name := pk_sysconfig.get_config(i_code_cf => i_url_name, i_prof => i_prof);
    
        IF l_url_name IS NULL
        THEN
            o_url       := 'N';
            o_flg_show  := 'Y';
            o_button    := 'R';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M074');
        ELSE
            IF i_area = g_buy_type_prof
            THEN
                o_url := l_url_name || i_prof.id;
            ELSIF i_area = g_buy_type_inst
            THEN
                o_url := l_url_name || i_prof.institution;
            ELSE
                g_error := 'INVALIDE I_AREA';
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADW_PRESC_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adw_presc_url;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ia_util_url;
/
