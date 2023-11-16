CREATE OR REPLACE PACKAGE BODY pk_hea_prv_epis IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_row_e.id_episode           := NULL;
        g_row_ei.id_episode          := NULL;
        g_row_s.id_schedule          := NULL;
        g_row_so.id_schedule_outp    := NULL;
        g_row_sr.id_schedule_sr      := NULL;
        g_clin_record                := NULL;
        g_row_e                      := NULL;
        g_row_ei                     := NULL;
        g_row_s                      := NULL;
        g_row_so                     := NULL;
        g_row_sr                     := NULL;
        g_row_sg                     := NULL;
        g_lang                       := NULL;
        g_prof                       := NULL;
        g_compl_diag                 := NULL;
        g_info_adic                  := NULL;
        g_desc_anamnesis             := NULL;
        g_anamnesis_prof             := NULL;
        g_desc_triage                := NULL;
        g_triage_prof                := NULL;
        g_compl_pain                 := NULL;
        g_dt_register                := NULL;
        g_dt_first                   := NULL;
        g_epis_number_available      := NULL;
        g_epis_number                := NULL;
        g_disp_date                  := NULL;
        g_disp_label                 := NULL;
        g_surg_prof                  := NULL;
        g_surg_prof_spec_inst        := NULL;
        g_ehr_access                 := NULL;
        g_epis_nhs_info              := NULL;
        g_epis_nhs_info_style        := NULL;
        g_epis_nhs_number            := NULL;
        g_epis_nhs_number_style      := NULL;
        g_epis_health_plan_info      := NULL;
        g_ehp_info_style             := NULL;
        g_epis_nhs_tooltip_info      := NULL;
        g_epis_nhs_tt_info_style     := NULL;
        g_ehp_tooltip_info           := NULL;
        g_ehp_tooltip_info_style     := NULL;
        g_epis_health_plan_number    := NULL;
        g_ehp_number_style           := NULL;
        g_epis_health_plan_available := NULL;
    
        g_pat_ges_available   := NULL;
        g_pat_ges_pathologies := NULL;
    END;

    /**
    * Sets the episode number.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_child_episode     Child Episode Id: to be used when the header is shown info about the parent and the child episode
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE set_epis_number
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_child_episode IN episode.id_episode%TYPE
    ) IS
        l_error t_error_out;
        l_aux   VARCHAR2(100);
    BEGIN
        g_error := 'CALL TO GET_EPIS_EXT';
        IF NOT pk_episode.get_epis_ext(i_lang       => i_lang,
                                  i_id_episode => CASE
                                                      WHEN i_prof.software = pk_alert_constant.g_soft_act_therapist THEN
                                                       i_id_child_episode
                                                      ELSE
                                                       i_id_episode
                                                  END,
                                  i_prof       => i_prof,
                                  o_dt_efectiv => l_aux,
                                  o_dt_atend   => l_aux,
                                  o_episode    => g_epis_number,
                                  o_error      => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF g_row_e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
        THEN
            g_dt_register := g_row_e.dt_begin_tstz;
        ELSE
            g_dt_register := NULL;
        END IF;
        g_dt_first := least(nvl(g_row_ei.dt_first_obs_tstz, g_row_ei.dt_first_nurse_obs_tstz),
                            nvl(g_row_ei.dt_first_nurse_obs_tstz, g_row_ei.dt_first_obs_tstz));
    END;

    /**
    * Fetchs all the variables for the schedule if they have not been fetched yet.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_schedule Schedule Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) IS
        l_id_schedule    schedule.id_schedule%TYPE;
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
        l_id_schedule_so schedule_outp.id_schedule_outp%TYPE;
        l_error          t_error_out;
    BEGIN
        l_id_schedule    := nvl(i_id_schedule, g_row_ei.id_schedule);
        l_id_schedule_so := nvl(g_row_ei.id_schedule_outp, -1);
        l_id_schedule_sr := nvl(g_row_ei.id_schedule_sr, -1);
    
        IF nvl(l_id_schedule, -1) = -1
           AND nvl(l_id_schedule_so, -1) = -1
           AND nvl(l_id_schedule_sr, -1) = -1
        THEN
            RETURN;
        END IF;
        IF g_row_s.id_schedule IS NULL
           OR g_row_s.id_schedule != i_id_schedule
        THEN
            g_error := 'SELECT * INTO g_row_s FROM schedule';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT *
                  INTO g_row_s
                  FROM schedule s
                 WHERE s.id_schedule = l_id_schedule;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
            g_error := 'SELECT * INTO g_row_so FROM schedule_outp';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT *
                  INTO g_row_so
                  FROM schedule_outp so
                 WHERE so.id_schedule = l_id_schedule
                    OR so.id_schedule_outp = l_id_schedule_so;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            g_error := 'SELECT * INTO g_row_sc FROM sch_resource';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT *
                  INTO g_row_sc
                  FROM (SELECT *
                          FROM sch_resource sc
                         WHERE sc.id_schedule = l_id_schedule
                         ORDER BY sc.flg_leader DESC NULLS LAST)
                 WHERE rownum < 2;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            g_error := 'SELECT * INTO g_row_sr FROM schedule_sr';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT *
                  INTO g_row_sr
                  FROM schedule_sr sr
                 WHERE sr.id_schedule = l_id_schedule
                    OR sr.id_schedule_sr = l_id_schedule_sr
                   AND rownum < 2; -- todo check if this statement is valid
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            g_error := 'SELECT * INTO g_row_sr FROM schedule_sr';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT *
                  INTO g_row_sg
                  FROM sch_group sg
                 WHERE sg.id_schedule = l_id_schedule
                   AND rownum < 2; -- todo check if this statement is valid
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            IF g_ehr_access IS NULL
               AND g_row_sg.id_patient IS NOT NULL
            THEN
                --g_ehr_access := 'Y';
                IF NOT pk_ehr_access.check_ehr_access(i_lang,
                                                      i_prof,
                                                      g_row_sg.id_patient,
                                                      NULL,
                                                      NULL,
                                                      g_ehr_access,
                                                      l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        END IF;
    END;

    /**
    * Fetchs all the variables for the schedule and episode if they have not been fetched yet.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) IS
        l_id_episode  episode.id_episode%TYPE;
        l_id_schedule schedule.id_schedule%TYPE := i_id_schedule;
        l_error       t_error_out;
        l_title_diag  sys_message.desc_message%TYPE;
        l_title_pain  sys_message.desc_message%TYPE;
    
    BEGIN
        IF i_id_episode IS NULL
           AND i_id_schedule IS NULL
        THEN
            RETURN;
        END IF;
        IF i_id_episode IS NULL
           OR g_row_e.id_episode IS NULL
           OR g_row_e.id_episode != i_id_episode
        THEN
            reset_var();
            g_error := 'SELECT * INTO g_row FROM episode';
            pk_alertlog.log_debug(g_error);
            BEGIN
            
                IF i_id_episode IS NOT NULL
                THEN
                    SELECT /*+ index(p eio_epis_fk_i)*/
                     p.*
                      INTO g_row_ei
                      FROM epis_info p
                     WHERE p.id_episode = i_id_episode;
                ELSIF i_id_schedule IS NOT NULL
                THEN
                
                    SELECT /*+ index(p eio_schd_episode_i)*/
                     p.*
                      INTO g_row_ei
                      FROM epis_info p
                     WHERE p.id_schedule = i_id_schedule
                       AND i_id_schedule != -1;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    IF l_id_schedule IS NULL
                    THEN
                        RETURN;
                    ELSE
                        check_var(i_lang, i_prof, l_id_schedule);
                    END IF;
            END;
            l_id_episode := nvl(i_id_episode, g_row_ei.id_episode);
            IF l_id_episode IS NOT NULL
            THEN
                SELECT *
                  INTO g_row_e
                  FROM episode p
                 WHERE p.id_episode = l_id_episode;
                pk_hea_prv_aux.set_comp_diag(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => l_id_episode,
                                             i_call_type  => pk_hea_prv_aux.g_call_header_app,
                                             o_title_diag => l_title_diag,
                                             o_compl_diag => g_compl_diag,
                                             o_title_pain => l_title_pain,
                                             o_compl_pain => g_compl_pain,
                                             o_info_adic  => g_info_adic);
                set_epis_number(i_lang, i_prof, l_id_episode, g_id_child_episode);
            END IF;
        END IF;
    
        IF g_row_e.id_patient IS NOT NULL
           AND g_ehr_access IS NULL
        THEN
        
            IF NOT pk_ehr_access.check_ehr_access(i_lang,
                                                  i_prof,
                                                  g_row_e.id_patient,
                                                  NULL,
                                                  l_id_episode,
                                                  g_ehr_access,
                                                  l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        l_id_schedule := nvl(l_id_schedule, g_row_ei.id_schedule);
        IF l_id_schedule IS NOT NULL
        THEN
            check_var(i_lang, i_prof, l_id_schedule);
        END IF;
    END;

    /**
    * Returns true if is an announced patient and hasn?t arrived yet to the hospital otherwise returns false
    *
    * @param i_episode             Episode Id
    *
    * @return                      The label
    *
    * @author   Alexandre Santos
    * @version  2.5
    * @since    2009/10/23
    */
    FUNCTION is_expected_patient(i_episode IN episode.id_episode%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_announced_arrival.get_ann_arrival_status(i_episode => i_episode) = pk_announced_arrival.g_aa_arrival_status_e;
    END;

    /**
    * Returns true if is an announced patient and hasn?t arrived yet to the hospital otherwise returns false
    *
    * @param i_episode             Episode Id
    *
    * @return                      The label
    *
    * @author   Alexandre Santos
    * @version  2.5
    * @since    2009/10/23
    */
    FUNCTION is_announced_arrival(i_episode IN episode.id_episode%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_announced_arrival.get_ann_arrival_status(i_episode => i_episode) = pk_announced_arrival.g_aa_arrival_status_a;
    END;
    /**
    * Returns the episode complaint or diagnoses.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    * @param i_flg_area             System application area flag
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_comp_diag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_compl_diag IS NOT NULL
        THEN
            RETURN g_compl_diag;
        ELSE
            RETURN g_compl_pain;
        END IF;
    END;

    /**
    * Returns the date and professional responsible for the last complaint or diagnoses.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    * @param i_flg_area             System application area flag
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_comp_diag_last_dt_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        RETURN g_info_adic;
    END;

    /**
    * Returns the episode software.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_epis_type         Episode type Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    *
    * @alter    Jos? Brito
    * @version  2.6
    * @since    2010/03/01
    */
    FUNCTION get_software
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_id_episode   IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_ret          VARCHAR2(200);
        l_triage_color triage_color.id_triage_color%TYPE;
    BEGIN
        IF i_id_epis_type = pk_edis_proc.g_epis_type_edis
        THEN
            -- urg?ncia
            -- Jos? Brito 01/03/2010 ALERT-721 Changes made to allow show ESI Level in the header.
            BEGIN
                SELECT ei.id_triage_color
                  INTO l_triage_color
                  FROM epis_info ei
                  JOIN triage_esi_level tlvl
                    ON tlvl.id_triage_color = ei.id_triage_color
                 WHERE ei.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_triage_color := NULL;
            END;
        
            IF l_triage_color IS NOT NULL
            THEN
                l_ret := pk_edis_triage.get_epis_esi_level(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_epis         => i_id_episode,
                                                           i_triage_color => l_triage_color,
                                                           i_type         => 'F');
            ELSE
                l_ret := pk_message.get_message(i_lang, i_prof, 'HEADER_M007');
            END IF;
        ELSE
            IF i_prof.software = 4
            THEN
                l_ret := pk_message.get_message(i_lang, i_prof, 'P1_HEADER_M001');
            ELSE
                IF i_id_epis_type IS NOT NULL
                THEN
                    l_ret := pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || i_id_epis_type);
                ELSE
                    l_ret := pk_translation.get_translation(i_lang, 'SOFTWARE.CODE_SOFTWARE.' || i_prof.software);
                END IF;
            END IF;
        END IF;
        l_ret := REPLACE(l_ret, '<br>', ' ');
        l_ret := REPLACE(l_ret, '  ', ' ');
        RETURN l_ret;
    END;

    /**
    * Returns the episode number.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    * @param i_id_external_request  Referral Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_number
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
    
        l_hea_epis_conf_val     sys_config.value%TYPE;
        l_id_external_request   p1_external_request.id_external_request%TYPE;
        l_display_external_epis sys_config.value%TYPE; --[CALERT-1123] team inspection
        l_error                 t_error_out;
    
    BEGIN
        -- Ricardo Patrocínio (2009-10-22): Check the HEA_EPIS_CONF configuration,
        -- if value = 'E' or NULL return the Episode #, if value is equal to
        -- 'R' return retrun Referral #
    
        -- Get the value of the configuration
        g_retval := pk_sysconfig.get_config(i_code_cf => g_hea_epis_conf,
                                            i_prof    => i_prof,
                                            o_msg_cf  => l_hea_epis_conf_val);
    
        -- If the call to pk_sysconfig.get_config log the error
        IF NOT g_retval
        THEN
            g_error := 'Call pk_sysconfig.get_config i_code_cf = ' || g_hea_epis_conf;
            pk_alertlog.log_error('ERROR: ' || g_error);
        END IF;
    
        l_display_external_epis := pk_sysconfig.get_config(i_code_cf => 'HEADER_EPIS_NUMBER_AVAILABLE',
                                                           i_prof    => i_prof);
        IF (l_display_external_epis = pk_alert_constant.g_yes)
        THEN
            IF nvl(l_hea_epis_conf_val, 'E') = 'E'
            THEN
                -- If the configuration result is 'E' or null, returns the Episode #
                check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
                IF g_row_e.flg_ehr != pk_ehr_access.g_flg_ehr_ehr
                THEN
                    RETURN nvl(g_epis_number, '---');
                ELSE
                    RETURN '---';
                END IF;
            ELSE
                -- If the configuration result is 'R' returns the Referral #
            
                -- Get the Referral ID
                l_id_external_request := pk_p1_external_request.get_pk(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_id_episode => i_id_episode,
                                                                       o_error      => l_error);
            
                -- Return the Referral Number
                RETURN pk_hea_prv_ref.get_value(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_external_request => l_id_external_request,
                                                i_tag                 => 'REFERRAL_NUMBER');
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    
    END get_number;

    /**
    * Returns the label for 'Episode'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_epis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    
        l_hea_epis_conf_val     sys_config.value%TYPE;
        l_display_external_epis sys_config.value%TYPE;
    
    BEGIN
        -- Ricardo Patrocínio (2009-10-23): Check the HEA_EPIS_CONF configuration,
        -- if value = 'E' or NULL return the Episode #, if value is equal to
        -- 'R' return retrun Referral #
    
        -- Get the value of the configuration
        g_retval := pk_sysconfig.get_config(i_code_cf => g_hea_epis_conf,
                                            i_prof    => i_prof,
                                            o_msg_cf  => l_hea_epis_conf_val);
    
        -- If the call to pk_sysconfig.get_config log the error
        IF NOT g_retval
        THEN
            g_error := 'Call pk_sysconfig.get_config i_code_cf = ' || g_hea_epis_conf;
            pk_alertlog.log_error('ERROR: ' || g_error);
        END IF;
    
        l_display_external_epis := pk_sysconfig.get_config(i_code_cf => 'HEADER_EPIS_NUMBER_AVAILABLE',
                                                           i_prof    => i_prof);
        IF (l_display_external_epis = pk_alert_constant.g_yes)
        THEN
            IF nvl(l_hea_epis_conf_val, 'E') = 'E'
            THEN
                -- If the configuration result is 'E' or null, returns the Episode #
                IF i_prof.software = 32 -- todo modify to global variable
                THEN
                    RETURN pk_message.get_message(i_lang, i_prof, 'COMMON_M026');
                ELSIF i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                                          pk_alert_constant.g_soft_primary_care,
                                          pk_alert_constant.g_soft_private_practice) -- todo modify to global variable
                THEN
                    RETURN pk_message.get_message(i_lang, i_prof, 'ID_T001');
                ELSE
                    RETURN pk_message.get_message(i_lang, i_prof, 'EDIS_ID_T001');
                END IF;
            ELSE
                -- If the configuration result is 'R' returns the Referral #
                RETURN pk_message.get_message(i_lang, i_prof, 'P1_HEADER_M001');
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END get_epis;

    /**
    * Returns the episode location.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_location
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
    
        IF g_row_sg.id_schedule IS NOT NULL
           AND g_row_sg.flg_contact_type = 'V'
        THEN
            IF g_row_e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
               AND (g_row_ei.dt_init IS NOT NULL OR g_row_ei.dt_first_obs_tstz IS NOT NULL)
            THEN
            
                RETURN pk_message.get_message(i_lang, i_prof, 'HEADER_M035');
            ELSE
                RETURN '---';
            END IF;
        ELSIF (g_row_sg.flg_contact_type <> 'V' OR g_row_sg.flg_contact_type IS NULL)
              AND i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            RETURN NULL;
        ELSIF g_row_e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled
              AND g_row_ei.id_room IS NULL
        THEN
            RETURN '---';
        ELSIF g_row_sg.flg_contact_type = 'P'
        THEN
            RETURN '---';
        END IF;
    
        RETURN pk_hea_prv_aux.get_room_name(i_lang => i_lang, i_prof => i_prof, i_id_room => g_row_ei.id_room);
    END;

    /**
    * Returns the label for EDIS 'Location'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_location
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        IF (g_row_sg.flg_contact_type <> 'V' OR g_row_sg.flg_contact_type IS NULL)
           AND i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            RETURN NULL;
        ELSE
            RETURN pk_message.get_message(i_lang, i_prof, 'EDIS_ID_T006');
        END IF;
    END;

    /**
    * Returns the episode room time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_time
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        RETURN pk_hea_prv_aux.get_room_time(i_lang, i_prof, g_row_e);
    END;

    /**
    * Returns the label for 'Room time'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'EDIS_ID_T008');
    END;

    /**
    * Returns the episode total time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_total_time
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        RETURN pk_edis_proc.get_los_duration(i_lang => i_lang, i_prof => i_prof, i_id_episode => g_row_e.id_episode); -- Length of stay
    END;

    /**
    * Returns the label for 'Total time'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_total_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'EDIS_ID_T010');
    END;

    /**
    * Returns the episode admission date.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_admission_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF (is_expected_patient(i_id_episode))
        THEN
            RETURN pk_date_utils.dt_hour_chr_short_tsz(i_lang,
                                                       pk_announced_arrival.get_expected_arrival_dt(i_id_episode),
                                                       i_prof);
        ELSE
            check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        
            IF (i_prof.software = pk_alert_constant.g_soft_inpatient)
            THEN
                --Sofia Mendes (22-10-2009): only returns the date if the episode is of type normal
                IF (g_row_e.flg_ehr = pk_alert_constant.g_flg_ehr_n)
                THEN
                    RETURN pk_date_utils.dt_hour_chr_short_tsz(i_lang, g_row_e.dt_begin_tstz, i_prof);
                ELSE
                    RETURN '---';
                END IF;
            ELSE
                RETURN pk_date_utils.dt_hour_chr_short_tsz(i_lang, g_row_e.dt_begin_tstz, i_prof);
            END IF;
            --
        
        END IF;
    END get_admission_date;

    /**
    * Returns the family doctor and its nickname.
    *
    * @param i_id_patient           Patient Id
    *
    * @param o_id_fam_doctor        Family Doctor Id
    * @param o_fam_doctor_nick      Family Doctor Nickname
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/06/29
    */
    PROCEDURE get_family_doctor
    (
        i_id_patient      IN patient.id_patient%TYPE,
        o_id_fam_doctor   OUT professional.id_professional%TYPE,
        o_fam_doctor_nick OUT professional.nick_name%TYPE
    ) IS
    BEGIN
        SELECT id_professional, nick_name
          INTO o_id_fam_doctor, o_fam_doctor_nick
          FROM ((SELECT pfp.id_professional, p.nick_name, 1, pfp.dt_begin_tstz dt_begin
                   FROM patient pat, pat_family_prof pfp, professional p
                  WHERE pat.id_patient = i_id_patient
                    AND pfp.id_patient = pat.id_patient
                    AND p.id_professional = pfp.id_professional
                    AND pfp.flg_status = 'A'
                 UNION ALL
                 SELECT pfp.id_professional, p.nick_name, 2, pfp.dt_begin_tstz dt_begin
                   FROM patient pat, pat_family_prof pfp, professional p
                  WHERE pat.id_patient = i_id_patient
                    AND pfp.id_pat_family = pat.id_pat_family
                    AND p.id_professional = pfp.id_professional) ORDER BY 3, dt_begin DESC)
         WHERE rownum = 1;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_fam_doctor   := NULL;
            o_fam_doctor_nick := NULL;
    END;

    /**
    * Returns the episode responsible doctor.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_resp_doctor
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_id_prof       professional.id_professional%TYPE;
        l_nick_prof     professional.nick_name%TYPE;
        l_id_patient    patient.id_patient%TYPE;
        l_category_type category.flg_type%TYPE;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        l_id_prof := nvl(g_row_ei.id_professional, g_row_sc.id_professional);
    
        BEGIN
            SELECT c.flg_type
              INTO l_category_type
              FROM prof_cat pc
              JOIN category c
                ON c.id_category = pc.id_category
             WHERE pc.id_professional = l_id_prof
               AND pc.id_institution = i_prof.institution;
        EXCEPTION
            WHEN OTHERS THEN
                l_category_type := NULL;
        END;
    
        IF l_id_prof = g_row_ei.id_first_nurse_resp
           OR l_category_type = g_cat_type_nurse -- consultas de enfermagem
        THEN
            RETURN NULL;
        END IF;
        IF l_id_prof IS NULL
           AND i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof)
        THEN
            l_id_patient := nvl(g_row_e.id_patient, g_row_sg.id_patient);
            get_family_doctor(i_id_patient      => l_id_patient,
                              o_id_fam_doctor   => l_id_prof,
                              o_fam_doctor_nick => l_nick_prof);
        END IF;
    
        RETURN pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_prof);
    END;

    /**
    * Returns the specialty and institution of the episode responsible doctor.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_resp_doctor_spec_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_spec            VARCHAR2(1000);
        l_inst            VARCHAR2(1000);
        l_id_prof         professional.id_professional%TYPE;
        l_id_inst         institution.id_institution%TYPE;
        l_id_fam_doctor   professional.id_professional%TYPE;
        l_fam_doctor_nick professional.nick_name%TYPE;
        l_id_patient      patient.id_patient%TYPE;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        l_id_prof    := nvl(g_row_ei.id_professional, g_row_sc.id_professional);
        l_id_inst    := nvl(g_row_e.id_institution, i_prof.institution);
        l_id_patient := nvl(g_row_e.id_patient, g_row_sg.id_patient);
        IF l_id_prof = g_row_ei.id_first_nurse_resp -- consultas de enfermagem
        THEN
            RETURN NULL;
        END IF;
    
        IF i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof)
        THEN
            get_family_doctor(i_id_patient      => l_id_patient,
                              o_id_fam_doctor   => l_id_fam_doctor,
                              o_fam_doctor_nick => l_fam_doctor_nick);
            IF l_id_fam_doctor IS NOT NULL
            THEN
                g_error := 'GET PROF SPEC (CS)';
                IF nvl(l_id_prof, 0) != 0
                   AND l_id_prof = l_id_fam_doctor
                THEN
                    RETURN '(' || pk_message.get_message(i_lang, 'HEADER_M005') || ')';
                ELSE
                    l_inst := pk_hea_prv_inst.get_acronym(i_lang, i_prof, l_id_inst);
                    RETURN '(' || pk_message.get_message(i_lang, 'HEADER_M005') || ': ' || l_fam_doctor_nick || '; ' || l_inst || ')';
                END IF;
            ELSE
                RETURN NULL;
            END IF;
        ELSE
        
            l_spec := pk_hea_prv_prof.get_speciality(i_lang, i_prof, l_id_prof);
            IF l_spec IS NOT NULL
            THEN
                l_inst := pk_hea_prv_inst.get_acronym(i_lang, i_prof, l_id_inst);
                RETURN '(' || l_spec || '; ' || l_inst || ')';
            ELSE
                RETURN NULL;
            END IF;
        END IF;
    END;

    /**
    * Returns the specialty of the episode's responsible doctor.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Goncalo Almeida
    * @version  2.6.1
    * @since    2011/07/01
    */
    FUNCTION get_resp_doctor_spec
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_spec    VARCHAR2(1000);
        l_inst    VARCHAR2(1000);
        l_id_prof professional.id_professional%TYPE;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        l_id_prof := nvl(g_row_ei.id_professional, g_row_sc.id_professional);
        IF l_id_prof = g_row_ei.id_first_nurse_resp -- consultas de enfermagem
        THEN
            RETURN NULL;
        END IF;
    
        l_spec := pk_hea_prv_prof.get_speciality(i_lang, i_prof, l_id_prof);
        IF l_spec IS NOT NULL
        THEN
            RETURN l_spec;
        ELSE
            RETURN NULL;
        END IF;
    
    END get_resp_doctor_spec;

    /**
    * Returns the episode responsible nurse.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_resp_nurse
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_resp_doct VARCHAR2(1000);
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        IF g_row_ei.id_first_nurse_resp IS NOT NULL
        THEN
            l_resp_doct := get_resp_doctor(i_lang, i_prof, i_id_episode, i_id_schedule);
            IF l_resp_doct IS NULL
            THEN
                RETURN pk_prof_utils.get_name_signature(i_lang, i_prof, g_row_ei.id_first_nurse_resp);
            ELSE
                RETURN '/ ' || pk_prof_utils.get_name_signature(i_lang, i_prof, g_row_ei.id_first_nurse_resp);
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the episode's responsible nurse.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The responsible's name
    *
    * @author   Goncalo Almeida
    * @version  2.6.1
    * @since    2011/07/01
    */
    FUNCTION get_resp_nurse_report
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_resp_doct VARCHAR2(1000);
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        IF g_row_ei.id_first_nurse_resp IS NOT NULL
        THEN
            RETURN pk_prof_utils.get_name_signature(i_lang, i_prof, g_row_ei.id_first_nurse_resp);
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the specialty and institution of the episode responsible nurse.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_resp_nurse_spec_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_spec VARCHAR2(1000);
        l_inst VARCHAR2(1000);
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        l_spec := pk_hea_prv_prof.get_speciality(i_lang, i_prof, g_row_ei.id_first_nurse_resp);
        IF l_spec IS NOT NULL
        THEN
            l_inst := pk_hea_prv_inst.get_acronym(i_lang, i_prof, g_row_e.id_institution);
            RETURN '(' || l_spec || '; ' || l_inst || ')';
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the specialty of the episode's responsible nurse.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Goncalo Almeida
    * @version  2.6.1
    * @since    2011/07/01
    */
    FUNCTION get_resp_nurse_spec
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_spec VARCHAR2(1000);
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        l_spec := pk_hea_prv_prof.get_speciality(i_lang, i_prof, g_row_ei.id_first_nurse_resp);
        IF l_spec IS NOT NULL
        THEN
            RETURN l_spec;
        ELSE
            RETURN NULL;
        END IF;
    END get_resp_nurse_spec;

    /**
    * Returns disposition, transfer or reopen if applied to the episode.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_disp_transf_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_status sys_message.desc_message%TYPE;
    BEGIN
        IF (is_expected_patient(i_id_episode))
        THEN
            --Announced arrival
            RETURN pk_message.get_message(i_lang, i_prof, 'ANN_ARRIV_MSG066');
        ELSE
            l_status := pk_hea_prv_aux.get_disp_transf_reopen(i_lang, i_prof, i_id_episode);
            IF l_status IS NULL
               AND is_announced_arrival(i_id_episode)
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'ANN_ARRIV_MSG066');
            ELSE
                RETURN l_status;
            END IF;
        END IF;
    END;

    /**
    * Returns the episode fast track message.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_fast_track
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        RETURN pk_fast_track.get_fast_track_desc(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_episode    => i_id_episode,
                                                 i_fast_track => g_row_e.id_fast_track,
                                                 i_type       => pk_edis_proc.g_desc_header);
    END;

    /**
    * Returns the episode fast track icon.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_fast_track_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_icon fast_track.icon%TYPE := NULL;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
    
        l_icon := pk_fast_track.get_fast_track_icon(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_id_epis      => i_id_episode,
                                                    i_fast_track   => g_row_e.id_fast_track,
                                                    i_triage_color => NULL,
                                                    i_type         => CASE
                                                                          WHEN g_row_e.id_fast_track IS NOT NULL THEN
                                                                           pk_edis_proc.g_icon_ft
                                                                          ELSE
                                                                           pk_edis_proc.g_icon_ft_transfer
                                                                      END,
                                                    i_has_transfer => NULL);
    
        IF g_row_e.id_fast_track IS NOT NULL
           AND l_icon IS NOT NULL
        THEN
            l_icon := 'HeaderFastTrackIcon';
        END IF;
    
        RETURN l_icon;
    END;

    /**
    * Returns the fast track shortcut.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Alexandre Santos
    * @version  2.6
    * @since    2011/11/03
    */
    FUNCTION get_fast_track_shortcut
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
    
        IF pk_epis_er_law_api.get_fast_track_id(i_episode => i_id_episode, i_fast_track => NULL) IS NOT NULL
        THEN
            --Emergency law shortcut
            RETURN 906363;
        ELSE
            RETURN NULL;
        END IF;
    END get_fast_track_shortcut;

    /**
    * Returns the episode manchester color or black if the patient is dead.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_manch_color
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF pk_hea_prv_pat.is_deceased(i_lang, i_prof, nvl(g_row_ei.id_patient, i_id_patient))
        THEN
            RETURN '0x000000';
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_edis
           OR i_prof.software = pk_alert_constant.g_soft_triage
           OR i_prof.software = pk_alert_constant.g_soft_ubu
           OR i_prof.software = pk_alert_constant.g_soft_labtech
           OR i_prof.software = pk_alert_constant.g_soft_imgtech
           OR i_prof.software = pk_alert_constant.g_soft_extech
           OR i_prof.software = pk_alert_constant.g_soft_resptherap
        THEN
            RETURN g_row_ei.triage_acuity;
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the style for the text above the photo.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_manch_text_style
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF i_id_episode IS NOT NULL
        THEN
            check_var(i_lang, i_prof, i_id_episode, NULL);
        END IF;
        -- upper on purpose
        IF (upper(g_row_ei.triage_color_text) = '0XFFFFFF' AND
           (i_prof.software = pk_alert_constant.g_soft_edis OR i_prof.software = pk_alert_constant.g_soft_triage OR
           i_prof.software = pk_alert_constant.g_soft_ubu OR i_prof.software = pk_alert_constant.g_soft_labtech OR
           i_prof.software = pk_alert_constant.g_soft_imgtech OR i_prof.software = pk_alert_constant.g_soft_extech OR
           i_prof.software = pk_alert_constant.g_soft_resptherap))
           OR pk_hea_prv_pat.is_deceased(i_lang, i_prof, nvl(g_row_ei.id_patient, i_id_patient))
        THEN
            RETURN 'Header4'; -- white
        ELSE
            RETURN 'Header1'; -- black
        END IF;
    END;

    /**
    * Returns the episode service.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_service
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        RETURN pk_hea_prv_aux.get_service(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_dep_clin_serv => g_row_ei.id_dep_clin_serv) || ' - ' || pk_hea_prv_aux.get_clin_service(i_lang             => i_lang,
                                                                                                                                       i_prof             => i_prof,
                                                                                                                                       i_id_dep_clin_serv => g_row_ei.id_dep_clin_serv);
    END;

    /**
    * Returns the service in which is the bed.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_service
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        RETURN pk_hea_prv_aux.get_bed_service(i_lang, i_prof, g_row_ei.id_bed);
    END;

    /**
    * Returns the room name in which is the bed.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_room
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF g_row_ei.id_bed IS NULL
        THEN
            RETURN NULL;
        END IF;
        RETURN pk_hea_prv_aux.get_room_name(i_lang => i_lang, i_prof => i_prof, i_id_bed => g_row_ei.id_bed);
    END;

    /**
    * Returns the bed name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_name
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        RETURN pk_hea_prv_aux.get_bed_name(i_lang, i_prof, g_row_ei.id_bed);
    END;

    /**
    * Returns the location service.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_location_service
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        RETURN pk_hea_prv_aux.get_service(i_lang => i_lang, i_prof => i_prof, i_id_room => g_row_ei.id_room);
    END;

    /**
    * Returns the label for 'Location'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_location_service
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        -- i_prof removed on purpose
        RETURN pk_message.get_message(i_lang, i_prof, 'INP_ID_T003');
    END;

    /**
    * Sets the disposition label and date.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE set_disp_dt_label
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    BEGIN
        pk_hea_prv_aux.get_disposition_date(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_row_ei     => g_row_ei,
                                            o_disp_date  => g_disp_date,
                                            o_disp_label => g_disp_label);
    
    END;

    /**
    * Returns the disposition date.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_disposition_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF g_disp_label IS NULL
        THEN
            set_disp_dt_label(i_lang, i_prof);
        END IF;
        RETURN g_disp_date;
    END;

    /**
    * Returns the disposition date label.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_label_disposition_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF g_disp_label IS NULL
        THEN
            set_disp_dt_label(i_lang, i_prof);
        END IF;
        RETURN g_disp_label;
    END;

    /**
    * Returns the episode appointment type.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_appointment_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        RETURN pk_hea_prv_aux.get_appointment_type(i_lang, i_prof, g_row_ei, i_id_schedule);
    END;

    /**
    * Returns the episode schedule.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_show_date sys_config.value%TYPE := nvl(pk_sysconfig.get_config('HEADER_SHOW_SCHEDULING_DATE', i_prof),
                                                 pk_alert_constant.g_yes);
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
    
        IF l_show_date = pk_alert_constant.g_yes
        THEN
            IF g_row_sr.dt_target_tstz IS NOT NULL
            THEN
                RETURN pk_date_utils.date_char_tsz(i_lang,
                                                   g_row_sr.dt_target_tstz,
                                                   i_prof.institution,
                                                   i_prof.software);
            ELSIF g_row_sg.id_schedule IS NOT NULL
            THEN
                RETURN pk_date_utils.date_char_tsz(i_lang, g_row_s.dt_begin_tstz, i_prof.institution, i_prof.software);
            
            ELSIF g_row_so.dt_target_tstz IS NOT NULL
            THEN
                RETURN pk_date_utils.date_char_tsz(i_lang,
                                                   g_row_so.dt_target_tstz,
                                                   i_prof.institution,
                                                   i_prof.software);
            ELSE
                RETURN pk_date_utils.date_char_tsz(i_lang, g_row_s.dt_begin_tstz, i_prof.institution, i_prof.software);
            END IF;
        ELSE
            IF g_row_sr.dt_target_tstz IS NOT NULL
            THEN
                RETURN pk_hea_prv_aux.get_format_date(i_lang, i_prof, g_row_sr.dt_target_tstz);
            ELSIF g_row_so.dt_target_tstz IS NOT NULL
            THEN
                RETURN pk_hea_prv_aux.get_format_date(i_lang, i_prof, g_row_so.dt_target_tstz);
            ELSE
                RETURN pk_hea_prv_aux.get_format_date(i_lang, i_prof, g_row_s.dt_begin_tstz);
            END IF;
        END IF;
    END;

    /**
    * Returns the label for 'Schedule'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_schedule
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'ID_T003');
    END;

    /**
    * Returns the episode register time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_register
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        RETURN pk_hea_prv_aux.get_format_date(i_lang, i_prof, g_dt_register);
    END;

    /**
    * Returns the label for 'Register'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_register
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'ID_T004');
    END;

    /**
    * Returns the episode waiting time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_waiting
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
        l_dt_init epis_info.dt_init%TYPE := NULL;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
    
        IF g_row_s.id_schedule IS NOT NULL
           AND g_row_s.id_schedule <> -1
        THEN
            BEGIN
                SELECT ei.dt_init
                  INTO l_dt_init
                  FROM epis_info ei
                 WHERE ei.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_init := NULL;
            END;
        END IF;
    
        IF g_row_e.flg_status = 'I'
        THEN
            RETURN '--- / ---';
        END IF;
        RETURN pk_hea_prv_aux.get_waiting(i_lang,
                                          i_prof,
                                          coalesce(g_row_so.dt_target_tstz, g_row_s.dt_begin_tstz),
                                          g_dt_register,
                                          coalesce(l_dt_init, g_dt_first));
    END;

    /**
    * Returns the label for 'Waiting'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_waiting
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'ID_T007');
    END;

    /**
    * Returns the episode surgery procedures.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_flg_area             System application area flag
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_surg_procedures
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_area   IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        RETURN pk_sr_clinical_info.get_proposed_surgery(i_lang, i_id_episode, i_prof, pk_alert_constant.g_no);
    END;

    /**
    * Returns the surgery estimated duration.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_surg_est_dur
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        RETURN pk_sr_surg_record.get_surg_est_dur(i_lang, i_prof, i_id_episode, g_row_sr.duration);
    END;

    /**
    * Returns the label for ORIS 'Estimated duration'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_surg_est_dur
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T015');
    END;

    /**
    * Sets the surgery responsible professional.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE set_surg_resp_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF g_surg_prof IS NULL
        THEN
            pk_hea_prv_aux.get_surg_resp_prof(i_lang, i_prof, i_id_episode, g_surg_prof, g_surg_prof_spec_inst);
        END IF;
    END;

    /**
    * Returns the surgery responsible professional.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_surg_resp_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        set_surg_resp_prof(i_lang, i_prof, i_id_episode);
        RETURN g_surg_prof;
    END;

    /**
    * Returns the specialty and institution of the surgery responsible professional .
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_surg_resp_prof_spec_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        set_surg_resp_prof(i_lang, i_prof, i_id_episode);
        RETURN g_surg_prof_spec_inst;
    END;

    FUNCTION between_comma(i_text VARCHAR2) RETURN VARCHAR IS
    BEGIN
        IF i_text IS NOT NULL
        THEN
            RETURN ' (' || i_text || ')';
        ELSE
            RETURN i_text;
        END IF;
    END;

    FUNCTION join_strings
    (
        i_str1 VARCHAR2,
        i_str2 VARCHAR2
    ) RETURN VARCHAR IS
    BEGIN
        IF i_str1 IS NOT NULL
           AND i_str2 IS NOT NULL
        THEN
            RETURN i_str1 || ' - ' || i_str2;
        ELSIF i_str1 IS NULL
              AND i_str2 IS NOT NULL
        THEN
            RETURN i_str2;
        ELSIF i_str1 IS NOT NULL
              AND i_str2 IS NULL
        THEN
            RETURN i_str1;
        ELSE
            RETURN NULL;
        END IF;
    END;
    /**
    * Sets the health plan.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   paulo teixeira
    * @version  2.6.1
    * @since    2011/02/18
    */
    PROCEDURE set_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) IS
        o_num_health_plan sys_message.desc_message%TYPE;
        o_hp_entity       sys_message.desc_message%TYPE;
        o_hp_desc         sys_message.desc_message%TYPE;
        o_hp_in_use       sys_message.desc_message%TYPE;
        o_nhn_number      sys_message.desc_message%TYPE;
        o_nhn_hp_entity   sys_message.desc_message%TYPE;
        o_nhn_hp_desc     sys_message.desc_message%TYPE;
        o_nhn_status      sys_message.desc_message%TYPE;
        o_nhn_desc_status sys_message.desc_message%TYPE;
        o_nhn_in_use      sys_message.desc_message%TYPE;
        l_nhn_in_use      sys_message.desc_message%TYPE;
        l_hp_in_use       sys_message.desc_message%TYPE;
        l_nhn_desc_status sys_message.desc_message%TYPE;
        l_idhp            pat_health_plan.id_health_plan%TYPE;
        l_nhn_idhp        pat_health_plan.id_health_plan%TYPE;
        t_error           t_error_out;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF g_ehp_number_style IS NULL
           OR g_ehp_info_style IS NULL
        THEN
            IF NOT pk_adt.get_health_plan(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_patient      => i_id_patient,
                                          i_id_episode      => i_id_episode,
                                          o_hp_id_hp        => l_idhp,
                                          o_num_health_plan => o_num_health_plan,
                                          o_hp_entity       => o_hp_entity,
                                          o_hp_desc         => o_hp_desc,
                                          o_hp_in_use       => o_hp_in_use,
                                          o_nhn_id_hp       => l_nhn_idhp,
                                          o_nhn_number      => o_nhn_number,
                                          o_nhn_hp_entity   => o_nhn_hp_entity,
                                          o_nhn_hp_desc     => o_nhn_hp_desc,
                                          o_nhn_status      => o_nhn_status,
                                          o_nhn_desc_status => o_nhn_desc_status,
                                          o_nhn_in_use      => o_nhn_in_use,
                                          o_error           => t_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_nhn_in_use      := between_comma(o_nhn_in_use);
            l_hp_in_use       := between_comma(o_hp_in_use);
            l_nhn_desc_status := between_comma(o_nhn_desc_status);
        
            IF o_nhn_number IS NOT NULL
            THEN
                --D
                g_epis_nhs_number := o_nhn_number;
                --E + F
                g_epis_nhs_info := join_strings(o_nhn_hp_entity, o_nhn_hp_desc) || ':';
                --E + F + D + G + H
                g_epis_nhs_tooltip_info := g_epis_nhs_info || ' ' || o_nhn_number || l_nhn_desc_status || l_nhn_in_use;
            
                IF nvl(o_nhn_status, 'NV') = 'NV'
                THEN
                    g_epis_nhs_tt_info_style  := 'Header7';
                    g_epis_nhs_tt_info_status := g_unverified;
                
                    g_epis_nhs_number_style  := 'Header7';
                    g_epis_nhs_number_status := g_unverified;
                ELSE
                    g_epis_nhs_tt_info_style  := 'Header18';
                    g_epis_nhs_tt_info_status := g_invalid;
                
                    g_epis_nhs_number_style  := 'Header18';
                    g_epis_nhs_number_status := g_invalid;
                END IF;
                g_ehp_number_style     := 'Header7';
                g_ehp_number_status    := g_unverified;
                g_epis_nhs_info_style  := 'Header7';
                g_epis_nhs_info_status := g_unverified;
            END IF;
        
            IF o_num_health_plan IS NOT NULL
               AND (o_nhn_number <> o_num_health_plan AND o_nhn_number IS NOT NULL)
               OR (o_nhn_number IS NULL)
            THEN
                --A
                g_epis_health_plan_number := o_num_health_plan;
                --B + C
                IF o_nhn_number IS NOT NULL
                THEN
                    g_epis_health_plan_info := '/ ' || join_strings(o_hp_entity, o_hp_desc) || ':';
                ELSE
                    g_epis_health_plan_info := join_strings(o_hp_entity, o_hp_desc) || ':';
                END IF;
                IF g_epis_health_plan_info = ':'
                THEN
                    g_epis_health_plan_info := NULL;
                END IF;
                --B + C + A + I
                g_ehp_tooltip_info := join_strings(o_hp_entity, o_hp_desc) || ': ' || o_num_health_plan || l_hp_in_use;
                IF g_ehp_tooltip_info = ': '
                THEN
                    g_ehp_tooltip_info := NULL;
                END IF;
                g_ehp_tooltip_info_style  := 'Header7';
                g_ehp_tooltip_info_status := g_unverified;
                g_ehp_number_style        := 'Header7';
                g_ehp_number_status       := g_unverified;
                g_ehp_info_style          := 'Header7';
                g_ehp_info_status         := g_unverified;
            END IF;
        
            IF o_nhn_status IS NULL
            THEN
                g_epis_health_plan_available := pk_alert_constant.g_yes;
            ELSE
                g_epis_health_plan_available := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_epis_nhs_info           := NULL;
            g_epis_nhs_info_style     := NULL;
            g_epis_nhs_number         := NULL;
            g_epis_nhs_number_style   := NULL;
            g_epis_health_plan_info   := NULL;
            g_ehp_info_style          := NULL;
            g_epis_nhs_tooltip_info   := NULL;
            g_epis_nhs_tt_info_style  := NULL;
            g_ehp_tooltip_info        := NULL;
            g_ehp_tooltip_info_style  := NULL;
            g_epis_health_plan_number := NULL;
            g_ehp_number_style        := NULL;
    END;

    /**
    * Returns set_healt_plan_info
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The episode value
    *
    * @author   paulo teixeira
    * @version  2.6.1
    * @since    2011/02/18
    */
    PROCEDURE set_health_plan_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        set_health_plan(i_lang, i_prof, i_id_patient, i_id_episode);
    END;

    /**
    * Returns the label for EDIS 'Admission date'/'Expected in'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_episode             Episode Id
    *
    * @return                      The label
    *
    * @author   Alexandre Santos
    * @version  2.5
    * @since    2009/10/23
    */
    FUNCTION get_label_admiss_dt_ann_arriv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF (is_expected_patient(i_episode))
        THEN
            --Previsto em
            RETURN pk_message.get_message(i_lang, i_prof, 'ANN_ARRIV_MSG067');
        ELSE
            RETURN pk_message.get_message(i_lang, i_prof, 'EDIS_ID_T009');
        END IF;
    END;

    /********************************************************************************************
    * Returns the episode complaint or diagnoses.
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    * @param i_id_schedule         Schedule ID
    * @param i_flg_area            Flag to indicate ths SYS_APPLICATION_AREA
    *
    *
    * @return                      Complaint/Diagnosis
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_comp_diag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_COMP_DIAG: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   i_id_episode)
          INTO l_epis_rehab
          FROM dual;
    
        check_var(i_lang, i_prof, l_epis_rehab, i_id_schedule);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        IF g_compl_diag IS NOT NULL
        THEN
            RETURN g_compl_diag;
        ELSE
            RETURN g_compl_pain;
        END IF;
    END;

    /********************************************************************************************
    * Returns the date and professional responsible for the last complaint or diagnoses.
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    * @param i_id_schedule         Schedule ID
    * @param i_flg_area            Flag to indicate ths SYS_APPLICATION_AREA
    *
    *
    * @return                      Complaint/Diagnosis
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_comp_diag_last_dt_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_COMP_DIAG_LAST_DT_PROF: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   i_id_episode)
          INTO l_epis_rehab
          FROM dual;
    
        check_var(i_lang, i_prof, l_epis_rehab, i_id_schedule);
        IF g_ehr_access != 'F'
           AND i_flg_area != 'P'
        THEN
            RETURN NULL;
        END IF;
        RETURN g_info_adic;
    END;

    /********************************************************************************************
    * Returns the service in which is the bed.
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    *
    *
    * @return                      Bed Service
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_bed_service
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_BED_SERVICE: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   i_id_episode)
          INTO l_epis_rehab
          FROM dual;
    
        check_var(i_lang, i_prof, l_epis_rehab, NULL);
        RETURN pk_hea_prv_aux.get_bed_service(i_lang, i_prof, g_row_ei.id_bed);
    END;

    /********************************************************************************************
    * Returns the room name in which is the bed.
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    *
    *
    * @return                      Bed Room
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_bed_room
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_BED_ROOM: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   i_id_episode)
          INTO l_epis_rehab
          FROM dual;
    
        check_var(i_lang, i_prof, l_epis_rehab, NULL);
        IF g_row_ei.id_bed IS NULL
        THEN
            RETURN NULL;
        END IF;
        RETURN pk_hea_prv_aux.get_room_name(i_lang => i_lang, i_prof => i_prof, i_id_bed => g_row_ei.id_bed);
    END;

    /********************************************************************************************
    * Returns the bed name.
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    *
    *
    * @return                      Bed Name
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_bed_name
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_BED_NAME: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   i_id_episode)
          INTO l_epis_rehab
          FROM dual;
    
        check_var(i_lang, i_prof, l_epis_rehab, NULL);
        RETURN pk_hea_prv_aux.get_bed_name(i_lang, i_prof, g_row_ei.id_bed);
    END;

    /********************************************************************************************
    * Returns the session type
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    *
    *
    * @return                      Bed Service
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_session_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab   rehab_epis_encounter.id_episode_rehab%TYPE;
        l_count        NUMBER(24);
        l_session_type VARCHAR2(400 CHAR);
        l_epis_type    epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_SESSION_TYPE: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   NULL)
          INTO l_epis_rehab
          FROM dual;
    
        IF i_id_episode IS NULL
        THEN
            IF i_id_schedule IS NOT NULL
            THEN
                SELECT pk_translation.get_translation(i_lang, rst.code_rehab_session_type)
                  INTO l_session_type
                  FROM rehab_sch_need rsn
                  JOIN rehab_session_type rst
                    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                  JOIN rehab_schedule rs
                    ON rs.id_rehab_sch_need = rsn.id_rehab_sch_need
                  JOIN schedule s
                    ON rs.id_schedule = s.id_schedule
                 WHERE rs.id_schedule = i_id_schedule
                   AND rsn.flg_status != 'C';
            ELSE
                RETURN NULL;
            END IF;
        ELSIF i_id_episode = l_epis_rehab
        THEN
        
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            IF l_epis_type <> pk_alert_constant.g_epis_type_rehab_appointment
            THEN
                --IF l_epis_type = g_epis_type_rehab_appointment, function rhb_schedule_type
                --is already inserting message REHAB_T148 in the header. No need to insert it
                --a second time. 
                l_session_type := pk_message.get_message(i_lang, i_prof, 'REHAB_T148');
            END IF;
        
        ELSE
        
            SELECT COUNT(*)
              INTO l_count
              FROM rehab_sch_need rsn
              JOIN rehab_session_type rst
                ON rst.id_rehab_session_type = rsn.id_rehab_session_type
             WHERE rsn.id_episode_origin = l_epis_rehab
               AND rsn.flg_status != 'C';
        
            IF l_count = 1
            THEN
            
                SELECT pk_translation.get_translation(i_lang, rst.code_rehab_session_type)
                  INTO l_session_type
                  FROM rehab_sch_need rsn
                  JOIN rehab_session_type rst
                    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                 WHERE rsn.id_episode_origin = l_epis_rehab
                   AND rsn.flg_status != 'C';
            
            END IF;
        
        END IF;
    
        RETURN l_session_type;
    END;

    /********************************************************************************************
    * Returns the schedule type
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    *
    *
    * @return                      Bed Service
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/18
    ********************************************************************************************/
    FUNCTION get_rhb_schedule_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    
        l_schedule_type VARCHAR2(400 CHAR);
    
        l_epis_type    episode.id_epis_type%TYPE;
        l_code_message sys_message.code_message%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_SCHEDULE_TYPE: ' || g_error);
    
        IF i_id_episode IS NOT NULL
        THEN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            IF l_epis_type IN (pk_alert_constant.g_epis_type_rehab_appointment,
                               pk_alert_constant.g_epis_type_cdc_appointment,
                               pk_alert_constant.g_epis_type_speech_therapy,
                               pk_alert_constant.g_epis_type_occup_therapy)
            THEN
                l_code_message := 'REHAB_T148';
            ELSE
                l_code_message := 'REHAB_T147';
            END IF;
        ELSIF i_id_schedule IS NOT NULL
        THEN
            l_code_message := 'REHAB_T147';
        ELSE
            RETURN NULL;
        END IF;
    
        l_schedule_type := pk_message.get_message(i_lang, i_prof, l_code_message);
    
        RETURN l_schedule_type;
    
    END get_rhb_schedule_type;

    /********************************************************************************************
    * Returns the register time
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    * @param i_id_schedule         Schedule ID
    *
    *
    * @return                      Bed Service
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/20
    ********************************************************************************************/
    FUNCTION get_rhb_register
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_REGISTER: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   NULL)
          INTO l_epis_rehab
          FROM dual;
    
        IF l_epis_rehab IS NULL
        THEN
            RETURN '--- / ---';
        ELSE
            check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
            RETURN pk_hea_prv_aux.get_format_date(i_lang, i_prof, g_dt_register);
        END IF;
    
    END;

    /********************************************************************************************
    * Returns the waiting time
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    * @param i_id_schedule         Schedule ID
    *
    *
    * @return                      Bed Service
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/20
    ********************************************************************************************/
    FUNCTION get_rhb_waiting
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab rehab_epis_encounter.id_episode_rehab%TYPE;
        l_dt_init    epis_info.dt_init%TYPE;
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_WAITING: ' || g_error);
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   NULL)
          INTO l_epis_rehab
          FROM dual;
    
        IF l_epis_rehab IS NULL
        THEN
            RETURN '--- / ---';
        ELSE
        
            check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
            IF g_row_e.flg_status = 'I'
            THEN
                RETURN '--- / ---';
            END IF;
            IF g_row_s.id_schedule IS NOT NULL
               AND g_row_s.id_schedule <> -1
            THEN
                BEGIN
                    SELECT ei.dt_init
                      INTO l_dt_init
                      FROM epis_info ei
                     WHERE ei.id_episode = i_id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_dt_init := NULL;
                END;
            END IF;
            RETURN pk_hea_prv_aux.get_waiting(i_lang,
                                              i_prof,
                                              coalesce(g_row_so.dt_target_tstz, g_row_s.dt_begin_tstz),
                                              g_dt_register,
                                              coalesce(l_dt_init, g_dt_first));
        END IF;
    END;

    /********************************************************************************************
    * Returns the location
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    *
    *
    * @return                      Bed Service
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/08/20
    ********************************************************************************************/
    FUNCTION get_rhb_location
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    
        l_epis_rehab   rehab_epis_encounter.id_episode_rehab%TYPE;
        l_id_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        g_error := 'SELECT REHAB ID_EPISODE FROM ID_EPISODE: ' || to_char(i_id_episode);
        pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_LOCATION: ' || g_error);
    
        IF i_id_episode IS NULL
        THEN
            RETURN '---';
        END IF;
    
        SELECT nvl((SELECT ree.id_episode_origin
                     FROM rehab_epis_encounter ree
                    WHERE ree.id_episode_rehab = i_id_episode
                      AND rownum = 1),
                   NULL)
          INTO l_epis_rehab
          FROM dual;
    
        IF l_epis_rehab IS NULL
        THEN
        
            g_error := 'SELECT ID_EPISODE_TYPE FROM ID_EPISODE: ' || to_char(i_id_episode);
            pk_alertlog.log_debug('PK_HEA_PRV_EPIS.GET_REHAB_LOCATION: ' || g_error);
            SELECT e.id_epis_type
              INTO l_id_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            IF l_id_epis_type = 5
            THEN
                check_var(i_lang, i_prof, i_id_episode, NULL);
                RETURN pk_hea_prv_aux.get_room_name(i_lang => i_lang, i_prof => i_prof, i_id_room => g_row_ei.id_room);
            ELSE
                RETURN '---';
            END IF;
        
        ELSE
        
            RETURN '---';
        
        END IF;
    
    END;

    /********************************************************************************************
    * Returns the icon to be used in position X
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_episode          Episode ID
    * @param i_icon_number         Icon position number
    *
    * @return                      Icon to be used
    *
    * @author                      S?rgio Santos
    * @version                     2.6.0.3.4
    * @since                       2010/11/22
    ********************************************************************************************/
    FUNCTION get_pat_photo_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    
        l_icon_main_resp CONSTANT VARCHAR2(40 CHAR) := 'MainRespIcon';
        l_icon_over_resp CONSTANT VARCHAR2(40 CHAR) := 'OverallRespIcon';
        l_icon_epi_resp  CONSTANT VARCHAR2(40 CHAR) := 'EpisodeRespIcon';
    
        l_icon_main_resp_hea CONSTANT VARCHAR2(40 CHAR) := 'MainRespHeaderIcon';
        l_icon_over_resp_hea CONSTANT VARCHAR2(40 CHAR) := 'OverallRespHeaderIcon';
        l_icon_epi_resp_hea  CONSTANT VARCHAR2(40 CHAR) := 'EpisodeRespHeaderIcon';
    
        l_resp_icons table_varchar;
    
        l_return_icon VARCHAR2(40 CHAR) := NULL;
    BEGIN
    
        l_resp_icons := pk_hand_off_api.get_resp_icons(i_lang, i_prof, i_id_episode, NULL);
    
        --if nothing then nothing
        IF l_resp_icons IS NULL
           OR NOT l_resp_icons.count > 0
        THEN
            RETURN NULL;
        END IF;
    
        IF pk_utils.search_table_varchar(l_resp_icons, l_icon_epi_resp) <> -1
           AND l_resp_icons.count = 1
        THEN
            l_return_icon := l_icon_epi_resp_hea;
        END IF;
    
        IF pk_utils.search_table_varchar(l_resp_icons, l_icon_over_resp) <> -1
        THEN
            l_return_icon := l_icon_over_resp_hea;
        END IF;
    
        IF pk_utils.search_table_varchar(l_resp_icons, l_icon_main_resp) <> -1
        THEN
            l_return_icon := l_icon_main_resp_hea;
        END IF;
        RETURN l_return_icon;
    
    END get_pat_photo_icon;

    /**
    * Validates if ges label is available
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       'Y' - if available; 'N' - Otherwise
    *
    * @author   Alexandre Santos
    * @version  2.6.1
    * @since    2011/11/22
    */
    FUNCTION get_pat_ges_available
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
    
        IF pk_hea_prv_epis.g_pat_ges_available IS NULL
        THEN
            IF pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution) =
               pk_alert_constant.g_id_market_cl
            THEN
                pk_hea_prv_epis.g_pat_ges_available := pk_alert_constant.g_yes;
            ELSE
                pk_hea_prv_epis.g_pat_ges_available := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN pk_hea_prv_epis.g_pat_ges_available;
    END get_pat_ges_available;

    /**
    * Returns GES Pathologies
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       GES Pathologies
    *
    * @author   Alexandre Santos
    * @version  2.6.1
    * @since    2011/11/22
    */
    FUNCTION get_ges_pathologies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_varchar IS
    BEGIN
        IF pk_hea_prv_epis.g_pat_ges_pathologies IS NULL
        THEN
            pk_hea_prv_epis.g_pat_ges_pathologies := pk_adt.get_pat_exemptions(i_lang       => i_lang,
                                                                               i_prof       => i_prof,
                                                                               i_id_patient => i_id_patient);
        END IF;
    
        RETURN pk_hea_prv_epis.g_pat_ges_pathologies;
    END get_ges_pathologies;

    /**
    * Returns GES Tooltip Title
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       Tooltip title
    *
    * @author   Alexandre Santos
    * @version  2.6.1
    * @since    2011/11/22
    */
    FUNCTION get_pat_ges_title
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_code_msg CONSTANT sys_message.code_message%TYPE := 'GES_M004';
        l_ret             VARCHAR2(32767);
        l_tab_pathologies table_varchar;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
    
        l_tab_pathologies := get_ges_pathologies(i_lang, i_prof, i_id_patient);
    
        IF get_pat_ges_available(i_lang, i_prof, i_id_episode) = pk_alert_constant.g_yes
           AND l_tab_pathologies.count > 0
        THEN
            l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_ges_title;

    /**
    * Returns GES Tooltip Text
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       Tooltip title
    *
    * @author   Alexandre Santos
    * @version  2.6.1
    * @since    2011/11/22
    */
    FUNCTION get_pat_ges_pathologies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret             VARCHAR2(32767);
        l_tab_pathologies table_varchar;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
    
        IF get_pat_ges_available(i_lang, i_prof, i_id_episode) = pk_alert_constant.g_yes
        THEN
            l_tab_pathologies := get_ges_pathologies(i_lang, i_prof, i_id_patient);
        
            IF l_tab_pathologies.count > 0
            THEN
                FOR r_pat IN (SELECT column_value desc_pathologie
                                FROM TABLE(l_tab_pathologies))
                LOOP
                    l_ret := l_ret || '- ' || r_pat.desc_pathologie || chr(13);
                END LOOP;
            ELSE
                l_ret := NULL;
            END IF;
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_ges_pathologies;

    /**
    * Returns GES Text
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       Tooltip title
    *
    * @author   Alexandre Santos
    * @version  2.6.1
    * @since    2011/11/22
    */
    FUNCTION get_pat_ges_txt
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_code_msg        CONSTANT sys_message.code_message%TYPE := 'GES_M005';
        l_text_to_replace CONSTANT VARCHAR2(2) := '@1';
        l_ret             VARCHAR2(32767);
        l_tab_pathologies table_varchar;
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, NULL);
        IF get_pat_ges_available(i_lang, i_prof, i_id_episode) = pk_alert_constant.g_yes
        THEN
            l_tab_pathologies := get_ges_pathologies(i_lang, i_prof, i_id_patient);
        
            IF l_tab_pathologies.count > 0
            THEN
                l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg) || ';';
            
                l_ret := REPLACE(l_ret, l_text_to_replace, l_tab_pathologies.count);
            ELSE
                l_ret := NULL;
            END IF;
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_ges_txt;

    /**
    * Returns the label for 'Process'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_process
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    
    BEGIN
    
        RETURN pk_message.get_message(i_lang, i_prof, 'HEADER_M018');
    
    END;

    /**
    * Returns the episode process.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_patient           Patient Id
    * @param i_id_schedule          Schedule Id
    * @param i_id_pat_identifier    Patient identifier
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_process
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE
    ) RETURN VARCHAR IS
    
    BEGIN
    
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
    
        IF i_id_patient IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF g_clin_record IS NULL
        THEN
            g_clin_record := pk_hea_prv_aux.get_process(i_lang, i_prof, i_id_patient, i_id_pat_identifier, i_id_episode);
        END IF;
    
        RETURN nvl(g_clin_record, '---');
    
    END get_process;

    FUNCTION get_epis_number_available
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    
    BEGIN
    
        g_epis_number_available := pk_sysconfig.get_config('HEADER_EPIS_NUMBER_AVAILABLE', i_prof);
    
        RETURN g_epis_number_available;
    
    END get_epis_number_available;

    FUNCTION get_location_action_param
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
    
        IF g_row_sg.id_schedule IS NOT NULL
           AND g_row_sg.flg_contact_type = 'V'
           AND g_row_e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
           AND i_flg_area = 'P'
           AND g_row_e.flg_status = pk_alert_constant.g_epis_status_active
           AND (g_row_ei.dt_init IS NOT NULL OR g_row_ei.dt_first_obs_tstz IS NOT NULL)
        THEN
            --    RETURN 'https://emr-demo.alert-online.com/index.html?idRoom=institution/2/software/1/specialty/360/professional/7020000660724/1594976359439&memberName=Professional&memberType=professional&patientId=7851546&languageId=8 ';
            RETURN g_row_s.video_link;
        ELSE
            RETURN NULL;
        END IF;
    
    END get_location_action_param;

    FUNCTION get_location_action
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
    
        IF g_row_sg.id_schedule IS NOT NULL
           AND g_row_sg.flg_contact_type = 'V'
           AND g_row_e.flg_ehr = pk_ehr_access.g_flg_ehr_normal
           AND i_flg_area = 'P'
           AND g_row_e.flg_status = pk_alert_constant.g_epis_status_active
           AND (g_row_ei.dt_init IS NOT NULL OR g_row_ei.dt_first_obs_tstz IS NOT NULL)
        THEN
            RETURN 'OPEN_URL_BLANK';
        ELSE
            RETURN NULL;
        END IF;
    
    END get_location_action;
    /**
    * Returns the episode value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_child_episode     Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_schedule          Schedule Id
    * @param i_id_epis_type         Episode type Id
    * @param i_id_institution       Institution Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data
    *
    * @return                       The episode value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_child_episode  IN episode.id_episode%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE,
        i_flg_area          IN sys_application_area.flg_area%TYPE,
        i_tag               IN header_tag.internal_name%TYPE,
        o_data_rec          OUT t_rec_header_data
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(64) := 'GET_VALUE';
        l_id_schedule NUMBER;
        l_data_rec    t_rec_header_data := t_rec_header_data(NULL,
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
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_episode IS NULL
           AND i_id_schedule IS NULL
           AND (i_tag NOT IN ('EPIS_SOFTWARE',
                              'EPIS_PROCESS',
                              'EPIS_MANCH_COLOR',
                              'EPIS_HEALTH_PLAN_AVAILABLE',
                              'EPIS_HEALTH_PLAN_INFO',
                              'EPIS_HEALTH_PLAN_NUMBER',
                              'EPIS_HEALTH_PLAN_TOOLTIP_INFO',
                              'EPIS_NHS_NUMBER',
                              'EPIS_NHS_TOOLTIP_INFO',
                              'EPIS_NHS_INFO',
                              'PAT_GES_AVAILABLE',
                              'PAT_GES_TITLE',
                              'PAT_GES_PATHOLOGIES',
                              'PAT_GES_TXT') OR i_id_patient IS NULL)
        THEN
            RETURN FALSE;
        END IF;
        CASE i_tag
            WHEN 'EPIS_REHAB_COMP_DIAG' THEN
                l_data_rec.text := get_rhb_comp_diag(i_lang, i_prof, i_id_episode, i_id_schedule, i_flg_area);
            WHEN 'EPIS_REHAB_COMP_DIAG_LAST_DT_PROF' THEN
                l_data_rec.text := get_rhb_comp_diag_last_dt_prof(i_lang,
                                                                  i_prof,
                                                                  i_id_episode,
                                                                  i_id_schedule,
                                                                  i_flg_area);
            WHEN 'EPIS_REHAB_BED_SERVICE' THEN
                l_data_rec.text := get_rhb_bed_service(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_REHAB_BED_ROOM' THEN
                l_data_rec.text := get_rhb_bed_room(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_REHAB_BED_NAME' THEN
                l_data_rec.text := get_rhb_bed_name(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_REHAB_SCHEDULE_TYPE' THEN
                l_data_rec.text := get_rhb_schedule_type(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_REHAB_SESSION_TYPE' THEN
                l_data_rec.text := get_rhb_session_type(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_REHAB_REGISTER' THEN
                l_data_rec.text := get_rhb_register(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_REHAB_WAITING' THEN
                l_data_rec.text := get_rhb_waiting(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_REHAB_LOCATION' THEN
                l_data_rec.text         := get_location(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.action       := get_location_action(i_lang, i_prof, i_id_episode, i_id_schedule, i_flg_area);
                l_data_rec.action_param := get_location_action_param(i_lang,
                                                                     i_prof,
                                                                     i_id_episode,
                                                                     i_id_schedule,
                                                                     i_flg_area);
            WHEN 'EPIS_COMP_DIAG' THEN
                l_data_rec.text := get_comp_diag(i_lang, i_prof, i_id_episode, i_id_schedule, i_flg_area);
            WHEN 'EPIS_COMP_DIAG_LAST_DT_PROF' THEN
                l_data_rec.text := get_comp_diag_last_dt_prof(i_lang, i_prof, i_id_episode, i_id_schedule, i_flg_area);
            WHEN 'EPIS_SOFTWARE' THEN
                l_data_rec.text := get_software(i_lang, i_prof, i_id_epis_type, i_id_episode);
            WHEN 'EPIS_PROCESS' THEN
                l_data_rec.text        := get_process(i_lang,
                                                      i_prof,
                                                      i_id_episode,
                                                      i_id_patient,
                                                      i_id_schedule,
                                                      i_id_pat_identifier);
                l_data_rec.description := get_process(i_lang, i_prof);
            WHEN 'EPIS_NUMBER' THEN
                l_data_rec.text        := get_number(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description := get_epis(i_lang, i_prof);
            WHEN 'EPIS_LOCATION' THEN
                l_data_rec.text         := get_location(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description  := get_location(i_lang, i_prof);
                l_data_rec.action       := get_location_action(i_lang, i_prof, i_id_episode, i_id_schedule, i_flg_area);
                l_data_rec.action_param := get_location_action_param(i_lang,
                                                                     i_prof,
                                                                     i_id_episode,
                                                                     i_id_schedule,
                                                                     i_flg_area);
            WHEN 'EPIS_ROOM_TIME' THEN
                l_data_rec.text        := get_room_time(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description := get_room_time(i_lang, i_prof);
            WHEN 'EPIS_TOTAL_TIME' THEN
                l_data_rec.text        := get_total_time(i_lang, i_prof, i_id_episode);
                l_data_rec.description := get_total_time(i_lang, i_prof);
            WHEN 'EPIS_ADMISSION_DATE' THEN
                l_data_rec.text        := get_admission_date(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description := get_label_admiss_dt_ann_arriv(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_RESP_DOCTOR' THEN
                l_data_rec.text := get_resp_doctor(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_RESP_DOCTOR_SPEC_INST' THEN
                l_data_rec.text := get_resp_doctor_spec_inst(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_RESP_NURSE' THEN
                l_data_rec.text := get_resp_nurse(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_RESP_NURSE_SPEC_INST' THEN
                l_data_rec.text := get_resp_nurse_spec_inst(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_DISPOSITION_TRANSFER_REOPEN' THEN
                l_data_rec.text := get_disp_transf_reopen(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_FAST_TRACK' THEN
                l_data_rec.text     := get_fast_track(i_lang, i_prof, i_id_episode);
                l_data_rec.icon     := pk_hea_prv_ehr.set_icon_prefix(get_fast_track_icon(i_lang, i_prof, i_id_episode)); -- EMR-463
                l_data_rec.shortcut := get_fast_track_shortcut(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_MANCH_COLOR' THEN
                l_data_rec.text := get_manch_color(i_lang, i_prof, i_id_episode, i_id_patient);
            WHEN 'EPIS_SERVICE' THEN
                l_data_rec.text := get_service(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_BED_SERVICE' THEN
                l_data_rec.text := get_bed_service(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_BED_ROOM' THEN
                l_data_rec.text := get_bed_room(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_BED_NAME' THEN
                l_data_rec.text := get_bed_name(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_LOCATION_SERVICE' THEN
                l_data_rec.text        := get_location_service(i_lang, i_prof, i_id_episode);
                l_data_rec.description := get_location_service(i_lang, i_prof);
            WHEN 'EPIS_DISPOSITION_DATE' THEN
                l_data_rec.text        := get_disposition_date(i_lang, i_prof, i_id_episode);
                l_data_rec.description := get_label_disposition_date(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_APPOINTMENT_TYPE' THEN
                l_data_rec.text := get_appointment_type(i_lang, i_prof, i_id_episode, i_id_schedule);
            WHEN 'EPIS_SCHEDULE' THEN
                l_data_rec.text        := get_schedule(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description := get_schedule(i_lang, i_prof);
            WHEN 'EPIS_REGISTER' THEN
                l_data_rec.text        := get_register(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description := get_register(i_lang, i_prof);
            WHEN 'EPIS_WAITING' THEN
                l_data_rec.text        := get_waiting(i_lang, i_prof, i_id_episode, i_id_schedule);
                l_data_rec.description := get_waiting(i_lang, i_prof);
            WHEN 'EPIS_SURG_PROCEDURES' THEN
                l_data_rec.text := get_surg_procedures(i_lang, i_prof, i_id_episode, i_flg_area);
            WHEN 'EPIS_SURG_EST_DUR' THEN
                l_data_rec.text        := get_surg_est_dur(i_lang, i_prof, i_id_episode);
                l_data_rec.description := get_surg_est_dur(i_lang, i_prof);
            WHEN 'EPIS_SURG_RESP_PROF' THEN
                l_data_rec.text := get_surg_resp_prof(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_SURG_RESP_PROF_SPEC_INST' THEN
                l_data_rec.text := get_surg_resp_prof_spec_inst(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_RESP_ICON' THEN
                l_data_rec.icon := pk_hea_prv_ehr.set_icon_prefix(get_pat_photo_icon(i_lang, i_prof, i_id_episode)); -- EMR-463
            WHEN 'EPIS_NHS_INFO' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.text           := g_epis_nhs_info;
                l_data_rec.tooltip_text   := g_epis_nhs_tooltip_info;
                l_data_rec.tooltip_status := g_epis_nhs_info_status;
                l_data_rec.status         := g_epis_nhs_info_status;
            WHEN 'EPIS_NHS_NUMBER' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.text   := g_epis_nhs_number;
                l_data_rec.status := g_epis_nhs_number_status;
            WHEN 'EPIS_HEALTH_PLAN_INFO' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.text           := g_epis_health_plan_info;
                l_data_rec.tooltip_text   := g_ehp_tooltip_info;
                l_data_rec.tooltip_status := g_ehp_info_status;
                l_data_rec.status         := g_ehp_info_status;
            WHEN 'EPIS_HEALTH_PLAN_NUMBER' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.text   := g_epis_health_plan_number;
                l_data_rec.status := g_ehp_number_status;
            WHEN 'EPIS_HEALTH_PLAN_AVAILABLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.text := g_epis_health_plan_available;
            WHEN 'PAT_GES_AVAILABLE' THEN
                l_data_rec.text := get_pat_ges_available(i_lang, i_prof, i_id_episode);
            WHEN 'PAT_GES_TXT' THEN
                l_data_rec.text          := get_pat_ges_txt(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.tooltip_title := get_pat_ges_title(i_lang, i_prof, i_id_patient, i_id_episode);
                l_data_rec.tooltip_text  := get_pat_ges_pathologies(i_lang, i_prof, i_id_patient, i_id_episode);
            WHEN 'EPIS_NUMBER_NOT_DISPLAY' THEN
                l_data_rec.text := get_epis_number_available(i_lang, i_prof);
            WHEN 'EPIS_HHC_ADMISSION' THEN
                l_data_rec.text        := pk_date_utils.dt_hour_chr_short_tsz(i_lang,
                                                                              pk_hhc_core.get_hhc_dt_admission(i_lang,
                                                                                                               i_prof,
                                                                                                               i_id_episode),
                                                                              i_prof);
                l_data_rec.description := pk_message.get_message(i_lang, i_prof, 'HEADER_M032');
            WHEN 'EPIS_HHC_DISCHARGE' THEN
                l_data_rec.text        := pk_date_utils.dt_hour_chr_short_tsz(i_lang,
                                                                              pk_hhc_core.get_hhc_dt_discharge(i_lang,
                                                                                                               i_prof,
                                                                                                               i_id_episode),
                                                                              i_prof);
                l_data_rec.description := pk_message.get_message(i_lang, i_prof, 'HEADER_M033');
            WHEN 'EPIS_HHC' THEN
                l_data_rec.text := pk_hhc_core.get_hhc_message(i_lang, i_prof, i_id_episode, i_id_patient); --get_fast_track(i_lang, i_prof, i_id_episode);
                l_data_rec.icon := pk_hea_prv_ehr.set_icon_prefix(pk_hhc_core.get_hhc_icon(i_lang,
                                                                                           i_prof,
                                                                                           i_id_episode,
                                                                                           i_id_patient));
            
                l_data_rec.shortcut := pk_hhc_core.get_home_care_shortcut(i_lang, i_prof, i_id_episode, i_id_patient);
            WHEN 'EPIS_HHC_PROFESSIONAL' THEN
                l_data_rec.text := pk_hhc_core.get_hhc_professional(i_lang, i_prof, i_id_schedule);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the episode value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_child_episode     Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_schedule          Schedule Id
    * @param i_id_epis_type         Episode type Id
    * @param i_id_institution       Institution Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_child_episode  IN episode.id_episode%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE,
        i_flg_area          IN sys_application_area.flg_area%TYPE,
        i_tag               IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_tag       header_tag.internal_name%TYPE;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_episode IS NULL
           AND i_id_schedule IS NULL
           AND (i_tag NOT IN ('EPIS_SOFTWARE',
                              'EPIS_PROCESS',
                              'EPIS_MANCH_TEXT_STYLE',
                              'EPIS_MANCH_COLOR',
                              'EPIS_HEALTH_PLAN_AVAILABLE',
                              'EPIS_HEALTH_PLAN_INFO',
                              'EPIS_HEALTH_PLAN_INFO_STYLE',
                              'EPIS_HEALTH_PLAN_NUMBER',
                              'EPIS_HEALTH_PLAN_NUMBER_STYLE',
                              'EPIS_HEALTH_PLAN_TOOLTIP_INFO',
                              'EPIS_HEALTH_PLAN_TOOLTIP_INFO_STYLE',
                              'EPIS_NHS_INFO_STYLE',
                              'EPIS_NHS_NUMBER',
                              'EPIS_NHS_NUMBER_STYLE',
                              'EPIS_NHS_TOOLTIP_INFO',
                              'EPIS_NHS_TOOLTIP_INFO_STYLE',
                              'EPIS_NHS_INFO',
                              'PAT_GES_AVAILABLE',
                              'PAT_GES_TITLE',
                              'PAT_GES_PATHOLOGIES',
                              'PAT_GES_TXT',
                              'EPIS_HHC_PROFESSIONAL') OR i_id_patient IS NULL)
        THEN
            RETURN NULL;
        END IF;
    
        -- Translate old tags to html version
        CASE i_tag
            WHEN 'EPIS_LABEL_ADMISSION_DATE' THEN
                l_tag := 'EPIS_ADMISSION_DATE';
            WHEN 'EPIS_LABEL_DISPOSITION_DATE' THEN
                l_tag := 'EPIS_DISPOSITION_DATE';
            WHEN 'EPIS_FAST_TRACK_ICON' THEN
                l_tag := 'EPIS_FAST_TRACK';
            WHEN 'EPIS_SHORTCUT_FAST_TRACK' THEN
                l_tag := 'EPIS_FAST_TRACK';
            WHEN 'EPIS_HEALTH_PLAN_TOOLTIP_INFO' THEN
                l_tag := 'EPIS_HEALTH_PLAN_INFO';
            WHEN 'EPIS_NHS_TOOLTIP_INFO' THEN
                l_tag := 'EPIS_NHS_INFO';
            WHEN 'PAT_GES_PATHOLOGIES' THEN
                l_tag := 'PAT_GES_TXT';
            WHEN 'PAT_GES_TITLE' THEN
                l_tag := 'PAT_GES_TXT';
            ELSE
                l_tag := i_tag;
        END CASE;
    
        l_ret := get_value_html(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                i_id_child_episode,
                                i_id_schedule,
                                i_id_epis_type,
                                i_id_pat_identifier,
                                i_flg_area,
                                l_tag,
                                l_data_rec);
    
        CASE i_tag
            WHEN 'EPIS_REHAB_COMP_DIAG' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_COMP_DIAG_LAST_DT_PROF' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_BED_SERVICE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_BED_ROOM' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_BED_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_SCHEDULE_TYPE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_SESSION_TYPE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_REGISTER' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_WAITING' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REHAB_LOCATION' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_COMP_DIAG' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_COMP_DIAG_LAST_DT_PROF' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_SOFTWARE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_PROCESS' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_NUMBER' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_LOCATION' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ROOM_TIME' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_TOTAL_TIME' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ADMISSION_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_RESP_DOCTOR' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_RESP_DOCTOR_SPEC_INST' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_RESP_NURSE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_RESP_NURSE_SPEC_INST' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_DISPOSITION_TRANSFER_REOPEN' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_FAST_TRACK' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_FAST_TRACK_ICON' THEN
                RETURN l_data_rec.icon;
            WHEN 'EPIS_SHORTCUT_FAST_TRACK' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'EPIS_MANCH_COLOR' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_MANCH_TEXT_STYLE' THEN
                RETURN get_manch_text_style(i_lang, i_prof, i_id_episode, i_id_patient);
            WHEN 'EPIS_SERVICE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_BED_SERVICE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_BED_ROOM' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_BED_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_LOCATION_SERVICE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_DISPOSITION_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_LABEL_DISPOSITION_DATE' THEN
                RETURN l_data_rec.description;
            WHEN 'EPIS_APPOINTMENT_TYPE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_SCHEDULE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_REGISTER' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_WAITING' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_SURG_PROCEDURES' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_SURG_EST_DUR' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_SURG_RESP_PROF' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_SURG_RESP_PROF_SPEC_INST' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_LABEL_ADMISSION_DATE' THEN
                RETURN l_data_rec.description;
            WHEN 'EPIS_RESP_ICON' THEN
                RETURN l_data_rec.icon;
            WHEN 'EPIS_NHS_INFO' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_NHS_INFO_STYLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                RETURN g_epis_nhs_info_style;
            WHEN 'EPIS_NHS_NUMBER' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_NHS_NUMBER_STYLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                RETURN g_epis_nhs_number_style;
            WHEN 'EPIS_HEALTH_PLAN_INFO' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_HEALTH_PLAN_INFO_STYLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                RETURN g_ehp_info_style;
            WHEN 'EPIS_NHS_TOOLTIP_INFO' THEN
                RETURN l_data_rec.tooltip_text;
            WHEN 'EPIS_NHS_TOOLTIP_INFO_STYLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                RETURN g_epis_nhs_tt_info_style;
            WHEN 'EPIS_HEALTH_PLAN_TOOLTIP_INFO' THEN
                RETURN l_data_rec.tooltip_text;
            WHEN 'EPIS_HEALTH_PLAN_TOOLTIP_INFO_STYLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                RETURN g_ehp_tooltip_info_style;
            WHEN 'EPIS_HEALTH_PLAN_NUMBER' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_HEALTH_PLAN_NUMBER_STYLE' THEN
                set_health_plan_info(i_lang, i_prof, i_id_patient, i_id_episode);
                RETURN g_ehp_number_style;
            WHEN 'EPIS_HEALTH_PLAN_AVAILABLE' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_GES_AVAILABLE' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_GES_TITLE' THEN
                RETURN l_data_rec.tooltip_title;
            WHEN 'PAT_GES_PATHOLOGIES' THEN
                RETURN l_data_rec.tooltip_text;
            WHEN 'PAT_GES_TXT' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_NUMBER_NOT_DISPLAY' THEN
                RETURN get_epis_number_available(i_lang, i_prof);
            WHEN 'EPIS_HHC_PROFESSIONAL' THEN
                RETURN l_data_rec.text;
            ELSE
                RETURN 'epis_' || i_tag;
        END CASE;
        RETURN 'epis_' || i_tag;
    END;

    FUNCTION get_admission_date_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        o_adm_date     OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_adm_date_str OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF (is_expected_patient(i_id_episode))
        THEN
            o_adm_date := pk_announced_arrival.get_expected_arrival_dt(i_id_episode);
        ELSE
            check_var(i_lang, i_prof, i_id_episode, i_id_schedule);
        
            IF (i_prof.software = pk_alert_constant.g_soft_inpatient)
            THEN
                IF (g_row_e.flg_ehr = pk_alert_constant.g_flg_ehr_n)
                THEN
                    o_adm_date := g_row_e.dt_begin_tstz;
                ELSE
                    o_adm_date := NULL;
                END IF;
            ELSE
                o_adm_date := g_row_e.dt_begin_tstz;
            END IF;
            --
        
        END IF;
    
        IF o_adm_date IS NOT NULL
        THEN
            o_adm_date_str := pk_date_utils.date_char_tsz(i_lang, o_adm_date, i_prof.institution, i_prof.software);
        ELSE
            o_adm_date_str := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_adm_date     := NULL;
            o_adm_date_str := NULL;
            RETURN FALSE;
    END;

    /**
    * Returns the episode's responsibles.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_patient           Schedule Id
    * @param o_resp_doctor          Responsible doctor
    * @param o_resp_doctor_spec     Responsible doctor's specialty
    * @param o_resp_nurse           Responsible nurse
    * @param o_resp_nurse_spec      Responsible nurse's specialty
    *
    * @return                       boolean
    *
    * @author   Goncalo Almeida
    * @version  2.6.1
    * @since    2011/07/01
    */
    FUNCTION get_epis_responsibles
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT VARCHAR,
        o_resp_doctor_spec OUT VARCHAR,
        o_resp_nurse       OUT VARCHAR,
        o_resp_nurse_spec  OUT VARCHAR,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message VARCHAR2(4000 CHAR);
    BEGIN
        l_message := 'CALL TO FUNCTION GET_EPIS_RESPONSIBLES';
    
        reset_var;
    
        o_resp_doctor      := get_resp_doctor(i_lang, i_prof, i_id_episode, NULL);
        o_resp_nurse       := get_resp_nurse_report(i_lang, i_prof, i_id_episode, NULL);
        o_resp_doctor_spec := get_resp_doctor_spec(i_lang, i_prof, i_id_episode, NULL);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              'ALERT',
                                              pk_alertlog.who_am_i(),
                                              'GET_EPIS_RESPONSIBLES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_responsibles;

    /**
    * Returns the episode complaint or diagnoses.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    * @param i_flg_area             System application area flag
    * @param o_diagnosis            the diagnostic or chief complaint
    *
    * @return                       The episode value
    *
    * @author   Fábio Martins
    * @version  2.7
    * @since    2018/02/21
    */
    FUNCTION get_diagnosis_or_complaint
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        o_diagnosis   OUT VARCHAR,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_diagnosis := get_comp_diag(i_lang, i_prof, i_id_episode, i_id_schedule, i_flg_area);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'CALL GET_DIAGNOSIS_OR_COMPLAINT',
                                              'ALERT',
                                              pk_alertlog.who_am_i(),
                                              'GET_DIAGNOSIS_OR_COMPLAINT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_diagnosis_or_complaint;

    /**
    * Returns the episode location (new).
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param o_location             Location
    *
    * @return                       true or false
    *
    * @author   Fábio Martins
    * @version  2.7
    * @since    2018/02/22
    */
    FUNCTION get_location_new
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_location   OUT VARCHAR
    ) RETURN BOOLEAN IS
    BEGIN
        o_location := get_location(i_lang, i_prof, i_id_episode, NULL);
        RETURN TRUE;
    END get_location_new;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
