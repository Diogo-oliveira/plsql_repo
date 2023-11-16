/*-- Last Change Revision: $Rev: 2027875 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wizards_core IS

    -- Private type declarations

    -- Private constant declarations
    g_error_action_type_u CONSTANT VARCHAR2(1) := 'U';

    -- Private variable declarations
    e_too_many_wizards  EXCEPTION;
    e_dup_wiz_component EXCEPTION;
    e_not_expected      EXCEPTION;
    e_error             EXCEPTION; --Generic error used to identify errors where o_error already come filled and it's just necessary to return false

    g_wiz_comp_chief_complaint CONSTANT wizard_components.internal_name%TYPE := 'CHIEF_COMPLAINT';
    g_wiz_comp_vital_signs     CONSTANT wizard_components.internal_name%TYPE := 'VITAL_SIGNS';

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Gets wizard and wizard component for the given sreen name
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_screen_name       Screen name
    *
    * @param   o_wizard            Wizard id
    * @param   o_wizard_component  Wizard component id
    * @param   o_error             Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.5
    * @since   28-01-2011
    */
    FUNCTION get_wiz_component
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_screen_name      IN wizard_comp_screens.screen_name%TYPE,
        o_wizard           OUT wizard.id_wizard%TYPE,
        o_wizard_component OUT wizard_components.id_wizard_component%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_SHORTCUT';
        --
        l_profile_template profile_template.id_profile_template%TYPE;
        l_prof_wizards     table_number;
    BEGIN
        g_error := 'INIT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET PROFILE_TEMPLATE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'GET PROF WIZARD''s';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT wpt.id_wizard
          BULK COLLECT
          INTO l_prof_wizards
          FROM wizard_prof_templ wpt
          JOIN wizard wz
            ON wz.id_wizard = wpt.id_wizard
           AND wz.flg_available = pk_alert_constant.g_available
         WHERE wpt.id_profile_template = l_profile_template
           AND wpt.flg_available = pk_alert_constant.g_available;
    
        g_error := 'FOR PROFILE: ' || l_profile_template || ' WE HAVE ' || l_prof_wizards.count || ' WIZARD''s';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --If l_prof_wizards.count = 0 means that current professional profile hasn't any wizard
        IF l_prof_wizards.count > 0
        THEN
            g_error := 'GET CURRENT WIZARD AND CURRENT COMPONENT';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            BEGIN
                SELECT wc.id_wizard_component, wcr.id_wizard
                  INTO o_wizard_component, o_wizard
                  FROM wizard_components wc
                  JOIN wizard_comp_rel wcr
                    ON wcr.id_wizard_component = wc.id_wizard_component
                   AND wcr.id_wizard IN (SELECT column_value
                                           FROM TABLE(l_prof_wizards))
                  JOIN wizard_comp_screens wcs
                    ON wcs.id_wizard_component = wc.id_wizard_component
                 WHERE wc.flg_available = pk_alert_constant.g_available
                   AND wcs.screen_name = i_screen_name
                   AND wcs.flg_available = pk_alert_constant.g_available;
            EXCEPTION
                WHEN no_data_found THEN
                    --Current screen isn't inside any wizard for the current profile
                    g_error := 'NO WIZARD_COMPONENT FOR SCREEN: ' || i_screen_name;
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_package,
                                                   sub_object_name => l_func_name);
                    o_wizard_component := NULL;
                    o_wizard           := NULL;
                WHEN dup_val_on_index THEN
                    --Configuration error: We cannot have the same screen in more then one wizard for the same profile
                    g_error := 'TOO MANY WIZARD_COMPONENT''s FOR SCREEN: ' || i_screen_name;
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package,
                                                   sub_object_name => l_func_name);
                    RAISE e_too_many_wizards;
            END;
        ELSE
            o_wizard_component := NULL;
            o_wizard           := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_too_many_wizards THEN
            --It's not possible to have the same screen in more then one wizard for the same profile
            DECLARE
                l_error_code CONSTANT sys_message.code_message%TYPE := 'WIZARDS_ERR001';
                l_error_message sys_message.desc_message%TYPE;
            BEGIN
                l_error_message := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_message,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => l_func_name,
                                                  i_action_type => g_error_action_type_u,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
        
            RETURN FALSE;
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
    END get_wiz_component;

    /**
    * Verifies if i_screen_name is in a wizard for the current i_prof profile and if so returns a shortcut
    * otherwise returns NULL
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_patient       Patient id
    * @param   i_screen_name   Screen name
    *
    * @param   o_shortcut      Shortcut for the next screen if in a wizard, otherwise NULL
    * @param   o_doc_area      Doc area id
    * @param   o_short_btn_lbl Shortcut button label
    * @param   o_error         Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.5
    * @since   04-12-2010
    */
    FUNCTION get_shortcut
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_screen_name   IN wizard_comp_screens.screen_name%TYPE,
        o_shortcut      OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_doc_area      OUT doc_area.id_doc_area%TYPE,
        o_short_btn_lbl OUT pk_translation.t_desc_translation,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_SHORTCUT';
        --
        l_wizard           wizard.id_wizard%TYPE;
        l_wizard_component wizard_components.id_wizard_component%TYPE;
        l_next_wiz_comp    wizard_components.id_wizard_component%TYPE;
        l_curr_rank        wizard_comp_param.rank%TYPE;
        l_next_rank        wizard_comp_param.rank%TYPE;
        l_inst             institution.id_institution%TYPE;
        l_gender           patient.gender%TYPE;
        l_age              patient.age%TYPE;
        --
        l_doc_area_name pk_translation.t_desc_translation;
        --
        c_prt    pk_types.cursor_type;
        c_access pk_access.c_shortcut;
        r_access pk_access.t_shortcut;
        l_error  t_error_out;
        --
        PROCEDURE get_next_shortcut
        (
            i_wiz           IN wizard.id_wizard%TYPE,
            i_next_wiz_comp IN wizard_comp_param.id_wizard_component%TYPE,
            o_short         OUT sys_shortcut.id_sys_shortcut%TYPE,
            o_darea         OUT doc_area.id_doc_area%TYPE
        ) IS
            l_proc_name CONSTANT VARCHAR2(50) := 'GET_NEXT_SHORTCUT';
        BEGIN
            g_error := 'GET SPECIFIC WIZARD SHORTCUT';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            BEGIN
                SELECT wcr.id_sys_shortcut, wcr.id_doc_area
                  INTO o_short, o_darea
                  FROM wizard_comp_rel wcr
                 WHERE wcr.id_wizard = i_wiz
                   AND wcr.id_wizard_component = i_next_wiz_comp;
            EXCEPTION
                WHEN no_data_found THEN
                    o_short := NULL;
                    o_darea := NULL;
            END;
        
            IF o_short IS NULL
            THEN
                g_error := 'GET DEFAULT WIZARD SHORTCUT';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package,
                                               sub_object_name => l_proc_name);
                SELECT wc.id_sys_shortcut, wc.id_doc_area
                  INTO o_short, o_darea
                  FROM wizard_components wc
                 WHERE wc.id_wizard_component = i_next_wiz_comp
                   AND wc.flg_available = pk_alert_constant.g_yes;
            END IF;
        END get_next_shortcut;
    BEGIN
        g_error := 'INIT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'INITIALIZE OUTPUT VAR''S';
        --If the screen or profile hasn't any wizard associated then the output vars will have the NULL value
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        o_shortcut := NULL;
        o_doc_area := NULL;
    
        g_error := 'GET WIZARD AND WIZARD_COMPONENT FOR I_SCREEN: ' || i_screen_name;
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_wiz_component(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_screen_name      => i_screen_name,
                                 o_wizard           => l_wizard,
                                 o_wizard_component => l_wizard_component,
                                 o_error            => o_error)
        THEN
            RAISE e_error;
        END IF;
    
        --If l_wizard_component IS NULL means that current screen isn't in any wizard
        IF l_wizard_component IS NOT NULL
        THEN
            g_error := 'GET PARAM VAR''s';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            --Verify if exists institution/software specific configuration or use default ones
            SELECT t.id_institution
              INTO l_inst
              FROM (SELECT wcp.id_institution,
                           row_number() over(ORDER BY decode(wcp.id_institution, i_prof.institution, 1, 2)) line_number
                      FROM wizard_comp_param wcp
                     WHERE wcp.flg_available = pk_alert_constant.g_available
                       AND wcp.id_wizard = l_wizard
                       AND wcp.id_institution IN (0, i_prof.institution)) t
             WHERE t.line_number = 1;
        
            g_error := 'GET PAT GENDER';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
        
            g_error := 'GET PAT AGE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0))
              INTO l_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        
            g_error := 'GET CURRENT WIZARD_COMPONENT/SCREEN RANK';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            BEGIN
                SELECT wcp.rank
                  INTO l_curr_rank
                  FROM wizard_comp_param wcp
                 WHERE wcp.flg_available = pk_alert_constant.g_available
                   AND wcp.id_wizard = l_wizard
                   AND wcp.id_institution = l_inst
                   AND wcp.id_wizard_component = l_wizard_component
                   AND (wcp.flg_gender = l_gender OR wcp.flg_gender IS NULL)
                   AND (l_age BETWEEN wcp.age_min AND wcp.age_max OR (wcp.age_min IS NULL AND wcp.age_max IS NULL));
            EXCEPTION
                WHEN no_data_found THEN
                    --Wizard component isn't available in l_inst, l_soft, l_gender, l_age
                    g_error := 'NO WIZARD_COMPONENT FOR WIZARD_COMP: ' || l_wizard_component || '; INST: ' || l_inst ||
                               '; PAT_GENDER: ' || l_gender || '; PAT_AGE: ' || l_age || ';';
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_package,
                                                   sub_object_name => l_func_name);
                    l_curr_rank := NULL;
                WHEN dup_val_on_index THEN
                    --Configuration error: Duplicated component
                    g_error := 'CURRENT SCREEN - TOO MANY WIZARD_COMPONENT''s FOR WIZARD_COMP: ' || l_wizard_component ||
                               '; WIZARD: ' || l_wizard || '; INST: ' || l_inst || '; PAT_GENDER: ' || l_gender ||
                               '; PAT_AGE: ' || l_age || ';';
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package,
                                                   sub_object_name => l_func_name);
                    RAISE e_dup_wiz_component;
            END;
        
            IF l_curr_rank IS NOT NULL
            THEN
                g_error := 'GET NEXT RANK';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package,
                                               sub_object_name => l_func_name);
                BEGIN
                    SELECT MIN(wcp.rank)
                      INTO l_next_rank
                      FROM wizard_comp_param wcp
                     WHERE wcp.flg_available = pk_alert_constant.g_available
                       AND wcp.id_wizard = l_wizard
                       AND wcp.id_institution = l_inst
                       AND wcp.rank > l_curr_rank
                       AND (wcp.flg_gender = l_gender OR wcp.flg_gender IS NULL)
                       AND (l_age BETWEEN wcp.age_min AND wcp.age_max OR (wcp.age_min IS NULL AND wcp.age_max IS NULL));
                EXCEPTION
                    WHEN no_data_found THEN
                        --Current component is the last component of the wizard
                        g_error := 'WIZARD: ' || l_wizard || '; WIZARD_COMPONENT: ' || l_wizard_component ||
                                   '; IS THE LAST WIZARD COMPONENT';
                        alertlog.pk_alertlog.log_debug(text            => g_error,
                                                       object_name     => g_package,
                                                       sub_object_name => l_func_name);
                        l_next_rank := NULL;
                END;
            
                IF l_next_rank IS NOT NULL
                THEN
                    g_error := 'GET NEXT COMPONENT';
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_package,
                                                   sub_object_name => l_func_name);
                    BEGIN
                        SELECT wcp.id_wizard_component
                          INTO l_next_wiz_comp
                          FROM wizard_comp_param wcp
                         WHERE wcp.flg_available = pk_alert_constant.g_available
                           AND wcp.id_wizard = l_wizard
                           AND wcp.id_institution = l_inst
                           AND wcp.rank = l_next_rank;
                    
                        g_error := 'GET NEXT SCREEN SHORTCUT';
                        alertlog.pk_alertlog.log_debug(text            => g_error,
                                                       object_name     => g_package,
                                                       sub_object_name => l_func_name);
                        get_next_shortcut(i_wiz           => l_wizard,
                                          i_next_wiz_comp => l_next_wiz_comp,
                                          o_short         => o_shortcut,
                                          o_darea         => o_doc_area);
                    EXCEPTION
                        WHEN no_data_found THEN
                            --Next rank was found in the previous block so this error shouldn't happen :)
                            g_error := 'NEXT SCREEN SHORT - NO_DATA_FOUND FOR WIZARD_COMP: ' || l_wizard_component ||
                                       '; WIZARD: ' || l_wizard || '; INST: ' || l_inst || '; NEXT RANK: ' ||
                                       l_next_rank;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package,
                                                           sub_object_name => l_func_name);
                            RAISE e_not_expected;
                        WHEN dup_val_on_index THEN
                            --Configuration error: Duplicated component
                            g_error := 'NEXT SCREEN - TOO MANY WIZARD_COMPONENT''s FOR WIZARD_COMP: ' ||
                                       l_wizard_component || '; INST: ' || l_inst || '; PAT_GENDER: ' || l_gender ||
                                       '; PAT_AGE: ' || l_age || '; NEXT RANK: ' || l_next_rank;
                            alertlog.pk_alertlog.log_error(text            => g_error,
                                                           object_name     => g_package,
                                                           sub_object_name => l_func_name);
                            RAISE e_dup_wiz_component;
                    END;
                END IF;
            END IF;
        END IF;
    
        IF o_shortcut IS NOT NULL
        THEN
            IF pk_access.get_shortcut(i_lang   => i_lang,
                                      i_prof   => i_prof,
                                      i_patient => NULL,
                                      i_episode => NULL,
                                      i_short  => o_shortcut,
                                      o_access => c_access,
                                      o_prt    => c_prt,
                                      o_error  => l_error)
            THEN
                BEGIN
                    FETCH c_access
                        INTO r_access;
                    CLOSE c_access;
                
                    o_short_btn_lbl := r_access.btn_label;
                EXCEPTION
                    WHEN OTHERS THEN
                        o_short_btn_lbl := NULL;
                END;
            ELSE
                o_short_btn_lbl := NULL;
            END IF;
        END IF;
    
        IF o_doc_area IS NOT NULL
        THEN
            l_doc_area_name := pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_doc_area => o_doc_area);
        
            IF l_doc_area_name IS NOT NULL
            THEN
                IF o_short_btn_lbl IS NULL
                THEN
                    o_short_btn_lbl := l_doc_area_name;
                ELSE
                    o_short_btn_lbl := o_short_btn_lbl || ': ' || chr(10) || l_doc_area_name;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_error THEN
            RETURN FALSE;
        WHEN e_dup_wiz_component THEN
            --Duplicated component
            DECLARE
                l_error_code CONSTANT sys_message.code_message%TYPE := 'WIZARDS_ERR002';
                l_error_message sys_message.desc_message%TYPE;
            BEGIN
                l_error_message := pk_message.get_message(i_lang => i_lang, i_code_mess => l_error_code);
            
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_message,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => l_func_name,
                                                  i_action_type => g_error_action_type_u,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
        
            RETURN FALSE;
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
    END get_shortcut;

    /**
    * Checks if some professional with the same category of i_prof already inserted data in screen component
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_screen_name  Screen name
    *
    * @param   o_flg_has_data Component already has data?
    * @param   o_error        Error information
    *
    * @value   o_flg_has_data {*} 'Y' Yes
    *                         {*} 'N' No
    *                         {*} 'A' Not applicable
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.5
    * @since   28-01-2011
    *
    * @changed Alexandre Santos
    * @version 2.5.1.3
    * @since   16-02-2011
    * @motive  Verify in vital_sign component if data was previously inserted in triage, 
    *          if so considered as if no data has been entered
    */
    FUNCTION check_profcat_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_screen_name  IN wizard_comp_screens.screen_name%TYPE,
        o_flg_has_data OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'CHECK_PROFCAT_DATA';
        --
        l_wizard           wizard.id_wizard%TYPE;
        l_wizard_component wizard_components.id_wizard_component%TYPE;
        --
        -- This function checks if current professional category already inserted data on chief complaint component
        -- Returns true if chief complaint already has data otherwise return false
        FUNCTION has_chief_complaint_data(i_prof_cat IN category.flg_type%TYPE) RETURN BOOLEAN IS
            l_obj_name CONSTANT VARCHAR2(50) := 'HAS_CHIEF_COMPLAINT_DATA';
            --
            l_tbl_prof_cat table_varchar;
            --
            l_return BOOLEAN;
        BEGIN
            g_error := 'INIT';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_obj_name);
        
            --In the current requirement it's only needed to validate in epis_complaint text so we don't need to validate in epis_anamnesis (free text inserted in triage)
            g_error := 'GET PROF_CAT OF ALL ACTIVE COMPLAINTS;';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            BEGIN
                SELECT pk_prof_utils.get_category(i_lang => i_lang,
                                                  i_prof => profissional(a.id_professional,
                                                                         i_prof.institution,
                                                                         i_prof.software)) prof_cat
                  BULK COLLECT
                  INTO l_tbl_prof_cat
                  FROM (SELECT DISTINCT ec.id_professional
                          FROM epis_complaint ec
                         WHERE ec.id_episode = i_episode
                           AND ec.flg_status = pk_complaint.g_complaint_act) a;
            EXCEPTION
                WHEN no_data_found THEN
                    l_return := FALSE;
            END;
        
            IF l_tbl_prof_cat.exists(1)
            THEN
                FOR i IN l_tbl_prof_cat.first .. l_tbl_prof_cat.last
                LOOP
                    IF l_tbl_prof_cat(i) = i_prof_cat
                    THEN
                        l_return := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            ELSE
                l_return := FALSE;
            END IF;
        
            RETURN l_return;
        END has_chief_complaint_data;
        --
        -- This funtion checks if existing data on vital_signs component was inserted in triage, 
        -- if so it's considered has if no data was inserted.
        -- Returns true if there is any vital sign inserted (excluding triage vs), otherwise false
        FUNCTION has_vs_data RETURN BOOLEAN IS
            l_obj_name CONSTANT VARCHAR2(50) := 'HAS_VS_DATA';
            --
            l_zero CONSTANT PLS_INTEGER := 0;
            l_count  PLS_INTEGER;
            l_return BOOLEAN;
        BEGIN
            g_error := 'INIT';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_obj_name);
        
            SELECT COUNT(*)
              INTO l_count
              FROM vital_sign_read vsr
             WHERE vsr.id_episode = i_episode
               AND vsr.flg_state = pk_alert_constant.g_active
               AND vsr.id_epis_triage IS NULL;
        
            l_return := (l_count > l_zero);
        
            RETURN l_return;
        END has_vs_data;
        --
        -- This funtins checks if current professional category already inserted data on current component
        -- Returns true if component already has data otherwise return false
        FUNCTION has_data RETURN BOOLEAN IS
            l_obj_name CONSTANT VARCHAR2(50) := 'HAS_DATA';
            --
            l_wiz_comp_int_name wizard_components.internal_name%TYPE;
            l_prof_cat          category.flg_type%TYPE;
            --
            l_return BOOLEAN;
        BEGIN
            g_error := 'INIT';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_obj_name);
        
            g_error := 'GET PROF_CAT OF I_PROF: (' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                       i_prof.software || ');';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'GET INTERNAL_NAME OF ID_WIZARDS_COMPONENT = ' || l_wizard_component;
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT wc.internal_name
              INTO l_wiz_comp_int_name
              FROM wizard_components wc
             WHERE wc.id_wizard_component = l_wizard_component;
        
            CASE l_wiz_comp_int_name
                WHEN g_wiz_comp_chief_complaint THEN
                    l_return := has_chief_complaint_data(i_prof_cat => l_prof_cat);
                WHEN g_wiz_comp_vital_signs THEN
                    l_return := has_vs_data;
                ELSE
                    l_return := FALSE;
            END CASE;
        
            RETURN l_return;
        END has_data;
    BEGIN
        g_error := 'INIT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET WIZARD AND WIZARD_COMPONENT FOR I_SCREEN: ' || i_screen_name;
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_wiz_component(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_screen_name      => i_screen_name,
                                 o_wizard           => l_wizard,
                                 o_wizard_component => l_wizard_component,
                                 o_error            => o_error)
        THEN
            RAISE e_error;
        END IF;
    
        IF l_wizard_component IS NOT NULL
        THEN
            g_error := 'CHECK IF CURRENT CATEGORY PROF ALREADY INSERTED DATA ON COMPONENT';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF has_data
            THEN
                o_flg_has_data := pk_alert_constant.g_yes;
            ELSE
                o_flg_has_data := pk_alert_constant.g_no;
            END IF;
        ELSE
            o_flg_has_data := pk_alert_constant.g_na;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_error THEN
            RETURN FALSE;
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
    END check_profcat_data;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wizards_core;
/
