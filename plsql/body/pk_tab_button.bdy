/*-- Last Change Revision: $Rev: 2027779 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_tab_button IS

    /*
    * Returns all available tab buttons that should be presented to one user depending on is profile
    *
    * @param  I_LANG                      language associated to the professional executing the request
    * @param  I_PROF                      professional (ID, INSTITUTION, SOFTWARE)
    * @param  SUBJECT                     SUBJECT string that identifies the tab buttons that should be returned
    * @param  O_TAB_BUTTON                information of available tab buttons
    * @param  O_ERROR                     warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Elisabete Bugalho
    * @version 1.0
    * @since   23-Feb-2010
    *
    */
    FUNCTION get_prof_tab_button
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN tab.subject%TYPE,
        o_tab_button OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_my_prof profile_template.id_profile_template%TYPE;
    
        l_num NUMBER;
    BEGIN
        g_error   := 'GET_PROF_PROFILE_TEMPLATE';
        l_my_prof := pk_prof_utils.get_prof_profile_template(i_prof);
        g_error   := 'GET_O_TAB_BUTTON';
    
        SELECT COUNT(1) -- configurações para a instituição
          INTO l_num
          FROM tab t, tab_button tb, tab_button_prof_inst tbpi, sys_button sb
         WHERE t.subject = i_subject
           AND tb.id_tab = t.id_tab
           AND tb.id_sys_button = sb.id_sys_button
           AND tbpi.id_tab_button = tb.id_tab_button
           AND tbpi.id_profile_template = l_my_prof
           AND tbpi.id_institution IN (0, i_prof.institution)
              --   AND tbpi.flg_available = g_yes
           AND tb.flg_available = g_yes;
    
        IF l_num > 0 -- se existem configurações para a instituição
        THEN
        
            OPEN o_tab_button FOR
                SELECT tb.flg_identifier flg_action,
                       pk_message.get_message(i_lang, i_prof, sb.code_tooltip_title) desc_tab_button,
                       sb.icon icon,
                       nvl(tbpi.rank, tb.rank) rank,
                       tb.id_tab_button,
                       tbpi.flg_default
                  FROM tab t, tab_button tb, tab_button_prof_inst tbpi, sys_button sb
                 WHERE t.subject = i_subject
                   AND tb.id_tab = t.id_tab
                   AND tb.id_sys_button = sb.id_sys_button
                   AND tbpi.id_tab_button = tb.id_tab_button
                   AND tbpi.id_profile_template = l_my_prof
                   AND tbpi.id_institution IN (0, i_prof.institution)
                   AND tbpi.flg_available = g_yes
                   AND tb.flg_available = g_yes
                 ORDER BY rank ASC, desc_tab_button ASC;
        
        ELSE
            -- configurações por mercado para o perfil
        
            OPEN o_tab_button FOR
                SELECT tb.flg_identifier flg_action,
                       decode(tbp.code_tab_button,
                              NULL,
                              pk_message.get_message(i_lang, i_prof, sb.code_tooltip_title),
                              pk_translation.get_translation(i_lang, tbp.code_tab_button)) desc_tab_button,
                       sb.icon icon,
                       nvl(tbp.rank, tb.rank) rank,
                       tb.id_tab_button,
                       tbp.flg_default
                  FROM tab t, tab_button tb, tab_button_ptm tbp, profile_template_market ptm, sys_button sb
                 WHERE t.subject = i_subject
                   AND tb.id_tab = t.id_tab
                   AND tb.id_sys_button = sb.id_sys_button
                   AND tbp.id_tab_button = tb.id_tab_button
                   AND ptm.id_profile_template = l_my_prof
                   AND tbp.id_profile_template_market = ptm.id_profile_template_market
                   AND tb.flg_available = g_yes
                   AND tbp.flg_available = g_yes
                 ORDER BY rank ASC, desc_tab_button ASC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_tab_button);
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_PROF_TAB_BUTTON',
                                                     o_error);
    END get_prof_tab_button;

    /*
    * Returns the default option for this professional
    *
    * @param  I_LANG                      language associated to the professional executing the request
    * @param  I_PROF                      professional (ID, INSTITUTION, SOFTWARE)
    * @param  SUBJECT                     SUBJECT string that identifies the tab buttons that should be returned
    * @param  o_tab_button_default        Default tab button
    * @param  O_ERROR                     warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Elisabete Bugalho
    * @version 1.0
    * @since   23-Feb-2010
    *
    */
    FUNCTION get_prof_tab_button_default
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_subject            IN tab.subject%TYPE,
        o_tab_button_default OUT tab_button_ptm.flg_identifier%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_my_prof profile_template.id_profile_template%TYPE;
        l_num     NUMBER;
    BEGIN
        g_error   := 'GET_PROF_PROFILE_TEMPLATE';
        l_my_prof := pk_prof_utils.get_prof_profile_template(i_prof);
    
        SELECT COUNT(1)
          INTO l_num
          FROM tab t, tab_button tb, tab_button_prof_inst tbpi
         WHERE t.id_tab = tb.id_tab
           AND t.subject = i_subject
           AND tbpi.id_tab_button = tb.id_tab_button
           AND tbpi.id_profile_template = l_my_prof
           AND tbpi.id_institution IN (0, i_prof.institution)
           AND tb.flg_available = g_yes;
    
        IF l_num > 0
        THEN
            BEGIN
                SELECT tb.flg_identifier
                  INTO o_tab_button_default
                  FROM tab t, tab_button tb, tab_button_prof_inst tbpi
                 WHERE t.id_tab = tb.id_tab
                   AND t.subject = i_subject
                   AND tbpi.id_tab_button = tb.id_tab_button
                   AND tbpi.id_profile_template = l_my_prof
                   AND tbpi.id_institution IN (0, i_prof.institution)
                   AND tb.flg_available = g_yes
                   AND tbpi.flg_default = g_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    o_tab_button_default := NULL;
            END;
        
        ELSE
            BEGIN
                SELECT nvl(tbp.flg_identifier, tb.flg_identifier)
                  INTO o_tab_button_default
                  FROM tab t, tab_button tb, tab_button_ptm tbp, profile_template_market ptm
                 WHERE t.id_tab = tb.id_tab
                   AND t.subject = i_subject
                   AND tbp.id_tab_button = tb.id_tab_button
                   AND tbp.id_profile_template_market = ptm.id_profile_template_market
                   AND ptm.id_profile_template = l_my_prof
                   AND tb.flg_available = g_yes
                   AND tbp.flg_default = g_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    o_tab_button_default := NULL;
            END;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_tab_button_default := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_PROF_TAB_BUTTON_DEFAULT',
                                                     o_error);
    END get_prof_tab_button_default;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_tab_button;
/
