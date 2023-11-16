/*-- Last Change Revision: $Rev: 2027852 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_view_option IS

    /*
    * Returns all available options that should be presented to one user when selected the VIEW button.
    * (the result depends of professional profile, selected button and selected button parent button)
    *
    * @param  I_LANG                      language associated to the professional executing the request
    * @param  I_PROF                      professional (ID, INSTITUTION, SOFTWARE)
    * @param  SUBJECT                     SUBJECT string that identifies the view options that should be returned to FLASH
    * @param  O_VIEW_OPTIONS              information of available options in VIEW button
    * @param  O_ERROR                     warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   09-Mar-2009
    *
    */
    FUNCTION get_prof_view_options
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_subject      IN view_option.subject%TYPE,
        o_view_options OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_PROFILE_VIEW_OPTIONS';
        OPEN o_view_options FOR
            SELECT v.id_view_option id_action,
                   v.id_parent id_parent,
                   v.screen_identifier flg_type,
                   pk_message.get_message(i_lang, i_prof, v.code_view_option) desc_action,
                   v.icon icon,
                   v.flg_action flg_action,
                   nvl(rank2, rank1) rank,
                   v.flg_access,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_create, NULL) flg_create,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_cancel, NULL) flg_cancel,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_search, NULL) flg_search,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_print, NULL) flg_print,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_ok, NULL) flg_ok,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_detail, NULL) flg_detail,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_content, NULL) flg_content,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_help, NULL) flg_help,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_graph, NULL) flg_graph,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_vision, NULL) flg_vision,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_digital, NULL) flg_digital,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_freq, NULL) flg_freq,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_no, NULL) flg_no,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_action_profile, NULL) flg_action,
                   decode(v.flg_access, pk_alert_constant.g_yes, v.flg_view, NULL) flg_view,
                   decode(v.id_view_option_inst, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_default
              FROM (SELECT vo.id_view_option,
                           vo.id_parent,
                           vo.screen_identifier,
                           vo.code_view_option,
                           vo.icon,
                           vo.flg_action,
                           voc.rank             rank2,
                           vo.rank              rank1,
                           voc.flg_access,
                           voc.flg_create,
                           voc.flg_cancel,
                           voc.flg_search,
                           voc.flg_print,
                           voc.flg_ok,
                           voc.flg_detail,
                           voc.flg_content,
                           voc.flg_help,
                           voc.flg_graph,
                           voc.flg_vision,
                           voc.flg_digital,
                           voc.flg_freq,
                           voc.flg_no,
                           voc.flg_action       flg_action_profile,
                           voc.flg_view,
                           voci.id_view_option  id_view_option_inst
                      FROM view_option vo
                     INNER JOIN view_option_config voc
                        ON voc.id_view_option = vo.id_view_option
                      LEFT JOIN view_option_config_inst voci
                        ON voc.id_view_option = voci.id_view_option
                       AND voc.id_profile_template = voci.id_profile_template
                       AND voci.id_institution = i_prof.institution
                     WHERE vo.subject = i_subject
                       AND voc.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)
                       AND voc.flg_available = g_yes) v
            CONNECT BY PRIOR v.id_view_option = v.id_parent
             START WITH v.id_parent IS NULL
             ORDER BY flg_default DESC, rank ASC, desc_action ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_view_options);
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_PROF_VIEW_OPTIONS',
                                                     o_error);
    END get_prof_view_options;

    FUNCTION get_prof_default_view
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN view_option.subject%TYPE,
        o_id_view_option OUT view_option.id_view_option%TYPE,
        o_screen         OUT view_option.screen_identifier%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --   NULL;
        BEGIN
            SELECT voci.id_view_option, vo.screen_identifier
              INTO o_id_view_option, o_screen
              FROM view_option vo
             INNER JOIN view_option_config voc
                ON voc.id_view_option = vo.id_view_option
             INNER JOIN view_option_config_inst voci
                ON voc.id_view_option = voci.id_view_option
               AND voc.id_profile_template = voci.id_profile_template
               AND voci.id_institution = i_prof.institution
             WHERE vo.subject = i_subject
               AND voc.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution)
               AND voc.flg_available = g_yes
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                SELECT t.id_view_option, t.screen_identifier
                  INTO o_id_view_option, o_screen
                  FROM (SELECT vo.id_view_option, vo.screen_identifier
                          FROM view_option vo
                         INNER JOIN view_option_config voc
                            ON voc.id_view_option = vo.id_view_option
                         WHERE vo.subject = i_subject
                           AND voc.id_profile_template IN
                               (SELECT ppt.id_profile_template
                                  FROM prof_profile_template ppt
                                 WHERE ppt.id_professional = i_prof.id
                                   AND ppt.id_software = i_prof.software
                                   AND ppt.id_institution = i_prof.institution)
                           AND voc.flg_available = g_yes
                         ORDER BY nvl(voc.rank, vo.rank)) t
                 WHERE rownum = 1;
        END;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            SELECT t.id_view_option, t.screen_identifier
              INTO o_id_view_option, o_screen
              FROM (SELECT vo.id_view_option, vo.screen_identifier
                      FROM view_option vo
                     WHERE vo.subject = i_subject
                     ORDER BY vo.rank) t
             WHERE rownum = 1;
            RETURN TRUE;
        WHEN OTHERS THEN
        
            o_id_view_option := NULL;
            o_screen         := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_VIEW_OPTIONS',
                                              o_error);
        
            RETURN FALSE;
    END;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    --
    g_generic_db_error_message := 'COMMON_M001';

END pk_view_option;
/
