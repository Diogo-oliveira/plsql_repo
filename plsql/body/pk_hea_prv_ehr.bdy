/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_ehr IS

    g_flg_adv_dir_field_typ_n CONSTANT VARCHAR2(1) := 'N'; -- Normal field
    g_flg_adv_dir_field_typ_d CONSTANT VARCHAR2(1) := 'D'; -- DNAR field
    g_flg_adv_dir_field_typ_p CONSTANT VARCHAR2(1) := 'P'; -- Patient or physician field

    -- Patient alert
    g_flg_pa_show_type_t CONSTANT VARCHAR2(1) := 'T'; -- Title
    g_flg_pa_show_type_i CONSTANT VARCHAR2(1) := 'I'; -- Icon
    g_flg_pa_show_type_o CONSTANT VARCHAR2(1) := 'O'; -- Tooltip
    g_flg_pa_show_type_s CONSTANT VARCHAR2(1) := 'S'; -- Status

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_id_patient := NULL;
        g_ehr_access := NULL;
    END;

    /**
    * Fetchs all the variables for the EHR if they have not been fetched yet.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_patient          Referral Id
    * @param i_id_epis_type        Episode type Id
    * @param i_id_episode          Episode Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_id_episode   IN episode.id_episode%TYPE
    ) IS
    
        l_error        t_error_out;
        l_func_name    VARCHAR2(64) := 'CHECK_VAR';
        l_flg_ehr      VARCHAR2(1);
        l_flg_sign_off VARCHAR2(1);
    
    BEGIN
    
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
    
        IF g_id_patient IS NOT NULL
           AND g_id_patient = i_id_patient
        THEN
            NULL;
        ELSE
            g_id_patient    := i_id_patient;
            g_habits        := pk_hea_prv_aux.get_habits(i_lang, i_prof, i_id_patient);
            g_prev_med_hist := pk_past_history.get_past_hist_header_count(i_lang, i_prof, i_id_patient);
            -- g_allergies     := pk_allergy.get_count_allergy(i_lang, i_id_patient, l_error);
            g_allergies   := pk_allergy.get_count_allergy_unawareness(i_lang, i_id_patient, l_error);
            g_relev_notes := pk_hea_prv_aux.get_relev_notes(i_lang, i_prof, i_id_patient);
            g_prev_epis   := pk_hea_prv_aux.get_prev_epis(i_lang, i_prof, i_id_patient);
            g_blood_type  := pk_hea_prv_aux.get_blood_type(i_lang, i_prof, i_id_patient);
        
            IF i_id_episode IS NOT NULL
            THEN
                SELECT e.flg_ehr,
                       decode(e.flg_status,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no)
                  INTO l_flg_ehr, g_epis_is_cancelled
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                IF l_flg_ehr = pk_ehr_access.g_flg_ehr_normal
                THEN
                    g_error := 'CALL PK_SIGN_OFF.GET_EPIS_SIGN_OFF_STATE';
                    IF NOT pk_sign_off.get_epis_sign_off_state(i_lang, i_prof, i_id_episode, l_flg_sign_off, l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF l_flg_sign_off = pk_alert_constant.g_yes
                    THEN
                        g_shortcut_area := 'SIGNOFF';
                    ELSE
                        g_shortcut_area := 'SOAP';
                    END IF;
                ELSE
                    IF pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof) = pk_alert_constant.g_no
                    THEN
                        g_shortcut_area := 'SOAP';
                    ELSE
                        g_shortcut_area := 'CLINPROC';
                    END IF;
                END IF;
            ELSE
                IF pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof) = pk_alert_constant.g_no
                THEN
                    g_shortcut_area := 'SOAP';
                ELSE
                    g_shortcut_area := 'CLINPROC';
                END IF;
            
                g_epis_is_cancelled := pk_alert_constant.g_no;
            END IF;
        
            g_error := 'CALL GET_ADV_DIRECTIVES_FOR_HEADER';
            IF NOT pk_advanced_directives.get_adv_directives_for_header(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_patient            => i_id_patient,
                                                                        i_episode            => i_id_episode,
                                                                        o_has_adv_directives => g_adv_dir_has,
                                                                        o_adv_directive_sh   => g_adv_dir_shortcut,
                                                                        o_error              => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_adv_dir_alert := pk_sysconfig.get_config('HEADER_PATIENT_ALERTS_AVAILABLE', i_prof);
            IF g_adv_dir_alert = pk_alert_constant.g_no
            THEN
                IF NOT pk_advanced_directives.get_pat_alerts_for_header(i_lang           => i_lang,
                                                                        i_prof           => i_prof,
                                                                        i_patient        => i_id_patient,
                                                                        i_episode        => i_id_episode,
                                                                        o_has_pat_alerts => g_pat_alerts_has,
                                                                        o_error          => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF g_shortcut_area = 'CLINPROC'
            THEN
                -- there is no advance directives menu in the Old (Non SOAP) area
                -- unless it's ADT software
                IF i_prof.software != pk_alert_constant.g_soft_adt
                THEN
                    g_adv_dir_shortcut := NULL;
                END IF;
            END IF;
            --[OA - 03-NOV-09] Added software 43 - NUTRITIONIST
            IF i_prof.software IN (pk_alert_constant.g_soft_imgtech,
                                   pk_alert_constant.g_soft_labtech,
                                   pk_alert_constant.g_soft_extech,
                                   pk_alert_constant.g_soft_triage,
                                   pk_alert_constant.g_soft_resptherap,
                                   pk_alert_constant.g_soft_adt,
                                   pk_alert_constant.g_soft_director,
                                   pk_alert_constant.g_soft_nutritionist,
                                   pk_alert_constant.g_soft_pharmacy,
                                   pk_alert_constant.g_soft_psychologist,
                                   pk_alert_constant.g_soft_rehab)
               OR i_id_epis_type IS NULL
            THEN
                g_epis_type_software := i_prof.software;
            ELSIF i_id_epis_type = pk_hhc_constant.k_hhc_epis_type
            THEN
                g_epis_type_software := i_prof.software;
            ELSE
                SELECT id_software
                  INTO g_epis_type_software
                  FROM (SELECT etsi.id_software
                          FROM epis_type_soft_inst etsi
                         WHERE etsi.id_epis_type = i_id_epis_type
                           AND etsi.id_institution IN (0, i_prof.institution)
                         ORDER BY etsi.id_institution DESC)
                 WHERE rownum < 2;
            END IF;
        
            IF g_ehr_access IS NULL
            THEN
                --g_ehr_access := 'F';
                IF NOT pk_ehr_access.check_ehr_access(i_lang, i_prof, i_id_patient, NULL, NULL, g_ehr_access, l_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
    END check_var;

    /**
    * Checks if the shortcut should be available for the given profile
    *
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The true if available and false otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION has_shortcut
    (
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN FALSE;
        END IF;
    
        IF g_epis_is_cancelled = pk_alert_constant.g_yes
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_prof.software != g_epis_type_software
        THEN
            IF i_prof.software IN (1, 3, 12)
               AND g_epis_type_software IN (15, 16, 25)
            THEN
                NULL;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    
        IF i_prof.software = 47
           AND i_flg_area != 'P'
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END;

    /**
    * Checks if the shortcut should be available for the given area and profile
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile template Id
    * @param i_flg_area            System application area flag
    * @param i_shortcut_area       Shortcut area
    * @param i_id_episode          Episode ID
    *
    * @return                      The true if available and false otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION has_shortcut
    (
        i_prof          IN profissional,
        i_id_profile    IN profile_template.id_profile_template%TYPE,
        i_flg_area      IN sys_application_area.flg_area%TYPE,
        i_shortcut_area IN VARCHAR2,
        i_id_episode    IN episode.id_episode%TYPE
    ) RETURN BOOLEAN IS
        l_flg_status episode.flg_status%TYPE;
        l_error      t_error_out;
        l_epis_type  episode.id_epis_type%TYPE;
    BEGIN
        IF i_id_episode IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_id_episode;
         
        IF l_epis_type = pk_hhc_constant.k_hhc_epis_type
        THEN
            RETURN FALSE;
        END IF;
        IF NOT has_shortcut(i_prof, i_flg_area)
        THEN
            RETURN FALSE;
        ELSE
            --
            IF i_id_profile IN (44, 45, 119, 120, 655, 665) -- TODO remove hardcoded numbers for prescription profiles
            THEN
                RETURN FALSE;
            ELSIF i_id_profile = pk_act_therap_constant.g_act_therapist
            THEN
                IF (i_shortcut_area = 'ADV_DIR')
                THEN
                    IF (i_id_episode IS NOT NULL)
                    THEN
                        IF i_flg_area = 'G'
                        THEN
                            g_error := 'CALL pk_episode.get_flg_status';
                            IF NOT pk_episode.get_flg_status(i_lang       => NULL,
                                                             i_prof       => i_prof,
                                                             i_id_episode => i_id_episode,
                                                             o_flg_status => l_flg_status,
                                                             o_error      => l_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        
                            IF (l_flg_status = pk_alert_constant.g_epis_status_inactive)
                            THEN
                                RETURN FALSE;
                            ELSE
                                RETURN TRUE;
                            END IF;
                        END IF;
                    ELSE
                        RETURN TRUE;
                    END IF;
                ELSE
                    RETURN FALSE;
                END IF;
            ELSIF i_id_profile IN (7, 17, 102, 620, 621, 622, 623) -- TODO remove hardcoded numbers for auxiliar profiles
            THEN
                RETURN FALSE;
            ELSIF i_id_profile IN (46, 47) -- TODO remove hardcoded numbers for US technician profiles
            THEN
                RETURN FALSE;
            ELSIF i_prof.software = 35 -- triage
                  AND i_shortcut_area IN ('BLOODTYPE', 'HABITS', '')
            THEN
                RETURN TRUE;
            END IF;
        END IF;
        RETURN TRUE;
    END;

    /**
    * Returns the EHR value for habits
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_habits
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_HABITS';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
    
        IF g_habits = 1
        THEN
            RETURN g_habits || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M009');
        ELSIF g_habits > 1
        THEN
            RETURN g_habits || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M010');
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for habits shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_habits_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area VARCHAR2(64) := 'HABITS';
        l_func_name     VARCHAR2(64) := 'GET_HABITS_SHORTCUT';
        l_shortcut      VARCHAR2(32);
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF g_habits < 1
        THEN
            RETURN NULL;
        ELSE
            l_shortcut := pk_sysconfig.get_config('SHORTCUT_' || g_shortcut_area || '_' || l_shortcut_area, i_prof);
            IF l_shortcut IS NOT NULL
            THEN
                RETURN l_shortcut;
            ELSE
                RETURN 166;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for habits shortcut color
    *
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_habits_shortcut_color(i_flg_area IN sys_application_area.flg_area%TYPE) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_HABITS_SHORTCUT_COLOR';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_habits < 1
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x3C3C32';
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for allergies
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_allergies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_ALLERGIES';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_allergies = 1
        THEN
            RETURN g_allergies || ' ' || pk_message.get_message(i_lang, i_prof, 'EDIS_ID_M003');
        ELSIF g_allergies > 1
        THEN
            RETURN g_allergies || ' ' || pk_message.get_message(i_lang, i_prof, 'EDIS_ID_M004');
        ELSIF g_allergies = -1
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'ALLERGY_M008');
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for allergies shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_allergies_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area VARCHAR2(64) := 'ALLERGIES';
        l_func_name     VARCHAR2(64) := 'GET_ALLERGIES_SHORTCUT';
        l_shortcut      VARCHAR2(32);
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF g_allergies = 0
        THEN
            RETURN NULL;
        ELSE
            l_shortcut := pk_sysconfig.get_config('SHORTCUT_' || g_shortcut_area || '_' || l_shortcut_area, i_prof);
            IF l_shortcut IS NOT NULL
            THEN
                RETURN l_shortcut;
            ELSE
                RETURN 1;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for allergies shortcut color
    *
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_allergies_shortcut_color(i_flg_area IN sys_application_area.flg_area%TYPE) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_ALLERGIES_SHORTCUT_COLOR';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_allergies = 0
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x3C3C32';
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for previous medication
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_med_hist
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_PREV_MED_HIST';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_prev_med_hist > 0
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'ID_M003');
        END IF;
    
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for previous medication shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_med_hist_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area    VARCHAR2(64) := 'RELEVDISEASES';
        l_func_name        VARCHAR2(64) := 'GET_PREV_MED_HIST_SHORTCUT';
        l_shortcut         VARCHAR2(32);
        l_areas_configured NUMBER;
    BEGIN
        -- checks if medical and surgical area are configured to be shown in past history screen. If not, uses shortcut to problems area
        g_error := 'CHECK SUMMARY PAGE ACCESS';
        pk_alertlog.log_debug(text => g_error);
    
        SELECT COUNT(1)
          INTO l_areas_configured
          FROM summary_page_access a
         WHERE a.id_summary_page_section IN
               (SELECT a.id_summary_page_section
                  FROM summary_page_section a
                 WHERE a.id_summary_page = 2
                   AND a.id_doc_area IN (pk_past_history.g_doc_area_past_med, pk_past_history.g_doc_area_past_surg))
           AND a.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof);
    
        IF l_areas_configured <= 0
        THEN
            IF (g_prev_med_hist > 0)
            THEN
                RETURN 609;
            ELSE
                RETURN NULL;
            END IF;
        END IF;
    
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
    
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
    
        IF g_prev_med_hist < 1
        THEN
            RETURN NULL;
        ELSE
            l_shortcut := pk_sysconfig.get_config('SHORTCUT_' || g_shortcut_area || '_' || l_shortcut_area, i_prof);
            IF l_shortcut IS NOT NULL
            THEN
                RETURN l_shortcut;
            ELSE
                IF i_prof.software IN
                   (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_triage, pk_alert_constant.g_soft_resptherap)
                THEN
                    RETURN 879;
                ELSE
                    RETURN 3;
                END IF;
            END IF;
        END IF;
    
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for previous medication shortcut color
    *
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_med_hist_sh_color(i_flg_area IN sys_application_area.flg_area%TYPE) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_PREV_MED_HIST_SH_COLOR';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_prev_med_hist < 1
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x3C3C32';
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for relevant notes
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_relev_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_RELEV_NOTES';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_relev_notes = 1
        THEN
            RETURN g_relev_notes || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M007');
        ELSIF g_relev_notes > 1
        THEN
            RETURN g_relev_notes || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M004');
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for relevant notes shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_relev_notes_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area VARCHAR2(64) := 'RELEVNOTES';
        l_func_name     VARCHAR2(64) := 'GET_RELEV_NOTES_SHORTCUT';
        l_shortcut      VARCHAR2(32);
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF g_relev_notes < 1
        THEN
            RETURN NULL;
        ELSE
            l_shortcut := pk_sysconfig.get_config('SHORTCUT_' || g_shortcut_area || '_' || l_shortcut_area, i_prof);
            IF l_shortcut IS NOT NULL
            THEN
                RETURN l_shortcut;
            ELSE
                IF i_prof.software IN (8, 35)
                THEN
                    RETURN 879;
                ELSIF i_prof.software IN (1, 3, 12)
                THEN
                    RETURN 4;
                ELSE
                    RETURN 3;
                END IF;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for relevant notes shortcut color
    *
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_relev_notes_shortcut_color(i_flg_area IN sys_application_area.flg_area%TYPE) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_RELEV_NOTES_SHORTCUT_COLOR';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_relev_notes < 1
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x3C3C32';
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for previous episodes
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_epis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_PREV_EPIS';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_prev_epis = 1
        THEN
            RETURN g_prev_epis || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M008');
        ELSIF g_prev_epis > 1
        THEN
            RETURN g_prev_epis || ' ' || pk_message.get_message(i_lang, i_prof, 'ID_M002');
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for previous episodes shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_epis_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area VARCHAR2(64) := 'EPISODES';
        l_func_name     VARCHAR2(64) := 'GET_PREV_EPIS_SHORTCUT';
        l_shortcut      VARCHAR2(32);
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF g_prev_epis < 1
        THEN
            RETURN NULL;
        ELSE
            l_shortcut := pk_sysconfig.get_config('SHORTCUT_' || g_shortcut_area || '_' || l_shortcut_area, i_prof);
            IF l_shortcut IS NOT NULL
            THEN
                RETURN l_shortcut;
            ELSE
                RETURN 5;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for previous episodes shortcut color
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_epis_shortcut_color RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_PREV_EPIS_SHORTCUT_COLOR';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_prev_epis < 1
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x3C3C32';
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for blood type
    *
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_blood_type(i_flg_area IN sys_application_area.flg_area%TYPE) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_BLOOD_TYPE';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        RETURN g_blood_type;
    END;

    /**
    * Returns the EHR value for blood type shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_blood_type_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area VARCHAR2(64) := 'BLOODTYPE';
        l_func_name     VARCHAR2(64) := 'GET_BLOOD_TYPE_SHORTCUT';
        l_shortcut      VARCHAR2(32);
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF g_blood_type IS NULL
        THEN
            RETURN NULL;
        ELSE
            l_shortcut := pk_sysconfig.get_config('SHORTCUT_' || g_shortcut_area || '_' || l_shortcut_area, i_prof);
            IF l_shortcut IS NOT NULL
            THEN
                RETURN l_shortcut;
            ELSE
                RETURN 2;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for blood type shortcut color
    *
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_blood_type_shortcut_color(i_flg_area IN sys_application_area.flg_area%TYPE) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_BLOOD_TYPE_SHORTCUT_COLOR';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_blood_type IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x3C3C32';
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for Advanced directives shortcut
    *
    * @param i_prof                Professional Id
    * @param i_id_profile          Profile Id
    * @param i_flg_area            System application area flag
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_adv_dir_shortcut
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_shortcut_area VARCHAR2(64) := 'ADV_DIR';
        l_func_name     VARCHAR2(64) := 'GET_ADV_DIR_SHORTCUT';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, l_shortcut_area, i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF g_adv_dir_has = 'Y'
        THEN
            RETURN g_adv_dir_shortcut;
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns description of advanced Directive
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_mess_flg            Type of advanced directive
    * @param o_text           Message "Advance directives"/"Patient"/"Physician"
    * @param o_txt_dnar       When applicable return DNAR
    *
    * @return                      If is or is not to show DNAR area or patien's alert
    *
    * @author   Jorge Silva
    * @version  2.6.1
    * @since    2012/07/26
    */
    FUNCTION get_description_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_mess_flg  IN VARCHAR2,
        o_text      OUT sys_message.desc_message%TYPE,
        o_text_dnar OUT sys_message.desc_message%TYPE
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_DESCTIPTION_TEXT';
        --
        l_code_message_adv_dir  CONSTANT sys_message.code_message%TYPE := 'ADVANCED_DIRECTIVES_M001'; --Advance directives
        l_code_message_pat      CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_M013'; --Patient
        l_code_message_phys     CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_M014'; --Physician
        l_code_message_patalert CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_T019'; --Patient Alert
        l_code_message_dnar     CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_M012'; --DNAR
        l_code_message_living   CONSTANT sys_message.code_message%TYPE := 'ADVANCE_DIRECTIVES_T022'; --Living will - us market
        l_is_dnar_area BOOLEAN;
    
        --
        l_error  t_error_out;
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                          i_id_institution => i_prof.institution);
    BEGIN
        CASE i_mess_flg
            WHEN pk_advanced_directives.g_adv_dir_icon_type_dph THEN
                o_text      := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_message_phys);
                o_text_dnar := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_message_dnar);
            WHEN pk_advanced_directives.g_adv_dir_icon_type_dp THEN
                IF l_market = 2
                THEN
                    o_text_dnar := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => l_code_message_living);
                    o_text      := NULL;
                ELSE
                    o_text      := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => l_code_message_pat);
                    o_text_dnar := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => l_code_message_dnar);
                END IF;
            WHEN pk_advanced_directives.g_adv_dir_icon_type_a THEN
                IF g_adv_dir_alert = pk_alert_constant.g_yes
                THEN
                    o_text      := NULL;
                    o_text_dnar := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => l_code_message_patalert);
                ELSE
                    o_text      := NULL;
                    o_text_dnar := NULL;
                END IF;
            WHEN pk_advanced_directives.g_adv_dir_icon_type_n THEN
                o_text      := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_message_adv_dir);
                o_text_dnar := NULL;
            ELSE
                o_text      := NULL;
                o_text_dnar := NULL;
        END CASE;
    
        IF o_text_dnar IS NOT NULL
        THEN
            l_is_dnar_area := TRUE;
        ELSE
            l_is_dnar_area := FALSE;
        END IF;
    
        RETURN l_is_dnar_area;
    END get_description_text;

    /**
    * Returns the EHR value for Advanced directives text
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    * @param i_episode             Episode id
    * @param i_flg_field           Field type
    *
    * @values i_flg_field          N - Normal field
    *                              D - DNAR field
    *                              P - Patient or physician field
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_adv_dir_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_area  IN sys_application_area.flg_area%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_field IN VARCHAR2
    ) RETURN VARCHAR IS
        l_is_dnar_area BOOLEAN;
        l_func_name    VARCHAR2(64) := 'GET_ADV_DIR_TEXT';
    
        l_adv_dir_dnar_txt sys_message.desc_message%TYPE;
        l_adv_dir_txt      sys_message.desc_message%TYPE;
        l_adv_dir_table    table_varchar2;
        l_adv_dir_count    NUMBER(5) := 0;
        l_cont             VARCHAR2(10);
    
        l_error t_error_out;
    BEGIN
    
        g_error := 'PK_HEA_PRV_EHR.GET_ADV_DIR_TEXT' || ', i_episode: ' || i_episode || ', g_ehr_access: ' ||
                   g_ehr_access || ', i_flg_area: ' || i_flg_area || ', g_adv_dir_has: ' || g_adv_dir_has;
        pk_alertlog.log_debug(g_error);
    
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
    
        IF g_adv_dir_has = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL PK_ADVANCED_DIRECTIVES.GET_HEADER_TEXT';
            IF NOT pk_advanced_directives.get_header_text(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_text    => l_adv_dir_table,
                                                          o_error   => l_error)
            THEN
                g_error := l_error.err_desc;
                pk_alertlog.log_error(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_func_name,
                                      owner           => g_package_owner);
                RETURN NULL;
            END IF;
        
            g_error := 'l_adv_dir_table.count: ' || l_adv_dir_table.count;
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_name,
                                  owner           => g_package_owner);
        
            IF l_adv_dir_table IS NOT NULL
               AND l_adv_dir_table.count > 0
            THEN
                l_is_dnar_area := get_description_text(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_mess_flg  => l_adv_dir_table(l_adv_dir_table.first),
                                                       o_text      => l_adv_dir_txt,
                                                       o_text_dnar => l_adv_dir_dnar_txt);
            
                l_cont := '(' || l_adv_dir_table.count || ') ';
            
                IF l_is_dnar_area
                   AND i_flg_field = g_flg_adv_dir_field_typ_d
                THEN
                    IF g_adv_dir_alert = pk_alert_constant.g_yes
                    THEN
                        RETURN l_cont || l_adv_dir_dnar_txt;
                    ELSE
                        FOR i IN 1 .. l_adv_dir_table.count
                        LOOP
                            IF l_adv_dir_table(i) != pk_advanced_directives.g_adv_dir_icon_type_a
                            THEN
                                l_adv_dir_count := l_adv_dir_count + 1;
                            END IF;
                        END LOOP;
                    
                        l_cont := '(' || ltrim(to_char(l_adv_dir_count, '99999')) || ') ' || l_adv_dir_dnar_txt;
                    
                        RETURN l_cont;
                    END IF;
                ELSIF l_is_dnar_area
                      AND i_flg_field = g_flg_adv_dir_field_typ_p
                THEN
                    RETURN l_adv_dir_txt;
                ELSIF NOT l_is_dnar_area
                      AND i_flg_field = g_flg_adv_dir_field_typ_n
                      AND g_adv_dir_alert = pk_alert_constant.g_yes
                THEN
                    RETURN l_cont || l_adv_dir_txt;
                ELSE
                    RETURN NULL;
                END IF;
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    
    END get_adv_dir_text;

    /**
    * Returns the EHR value for Advanced directives icon
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    * @param i_episode             Episode id
    * @param i_flg_field           Field type
    *
    * @values i_flg_field          N - Normal field
    *                              D - DNAR field
    *                              P - Patient or physician field
    *
    * @return                      The EHR value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_adv_dir_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_area  IN sys_application_area.flg_area%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_field IN VARCHAR2
    ) RETURN VARCHAR IS
    
        l_func_name VARCHAR2(64) := 'GET_ADV_DIR_ICON';
    
        l_label table_varchar2;
    
        l_error t_error_out;
    
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
    
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.GET_HEADER_TEXT';
        IF NOT pk_advanced_directives.get_header_text(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_episode => i_episode,
                                                      o_text    => l_label,
                                                      o_error   => l_error)
        THEN
            g_error := l_error.err_desc;
            pk_alertlog.log_error(text            => g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_name,
                                  owner           => g_package_owner);
            RETURN NULL;
        END IF;
    
        IF l_label.count > 0
        THEN
            IF g_adv_dir_alert = pk_alert_constant.g_no
               AND l_label(l_label.first) = pk_advanced_directives.g_adv_dir_icon_type_a
            THEN
                RETURN NULL;
            END IF;
        END IF;
    
        IF g_adv_dir_has = pk_alert_constant.g_yes
        THEN
            RETURN pk_advanced_directives.get_header_icon(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        ELSE
            RETURN NULL;
        END IF;
    
    END get_adv_dir_icon;

    /**
    * Returns the EHR value for Advanced directives Tooltip
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_flg_area            System application area flag
    * @param i_episode             Episode id
    * @param i_flg_field           Field type
    *
    * @values i_flg_field          N - Normal field
    *                              D - DNAR field
    *                              P - Patient or physician field
    *
    * @return                      The Tooltip value
    *
    */
    FUNCTION get_adv_dir_tooltip
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_ADV_DIR_TOOLTIP';
    
        l_label            table_varchar2;
        vresult            VARCHAR2(200);
        l_adv_dir_dnar_txt VARCHAR2(200);
        l_is_dnar_area     BOOLEAN;
        l_ret              VARCHAR2(200);
    
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_advanced_directives.get_header_text(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_episode => i_episode,
                                                      o_text    => l_label,
                                                      o_error   => l_error)
        THEN
            g_error := l_error.err_desc;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            RETURN NULL;
        END IF;
    
        IF l_label.count > 0
        THEN
            vresult := '(' || l_label.count || ') ';
        
            FOR indx IN 1 .. l_label.count
            LOOP
                l_is_dnar_area := get_description_text(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_mess_flg  => l_label(indx),
                                                       o_text      => l_ret,
                                                       o_text_dnar => l_adv_dir_dnar_txt);
            
                IF l_adv_dir_dnar_txt IS NULL
                THEN
                    vresult := vresult || l_ret || ', ';
                ELSE
                    vresult := vresult || l_adv_dir_dnar_txt || ' ' || l_ret || ', ';
                END IF;
            END LOOP;
        
            vresult := substr(vresult, 1, length(vresult) - 2);
        
            RETURN vresult;
        END IF;
    
        RETURN NULL;
    
    END get_adv_dir_tooltip;

    /**
    * Returns the photo shortcut.
    *
    * @param i_prof                 Professional Id
    * @param i_id_profile           Profile Id
    * @param i_flg_area             System application area flag
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/05/27
    */
    FUNCTION get_photo_shortcut
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_func_name VARCHAR2(64) := 'GET_PHOTO_SHORTCUT';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        IF NOT has_shortcut(i_prof, i_id_profile, i_flg_area, 'PHOTO', i_id_episode)
        THEN
            RETURN NULL;
        END IF;
        IF pk_adt.is_contact(i_lang, i_prof, i_id_patient) = pk_alert_constant.g_yes
        THEN
            RETURN NULL;
        ELSE
            IF i_prof.software IN (1, 3, 11, 12)
            THEN
                RETURN 650;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the patient's alert tooltip
    *
    * @param i_lang         Language Id
    * @param i_prof         Professional Id
    * @param i_id_episode   Episode Id
    * @param i_id_patient  Patient Id
    *
    * @return               Tooltip description
    *
    * @author   Lillian Lu
    * @version  2.7.3.6
    * @since    2018/06/27
    */
    FUNCTION get_pat_alerts_tooltip
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_func_name         VARCHAR2(64) := 'GET_PAT_ALERT_TOOLTIP';
        l_pat_alert_tooltip VARCHAR2(200);
    
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_PAT_ALERT_TOOLTIP';
        IF NOT pk_advanced_directives.get_pat_alerts_tooltip(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_patient            => i_id_patient,
                                                             i_episode            => i_id_episode,
                                                             o_pat_alerts_tooltip => l_pat_alert_tooltip,
                                                             o_error              => l_error)
        THEN
            g_error := l_error.err_desc;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            RETURN NULL;
        END IF;
        RETURN l_pat_alert_tooltip;
    END get_pat_alerts_tooltip;

    /**
    * Returns the patient's alert info by show type
    *
    * @param i_lang         Language Id
    * @param i_prof         Professional Id
    * @param i_flg_area   System application area flag
    * @param i_flg_show_type          show type flag
    *
    * @return               patient alert value
    *
    * @author   Lillian Lu
    * @version  2.7.3.6
    * @since    2018/06/27
    */
    FUNCTION get_patient_alerts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_area      IN sys_application_area.flg_area%TYPE,
        i_flg_show_type IN VARCHAR2
    ) RETURN VARCHAR IS
        l_urgent_status VARCHAR2(30) := 'URGENT';
        l_icon_adv_dir_black CONSTANT VARCHAR2(50) := 'HeaderAdvDirectivesIcon';
    BEGIN
        g_error := 'GET_PATIENT_ALERTS';
        pk_alertlog.log_debug(g_error);
    
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
    
        IF g_pat_alerts_has = pk_alert_constant.g_yes
        THEN
            IF i_flg_show_type = g_flg_pa_show_type_t
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'HEADER_M025');
            ELSIF i_flg_show_type = g_flg_pa_show_type_i
            THEN
                RETURN l_icon_adv_dir_black;
            ELSIF i_flg_show_type = g_flg_pa_show_type_s
            THEN
                RETURN l_urgent_status;
            END IF;
        END IF;
    
        RETURN NULL;
    END get_patient_alerts;

    /**
    * Returns the icon name with the prefix "icon-" , EMR-463
    *
    * @param i_icon_name           Icon name
    *
    * @return                      Icon name with the prefix "icon-"
    *
    * @author   Alexander Camilo
    * @version  1
    * @since    2018/03/15
    */
    FUNCTION set_icon_prefix(i_icon_name IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF i_icon_name IS NOT NULL
           AND length(i_icon_name) > 1
        THEN
            RETURN 'icon-' || i_icon_name;
        END IF;
        RETURN i_icon_name;
    END set_icon_prefix;
    -- EMR-463

    /**
    * Returns the ehr value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_patient          Patient Id
    * @param i_id_child_episode    Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_epis_type        Episode type Id
    * @param i_id_profile          Profile template Id
    * @param i_flg_area            System application area flag
    * @param i_tag                 Tag to be replaced
    * @param o_data_rec            Tag's data
    *
    * @return                      The ehr value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_child_episode IN episode.id_episode%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_id_profile       IN profile_template.id_profile_template%TYPE,
        i_flg_area         IN sys_application_area.flg_area%TYPE,
        i_tag              IN header_tag.internal_name%TYPE,
        o_data_rec         OUT t_rec_header_data
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_VALUE_HTML';
        l_data_rec  t_rec_header_data := t_rec_header_data(NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL);
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
    
        IF i_id_patient IS NULL
        THEN
            RETURN FALSE;
        END IF;
        check_var(i_lang, i_prof, i_id_patient, i_id_epis_type, i_id_episode);
    
        -- EMR-463, Add the prefix 'icon-' in all the advance_directives icon names
        CASE i_tag
            WHEN 'EHR_HABITS' THEN
                l_data_rec.text     := get_habits(i_lang, i_prof, i_flg_area);
                l_data_rec.shortcut := get_habits_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
            
            WHEN 'EHR_ALLERGIES' THEN
                l_data_rec.text     := get_allergies(i_lang, i_prof, i_flg_area);
                l_data_rec.shortcut := get_allergies_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
            
            WHEN 'EHR_PREV_EPIS' THEN
                l_data_rec.text     := get_prev_epis(i_lang, i_prof);
                l_data_rec.shortcut := get_prev_epis_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
            
            WHEN 'EHR_BLOOD_TYPE' THEN
                l_data_rec.text     := get_blood_type(i_flg_area);
                l_data_rec.shortcut := get_blood_type_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
            
            WHEN 'EHR_PREV_MED_HIST' THEN
                l_data_rec.text     := get_prev_med_hist(i_lang, i_prof, i_flg_area);
                l_data_rec.shortcut := get_prev_med_hist_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
            
            WHEN 'EHR_RELEV_NOTES' THEN
                l_data_rec.text     := get_relev_notes(i_lang, i_prof, i_flg_area);
                l_data_rec.shortcut := get_relev_notes_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
            
            WHEN 'EHR_ADVANCE_DIRECTIVES' THEN
                l_data_rec.text        := get_adv_dir_text(i_lang,
                                                           i_prof,
                                                           i_flg_area,
                                                           i_id_episode,
                                                           g_flg_adv_dir_field_typ_n);
                l_data_rec.icon        := set_icon_prefix(get_adv_dir_icon(i_lang,
                                                                           i_prof,
                                                                           i_flg_area,
                                                                           i_id_episode,
                                                                           g_flg_adv_dir_field_typ_n));
                l_data_rec.status      := pk_advanced_directives.get_header_icon_status(i_lang    => i_lang,
                                                                                        i_prof    => i_prof,
                                                                                        i_episode => i_id_episode);
                l_data_rec.shortcut    := get_adv_dir_shortcut(i_prof, i_id_profile, i_flg_area, i_id_episode);
                l_data_rec.description := get_adv_dir_tooltip(i_lang, i_prof, i_id_episode);
            
            WHEN 'EHR_ADVANCE_DIRECTIVES_DNAR' THEN
                l_data_rec.text   := get_adv_dir_text(i_lang,
                                                      i_prof,
                                                      i_flg_area,
                                                      i_id_episode,
                                                      g_flg_adv_dir_field_typ_d);
                l_data_rec.icon   := set_icon_prefix(get_adv_dir_icon(i_lang,
                                                                      i_prof,
                                                                      i_flg_area,
                                                                      i_id_episode,
                                                                      g_flg_adv_dir_field_typ_d));
                l_data_rec.status := pk_advanced_directives.get_header_icon_status(i_lang    => i_lang,
                                                                                   i_prof    => i_prof,
                                                                                   i_episode => i_id_episode);
            WHEN 'EHR_ADVANCE_DIRECTIVES_PAT_PHYS' THEN
                l_data_rec.text := get_adv_dir_text(i_lang, i_prof, i_flg_area, i_id_episode, g_flg_adv_dir_field_typ_p);
            WHEN 'PAT_PHOTO_SHORTCUT' THEN
                l_data_rec.shortcut := get_photo_shortcut(i_lang,
                                                          i_prof,
                                                          i_id_profile,
                                                          i_flg_area,
                                                          i_id_patient,
                                                          i_id_episode);
            WHEN 'EHR_PATIENT_ALERT' THEN
                l_data_rec.text          := get_patient_alerts(i_lang, i_prof, i_flg_area, g_flg_pa_show_type_t);
                l_data_rec.icon          := set_icon_prefix(get_patient_alerts(i_lang,
                                                                               i_prof,
                                                                               i_flg_area,
                                                                               g_flg_pa_show_type_i));
                l_data_rec.status        := get_patient_alerts(i_lang, i_prof, i_flg_area, g_flg_pa_show_type_s);
                l_data_rec.tooltip_title := get_patient_alerts(i_lang, i_prof, i_flg_area, g_flg_pa_show_type_t);
                l_data_rec.tooltip_text  := get_pat_alerts_tooltip(i_lang, i_prof, i_id_episode, i_id_patient);
            WHEN 'EHR_PATIENT_ALERT_TOOLTIP_TITLE' THEN
                l_data_rec.text := get_patient_alerts(i_lang, i_prof, i_flg_area, g_flg_pa_show_type_t);
            
            WHEN 'EHR_PATIENT_ALERT_TOOLTIP_TEXT' THEN
                l_data_rec.description := get_pat_alerts_tooltip(i_lang, i_prof, i_id_episode, i_id_patient);
            
            WHEN 'EHR_PATIENT_ALERT_ICON' THEN
                l_data_rec.icon   := set_icon_prefix(get_patient_alerts(i_lang,
                                                                        i_prof,
                                                                        i_flg_area,
                                                                        g_flg_pa_show_type_i));
                l_data_rec.status := get_patient_alerts(i_lang, i_prof, i_flg_area, g_flg_pa_show_type_s);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;
    /**
    * Returns the ehr value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_patient          Patient Id
    * @param i_id_child_episode    Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_epis_type        Episode type Id
    * @param i_id_profile          Profile template Id
    * @param i_flg_area            System application area flag
    * @param i_tag                 Tag to be replaced
    *
    * @return                      The ehr value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_child_episode IN episode.id_episode%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_id_profile       IN profile_template.id_profile_template%TYPE,
        i_flg_area         IN sys_application_area.flg_area%TYPE,
        i_tag              IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_tag       header_tag.internal_name%TYPE;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        g_error := l_func_name;
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        IF i_id_patient IS NULL
        THEN
            RETURN NULL;
        END IF;
        check_var(i_lang, i_prof, i_id_patient, i_id_epis_type, i_id_episode);
    
        -- Translate old tags to html version
        CASE i_tag
            WHEN 'EHR_ADVANCE_DIRECTIVES_ICON' THEN
                l_tag := 'EHR_ADVANCE_DIRECTIVES';
            WHEN 'EHR_ADVANCE_DIRECTIVES_SHORTCUT' THEN
                l_tag := 'EHR_ADVANCE_DIRECTIVES';
            WHEN 'EHR_ADVANCE_DIRECTIVES_TOOLTIP' THEN
                l_tag := 'EHR_ADVANCE_DIRECTIVES';
            WHEN 'EHR_ADVANCE_DIRECTIVES_ICON_DNAR' THEN
                l_tag := 'EHR_ADVANCE_DIRECTIVES_DNAR';
            WHEN 'EHR_ALLERGIES_SHORTCUT' THEN
                l_tag := 'EHR_ALLERGIES';
            WHEN 'EHR_BLOOD_TYPE_SHORTCUT' THEN
                l_tag := 'EHR_BLOOD_TYPE';
            WHEN 'EHR_HABITS_SHORTCUT' THEN
                l_tag := 'EHR_HABITS';
            WHEN 'EHR_PREV_EPIS_SHORTCUT' THEN
                l_tag := 'EHR_PREV_EPIS';
            WHEN 'EHR_PREV_MED_HIST_SHORTCUT' THEN
                l_tag := 'EHR_PREV_MED_HIST';
            WHEN 'EHR_RELEV_NOTES_SHORTCUT' THEN
                l_tag := 'EHR_RELEV_NOTES';
            ELSE
                l_tag := i_tag;
        END CASE;
    
        l_ret := get_value_html(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                i_id_child_episode,
                                i_id_epis_type,
                                i_id_profile,
                                i_flg_area,
                                l_tag,
                                l_data_rec);
    
        CASE i_tag
            WHEN 'EHR_HABITS' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_ALLERGIES' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_PREV_EPIS' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_BLOOD_TYPE' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_PREV_MED_HIST' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_RELEV_NOTES' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_HABITS_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_ALLERGIES_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_PREV_EPIS_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_BLOOD_TYPE_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_PREV_MED_HIST_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_RELEV_NOTES_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_HABITS_SHORTCUT_COLOR' THEN
                RETURN get_habits_shortcut_color(i_flg_area);
            WHEN 'EHR_ALLERGIES_SHORTCUT_COLOR' THEN
                RETURN get_allergies_shortcut_color(i_flg_area);
            WHEN 'EHR_PREV_EPIS_SHORTCUT_COLOR' THEN
                RETURN get_prev_epis_shortcut_color();
            WHEN 'EHR_BLOOD_TYPE_SHORTCUT_COLOR' THEN
                RETURN get_blood_type_shortcut_color(i_flg_area);
            WHEN 'EHR_PREV_MED_HIST_SHORTCUT_COLOR' THEN
                RETURN get_prev_med_hist_sh_color(i_flg_area);
            WHEN 'EHR_RELEV_NOTES_SHORTCUT_COLOR' THEN
                RETURN get_relev_notes_shortcut_color(i_flg_area);
            WHEN 'EHR_ADVANCE_DIRECTIVES_ICON' THEN
                RETURN l_data_rec.icon;
            WHEN 'EHR_ADVANCE_DIRECTIVES_ICON_DNAR' THEN
                RETURN l_data_rec.icon;
            WHEN 'EHR_ADVANCE_DIRECTIVES' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_ADVANCE_DIRECTIVES_DNAR' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_ADVANCE_DIRECTIVES_PAT_PHYS' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_ADVANCE_DIRECTIVES_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_ADVANCE_DIRECTIVES_TOOLTIP' THEN
                RETURN l_data_rec.description;
            WHEN 'PAT_PHOTO_SHORTCUT' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EHR_PATIENT_ALERT' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_PATIENT_ALERT_TOOLTIP_TEXT' THEN
                RETURN l_data_rec.description;
            WHEN 'EHR_PATIENT_ALERT_TOOLTIP_TITLE' THEN
                RETURN l_data_rec.text;
            WHEN 'EHR_PATIENT_ALERT_ICON' THEN
                RETURN l_data_rec.icon;
            ELSE
                NULL;
        END CASE;
        RETURN NULL;
    END;

    /**
    * Returns the EHR value for blood type (NEW)
    *
    * @param i_flg_area            System application area flag
    * @param o_blood_type          
    *
    * @return                      The EHR value
    *
    * @author  Fábio Martins
    * @version  2.7
    * @since    2018/02/22
    */
    FUNCTION get_blood_type_new
    (
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        o_blood_type OUT VARCHAR
    ) RETURN BOOLEAN IS
    BEGIN
        o_blood_type := get_blood_type(i_flg_area);
        RETURN TRUE;
    END get_blood_type_new;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
