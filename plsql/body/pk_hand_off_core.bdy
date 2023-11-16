/*-- Last Change Revision: $Rev: 2051264 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-11-25 16:20:32 +0000 (sex, 25 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hand_off_core IS

    -- Private constant declarations
    g_empty_str       CONSTANT VARCHAR2(1) := '';
    g_dft_line_number CONSTANT PLS_INTEGER := 1;

    g_cfg_show_epis_over_resp CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_EPISODES_OVERALL_RESPONSIBILITY';

    g_code_trans_clin_serv CONSTANT translation.code_translation%TYPE := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
    --g_code_trans_depart    CONSTANT translation.code_translation%TYPE := 'DEPARTMENT.CODE_DEPARTMENT.';

    g_code_msg_opn_m001 CONSTANT sys_message.code_message%TYPE := 'OPINION_M001'; --<any>

    g_code_msg_hoff_m003 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M003'; --Requested
    g_code_msg_hoff_m004 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M004'; --Complete
    g_code_msg_hoff_m005 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M005'; --Declined
    g_code_msg_hoff_m006 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M006'; --Cancelled

    g_code_msg_hoff_m069 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M069'; --(Assumed)
    g_code_msg_hoff_m070 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M070'; --(Diverted)
    g_code_msg_hoff_m071 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M071'; --(Transfered)
    g_code_msg_hoff_m072 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M072'; --(Completed)

    g_show_overall_resp sys_config.value%TYPE := NULL;

    g_desc_msg_clin_serv  sys_message.desc_message%TYPE; -- Clinical Service
    g_desc_msg_service    sys_message.desc_message%TYPE; -- Service
    g_desc_msg_speciality sys_message.desc_message%TYPE; -- Speciality
    g_desc_msg_department sys_message.desc_message%TYPE; -- Department

    g_domain_hoff_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_PROF_RESP.FLG_STATUS'; -- hand off status domain

    g_resp_icons_prof_cat category.flg_type%TYPE;

    /* CAN'T TOUCH THIS */
    g_owner VARCHAR2(30 CHAR);

    /**
    * Gets config show overall_resp
    *
    * @param   i_prof      professional, institution and software ids
    * @param   i_prof_cat  Professional category
    *
    * @return              'Y' if is to include overall responsibles, otherwise 'N'
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_show_overall_resp
    (
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN sys_config.value%TYPE IS
    BEGIN
        -- Check if episodes under OVERALL responsability should be displayed
        IF g_show_overall_resp IS NULL
           AND i_prof_cat = pk_alert_constant.g_cat_type_doc
        THEN
            g_error             := 'CHECK CONFIG SHOW_EPISODES_OVERALL_RESPONSIBILITY';
            g_show_overall_resp := pk_sysconfig.get_config(g_cfg_show_epis_over_resp,
                                                           i_prof.institution,
                                                           i_prof.software);
        END IF;
    
        RETURN g_show_overall_resp;
    END get_show_overall_resp;

    /********************************************************************************************
    * Assign the configured hand-off type to a given variable.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   io_hand_off_type       configured hand-off type (N) Normal (M) Multiple
    *                        
    * @return  The configured hand-off type.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/

    FUNCTION get_hand_off_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_hand_off_type IN sys_config.value%TYPE
    ) RETURN VARCHAR2 IS
        l_config    sys_config.value%TYPE;
        l_id_market market.id_market%TYPE;
        l_return    VARCHAR2(4000) := i_hand_off_type;
    BEGIN
        IF i_hand_off_type IS NULL
        THEN
            g_error := 'GET INST. MARKET';
            BEGIN
                SELECT i.id_market
                  INTO l_id_market
                  FROM institution i
                 WHERE i.id_institution = i_prof.institution;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_market := NULL;
            END;
        
            IF l_id_market IS NULL
            THEN
                l_return := pk_hand_off.g_handoff_normal;
            ELSE
                l_config := pk_sysconfig.get_config('MULTIPLE_HAND_OFF_MARKET', i_prof.institution, i_prof.software);
            
                IF instr(l_config, '|' || l_id_market || '|') > 0
                THEN
                    l_return := pk_hand_off.g_handoff_multiple;
                ELSE
                    l_return := pk_hand_off.g_handoff_normal;
                END IF;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END get_hand_off_type;

    PROCEDURE get_hand_off_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        io_hand_off_type IN OUT sys_config.value%TYPE
    ) IS
        l_tmp VARCHAR2(4000) := io_hand_off_type;
    BEGIN
    
        io_hand_off_type := get_hand_off_type(i_lang, i_prof, l_tmp);
    
    END get_hand_off_type;

    /********************************************************************************************
    * Get the maximum episode responsability request date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    * @param   i_flg_type             episode responsability type: (N)urse or (P)hysician
    * @param   i_flg_profile          profile type: S - specialist, R - resident, I - intern
    *                        
    * @return  Maximum request date
    * 
    * @author                         Jose Silva
    * @version                        2.5
    * @since                          12-10-2010
    **********************************************************************************************/
    FUNCTION get_max_dt_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_hand_off_type IN VARCHAR2
    ) RETURN epis_prof_resp.dt_request_tstz%TYPE IS
        l_error t_error_out;
        l_ret   epis_prof_resp.dt_request_tstz%TYPE;
    
        CURSOR c_dt_request_status(i_flg_status IN epis_prof_resp.flg_status%TYPE) IS
            SELECT MAX(t.dt_request_tstz)
              FROM (SELECT /*+ use_nl(epr1 empr) */
                     epr1.dt_request_tstz, empr.flg_profile
                      FROM alert.epis_prof_resp epr1
                      LEFT OUTER JOIN alert.epis_multi_prof_resp empr
                        ON epr1.id_epis_prof_resp = empr.id_epis_prof_resp
                     WHERE epr1.id_episode = i_episode
                       AND epr1.flg_type = i_flg_type
                       AND epr1.flg_status = i_flg_status
                       AND rownum > 0) t
             WHERE ((t.flg_profile = nvl(i_flg_profile, t.flg_profile) AND
                   i_hand_off_type = pk_hand_off.g_handoff_multiple) OR i_hand_off_type = pk_hand_off.g_handoff_normal);
    
        CURSOR c_dt_request IS
            SELECT MAX(t.dt_request_tstz)
              FROM (SELECT /*+ use_nl(epr1 empr) */
                     epr1.dt_request_tstz, empr.flg_profile
                      FROM alert.epis_prof_resp epr1
                      LEFT OUTER JOIN alert.epis_multi_prof_resp empr
                        ON epr1.id_epis_prof_resp = empr.id_epis_prof_resp
                     WHERE epr1.id_episode = i_episode
                       AND epr1.flg_type = i_flg_type
                       AND rownum > 0) t
             WHERE ((t.flg_profile = nvl(i_flg_profile, t.flg_profile) AND
                   i_hand_off_type = pk_hand_off.g_handoff_multiple) OR i_hand_off_type = pk_hand_off.g_handoff_normal);
    
    BEGIN
    
        g_error := 'GET MAX DT_REQUEST 1';
        OPEN c_dt_request_status(pk_hand_off.g_hand_off_r);
        FETCH c_dt_request_status
            INTO l_ret;
        CLOSE c_dt_request_status;
    
        IF l_ret IS NULL
        THEN
            g_error := 'GET MAX DT_REQUEST 2';
            OPEN c_dt_request;
            FETCH c_dt_request
                INTO l_ret;
            CLOSE c_dt_request;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_MAX_DT_REQUEST',
                                              l_error);
            RETURN NULL;
    END get_max_dt_request;

    /********************************************************************************************
    * Cancel a given hand-off request if was destinated to the current professional's department.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_cs_dest              destination clinical service
    * @param   i_dpt_dest             destination department
    * @param   i_id_epis_prof_resp    hand-off request ID
    * @param   i_flg_profile          type of profile
    * @param   i_hand_off_type        type of hand-off mechanism
    * @param   i_id_speciality        Speciality for the current transfer
    * @param   i_flg_resp_type        Type of responsability: (E) Episode (O) Overall
    * @param   o_error                error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          02-10-2009
    **********************************************************************************************/
    FUNCTION cancel_dpt_hand_off_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cs_dest           IN clinical_service.id_clinical_service%TYPE,
        i_dpt_dest          IN department.id_department%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_resp_type     IN epis_multi_prof_resp.flg_resp_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_DPT_HAND_OFF_REQUEST';
    
        CURSOR c_prof_dcs
        (
            i_cs_dest  epis_prof_resp.id_clinical_service_dest%TYPE,
            i_dpt_dest epis_prof_resp.id_department_dest%TYPE
        ) IS
            SELECT dcs.id_department
              FROM prof_dep_clin_serv pdcs
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
             WHERE pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = pk_edis_list.g_prof_dcs_status_active
               AND (dcs.id_clinical_service = i_cs_dest OR i_cs_dest IS NULL)
               AND (dcs.id_department = i_dpt_dest OR i_dpt_dest IS NULL);
    
        l_id_department department.id_department%TYPE;
        l_sysdate       TIMESTAMP WITH LOCAL TIME ZONE;
        l_internal_error EXCEPTION;
    
        l_r_epis_prof_resp        epis_prof_resp%ROWTYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_can_cancel              VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_request_speciality      epis_multi_prof_resp.id_speciality%TYPE;
    BEGIN
        l_sysdate := nvl(i_sysdate, current_timestamp);
    
        IF i_hand_off_type = pk_hand_off.g_handoff_normal
           OR (i_hand_off_type = pk_hand_off.g_handoff_multiple AND i_flg_profile = g_nurse)
        THEN
            -- Check if current professional belongs to the 
            -- destination department/clinical service
            g_error := 'GET PROF DCS';
            OPEN c_prof_dcs(i_cs_dest, i_dpt_dest);
            FETCH c_prof_dcs
                INTO l_id_department;
            CLOSE c_prof_dcs;
        
            IF l_id_department IS NOT NULL
            THEN
                l_can_cancel := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            g_error := 'GET REQUEST SPECIALITY';
            SELECT empr.id_speciality
              INTO l_request_speciality
              FROM epis_multi_prof_resp empr
             WHERE empr.id_epis_prof_resp = i_id_epis_prof_resp;
        
            IF l_request_speciality = i_id_speciality
            THEN
                -- If the request is destined to the current speciality, than cancel the existing request to "Any" professional.
                l_can_cancel := pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        IF l_can_cancel = pk_alert_constant.g_yes
        THEN
            g_error := 'CANCEL HAND-OFF REQUEST';
            UPDATE epis_prof_resp
               SET dt_cancel_tstz = l_sysdate,
                   flg_status     = pk_hand_off.g_hand_off_c,
                   id_prof_cancel = i_prof.id,
                   notes_cancel   = NULL
             WHERE id_epis_prof_resp = i_id_epis_prof_resp;
        
            g_error := 'GET HAND-OFF REQUEST DATA';
            SELECT erp.*
              INTO l_r_epis_prof_resp
              FROM epis_prof_resp erp
             WHERE erp.id_epis_prof_resp = i_id_epis_prof_resp;
        
            g_error := 'CALL TO SET_MULTI_PROF_RESP';
            IF NOT set_multi_prof_resp(i_lang                    => i_lang,
                                       i_prof                    => i_prof,
                                       i_id_episode              => l_r_epis_prof_resp.id_episode,
                                       i_id_prof_resp            => l_r_epis_prof_resp.id_prof_to,
                                       i_flg_profile             => i_flg_profile,
                                       i_id_epis_prof_resp       => l_r_epis_prof_resp.id_epis_prof_resp,
                                       i_flg_status              => l_r_epis_prof_resp.flg_status,
                                       i_sysdate                 => l_sysdate,
                                       i_hand_off_type           => i_hand_off_type,
                                       i_id_speciality           => i_id_speciality,
                                       i_flg_resp_type           => i_flg_resp_type,
                                       o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                       o_error                   => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_dpt_hand_off_request;

    /********************************************************************************************
    * Checks responsability over the episode, when accessing the patient's EHR.
    * Allows to retrieve all the necessary data to configure the responsability message boxes.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_pat                      Patient ID
    * @param   i_pat                      Patient ID
    * @param   o_show_msg_box             Show message box?
    *                                          (N) No, don't show any
    *                                          (E) Episode responsability message box, only
    *                                          (O) Overall responsability message box, only
    *                                          (A) All, show both episode and overall responsability message boxes
    * @param   o_flg_hand_off_type        Type of hand-off: (N) Normal (M) Multiple
    * @param   o_responsibles             List of ALL responsabiles for this episode
    * @param   o_episode_resp_box         Data for the EPISODE message box
    * @param   o_overall_resp_box         Data for the OVERALL message box
    * @param   o_episode_resp_options     Options for the EPISODE message box
    * @param   o_overall_resp_options     Options for the OVERALL message box
    * @param   o_labels_grid              Grid labels
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION check_prof_resp
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN epis_info.id_episode%TYPE,
        o_show_msg_box         OUT VARCHAR2,
        o_flg_hand_off_type    OUT VARCHAR2,
        o_responsibles         OUT pk_types.cursor_type,
        o_overall_resp_box     OUT pk_types.cursor_type,
        o_episode_resp_options OUT pk_types.cursor_type,
        o_labels_grid          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name     VARCHAR2(200 CHAR) := 'CHECK_PROF_RESP';
        l_error_message VARCHAR2(200 CHAR);
    
        -- Types of message box to show
        l_show_box_none    CONSTANT VARCHAR2(1 CHAR) := 'N';
        l_show_box_epis    CONSTANT VARCHAR2(1 CHAR) := 'E';
        l_show_box_overall CONSTANT VARCHAR2(1 CHAR) := 'O';
        l_show_box_all     CONSTANT VARCHAR2(1 CHAR) := 'A';
        l_show_msg_box           VARCHAR2(1 CHAR);
        l_handle_overall_msg_box BOOLEAN := FALSE;
    
        -- Aux. variables
        l_has_responsible        VARCHAR2(1 CHAR);
        l_responsibles           table_number := table_number();
        l_is_overall_responsible VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_is_epis_responsible    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_code_desc_title        sys_message.code_message%TYPE;
        l_code_desc_message_body sys_message.code_message%TYPE;
        l_allowed_profiles_tab   table_number;
    
        -- Data variables
        l_flg_status                 episode.flg_status%TYPE;
        l_id_profile_template        profile_template.id_profile_template%TYPE;
        l_prof_cat                   category.flg_type%TYPE;
        l_prof_profile_type          profile_template.flg_type%TYPE;
        l_flg_profile                profile_template.flg_profile%TYPE;
        l_take_resp_episode          sys_config.value%TYPE;
        l_hand_off_type              sys_config.value%TYPE;
        l_id_speciality              professional.id_speciality%TYPE;
        l_current_responsible_id     professional.id_professional%TYPE;
        l_current_responsible_name   professional.name%TYPE;
        l_current_amb_responsible_id professional.id_professional%TYPE;
        l_id_clinical_serv_amb       clinical_service.id_clinical_service%TYPE;
        l_id_department_amb          department.id_department%TYPE;
    
        -- Grid labels
        l_labels_grid table_varchar;
    
        l_code_cfg_epis_type CONSTANT sys_config.id_sys_config%TYPE := 'EPIS_TYPE';
        l_cfg_epis_type PLS_INTEGER;
        l_epis_type     PLS_INTEGER;
    
        l_internal_error EXCEPTION;
        l_data_error     EXCEPTION;
    
        --Is read only professional
        l_is_read_only_prof          VARCHAR2(1 CHAR);
        l_area_access                ehr_access_area_def.area%TYPE := 'HAND_OFF';
        l_acess_permission           VARCHAR2(1 CHAR);
        l_config                     sys_config.value%TYPE;
        l_same_specialty_responsible NUMBER;
        l_epis_resp_default          sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'HANDOFF_EPIS_RESP_DEFAULT',
                                                                                      i_prof    => i_prof);
    
        l_epis_resp_consultation sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'HAND_OFF_CONSULTATION',
                                                                                  i_prof    => i_prof);
        --l_has_consultation_request VARCHAR2(1 CHAR);
    
        l_flg_mrp            profile_template.flg_mrp%TYPE;
        l_same_specialty_mrp NUMBER;
        l_id_schedule        schedule.id_schedule%TYPE;
        --l_prof_list          table_number;
        l_flg_ehr episode.flg_ehr%TYPE;
    BEGIN
    
        --------------------------------------------------------------------
        -- 0) Check pre-conditions
        --------------------------------------------------------------------
        g_error := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error         := 'GET PROF EPIS_TYPE';
        l_cfg_epis_type := to_number(pk_sysconfig.get_config(i_code_cf => l_code_cfg_epis_type, i_prof => i_prof));
    
        -- Don't show any message box (default)
        o_show_msg_box := l_show_box_none;
        -- Return type of hand-off
        o_flg_hand_off_type := l_hand_off_type;
    
        g_error             := 'CALL CHECK_HAS_FUNCTIONALITY FUNCTION';
        l_is_read_only_prof := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_intern_name => pk_access.g_view_only_profile);
    
        IF l_is_read_only_prof = pk_alert_constant.g_yes
        THEN
            g_error := 'READ ONLY PROFESSIONAL';
        
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_my_cursor(o_episode_resp_options);
            pk_types.open_my_cursor(o_overall_resp_box);
            pk_types.open_my_cursor(o_labels_grid);
        
            RETURN TRUE;
        END IF;
    
        IF l_epis_resp_consultation = pk_alert_constant.g_no -- not shown pop-up if exists a consultation 
        THEN
            -- a consultation exists
            IF pk_opinion.check_opinion_prof(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode) =
               pk_alert_constant.g_yes
            THEN
                pk_types.open_my_cursor(o_responsibles);
                pk_types.open_my_cursor(o_episode_resp_options);
                pk_types.open_my_cursor(o_overall_resp_box);
                pk_types.open_my_cursor(o_labels_grid);
                RETURN TRUE;
            END IF;
        END IF;
    
        g_error := 'CALL CHECK_AREA_CREATE_PERMISSION FUNCTION';
    
        IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_id_episode,
                                                          i_area    => l_area_access,
                                                          o_val     => l_acess_permission,
                                                          o_error   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_acess_permission = pk_alert_constant.g_no
        THEN
            g_error := 'CONSULTANT PROFESSIONAL';
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_my_cursor(o_episode_resp_options);
            pk_types.open_my_cursor(o_overall_resp_box);
            pk_types.open_my_cursor(o_labels_grid);
            RETURN TRUE;
        END IF;
    
        g_error    := 'GET PROFESSIONAL CATEGORY/PROFILE';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF i_prof.software = pk_alert_constant.g_soft_triage
        THEN
            g_error := 'CHECK EDIS/UBU profile';
            -- If taking over responsability in TRIAGE, get the profile assigned to the professional in EDIS OR UBU.
            l_id_profile_template := nvl(pk_prof_utils.get_prof_profile_template(i_prof => profissional(i_prof.id,
                                                                                                        i_prof.institution,
                                                                                                        pk_alert_constant.g_soft_edis)),
                                         pk_prof_utils.get_prof_profile_template(i_prof => profissional(i_prof.id,
                                                                                                        i_prof.institution,
                                                                                                        pk_alert_constant.g_soft_ubu)));
        
            -- If the professional doesn't have any EDIS/UBU profile this pop-up never shows
            IF l_id_profile_template IS NULL
            THEN
                pk_types.open_my_cursor(o_responsibles);
                pk_types.open_my_cursor(o_episode_resp_options);
                pk_types.open_my_cursor(o_overall_resp_box);
                pk_types.open_my_cursor(o_labels_grid);
                RETURN TRUE;
            END IF;
        ELSE
            l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        END IF;
    
        g_error := 'GET EPISODE STATUS AND EPIS_TYPE';
        BEGIN
            SELECT epis.flg_status, epis.id_epis_type, ei.id_schedule, flg_ehr
              INTO l_flg_status, l_epis_type, l_id_schedule, l_flg_ehr
              FROM episode epis
              JOIN epis_info ei
                ON epis.id_episode = ei.id_episode
             WHERE epis.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := NULL;
        END;
    
        IF l_flg_status IS NULL
           OR l_flg_status <> pk_hand_off.g_epis_active
           OR (l_prof_cat = pk_hand_off.g_flg_type_n AND
           i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_private_practice))
           OR
           (l_prof_cat NOT IN (pk_alert_constant.g_cat_type_doc,
                               pk_alert_constant.g_cat_type_nurse,
                               pk_alert_constant.g_cat_type_case_manager,
                               pk_alert_constant.g_cat_type_social,
                               pk_alert_constant.g_cat_type_nutritionist,
                               pk_alert_constant.g_cat_type_coordinator,
                               pk_alert_constant.g_cat_type_physiotherapist,
                               pk_alert_constant.g_cat_type_psychologist,
                               pk_alert_constant.g_cat_type_technician) OR
           (l_prof_cat = pk_alert_constant.g_cat_type_technician AND l_id_profile_template <> g_id_profile_resp_therap))
           OR (l_epis_type != l_cfg_epis_type AND (l_epis_type <> pk_alert_constant.g_epis_type_rehab_appointment AND
           i_prof.software <> pk_alert_constant.g_soft_rehab) AND
           l_epis_type <> pk_alert_constant.g_epis_type_home_health_care)
           OR (l_epis_type = pk_alert_constant.g_epis_type_home_health_care AND
           l_id_profile_template NOT IN (pk_hhc_constant.k_prof_templ_die,
                                             pk_hhc_constant.k_prof_templ_nurse,
                                             pk_hhc_constant.k_prof_templ_ot,
                                             pk_hhc_constant.k_prof_templ_psy,
                                             pk_hhc_constant.k_prof_templ_pt,
                                             pk_hhc_constant.k_prof_templ_phy,
                                             pk_hhc_constant.k_prof_templ_rt,
                                             pk_hhc_constant.k_prof_templ_sw_h,
                                             pk_hhc_constant.k_prof_templ_st,
                                             pk_hhc_constant.k_prof_templ_pt_c))
        THEN
            -- If episode isn't active, don't show any window.
            -- Hand-off not available for NURSES of OUTP / PP / CARE
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_my_cursor(o_episode_resp_options);
            pk_types.open_my_cursor(o_overall_resp_box);
            pk_types.open_my_cursor(o_labels_grid);
            RETURN TRUE;
        END IF;
    
        IF l_flg_ehr = pk_alert_constant.g_epis_ehr_schedule
           AND l_epis_type <> pk_alert_constant.g_epis_type_home_health_care
        THEN
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_my_cursor(o_episode_resp_options);
            pk_types.open_my_cursor(o_overall_resp_box);
            pk_types.open_my_cursor(o_labels_grid);
            RETURN TRUE;
        END IF;
        -- Get all episode responsibles of the current category
        g_error        := 'GET LIST OF RESPONSIBLES ID';
        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => i_id_episode,
                                                               i_prof_cat      => l_prof_cat,
                                                               i_hand_off_type => l_hand_off_type,
                                                               i_my_patients   => pk_alert_constant.g_yes,
                                                               i_flg_resp_type => g_resp_episode);
    
        IF pk_utils.search_table_number(i_table => l_responsibles, i_search => i_prof.id) > -1
        THEN
            l_is_epis_responsible := pk_alert_constant.g_yes;
        END IF;
    
        -- Get the overall responsible
        g_error        := 'GET LIST OF RESPONSIBLES ID';
        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => i_id_episode,
                                                               i_prof_cat      => l_prof_cat,
                                                               i_hand_off_type => l_hand_off_type,
                                                               i_my_patients   => pk_alert_constant.g_yes,
                                                               i_flg_resp_type => g_resp_overall);
    
        IF pk_utils.search_table_number(i_table => l_responsibles, i_search => i_prof.id) > -1
        THEN
            l_is_overall_responsible := pk_alert_constant.g_yes;
        END IF;
    
        IF l_is_overall_responsible = pk_alert_constant.g_yes
           AND l_is_epis_responsible = pk_alert_constant.g_yes
        THEN
            -- If current professional is already episode and overall responsible, don't show any window.
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_my_cursor(o_episode_resp_options);
            pk_types.open_my_cursor(o_overall_resp_box);
            pk_types.open_my_cursor(o_labels_grid);
            RETURN TRUE;
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_oris
        THEN
            -- ORIS doesn't have support for EPISODE responsability
            l_take_resp_episode := pk_alert_constant.g_no;
        
        ELSIF l_is_overall_responsible = pk_alert_constant.g_no
              AND l_is_epis_responsible = pk_alert_constant.g_no
              AND i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                                      pk_alert_constant.g_soft_social,
                                      pk_alert_constant.g_soft_nutritionist,
                                      pk_alert_constant.g_soft_primary_care)
        THEN
        
            --------------------------------------------------------------------------------------
            -- [OUTPATIENT] IMPORTANT!! 
            -- The variable 'l_is_responsible' only is returned as 'Y' if the professional has
            -- OVERALL responsability. So, if 'N' is returned, we have to consult EPIS_INFO
            -- to check if professional has EPISODE responsability. This kind of responsability
            -- is not registered in the hand-off tables (EPIS_PROF_RESP/EPIS_MULTI_PROF_RESP) in 
            -- OUTPATIENT, only in EPIS_INFO.
            --------------------------------------------------------------------------------------
        
            -- This will avoid the hand-off popup to be displayed if the current professional
            -- already is registered in EPIS_INFO.
        
            g_error := 'CHECK AMBULATORY RESPONSIBLE (1)';
            IF NOT get_epis_info_resp(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_episode      => i_id_episode,
                                      i_prof_cat        => l_prof_cat,
                                      o_id_professional => l_current_amb_responsible_id,
                                      o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF nvl(l_current_amb_responsible_id, -1) = i_prof.id
            THEN
                l_take_resp_episode := pk_alert_constant.g_no;
            ELSE
                l_take_resp_episode := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            -- Check if interns are allowed to take over responsability of EPISODES
            g_error := 'GET PROFILE TYPE';
            SELECT p.flg_type
              INTO l_prof_profile_type
              FROM profile_template p
             WHERE p.id_profile_template = l_id_profile_template;
        
            IF l_prof_profile_type = pk_hand_off_core.g_profile_type_intern
            THEN
                -- Check if interns can take over responsability over EPISODE.
                l_take_resp_episode := nvl(pk_sysconfig.get_config('INTERN_TAKE_OVER_RESPONSABILITY', i_prof),
                                           pk_alert_constant.g_yes);
            
            ELSE
                -- If it's other profile/software, then it can always take over responsability over episode.
                l_take_resp_episode := pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        --------------------------------------------------------------------
        -- 1) Check which message boxes to show
        --------------------------------------------------------------------
    
        g_error := 'GET KIND OF PROFILE';
        IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_profile_template => l_id_profile_template,
                                                o_flg_profile      => l_flg_profile,
                                                o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Check configurations to see if profile is blocked from taking responsability
        l_config := pk_sysconfig.get_config('PROFILE_TEMPLATE_HANDOFF_PERMISSION', i_prof.institution, i_prof.software);
    
        -- If the current profile is a student or configured to not have permissions, no popup should be shown
        IF l_flg_profile = g_student
           OR instr(l_config, '|' || l_id_profile_template || '|') > 0
        THEN
            l_show_msg_box := l_show_box_none;
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            -- "Normal" hand-off only has support for EPISODE responsability.
            l_show_msg_box := CASE l_take_resp_episode
                                  WHEN pk_alert_constant.g_yes THEN
                                   l_show_box_epis
                                  ELSE
                                   l_show_box_none
                              END;
        
            l_flg_profile   := NULL;
            l_id_speciality := NULL;
        
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
        
            g_error         := 'GET PROF SPECIALITY';
            l_id_speciality := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'CHECK RESPONSIBLES WITH THE SAME SPECIALTY';
            SELECT COUNT(1)
              INTO l_same_specialty_responsible
              FROM professional p
             WHERE p.id_professional IN (SELECT *
                                           FROM TABLE(l_responsibles))
               AND p.id_speciality = l_id_speciality;
        
            -- check if professional can assume mrp responsability
            l_flg_mrp := pk_prof_utils.get_flg_mrp(i_lang, i_prof, l_id_profile_template);
        
            l_allowed_profiles_tab := table_number();
        
            -- Check if current profile has permission to request OVERALL responsability.
            -- There's no need to check for EPISODE responsability here, because all profiles have that permission at this point.
            g_error := 'GET ALLOWED PROFILES';
            IF NOT pk_hand_off_core.get_allowed_profiles(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_id_profile_templ_req => l_id_profile_template,
                                                         i_flg_type             => pk_hand_off.g_flg_type_d,
                                                         i_flg_resp_type        => pk_hand_off_core.g_resp_overall,
                                                         o_profiles             => l_allowed_profiles_tab,
                                                         o_error                => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_same_specialty_responsible > 0
               AND l_flg_mrp = pk_alert_constant.g_no
            THEN
            
                SELECT COUNT(1)
                  INTO l_same_specialty_mrp
                  FROM epis_multi_prof_resp empr
                 WHERE empr.id_episode = i_id_episode
                   AND empr.flg_main_responsible = pk_alert_constant.g_yes
                   AND empr.flg_status = g_active
                   AND empr.id_speciality = l_id_speciality;
            
            END IF;
            IF l_take_resp_episode = pk_alert_constant.g_yes
            THEN
                IF i_prof.software = pk_alert_constant.g_soft_triage
                THEN
                    l_show_msg_box := l_show_box_epis;
                ELSE
                    -- Can take over responsability over EPISODE. Check if can request OVERALL responsability as well.
                    IF l_allowed_profiles_tab.exists(1)
                       AND pk_utils.search_table_number(i_table  => l_allowed_profiles_tab,
                                                        i_search => l_id_profile_template) > -1
                    THEN
                        SELECT decode(l_is_overall_responsible,
                                      pk_alert_constant.g_no,
                                      decode(l_is_epis_responsible,
                                             pk_alert_constant.g_no,
                                             l_show_box_all,
                                             l_show_box_overall),
                                      decode(l_is_epis_responsible,
                                             pk_alert_constant.g_no,
                                             l_show_box_epis,
                                             l_show_box_none))
                          INTO l_show_msg_box
                          FROM dual;
                    ELSE
                        SELECT decode(l_is_epis_responsible, pk_alert_constant.g_yes, l_show_box_none, l_show_box_epis)
                          INTO l_show_msg_box
                          FROM dual;
                    END IF;
                END IF;
            ELSE
                IF i_prof.software = pk_alert_constant.g_soft_triage
                THEN
                    l_show_msg_box := l_show_box_none;
                ELSE
                    -- Can NOT take over responsability over EPISODE. Check if can request OVERALL responsability.
                    IF l_allowed_profiles_tab.exists(1)
                       AND pk_utils.search_table_number(i_table  => l_allowed_profiles_tab,
                                                        i_search => l_id_profile_template) > -1
                    THEN
                        SELECT decode(l_is_overall_responsible,
                                      pk_alert_constant.g_no,
                                      l_show_box_overall,
                                      l_show_box_none)
                          INTO l_show_msg_box
                          FROM dual;
                    ELSE
                        l_show_msg_box := l_show_box_none;
                    END IF;
                END IF;
            END IF;
        
            g_error := 'REMOVE OVERALL RESPONSIBILITY ';
            -- if there are already responsibles with the same specialty, removes overall responsability from the possibilities
            IF l_same_specialty_responsible > 0
               AND (pk_sysconfig.get_config('REMOVE_OVERALL_RESPONSIBILITY', i_prof.institution, i_prof.software) =
               pk_alert_constant.g_yes OR l_same_specialty_mrp > 0)
            THEN
                SELECT decode(l_show_msg_box,
                              l_show_box_all,
                              l_show_box_epis,
                              l_show_box_overall,
                              l_show_box_none,
                              l_show_msg_box)
                  INTO l_show_msg_box
                  FROM dual;
            END IF;
        ELSE
            l_error_message := 'INVALID HAND-OFF TYPE';
            RAISE l_data_error;
        END IF;
    
        IF l_show_msg_box = l_show_box_none
        THEN
            -- If there are no message boxes to show, just return and exit
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_my_cursor(o_episode_resp_options);
            pk_types.open_my_cursor(o_overall_resp_box);
            pk_types.open_my_cursor(o_labels_grid);
            RETURN TRUE;
        ELSE
            -- Set box(es) to show
            o_show_msg_box := l_show_msg_box;
            -- Check which message boxes should be handled by this function
            l_handle_overall_msg_box := l_show_msg_box = l_show_box_overall OR l_show_msg_box = l_show_box_all;
        END IF;
    
        --------------------------------------------------------------------
        -- Get grid labels
        --------------------------------------------------------------------
    
        IF l_show_msg_box <> l_show_box_none
        THEN
            g_error       := 'GET LABELS';
            l_labels_grid := table_varchar();
            l_labels_grid.extend;
        
            l_labels_grid.extend;
            l_labels_grid(1) := 'EDIS_HAND_OFF_M086'; -- There is no consultant following this patient.
        
            l_labels_grid.extend;
            l_labels_grid(2) := 'EDIS_HAND_OFF_M087'; -- Do you wish to follow this patient?
        
            l_labels_grid.extend;
            l_labels_grid(3) := 'EDIS_HAND_OFF_M089'; -- A consultant is already following this patient.
        
            l_labels_grid.extend;
            l_labels_grid(4) := 'EDIS_HAND_OFF_M090'; -- Current patient's consultants:
        
            l_labels_grid.extend;
            l_labels_grid(5) := 'EDIS_HAND_OFF_M091'; -- @1, (@2) is assigned to this episode.
        
            l_labels_grid.extend;
            l_labels_grid(6) := 'EDIS_HAND_OFF_M092'; -- A professional is already assigned to this episode.
        
            l_labels_grid.extend;
            l_labels_grid(7) := 'EDIS_HAND_OFF_M093'; -- Do you wish to take over the responsability for this episode?
        
            l_labels_grid.extend;
            l_labels_grid(8) := 'EDIS_HAND_OFF_M094'; -- Current episode responsibles:
        
            l_labels_grid.extend;
            l_labels_grid(9) := 'EDIS_HAND_OFF_M095'; -- There is no professional assigned to this episode.
        
            g_error := 'OPEN O_LABELS_GRID';
            OPEN o_labels_grid FOR
                SELECT 'GRID_LABEL_' || idx code_message, pk_message.get_message(i_lang, i_prof, code_m) desc_message
                  FROM (SELECT column_value code_m, rownum idx
                          FROM TABLE(l_labels_grid) a) code_msg;
        ELSE
            pk_types.open_my_cursor(o_labels_grid);
        END IF;
    
        --------------------------------------------------------------------
        -- 2) Handle message boxes
        --------------------------------------------------------------------
    
        --------------------------------------------------------------------
        -- 2.1) EPISODE responsability message box
    
        IF i_prof.software = pk_alert_constant.g_soft_outpatient
           OR
           (i_prof.software IN (pk_alert_constant.g_soft_social,
                                pk_alert_constant.g_soft_nutritionist,
                                pk_alert_constant.g_soft_primary_care,
                                pk_alert_constant.g_soft_resptherap,
                                pk_alert_constant.g_soft_psychologist,
                                pk_alert_constant.g_soft_home_care,
                                pk_alert_constant.g_soft_rehab) AND l_hand_off_type = pk_hand_off.g_handoff_normal)
        THEN
        
            g_error := 'CHECK AMBULATORY RESPONSIBLE (2)';
            IF NOT get_epis_info_resp(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_episode      => i_id_episode,
                                      i_prof_cat        => l_prof_cat,
                                      i_epis_type       => l_epis_type,
                                      o_id_professional => l_current_amb_responsible_id,
                                      o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_current_amb_responsible_id IS NULL
               AND l_epis_type = pk_alert_constant.g_epis_type_home_health_care
            THEN
            
                l_current_amb_responsible_id := pk_hhc_core.get_prof_list(i_lang     => i_lang,
                                                                          i_prof     => i_prof,
                                                                          i_schedule => l_id_schedule,
                                                                          i_prof_cat => l_prof_cat);
            
            END IF;
        
            IF l_current_amb_responsible_id IS NOT NULL
            THEN
                -- There is a responsible for the patient
                l_has_responsible := pk_alert_constant.g_yes;
            
                BEGIN
                    g_error := 'GET AMBULATORY DEP_CLIN_SERV';
                    SELECT dcs.id_clinical_service, dcs.id_department
                      INTO l_id_clinical_serv_amb, l_id_department_amb
                      FROM prof_dep_clin_serv pdcs
                      JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                      JOIN department d
                        ON d.id_department = dcs.id_department
                     WHERE pdcs.id_professional = l_current_amb_responsible_id
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.flg_default = pk_alert_constant.g_yes
                       AND d.id_software = i_prof.software;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_clinical_serv_amb := NULL;
                        l_id_department_amb    := NULL;
                END;
            
                g_error := 'GET AMBULATORY RESPONSIBLE DETAIL';
                OPEN o_responsibles FOR
                    SELECT NULL id_epis_prof_resp,
                           g_empty_str flg_resp_type,
                           g_empty_str desc_resp_type,
                           pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                                 i_prof,
                                                                 -- Use the default clinical service/department, since there are no responsability records in EPIS_PROF_RESP
                                                                 l_id_clinical_serv_amb,
                                                                 l_id_department_amb,
                                                                 p.id_speciality) desc_spec,
                           p.id_professional id_prof_comp,
                           p.id_professional id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                           g_empty_str flg_profile,
                           pk_prof_utils.get_desc_category(i_lang, i_prof, p.id_professional, pc.id_institution) desc_profile,
                           decode(l_prof_cat, pk_alert_constant.g_cat_type_doc, 0, 1) rank_for_sorting,
                           NULL date_begin,
                           NULL hour_begin,
                           NULL date_end,
                           NULL hour_end,
                           NULL start_evt,
                           NULL end_evt,
                           '' flg_type,
                           -- Set permissions for each request:
                           -- Cancel button
                           pk_alert_constant.g_no flg_cancel,
                           -- OK button
                           pk_alert_constant.g_no flg_ok,
                           -- Action TRANSFER RESPONSABILITY
                           pk_alert_constant.g_no flg_action_transfer,
                           -- Action TERMINATE RESPONSABILITY
                           pk_alert_constant.g_no flg_action_terminate,
                           -- Action SET MAIN RESPONSIBLE: Not available for this type of hand-off
                           pk_alert_constant.g_no flg_action_set_main,
                           decode(p.id_speciality,
                                  pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof),
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_same_category
                      FROM professional p
                      JOIN prof_cat pc
                        ON pc.id_professional = p.id_professional
                     WHERE pc.id_institution = i_prof.institution
                       AND p.id_professional = l_current_amb_responsible_id;
            
            ELSE
                -- There is no responsible for the patient
                l_has_responsible := pk_alert_constant.g_no;
                pk_types.open_my_cursor(o_responsibles);
            END IF;
        
        ELSE
            -- Get list of all current responsibles (OVERALL and EPISODE)
            g_error := 'CALL TO GET_CURRENT_RESP_GRID';
            IF NOT pk_hand_off_core.get_current_resp_grid(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_episode         => i_id_episode,
                                                          o_grid            => o_responsibles,
                                                          o_has_responsible => l_has_responsible,
                                                          o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF l_prof_cat = pk_hand_off.g_flg_type_q
        THEN
            -- Case manager labels. Uses the same labels whether there's a responsible or not.
            l_code_desc_title        := 'VISIT_M027';
            l_code_desc_message_body := 'VISIT_M028';
        
        ELSIF l_has_responsible = pk_alert_constant.g_yes
        THEN
            -- There is at least one responsible. Check the responsible for the current user's category or speciality (when applicable).
            g_error := 'CALL GET_PROF_RESP_BY_TYPE (1)';
            IF NOT get_prof_resp_by_type(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_episode    => i_id_episode,
                                         i_prof_cat      => l_prof_cat,
                                         i_flg_profile   => l_flg_profile,
                                         i_hand_off_type => l_hand_off_type,
                                         -- Check the EPISODE responsible for the current speciality
                                         i_flg_resp_type => g_resp_episode,
                                         i_id_speciality => l_id_speciality,
                                         o_epis_status   => l_flg_status,
                                         o_id_prof_resp  => l_current_responsible_id,
                                         o_prof_name     => l_current_responsible_name,
                                         o_error         => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_current_responsible_id IS NOT NULL
            THEN
                -- There is a responsible for the current speciality.
                l_code_desc_title        := 'EDIS_HAND_OFF_T045';
                l_code_desc_message_body := REPLACE(pk_message.get_message(i_lang, i_prof, 'VISIT_M004'),
                                                    '@1',
                                                    l_current_responsible_name);
            
            ELSE
                -- There is no responsible for the current speciality.
                l_code_desc_title        := 'EDIS_HAND_OFF_T045';
                l_code_desc_message_body := 'EDIS_HAND_OFF_M027';
            END IF;
        
        ELSE
            -- There are no responsibles, regardless of the category.
            l_code_desc_title        := 'EDIS_HAND_OFF_T044';
            l_code_desc_message_body := 'EDIS_HAND_OFF_M023';
        END IF;
    
        -- Return the EPISODE responsability options
        g_error := 'OPEN O_EPISODE_RESP_OPTIONS';
        OPEN o_episode_resp_options FOR
            SELECT pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M032') desc_option,
                   nvl(l_epis_resp_default, pk_alert_constant.g_yes) flg_default,
                   NULL shortcut_num,
                   pk_hand_off_core.g_action_create flg_action
              FROM dual;
        --------------------------------------------------------------------
        -- 2.2) OVERALL responsability message box
    
        IF l_handle_overall_msg_box
        THEN
        
            l_code_desc_title        := 'EDIS_HAND_OFF_T046';
            l_code_desc_message_body := 'EDIS_HAND_OFF_M028';
        
            -- Return the labels of the message box
            g_error := 'OPEN O_OVERALL_RESP_BOX';
            OPEN o_overall_resp_box FOR
                SELECT pk_message.get_message(i_lang, l_code_desc_title) desc_title,
                       pk_message.get_message(i_lang, l_code_desc_message_body) desc_message_body,
                       nvl2(l_flg_profile, pk_message.get_message(i_lang, pt.code_profile_template), NULL) desc_cur_profile,
                       l_flg_profile flg_profile,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_cur_speciality,
                       p.id_speciality id_speciality
                  FROM professional p
                  JOIN prof_profile_template ppt
                    ON ppt.id_professional = p.id_professional
                  JOIN profile_template pt
                    ON pt.id_profile_template = ppt.id_profile_template
                 WHERE p.id_professional = i_prof.id
                   AND ppt.id_software = i_prof.software
                   AND ppt.id_institution = i_prof.institution
                   AND pt.id_software = i_prof.software;
        ELSE
            g_error := 'OPEN CURSORS (2)';
            pk_types.open_my_cursor(o_overall_resp_box);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_data_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'DATA ERROR',
                                              l_error_message,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_cursor_if_closed(o_labels_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_cursor_if_closed(o_labels_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_responsibles);
            pk_types.open_cursor_if_closed(o_labels_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_prof_resp;

    /********************************************************************************************
    * Get the type of profile template.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_profile_template     profile template ID
    * @param   o_flg_profile          type of profile
    * @param   o_error                error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          02-10-2009
    **********************************************************************************************/
    FUNCTION get_flg_profile
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        o_flg_profile      OUT profile_template.flg_profile%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_FLG_PROFILE';
        l_profile_error EXCEPTION;
        l_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
    
        IF i_prof.software = pk_alert_constant.g_soft_triage
        THEN
            -- If taking over responsability in TRIAGE, get the profile assigned to the professional in EDIS.
            l_profile_template := nvl(pk_prof_utils.get_prof_profile_template(i_prof => profissional(i_prof.id,
                                                                                                     i_prof.institution,
                                                                                                     pk_alert_constant.g_soft_edis)),
                                      pk_prof_utils.get_prof_profile_template(i_prof => profissional(i_prof.id,
                                                                                                     i_prof.institution,
                                                                                                     pk_alert_constant.g_soft_ubu)));
        ELSE
            IF i_profile_template IS NULL
            THEN
                g_error            := 'GET PROFESSIONAL PROFILE';
                l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
            ELSE
                l_profile_template := i_profile_template;
            END IF;
        
        END IF;
    
        IF l_profile_template IS NOT NULL
        THEN
            g_error := 'GET TYPE OF PROFILE';
            SELECT pt.flg_profile
              INTO o_flg_profile
              FROM profile_template pt
             WHERE pt.id_profile_template = l_profile_template;
            --        ELSE
            --            g_error := 'INVALID PROFILE';
            --            RAISE l_profile_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_profile_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PROFILE_ERROR',
                                              'UNDEFINED PROFILE TEMPLATE',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_flg_profile;
    --
    /********************************************************************************************
    * Get the type of profile template.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_profile_template     profile template ID
    *                        
    * @return  type of profile
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          02-10-2009
    **********************************************************************************************/
    FUNCTION get_flg_profile
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_FLG_PROFILE';
        l_error     t_error_out;
        l_internal_error EXCEPTION;
        l_flg_profile profile_template.flg_profile%TYPE;
    BEGIN
    
        g_error := 'CALL TO GET_FLG_PROFILE';
        IF NOT get_flg_profile(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_profile_template => i_profile_template,
                               o_flg_profile      => l_flg_profile,
                               o_error            => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN l_flg_profile;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_flg_profile;

    /********************************************************************************************
    * Returns the ID's of the profiles for which the current professional 
    * can make a hand-off request. Can be used for both normal and multiple hand-off mechanisms.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_profile_templ_req     Profile template ID of the current professional
    * @param   i_flg_type                 type of category (D) Physician (N) Nurse
    * @param   i_flg_resp_type            (E - default) Episode or (O) Overall responsability
    * @param   o_profiles                 Profile template ID's
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          09-10-2009
    **********************************************************************************************/
    FUNCTION get_allowed_profiles
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_profile_templ_req IN profile_template.id_profile_template%TYPE,
        i_flg_type             IN category.flg_type%TYPE,
        i_flg_resp_type        IN handoff_permission_inst.flg_resp_type%TYPE DEFAULT 'E',
        o_profiles             OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ALLOWED_PROFILES';
        l_invalid_param EXCEPTION;
        l_prof_cat            category.flg_type%TYPE;
        l_handoff_type        sys_config.value%TYPE;
        l_handoff_no_perm     sys_config.value%TYPE;
        l_tab_handoff_no_perm table_number;
    
    BEGIN
        -- Check configurations to see which profiles are blocked from taking responsability
        l_handoff_no_perm     := TRIM('|' FROM pk_sysconfig.get_config('PROFILE_TEMPLATE_HANDOFF_PERMISSION',
                                                              i_prof.institution,
                                                              i_prof.software));
        l_tab_handoff_no_perm := pk_utils.str_split_n(i_list => l_handoff_no_perm, i_delim => '|');
    
        g_error := 'GET CONFIGURATIONS (HAND-OFF TYPE)';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type);
    
        g_error    := 'GET CATEGORY';
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        IF l_handoff_type = pk_hand_off.g_handoff_multiple
           OR l_prof_cat <> i_flg_type -- Requests for different categories from the current professional.
        THEN
            -- If professional is of a different category,
            -- check for which profiles it has permission to request hand-off transfers.
            g_error := 'GET PROFILE TEMPLATES (1)';
            SELECT hop.id_profile_template_dest
              BULK COLLECT
              INTO o_profiles
              FROM handoff_permission_inst hop
             WHERE hop.id_profile_template_req = i_id_profile_templ_req
                  -- The destination profiles must be of the same type of the hand-off
               AND hop.id_profile_template_dest IN (SELECT pt.id_profile_template
                                                      FROM profile_template pt, category c
                                                     WHERE pt.id_category = c.id_category
                                                       AND c.flg_type = i_flg_type)
               AND ((hop.id_institution = 0 AND NOT EXISTS
                    (SELECT 0
                        FROM handoff_permission_inst hop1
                       WHERE hop1.id_institution = i_prof.institution
                         AND hop1.id_profile_template_req = hop.id_profile_template_req
                         AND hop1.flg_available = 'Y'
                         AND hop1.flg_resp_type = i_flg_resp_type)) OR hop.id_institution = i_prof.institution)
               AND hop.flg_available = 'Y'
               AND hop.flg_resp_type = i_flg_resp_type
            -- Add the profiles with the same FLG_PROFILE,
            -- if it's a multiple hand-off request AND request to the same category AND is an EPISODE responsability request.
            UNION ALL
            SELECT pt.id_profile_template
              FROM profile_template pt
              JOIN profile_template pt_current
                ON pt_current.flg_profile = pt.flg_profile
             WHERE pt_current.id_profile_template = i_id_profile_templ_req
               AND pt.id_software = i_prof.software
               AND pt.flg_available = pk_alert_constant.g_yes
               AND pt.flg_profile IS NOT NULL
               AND pt.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_profile_template <> i_id_profile_templ_req
                       AND ppt.id_profile_template NOT IN
                           (SELECT /*+ OPT_ESTIMATE(TABLE xsql ROWS=1) */
                             column_value
                              FROM TABLE(l_tab_handoff_no_perm) xsql))
               AND l_handoff_type = pk_hand_off.g_handoff_multiple
               AND i_flg_resp_type = pk_hand_off_core.g_resp_episode
               AND l_prof_cat = i_flg_type
            -- Only return the profile of the current professional, if it's a request of the same category.
            UNION ALL
            SELECT i_id_profile_templ_req
              FROM dual
             WHERE l_prof_cat = i_flg_type
               AND (i_flg_resp_type = pk_hand_off_core.g_resp_episode OR
                   -- In OVERALL responsability requests, only return the current profile, if it's a specialist physician.
                    (i_flg_resp_type = pk_hand_off_core.g_resp_overall AND
                    i_id_profile_templ_req IN (SELECT pt1.id_profile_template
                                                   FROM profile_template pt1
                                                  WHERE pt1.flg_profile = pk_hand_off_core.g_specialist
                                                    AND pt1.flg_available = pk_alert_constant.g_yes
                                                    AND pt1.id_software = i_prof.software)))
            UNION ALL
            SELECT pt.id_profile_template
              FROM profile_template pt
             WHERE pt.id_software = i_prof.software
               AND pt.flg_available = pk_alert_constant.g_yes
               AND pt.flg_profile IS NOT NULL
               AND pt.flg_type = i_flg_type
               AND pt.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_profile_template <> i_id_profile_templ_req
                       AND ppt.id_profile_template NOT IN
                           (SELECT /*+ OPT_ESTIMATE(TABLE xsql ROWS=1) */
                             column_value
                              FROM TABLE(l_tab_handoff_no_perm) xsql))
               AND l_handoff_type = pk_hand_off.g_handoff_multiple
               AND i_flg_resp_type = pk_hand_off_core.g_resp_episode
               AND l_prof_cat = i_flg_type
               AND i_id_profile_templ_req IN (SELECT /*+ OPT_ESTIMATE(TABLE xsql ROWS=1) */
                                               column_value
                                                FROM TABLE(l_tab_handoff_no_perm) xsql);
        
        ELSIF l_prof_cat = i_flg_type
              AND l_handoff_type = pk_hand_off.g_handoff_normal
        THEN
            -- Allow to request hand-off to profiles of the same category as me.
            g_error := 'GET PROFILE TEMPLATES (2)';
            SELECT pt.id_profile_template
              BULK COLLECT
              INTO o_profiles
              FROM profile_template pt
              JOIN category c
                ON c.id_category = pt.id_category
             WHERE pt.id_software = i_prof.software
               AND pt.flg_available = 'Y'
               AND c.flg_type = i_flg_type
               AND EXISTS (SELECT 1
                      FROM prof_profile_template ppt
                     WHERE ppt.id_profile_template = pt.id_profile_template
                       AND ppt.id_software = pt.id_software
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_profile_template NOT IN
                           (SELECT /*+ OPT_ESTIMATE(TABLE xsql ROWS=1) */
                             column_value
                              FROM TABLE(l_tab_handoff_no_perm) xsql));
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_param THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_allowed_profiles;

    /********************************************************************************************
    * Returns the type of profiles (specialists, residents, interns, nurses...)
    * for which the current professional can make a hand-off request.
    *
    * IMPORTANT!! Currently this function only is supported by the MULTIPLE
    *             hand-off mechanism.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_profile_templ_req     Profile template ID of the current professional
    * @param   i_flg_type                 type of category (D) Physician (N) Nurse
    * @param   i_flg_resp_type            (E - default) Episode or (O) Overall responsability
    * @param   o_flg_profiles             Profile types
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          09-10-2009
    **********************************************************************************************/
    FUNCTION get_allowed_profile_types
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_profile_templ_req IN profile_template.id_profile_template%TYPE,
        i_flg_type             IN category.flg_type%TYPE,
        i_flg_resp_type        IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        o_flg_profiles         OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(200) := 'GET_ALLOWED_PROFILE_TYPES';
        l_id_profile_templ table_number;
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO GET_ALLOWED_PROFILES';
        IF NOT get_allowed_profiles(i_lang                 => i_lang,
                                    i_prof                 => i_prof,
                                    i_id_profile_templ_req => i_id_profile_templ_req,
                                    i_flg_type             => i_flg_type,
                                    i_flg_resp_type        => i_flg_resp_type,
                                    o_profiles             => l_id_profile_templ,
                                    o_error                => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_id_profile_templ.exists(1)
        THEN
            -- Get profile types, only if array has values
            g_error := 'GET PROFILE TYPES';
            SELECT pt.flg_profile
              BULK COLLECT
              INTO o_flg_profiles
              FROM profile_template pt
             WHERE pt.id_profile_template IN (SELECT column_value
                                                FROM TABLE(l_id_profile_templ));
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_allowed_profile_types;

    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    * @param   i_only_main_overall        In multiple hand-off, for specialists, set as 'Y' (default) to check for MAIN OVERALL.
                                           Set as 'N', to check for all overall responsibles (Main included).
    * @param   o_epis_status              Episode status (active, inactive, cancelled, etc.)
    * @param   o_id_prof_resp             ID of the responsible professional (physician OR nurse)
    * @param   o_prof_name                Name of the responsible professional
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof_cat          IN category.flg_type%TYPE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_flg_resp_type     IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_only_main_overall IN VARCHAR2 DEFAULT 'Y',
        o_epis_status       OUT episode.flg_status%TYPE,
        o_id_prof_resp      OUT table_number,
        o_prof_name         OUT table_varchar,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_PROF_RESP_BY_TYPE';
        --
        l_hand_off_type        sys_config.value%TYPE := i_hand_off_type;
        l_epis_flg_status      episode.flg_status%TYPE;
        l_id_current_prof_resp table_number;
        l_prof_name            table_varchar;
        --l_flg_transf_type      epis_prof_resp.flg_transf_type%TYPE;
        --l_id_epis_prof_resp    epis_prof_resp.id_epis_prof_resp%TYPE;
        l_flg_profile profile_template.flg_profile%TYPE := i_flg_profile;
        --
        l_check_main_overall BOOLEAN := FALSE;
        l_check_nurse_resp   BOOLEAN := FALSE;
        --
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'VALIDATE PARAMETERS';
        get_hand_off_type(i_lang, i_prof, l_hand_off_type); -- Get the type of hand-off
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
           AND i_prof_cat IN (pk_hand_off.g_flg_type_d, pk_hand_off.g_flg_type_n)
        THEN
            IF l_flg_profile IS NULL
            THEN
                g_error := 'GET KIND OF PROFILE';
                IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_profile_template => NULL,
                                                        o_flg_profile      => l_flg_profile,
                                                        o_error            => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            IF l_flg_profile IS NULL
            THEN
                -- For the "multiple" hand-off, it is necessary to specify the
                -- type of profile (i_flg_profile)
                g_error := 'INVALID I_FLG_PROFILE (NULL VALUE FOUND)';
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                RAISE l_param_error;
            END IF;
        END IF;
    
        -- Verify if is a request for MAIN overall responsability
        l_check_main_overall := l_hand_off_type = pk_hand_off.g_handoff_multiple AND l_flg_profile = g_specialist AND
                                nvl(i_flg_resp_type, g_resp_overall) = g_resp_overall AND
                                i_only_main_overall = pk_alert_constant.g_yes;
    
        -- Verify if is a request for NURSE responsability (multiple hand-off)
        l_check_nurse_resp := l_hand_off_type = pk_hand_off.g_handoff_multiple AND l_flg_profile = g_nurse;
    
        -- Get the current responsible for the patient, 
        -- according to the type of hand-off, and/or the type of profile.
        SELECT e.flg_status
          INTO l_epis_flg_status
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_normal
           OR l_check_nurse_resp
        THEN
            -- Even if the hand-off type is multiple, we can get the responsible specialist or nurse through EPIS_INFO.
            g_error := 'GET EPISODE STATUS/RESPONSIBLE (OTHER)';
            SELECT t.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
              BULK COLLECT
              INTO l_id_current_prof_resp, l_prof_name
              FROM (SELECT decode(i_prof_cat,
                                  pk_hand_off.g_flg_type_d,
                                  ei.id_professional,
                                  pk_hand_off.g_flg_type_n,
                                  ei.id_first_nurse_resp,
                                  pk_hand_off.g_flg_type_q,
                                  ei.id_professional,
                                  pk_alert_constant.g_cat_type_nutritionist,
                                  ei.id_professional,
                                  pk_alert_constant.g_cat_type_social,
                                  ei.id_professional,
                                  NULL) id_professional
                      FROM episode e, epis_info ei
                     WHERE e.id_episode = ei.id_episode
                       AND e.id_episode = i_id_episode) t;
        
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_multiple
              AND l_check_main_overall
        THEN
            -- Check for MAIN OVERALL RESPONSIBLE
            g_error := 'GET EPISODE STATUS/RESPONSIBLE (2)';
            SELECT t.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
              BULK COLLECT
              INTO l_id_current_prof_resp, l_prof_name
              FROM (SELECT empr.id_professional
                      FROM episode e
                      JOIN epis_multi_prof_resp empr
                        ON empr.id_episode = e.id_episode
                     WHERE e.id_episode = i_id_episode
                       AND empr.flg_status = g_active
                       AND empr.flg_profile = l_flg_profile
                       AND empr.flg_resp_type = i_flg_resp_type
                       AND empr.flg_main_responsible = pk_alert_constant.g_yes
                     ORDER BY empr.dt_create DESC) t
             WHERE rownum = 1;
        
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the responsible for the specified type of profile
            g_error := 'GET EPISODE STATUS/RESPONSIBLE (2)';
            SELECT t.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
              BULK COLLECT
              INTO l_id_current_prof_resp, l_prof_name
              FROM (SELECT empr.id_professional
                      FROM epis_multi_prof_resp empr, episode e
                     WHERE e.id_episode = i_id_episode
                       AND empr.id_episode(+) = e.id_episode
                       AND empr.flg_status(+) = g_active
                       AND empr.flg_profile(+) = l_flg_profile
                       AND empr.id_speciality(+) = i_id_speciality
                       AND empr.flg_resp_type(+) = i_flg_resp_type
                     ORDER BY empr.dt_create DESC) t;
        ELSE
            g_error := 'INVALID HAND-OFF TYPE';
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            RAISE l_param_error;
        END IF;
    
        o_epis_status  := l_epis_flg_status;
        o_id_prof_resp := l_id_current_prof_resp;
        o_prof_name    := l_prof_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_resp_by_type;
    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    * @param   i_only_main_overall        In multiple hand-off, for specialists, set as 'Y' (default) to check for MAIN OVERALL.
                                           Set as 'N', to check for all overall responsibles (Main included).
    * @param   o_epis_status              Episode status (active, inactive, cancelled, etc.)
    * @param   o_id_prof_resp             ID of the responsible professional (physician OR nurse)
    * @param   o_prof_name                Name of the responsible professional
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof_cat          IN category.flg_type%TYPE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_flg_resp_type     IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_only_main_overall IN VARCHAR2 DEFAULT 'Y',
        o_epis_status       OUT episode.flg_status%TYPE,
        o_id_prof_resp      OUT professional.id_professional%TYPE,
        o_prof_name         OUT professional.name%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_PROF_RESP_BY_TYPE';
        l_internal_error EXCEPTION;
        l_id_prof_resp table_number;
        l_prof_name    table_varchar;
    BEGIN
        g_error := 'CALL TO GET_PROF_RESP_BY_TYPE';
        IF NOT get_prof_resp_by_type(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_id_episode    => i_id_episode,
                                     i_prof_cat      => i_prof_cat,
                                     i_flg_profile   => i_flg_profile,
                                     i_hand_off_type => i_hand_off_type,
                                     i_flg_resp_type => i_flg_resp_type,
                                     i_id_speciality => i_id_speciality,
                                     o_epis_status   => o_epis_status,
                                     o_id_prof_resp  => l_id_prof_resp,
                                     o_prof_name     => l_prof_name,
                                     o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_id_prof_resp IS NOT NULL
           AND l_id_prof_resp.exists(1)
        THEN
            o_id_prof_resp := l_id_prof_resp(1);
            o_prof_name    := l_prof_name(1);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_resp_by_type;

    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    * @param   o_epis_status              Episode status (active, inactive, cancelled, etc.)
    * @param   o_id_prof_resp             ID of the responsible professional (physician OR nurse)
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality IN epis_multi_prof_resp.id_speciality%TYPE,
        o_epis_status   OUT episode.flg_status%TYPE,
        o_id_prof_resp  OUT professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_PROF_RESP_BY_TYPE';
        l_dummy     professional.name%TYPE;
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO GET_PROF_RESP_BY_TYPE';
        IF NOT get_prof_resp_by_type(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_id_episode    => i_id_episode,
                                     i_prof_cat      => i_prof_cat,
                                     i_flg_profile   => i_flg_profile,
                                     i_hand_off_type => i_hand_off_type,
                                     i_flg_resp_type => i_flg_resp_type,
                                     i_id_speciality => i_id_speciality,
                                     o_epis_status   => o_epis_status,
                                     o_id_prof_resp  => o_id_prof_resp,
                                     o_prof_name     => l_dummy,
                                     o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_resp_by_type;

    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    * IMPORTANT: Database internal function.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    *                        
    * @return  Professional ID
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          03-11-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality IN epis_multi_prof_resp.id_speciality%TYPE
    ) RETURN NUMBER IS
        l_func_name    VARCHAR2(200) := 'GET_PROF_RESP_BY_TYPE';
        l_dummy        professional.name%TYPE;
        l_dummy_status episode.flg_status%TYPE;
        l_internal_error EXCEPTION;
        l_error t_error_out;
    
        l_professional professional.id_professional%TYPE;
    BEGIN
    
        g_error := 'CALL TO GET_PROF_RESP_BY_TYPE';
        IF NOT get_prof_resp_by_type(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_id_episode    => i_id_episode,
                                     i_prof_cat      => i_prof_cat,
                                     i_flg_profile   => i_flg_profile,
                                     i_hand_off_type => i_hand_off_type,
                                     i_flg_resp_type => i_flg_resp_type,
                                     i_id_speciality => i_id_speciality,
                                     o_epis_status   => l_dummy_status,
                                     o_id_prof_resp  => l_professional,
                                     o_prof_name     => l_dummy,
                                     o_error         => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN l_professional;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN - 1;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN - 1;
    END get_prof_resp_by_type;

    /********************************************************************************************
    * Checks the ID_EPISODE of a requested hand-off transfer.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Hand-off request ID
    * @param   i_hand_off_type            Hand-off mechanism (N)ormal (M)ultiple
    * @param   i_flg_profile              Type of profile (S)pecialist (R)esident (I)ntern (N)urse
    * @param   i_flg_transf_type          Type of transfer (E)pisode (O)verall
    * @param   o_epis_prof_resp           Hand-off request complete record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_existing_handoff_req_by_id
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_flg_transf_type   IN epis_prof_resp.flg_transf_type%TYPE,
        o_id_episode        OUT episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_EXISTING_HANDOFF_REQ_BY_ID';
        l_param_error EXCEPTION;
        l_hand_off_type sys_config.value%TYPE := i_hand_off_type;
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        get_hand_off_type(i_lang, i_prof, l_hand_off_type); -- Get the type of hand-off
    
        g_error := 'VALIDATE PARAMETERS';
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
           AND i_flg_profile IS NULL
        THEN
            g_error := 'TYPE OF PROFILE IS NULL';
            pk_alertlog.log_error(g_error);
            RAISE l_param_error;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            g_error := 'GET ID EPISODE (1)';
            BEGIN
                SELECT epr.id_episode
                  INTO o_id_episode
                  FROM epis_prof_resp epr
                 WHERE id_epis_prof_resp = i_id_epis_prof_resp
                   AND flg_status = pk_hand_off.g_hand_off_r
                   AND flg_transf_type IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_a);
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_episode := NULL;
            END;
        
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET ID EPISODE (2)';
            BEGIN
                SELECT epr.id_episode
                  INTO o_id_episode
                  FROM epis_prof_resp epr
                  JOIN epis_multi_prof_resp empr
                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                 WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
                   AND epr.id_episode = empr.id_episode
                   AND empr.flg_status = g_onhold
                   AND empr.flg_profile = i_flg_profile
                   AND epr.flg_status = pk_hand_off.g_hand_off_r
                   AND epr.flg_transf_type = i_flg_transf_type;
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_episode := NULL;
            END;
        
        ELSE
            o_id_episode := NULL;
        
            g_error := 'INVALID HAND-OFF CONFIGURATION';
            RAISE l_param_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_existing_handoff_req_by_id;

    /********************************************************************************************
    * Check if exists a requested hand-off transfer.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_req_status               Hand-off request status
    * @param   i_transf_type              Hand-off request transfer type (e.g. Individual)
    * @param   i_flg_type                 Hand-off request to physician (D) or nurse (N)
    * @param   i_flg_profile              Type of profile (S)pecialist (R)esident (I)ntern (N)urse
    * @param   i_hand_off_type            Hand-off mechanism (N)ormal (M)ultiple
    * @param   i_id_speciality            Responsability speciality
    * @param   o_epis_prof_resp           Hand-off request complete record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_existing_handoff_req
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_req_status      IN epis_prof_resp.flg_status%TYPE,
        i_transf_type     IN epis_prof_resp.flg_transf_type%TYPE,
        i_flg_type        IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile     IN profile_template.flg_profile%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        i_id_speciality   IN epis_multi_prof_resp.id_speciality%TYPE,
        i_id_professional IN epis_prof_resp.id_prof_comp%TYPE DEFAULT NULL,
        o_epis_prof_resp  OUT epis_prof_resp%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(200) := 'GET_EXISTING_HANDOFF_REQ';
        l_hand_off_type sys_config.value%TYPE := i_hand_off_type;
        l_param_error EXCEPTION;
    BEGIN
    
        g_error := 'VALIDATE PARAMETERS';
        get_hand_off_type(i_lang, i_prof, l_hand_off_type); -- Get the type of hand-off
    
        IF i_transf_type NOT IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_o, pk_hand_off.g_flg_transf_a)
        THEN
            -- Only individual transfers are supported.
            g_error := 'VALIDATE PARAMETERS - TYPE OF TRANSFER';
            pk_alertlog.log_error(g_error);
            RAISE l_param_error;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            g_error := 'CHECK EXISTING REQUESTED TRANSFER (1)';
            BEGIN
                SELECT epr.*
                  INTO o_epis_prof_resp
                  FROM epis_prof_resp epr
                 WHERE id_episode = i_id_episode
                   AND flg_status = i_req_status
                   AND flg_transf_type = i_transf_type
                   AND flg_type = i_flg_type;
            EXCEPTION
                WHEN no_data_found THEN
                    o_epis_prof_resp := NULL;
            END;
        
        ELSE
            g_error := 'CHECK EXISTING REQUESTED TRANSFER (2)';
            IF i_id_professional IS NOT NULL
            THEN
                BEGIN
                    SELECT epr.*
                      INTO o_epis_prof_resp
                      FROM epis_prof_resp epr
                      JOIN epis_multi_prof_resp empr
                        ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                     WHERE empr.flg_status = i_req_status
                          -- If the transfer is "requested", then ...
                          --  the multi-transfer record status must be "on hold"
                       AND empr.flg_profile = i_flg_profile
                       AND ((empr.id_speciality = i_id_speciality AND i_flg_profile <> g_nurse) OR
                           (empr.id_speciality IS NULL AND i_flg_profile = g_nurse))
                       AND epr.id_episode = i_id_episode
                       AND epr.flg_transf_type = i_transf_type
                       AND ((empr.flg_resp_type = g_resp_episode AND
                           epr.flg_transf_type IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_a)) OR
                           (empr.flg_resp_type = g_resp_overall AND epr.flg_transf_type = pk_hand_off.g_flg_transf_o))
                       AND epr.flg_type = i_flg_type
                       AND empr.id_professional = i_id_professional;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_epis_prof_resp := NULL;
                END;
            ELSE
            
                BEGIN
                    SELECT epr.*
                      INTO o_epis_prof_resp
                      FROM epis_prof_resp epr
                      JOIN epis_multi_prof_resp empr
                        ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                     WHERE empr.flg_status = g_onhold
                          -- If the transfer is "requested", then ...
                          --  the multi-transfer record status must be "on hold"
                       AND empr.flg_profile = i_flg_profile
                       AND ((empr.id_speciality = i_id_speciality AND i_flg_profile <> g_nurse) OR
                           (empr.id_speciality IS NULL AND i_flg_profile = g_nurse))
                       AND epr.id_episode = i_id_episode
                       AND epr.flg_status = i_req_status
                       AND epr.flg_transf_type = i_transf_type
                       AND ((empr.flg_resp_type = g_resp_episode AND
                           epr.flg_transf_type IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_a)) OR
                           (empr.flg_resp_type = g_resp_overall AND epr.flg_transf_type = pk_hand_off.g_flg_transf_o))
                       AND epr.flg_type = i_flg_type;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_epis_prof_resp := NULL;
                END;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_existing_handoff_req;

    /********************************************************************************************
    * Checks if an episode has a responsible specialist physician.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_hand_off_type            Type of hand-off mechanism (N)ormal (M)ultiple
    * @param   o_has_specialist           (Y) has a responsible specialist (N) doesn't have a responsible specialist
    * @param   o_specialist_name          Specialist name
    * @param   o_speciality               Speciality description
    * @param   o_profile_desc             Profile type description for specialist physicians
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION has_responsible_specialist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        o_has_specialist  OUT VARCHAR2,
        o_specialist_name OUT professional.name%TYPE,
        o_speciality      OUT VARCHAR2,
        o_profile_desc    OUT sys_domain.desc_val%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'HAS_RESPONSIBLE_SPECIALIST';
        l_dummy     episode.flg_status%TYPE;
        l_prof_resp professional.id_professional%TYPE;
        l_prof_name professional.name%TYPE;
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO GET_PROF_RESP_BY_TYPE';
        IF NOT get_prof_resp_by_type(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_id_episode    => i_id_episode,
                                     i_prof_cat      => pk_hand_off.g_prof_cat_doc,
                                     i_flg_profile   => g_specialist, -- Get the responsible specialist
                                     i_hand_off_type => i_hand_off_type,
                                     i_flg_resp_type => CASE i_hand_off_type
                                                            WHEN pk_hand_off.g_handoff_multiple THEN
                                                             g_resp_overall
                                                            ELSE
                                                             g_resp_episode
                                                        END,
                                     i_id_speciality => NULL,
                                     o_epis_status   => l_dummy,
                                     o_id_prof_resp  => l_prof_resp,
                                     o_prof_name     => l_prof_name,
                                     o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_prof_resp IS NULL
        THEN
            o_has_specialist := pk_alert_constant.g_no; -- The patient doesn't have a responsible specialist
        ELSE
            o_has_specialist  := pk_alert_constant.g_yes; -- There is a responsible specialist
            o_specialist_name := l_prof_name;
        
            g_error := 'GET PROFESSIONAL SPECIALITY';
            SELECT pk_prof_utils.get_spec_signature(i_lang, i_prof, l_prof_resp, NULL, NULL),
                   pk_sysdomain.get_domain('PROFILE_TEMPLATE.FLG_PROFILE', g_specialist, i_lang)
              INTO o_speciality, o_profile_desc
              FROM professional p
             WHERE p.id_professional = l_prof_resp;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END has_responsible_specialist;

    /********************************************************************************************
    * Returns a string with the responsible TEAM, formatted according to the hand-off type.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_dept                     Department ID
    * @param   i_soft                     Software ID
    * @param   i_prof_resp_doc            Responsible physician
    * @param   i_prof_resp_nurse          Responsible nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_team_str                 Team name (if available)
    *                        
    * @return  Formatted string
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_team_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dept            IN department.id_department%TYPE,
        i_soft            IN software.id_software%TYPE,
        i_prof_resp_doc   IN professional.id_professional%TYPE,
        i_prof_resp_nurse IN professional.id_professional%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        i_team_str        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name               VARCHAR2(200) := 'GET_TEAM_STR';
        l_error                   t_error_out;
        l_team_str                VARCHAR2(4000);
        l_show_resident_physician VARCHAR2(0010 CHAR);
        k_no CONSTANT VARCHAR2(0010 CHAR) := 'N';
    BEGIN
    
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => 'GRIDS_SHOW_RESIDENT', i_prof => i_prof);
    
        IF i_team_str IS NULL
        THEN
            g_error := 'GET EPISODE TEAM';
            IF l_show_resident_physician = k_no
            THEN
                l_team_str := pk_prof_teams.get_prof_current_team(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_department    => i_dept,
                                                                  i_epis_software => i_soft,
                                                                  i_prof_doc      => i_prof_resp_doc,
                                                                  i_prof_nurse    => i_prof_resp_nurse);
            END IF;
        ELSE
            l_team_str := i_team_str;
        END IF;
    
        IF l_team_str IS NOT NULL
           AND i_hand_off_type = pk_hand_off.g_handoff_multiple
           AND l_show_resident_physician = k_no
        THEN
            l_team_str := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M007') || '</b>' ||
                          chr(13) || l_team_str;
        
        ELSIF l_team_str IS NULL
              AND i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Avoids a bug (?) in UX's cell renderer, which shows the third line of the cell, if 'l_team_str' is null.
            l_team_str := '';
        END IF;
    
        RETURN l_team_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_team_str;

    /********************************************************************************************
    * Returns a string with the responsible professionals, FOR A CERTAIN TYPE/CATEGORY
    * formatted according to the place where it will be displayed (grids, tooltips).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_profile              Type of profile
    * @param   i_format                   Format text to show in (G) Grids (T) Tooltips
    *                        
    * @return  Formatted string
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.5
    * @since                          27-JAN-2011
    **********************************************************************************************/
    FUNCTION get_resp_by_type_grid_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_profile   IN epis_multi_prof_resp.flg_profile%TYPE,
        i_format        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_RESP_BY_TYPE_GRID_STR';
    
        l_format_g       CONSTANT VARCHAR2(1 CHAR) := 'G'; -- Show in grids
        l_format_t       CONSTANT VARCHAR2(1 CHAR) := 'T'; -- Show in tooltips
        l_profile_domain CONSTANT VARCHAR2(200 CHAR) := 'EPIS_MULTI_PROF_RESP.FLG_PROFILE';
        l_separator         VARCHAR2(2 CHAR) := '';
        l_separator_comma   VARCHAR2(2 CHAR) := ', ';
        l_separator_newline VARCHAR2(1 CHAR) := chr(13);
    
        l_tab_responsibles table_number;
        --l_tab_count        NUMBER(6);
        l_continue     BOOLEAN := FALSE;
        l_responsibles VARCHAR2(4000 CHAR) := '';
        l_error        t_error_out;
    
    BEGIN
    
        IF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET RESPONSIBLES LIST BY TYPE';
            SELECT empr.id_professional
              BULK COLLECT
              INTO l_tab_responsibles
              FROM epis_multi_prof_resp empr
             WHERE empr.id_episode = i_id_episode
               AND empr.flg_status = g_active
               AND empr.flg_profile = i_flg_profile;
        
            IF l_tab_responsibles.exists(1)
            THEN
            
                l_continue := l_tab_responsibles.count > 0;
            
                IF l_continue
                THEN
                    l_separator := CASE i_format
                                       WHEN l_format_g THEN
                                        l_separator_comma
                                       ELSE
                                        l_separator_newline
                                   END;
                
                    g_error := 'CONCAT NAMES - GRIDS';
                    SELECT decode(i_format,
                                  l_format_t,
                                  -- Show title in tooltips
                                  '<b>' || pk_sysdomain.get_domain(l_profile_domain, i_flg_profile, i_lang) || ':</b>' ||
                                  chr(13),
                                  '') ||
                           pk_utils.concat_table(CAST(MULTISET (SELECT pk_prof_utils.get_nickname(i_lang, t.id)
                                                         FROM (SELECT column_value id
                                                                 FROM TABLE(l_tab_responsibles)) t) AS table_varchar),
                                                 l_separator)
                      INTO l_responsibles
                      FROM dual;
                
                END IF;
            
            END IF;
        END IF;
    
        RETURN l_responsibles;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_resp_by_type_grid_str;

    /********************************************************************************************
    * Returns a string with the responsible professionals, formatted according to the place
    * where it will be displayed (grids, tooltips).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_prof_cat                 Professional category
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Main responsible professional ID (specialist physician or nurse)
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_format                   Format text to show in (G) Grids (T) Tooltips
    * @param   i_only_show_epis_resp      Is to only show the episode responsibles in the grids? Y - Yes; N - Otherwise;
    *                        
    * @return  Formatted string
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_cat            IN category.flg_type%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_hand_off_type       IN sys_config.value%TYPE,
        i_format              IN VARCHAR2,
        i_only_show_epis_resp IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(200) := 'GET_RESPONSIBLES_STR';
        l_error            t_error_out;
        l_number_resp      NUMBER(6);
        l_tab_responsibles table_number;
        l_tab_names        table_varchar;
    
        l_format_g CONSTANT VARCHAR2(1) := 'G'; -- Show in grids
        l_format_t CONSTANT VARCHAR2(1) := 'T'; -- Show in tooltips
    
        l_title_overall sys_domain.desc_val%TYPE;
        l_title_epis    sys_domain.desc_val%TYPE;
        l_title_nurse   sys_domain.desc_val%TYPE;
        l_title_main    sys_message.desc_message%TYPE;
    
        l_overall_responsibles VARCHAR2(4000 CHAR) := NULL;
        l_epis_responsibles    VARCHAR2(4000 CHAR) := NULL;
        l_nurse_responsible    VARCHAR2(4000 CHAR) := NULL;
        l_responsibles         VARCHAR2(4000 CHAR) := NULL;
    
        l_param_error EXCEPTION;
    BEGIN
    
        g_error := 'VALIDATE PARAMETERS';
        IF i_hand_off_type IS NULL
           OR i_format NOT IN (l_format_g, l_format_t)
        THEN
            g_error := 'INVALID PARAM (' || i_format || '/' || i_hand_off_type || ')';
            RAISE l_param_error;
        END IF;
    
        IF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the ID's of the responsibles for the patient, for the given category
            g_error := 'GET RESPONSIBLES COUNT';
            SELECT empr.id_professional
              BULK COLLECT
              INTO l_tab_responsibles
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_episode = i_id_episode
               AND empr.flg_status = g_active
               AND epr.flg_type = i_prof_cat
               AND epr.flg_status = pk_hand_off.g_hand_off_f
               AND (i_format = l_format_t OR
                   (i_format = l_format_g AND (i_only_show_epis_resp = pk_alert_constant.g_no OR
                   (i_only_show_epis_resp = pk_alert_constant.g_yes AND
                   empr.flg_resp_type = pk_hand_off_core.g_resp_episode))));
        
            IF l_tab_responsibles.exists(1)
            THEN
                l_number_resp := l_tab_responsibles.count;
            ELSE
                l_number_resp := 0;
            END IF;
        
            IF i_format = l_format_g -- Show responsibles in GRIDS
            THEN
                IF i_only_show_epis_resp = pk_alert_constant.g_no
                THEN
                    IF i_id_professional IS NOT NULL
                       AND nvl(l_number_resp, -1) = 0
                    THEN
                        g_error        := 'FORMAT RESPONSIBLE TEXT (NORMAL HAND-OFF)';
                        l_responsibles := pk_prof_utils.get_nickname(i_lang, i_id_professional);
                    
                    ELSIF i_id_professional IS NOT NULL
                          AND nvl(l_number_resp, -1) > 1
                    THEN
                        -- There is a responsible specialist,
                        -- and AT LEAST another responsible of other profile type.
                        g_error        := 'FORMAT RESPONSIBLE TEXT (G1)';
                        l_responsibles := '(' || l_number_resp || ') ' ||
                                          pk_prof_utils.get_nickname(i_lang, i_id_professional);
                    
                    ELSIF i_id_professional IS NOT NULL
                          AND nvl(l_number_resp, -1) = 1
                    THEN
                        -- Only exists a responsible specialist.
                        g_error        := 'FORMAT RESPONSIBLE TEXT (G2)';
                        l_responsibles := pk_prof_utils.get_nickname(i_lang, i_id_professional);
                    
                    ELSIF i_id_professional IS NULL
                          AND nvl(l_number_resp, -1) >= 1
                    THEN
                        -- There is NOT a responsible specialist,
                        -- but exists AT LEAST one responsible of other profile type.
                        g_error := 'GET TABLE WITH NAMES';
                        SELECT pk_prof_utils.get_nickname(i_lang, t.id)
                          BULK COLLECT
                          INTO l_tab_names
                          FROM (SELECT column_value id
                                  FROM TABLE(l_tab_responsibles)) t;
                    
                        g_error := 'CONCATENATE NAMES';
                        SELECT pk_utils.concat_table(l_tab_names, '; ')
                          INTO l_responsibles
                          FROM dual;
                    
                        g_error        := 'FORMAT RESPONSIBLE TEXT (G3)';
                        l_responsibles := '(' || l_number_resp || ') ' || l_responsibles;
                    
                    END IF;
                ELSE
                    g_error := 'GET TABLE WITH NAMES';
                    SELECT pk_prof_utils.get_nickname(i_lang, t.id)
                      BULK COLLECT
                      INTO l_tab_names
                      FROM (SELECT column_value id
                              FROM TABLE(l_tab_responsibles)) t;
                
                    g_error := 'CONCATENATE NAMES';
                    SELECT pk_utils.concat_table(l_tab_names, '; ')
                      INTO l_responsibles
                      FROM dual;
                
                    g_error        := 'FORMAT RESPONSIBLE TEXT (G3)';
                    l_responsibles := CASE
                                          WHEN l_number_resp > 0 THEN
                                           '(' || l_number_resp || ') '
                                          ELSE
                                           NULL
                                      END || l_responsibles;
                END IF;
            ELSIF i_format = l_format_t
                  AND nvl(l_number_resp, -1) > 0 -- Show responsibles in TOOLTIPS
            THEN
            
                IF i_prof_cat = pk_alert_constant.g_cat_type_doc
                THEN
                    -- Get required titles
                    l_title_overall := pk_sysdomain.get_domain(i_code_dom => 'EPIS_MULTI_PROF_RESP.FLG_RESP_TYPE',
                                                               i_val      => g_resp_overall,
                                                               i_lang     => i_lang);
                
                    l_title_main := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_M075');
                
                    l_title_epis := pk_sysdomain.get_domain(i_code_dom => 'EPIS_MULTI_PROF_RESP.FLG_RESP_TYPE',
                                                            i_val      => g_resp_episode,
                                                            i_lang     => i_lang);
                
                    -- Get list of OVERALL responsibles
                    g_error := 'CONCAT OVERALL';
                    SELECT pk_utils.concatenate_list(CURSOR (SELECT t.prof_name
                                                        FROM (SELECT pk_prof_utils.get_nickname(i_lang,
                                                                                                empr.id_professional) ||
                                                                     decode(empr.flg_main_responsible,
                                                                            pk_alert_constant.g_yes,
                                                                            ' - ' || l_title_main || ' (',
                                                                            ' (') ||
                                                                     pk_prof_utils.get_spec_signature(i_lang,
                                                                                                      i_prof,
                                                                                                      empr.id_professional,
                                                                                                      NULL,
                                                                                                      NULL) || ')' prof_name,
                                                                     decode(empr.flg_main_responsible,
                                                                            pk_alert_constant.g_yes,
                                                                            0,
                                                                            1) rank
                                                                FROM epis_multi_prof_resp empr
                                                               WHERE empr.id_episode = i_id_episode
                                                                 AND empr.flg_status = g_active
                                                                 AND empr.flg_resp_type = g_resp_overall
                                                               ORDER BY rank, priority, prof_name) t),
                                                     chr(13))
                      INTO l_overall_responsibles
                      FROM dual;
                
                    IF l_overall_responsibles IS NOT NULL
                    THEN
                        l_overall_responsibles := '<b>' || l_title_overall || '</b>' || chr(13) ||
                                                  l_overall_responsibles || chr(13);
                    END IF;
                
                    -- Get list of EPISODE responsibles
                    g_error := 'CONCAT EPISODE';
                    SELECT pk_utils.concatenate_list(CURSOR (SELECT t.prof_name
                                                        FROM (SELECT pk_prof_utils.get_nickname(i_lang,
                                                                                                empr.id_professional) || ' (' ||
                                                                     pk_prof_utils.get_spec_signature(i_lang,
                                                                                                      i_prof,
                                                                                                      empr.id_professional,
                                                                                                      NULL,
                                                                                                      NULL) || ')' prof_name,
                                                                     decode(empr.flg_profile,
                                                                            g_specialist,
                                                                            0,
                                                                            g_resident,
                                                                            1,
                                                                            g_intern,
                                                                            2) rank
                                                                FROM epis_multi_prof_resp empr
                                                               WHERE empr.id_episode = i_id_episode
                                                                 AND empr.flg_status = g_active
                                                                 AND empr.flg_resp_type = g_resp_episode
                                                                 AND empr.flg_profile <> g_nurse -- Only physicians
                                                               ORDER BY rank, priority) t),
                                                     chr(13))
                      INTO l_epis_responsibles
                      FROM dual;
                
                    IF l_epis_responsibles IS NOT NULL
                    THEN
                        l_epis_responsibles := '<b>' || l_title_epis || '</b>' || chr(13) || l_epis_responsibles ||
                                               chr(13);
                    END IF;
                
                    -- Concatenate all responsability strings
                    l_responsibles := l_overall_responsibles || chr(13) || l_epis_responsibles;
                
                ELSIF i_prof_cat = pk_alert_constant.g_cat_type_nurse
                THEN
                
                    l_title_nurse := pk_sysdomain.get_domain(i_code_dom => 'PROFILE_TEMPLATE.FLG_PROFILE',
                                                             i_val      => g_nurse,
                                                             i_lang     => i_lang);
                
                    -- Get responsible NURSE
                    g_error := 'CONCAT NURSE';
                    SELECT pk_prof_utils.get_nickname(i_lang, empr.id_professional) prof_name
                      INTO l_nurse_responsible
                      FROM epis_multi_prof_resp empr
                     WHERE empr.id_episode = i_id_episode
                       AND empr.flg_status = g_active
                       AND empr.flg_resp_type = g_resp_episode
                       AND empr.flg_profile = g_nurse;
                
                    IF l_nurse_responsible IS NOT NULL
                    THEN
                        l_nurse_responsible := '<b>' || l_title_nurse || '</b>' || chr(13) || l_nurse_responsible;
                    END IF;
                
                    -- Concatenate all responsability strings
                    l_responsibles := chr(13) || l_nurse_responsible;
                
                END IF;
            END IF;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            -- In normal hand-off, only the name of the professional is shown, regardless of the format.
            g_error        := 'FORMAT RESPONSIBLE TEXT (NORMAL HAND-OFF)';
            l_responsibles := pk_prof_utils.get_nickname(i_lang, i_id_professional);
        END IF;
    
        RETURN l_responsibles;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_responsibles_str;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_my_patients              Called from a 'My patients' grid: (Y) Yes (N) No - default
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN table_number IS
        l_func_name VARCHAR2(200) := 'GET_RESPONSIBLES_ID';
        l_error     t_error_out;
        l_tab_resp  table_number := table_number();
        l_show_all  VARCHAR2(1 CHAR);
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
    
        --l_id_epis_prof_resp    epis_prof_resp.id_epis_prof_resp%TYPE;
        --l_id_current_prof_resp epis_prof_resp.id_prof_comp%TYPE;
    BEGIN
    
        IF nvl(i_hand_off_type, pk_hand_off.g_handoff_normal) = pk_hand_off.g_handoff_normal
           OR i_prof_cat NOT IN (pk_hand_off.g_flg_type_d, pk_hand_off.g_flg_type_n) -- Add support for other categories with hand-off 
        THEN
        
            g_error := 'GET RESPONSIBLES (N)';
            SELECT nvl(t.id_professional, -1)
              BULK COLLECT
              INTO l_tab_resp
              FROM (SELECT decode(i_prof_cat,
                                  pk_hand_off.g_flg_type_d,
                                  nvl(ei.id_professional, sr.id_professional),
                                  pk_hand_off.g_flg_type_n,
                                  ei.id_first_nurse_resp,
                                  nvl(ei.id_professional, sr.id_professional)) id_professional
                      FROM epis_info ei
                      LEFT JOIN sch_resource sr
                        ON ei.id_schedule = sr.id_schedule
                     WHERE ei.id_episode = i_id_episode) t;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
        
            IF i_my_patients = pk_alert_constant.g_yes
               AND nvl(get_show_overall_resp(i_prof, i_prof_cat), pk_alert_constant.g_no) = pk_alert_constant.g_no
            THEN
                -- "My patients" grids can be configured to show/hide patients under OVERALL responsability
                l_show_all := pk_alert_constant.g_no;
            ELSE
                -- Show all patients under EPISODE and/or OVERALL responsability
                l_show_all := pk_alert_constant.g_yes;
            END IF;
        
            g_error := 'GET RESPONSIBLES (M)';
            SELECT aux.id_professional
              BULK COLLECT
              INTO l_tab_resp
              FROM (SELECT empr.id_professional
                      FROM epis_multi_prof_resp empr
                      JOIN epis_prof_resp epr
                        ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
                     WHERE empr.id_episode = i_id_episode
                       AND empr.flg_status = g_active
                          -- Code commented to return all professionals from the provided category
                          --AND empr.flg_profile IN (SELECT pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL)
                          --                           FROM dual)
                          --------------------------------------------------
                          -- Check if patients under OVERALL responsability will be displayed in the 'My patients' grids
                       AND ((empr.flg_resp_type = g_resp_episode AND l_show_all = pk_alert_constant.g_no) OR
                           (empr.flg_resp_type IN (g_resp_episode, g_resp_overall) AND
                           l_show_all = pk_alert_constant.g_yes))
                       AND epr.flg_type = i_prof_cat
                       AND epr.flg_status = pk_hand_off.g_hand_off_f
                    UNION ALL
                    SELECT nvl(t.id_professional, -1) id_professional
                      FROM (SELECT decode(i_prof_cat,
                                          pk_hand_off.g_flg_type_d,
                                          ei.id_professional,
                                          pk_hand_off.g_flg_type_n,
                                          ei.id_first_nurse_resp,
                                          ei.id_professional) id_professional
                              FROM epis_info ei
                             WHERE ei.id_episode = i_id_episode
                               AND i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                                                       pk_alert_constant.g_soft_social,
                                                       pk_alert_constant.g_soft_nutritionist,
                                                       pk_alert_constant.g_soft_primary_care)
                               AND i_my_patients = pk_alert_constant.g_yes) t) aux;
        
        ELSE
            -- g_error := 'INVALID HAND-OFF TYPE (' || i_hand_off_type || ')';
            l_tab_resp := NULL;
        END IF;
    
        RETURN l_tab_resp;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_responsibles_id;

    /********************************************************************************************
    * Returns an array with the all responsible professionals for the episode, 
    * for a configured professional category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Table number with all id episodes
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.15
    * @since                          04-04-2014
    **********************************************************************************************/
    FUNCTION get_all_responsibles_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode_table IN table_number
    ) RETURN t_resp_professional_cda IS
        l_type_hand_off VARCHAR2(4000);
        l_error         t_error_out;
        --l_tbl_aux       table_number;
        --l_epis_profs_id table_number := table_number();
        l_exception EXCEPTION;
        --l_n             NUMBER;
        l_prof        profissional;
        l_prof_result t_resp_professional_cda := t_resp_professional_cda();
        l_count       PLS_INTEGER := 0;
    BEGIN
        FOR rec_episode IN (SELECT a.id_episode, a.flg_type, epis.id_institution, ei.id_software
                              FROM (SELECT DISTINCT epr.id_episode, epr.flg_type
                                      FROM epis_prof_resp epr
                                     WHERE epr.id_episode IN (SELECT column_value
                                                                FROM TABLE(i_id_episode_table))) a
                              JOIN episode epis
                                ON epis.id_episode = a.id_episode
                              JOIN epis_info ei
                                ON ei.id_episode = a.id_episode)
        LOOP
            l_prof := profissional(0, rec_episode.id_institution, rec_episode.id_software);
        
            IF NOT pk_hand_off.get_hand_off_type(i_lang          => i_lang,
                                                 i_prof          => l_prof,
                                                 o_hand_off_type => l_type_hand_off,
                                                 o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FOR rec_prof IN (SELECT column_value
                               FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                               i_prof          => l_prof,
                                                                               i_id_episode    => rec_episode.id_episode,
                                                                               i_prof_cat      => rec_episode.flg_type,
                                                                               i_hand_off_type => l_type_hand_off)))
            LOOP
            
                --HIE requeriment - Don't show duplicated profissionals
                BEGIN
                    SELECT COUNT(1)
                      INTO l_count
                      FROM TABLE(l_prof_result) t
                     WHERE t.id = rec_prof.column_value;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count := 0;
                END;
            
                IF l_count = 0
                THEN
                    l_prof_result.extend();
                    l_prof_result(l_prof_result.count) := profissional(rec_prof.column_value,
                                                                       l_prof.institution,
                                                                       l_prof.software);
                END IF;
            END LOOP;
        
        END LOOP;
    
        RETURN l_prof_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ALL_RESPONSIBLES_ID',
                                              l_error);
            RETURN NULL;
    END get_all_responsibles_id;

    /********************************************************************************************
    * Verifies the permission to activate the OK and CANCEL buttons in the hand-off requests list
    * for the episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_button                   Button to validate (O) OK (C) CANCEL
    * @param   i_flg_status_req           Status of the request
    * @param   i_prof_req                 Professional who made the request
    * @param   i_prof_to                  Destination professional
    * @param   i_prof_comp                Professional who accepted the request
    * @param   i_flg_profile_req          Type of profile of the request (S)/(R)/(I)/(N)
    * @param   i_flg_profile_prof         Type of profile of the current professional
    * @param   i_flg_type                 Hand-off category (D)/(N)
    * @param   i_prof_cat                 Professional category
    * @param   i_hand_off_type            Type of hand-off mechanism (N) Normal (M) Multiple
    * @param   i_speciality_req           Hand-off request speciality
    * @param   i_speciality_prof          Speciality of the current professional
    * @param   i_episode                  Episode id
    * @param   i_flg_main_responsible     Professional is main overall responsible (Y)/(N)
    *                        
    * @return  (Y) to activate button (N) to inactivate
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          23-10-2009
    **********************************************************************************************/
    FUNCTION get_button_permission
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_button               IN VARCHAR2,
        i_flg_status_req       IN epis_prof_resp.flg_status%TYPE,
        i_prof_req             IN epis_prof_resp.id_prof_req%TYPE,
        i_prof_to              IN epis_prof_resp.id_prof_to%TYPE,
        i_prof_comp            IN epis_prof_resp.id_prof_comp%TYPE,
        i_flg_profile_req      IN epis_multi_prof_resp.flg_profile%TYPE,
        i_flg_profile_prof     IN profile_template.flg_profile%TYPE,
        i_flg_type             IN epis_prof_resp.flg_type%TYPE,
        i_prof_cat             IN category.flg_type%TYPE,
        i_hand_off_type        IN sys_config.value%TYPE,
        i_speciality_req       IN epis_multi_prof_resp.id_speciality%TYPE,
        i_speciality_prof      IN epis_multi_prof_resp.id_speciality%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_main_responsible IN epis_multi_prof_resp.flg_main_responsible%TYPE
    ) RETURN VARCHAR2 IS
        --l_func_name VARCHAR2(200) := 'GET_BUTTON_PERMISSION';
        l_yes CONSTANT VARCHAR2(1) := pk_alert_constant.g_yes;
        l_no  CONSTANT VARCHAR2(1) := pk_alert_constant.g_no;
        l_permission       VARCHAR2(1) := l_no;
        l_cancel_request   BOOLEAN := FALSE;
        l_cancel_finalized BOOLEAN := FALSE;
    
    BEGIN
    
        IF i_button = g_button_cancel
        THEN
            -- Check if I can cancel an hand-off REQUEST
            l_cancel_request := i_prof_req = i_prof.id AND i_flg_status_req = pk_hand_off.g_hand_off_r;
        
            -- Check if I can cancel a finalized (ACCEPTED) hand-off record:
            l_cancel_finalized := (i_prof_req = i_prof.id -- only if I made the request
                                  OR i_prof_comp = i_prof.id) -- only if I'm current responsible
                                  AND i_flg_status_req = pk_hand_off.g_hand_off_f -- only if it's accepted
                                  AND nvl(i_flg_main_responsible, pk_alert_constant.g_no) = pk_alert_constant.g_no -- it isn't a main overall responsible
                                 -- Ambulatory products do not allow to cancel accepted responsabilities
                                  AND
                                  i_prof.software NOT IN
                                  (pk_alert_constant.g_soft_primary_care, pk_alert_constant.g_soft_private_practice);
        
            -- If I comply with at least one of the previous conditions, than I can cancel the responsability record.
            IF l_cancel_request
               OR l_cancel_finalized
            THEN
                l_permission := l_yes;
            END IF;
        
        ELSIF i_button = g_button_ok
              AND i_flg_status_req = pk_hand_off.g_hand_off_r
        THEN
        
            -- If the request was made to me, or to anyone of my profile/category, I can accept it.
            IF i_prof_to = i_prof.id
            THEN
                l_permission := l_yes;
            
            ELSIF i_hand_off_type = pk_hand_off.g_handoff_normal
                  AND i_prof_to IS NULL
                  AND i_flg_type = i_prof_cat
            THEN
                l_permission := l_yes;
            
            ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
                  AND i_prof_to IS NULL
                  AND i_flg_profile_req = i_flg_profile_prof
                  AND nvl(i_speciality_req, -1) = nvl(i_speciality_prof, -1)
            THEN
            
                IF pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    i_episode,
                                                                                    i_prof_cat,
                                                                                    i_hand_off_type),
                                                i_prof.id) = -1
                THEN
                    l_permission := l_yes;
                END IF;
            END IF;
        
        ELSE
            l_permission := l_no;
        END IF;
    
        RETURN l_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_button_permission;

    /********************************************************************************************
    * Manages the possibility to make hand-off requests (episode or overall) according
    * to the permissions set to the current profile, and current state of the episode responsability.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_profile_templ_req     Profile of the current professional
    * @param   i_prof_cat_req             Category of the current professional
    * @param   i_flg_type                 Type of request: nurse or physician hand-off request
    * @param   i_flg_resp_type            Responsability type: (E) Episode (O) Overall
    * @param   i_flg_profile              Type of profile of the current professional
    * @param   i_hand_off_type            Type of hand-off: (N) Normal (M) Multiple
    * @param   i_id_speciality            Speciality ID of the current professional
    * @param   o_full_permission          Current professional has permission to make hand-off requests? Y/N
    * @param   o_req_to_self              Current professional can make a request to him/herself? Y/N
    * @param   o_req_to_other             Current professional can make a request to other professional? Y/N
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          18-10-2010
    **********************************************************************************************/
    FUNCTION check_request_permission
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_profile_templ_req IN profile_template.id_profile_template%TYPE,
        i_prof_cat_req         IN category.flg_type%TYPE,
        i_flg_type             IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp_type        IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_flg_profile          IN profile_template.flg_profile%TYPE,
        i_hand_off_type        IN sys_config.value%TYPE,
        i_id_speciality        IN epis_multi_prof_resp.id_speciality%TYPE,
        o_full_permission      OUT VARCHAR2,
        o_req_to_self          OUT VARCHAR2,
        o_req_to_other         OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CHECK_REQUEST_PERMISSION';
        l_internal_error EXCEPTION;
    
        l_count                  NUMBER(6);
        l_tab_flg_profiles       table_varchar;
        l_responsibles           table_number := table_number();
        l_is_overall_responsible VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_is_epis_responsible    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_flg_status_epis      episode.flg_status%TYPE;
        l_id_professional_resp epis_multi_prof_resp.id_professional%TYPE;
        l_handoff_type         sys_config.value%TYPE;
        l_config               sys_config.value%TYPE;
    
        l_id_market      institution.id_market%TYPE := NULL;
        l_config_markets sys_config.value%TYPE;
        l_flg_mrp        profile_template.flg_mrp%TYPE;
        --l_mrp_speciality        epis_multi_prof_resp.id_speciality%TYPE;
        --l_dummy_name            professional.name%TYPE;
        l_id_cur_main_prof_resp table_number;
    BEGIN
        -- Check configurations to see if profile is blocked from taking responsability
        l_config := pk_sysconfig.get_config('PROFILE_TEMPLATE_HANDOFF_PERMISSION', i_prof.institution, i_prof.software);
    
        -- If the current profile is a student or configured to not have permissions, no popup should be shown  
        IF i_flg_profile = g_student
           OR instr(l_config, '|' || i_id_profile_templ_req || '|') > 0
        THEN
            o_req_to_self := pk_alert_constant.g_no;
        
            IF i_flg_profile = g_student
            THEN
                --Get the market id
                BEGIN
                    SELECT i.id_market
                      INTO l_id_market
                      FROM institution i
                     WHERE i.id_institution = i_prof.institution;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_market := NULL;
                END;
            
                --Get the markets for which the student can request an hand_off to
                l_config_markets := pk_sysconfig.get_config('STUDENT_HAND_OFF_PERMISSION',
                                                            i_prof.institution,
                                                            i_prof.software);
            
                --Check if the market of the institution allows students to hand_off to
                IF l_id_market IS NULL
                   OR instr(l_config_markets, '|' || l_id_market || '|') = 0
                THEN
                    o_req_to_other := pk_alert_constant.g_no;
                ELSE
                    o_req_to_other := pk_alert_constant.g_yes;
                END IF;
            ELSE
                o_req_to_other := pk_alert_constant.g_yes;
            END IF;
            o_full_permission := pk_alert_constant.g_yes;
            RETURN TRUE;
        END IF;
    
        g_error := 'CHECK TYPE OF HAND OFF';
        get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        -- Get the profile types for which the professional can make a responsability hand-off request
        g_error := 'CALL TO PK_HAND_OFF.GET_ALLOWED_PROFILE_TYPES';
        IF NOT pk_hand_off_core.get_allowed_profile_types(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_id_profile_templ_req => i_id_profile_templ_req,
                                                          i_flg_type             => i_flg_type,
                                                          i_flg_resp_type        => i_flg_resp_type,
                                                          o_flg_profiles         => l_tab_flg_profiles,
                                                          o_error                => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_tab_flg_profiles.exists(1)
        THEN
            -- Check if exists any EPISODE hand-off request to any of the allowed profiles
            g_error := 'CHECK HAND-OFF REQUEST COUNT (M)';
            SELECT COUNT(*)
              INTO l_count
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE epr.flg_type = i_flg_type
               AND empr.id_episode = i_id_episode
               AND empr.flg_status = pk_hand_off_core.g_onhold
               AND empr.flg_profile IN (SELECT column_value
                                          FROM TABLE(l_tab_flg_profiles))
               AND empr.flg_resp_type = i_flg_resp_type;
        
            -- If still exist any profile without a request "on hold", then the professional can make a request. 
            IF l_count < l_tab_flg_profiles.count
            THEN
                -- Get the responsible for the current speciality
                g_error := 'GET EPISODE RESPONSIBLE';
                IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_id_episode    => i_id_episode,
                                                              i_prof_cat      => i_prof_cat_req,
                                                              i_flg_profile   => i_flg_profile,
                                                              i_hand_off_type => i_hand_off_type,
                                                              i_flg_resp_type => i_flg_resp_type,
                                                              i_id_speciality => i_id_speciality,
                                                              o_epis_status   => l_flg_status_epis,
                                                              o_id_prof_resp  => l_id_professional_resp,
                                                              o_error         => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF l_id_professional_resp = i_prof.id
                   AND i_prof_cat_req = i_flg_type
                THEN
                    -- The professionals only can make a request if they are responsible for the episode
                    o_req_to_self  := pk_alert_constant.g_no;
                    o_req_to_other := pk_alert_constant.g_yes;
                
                ELSIF i_prof_cat_req = pk_alert_constant.g_cat_type_nurse
                      AND i_flg_type = pk_alert_constant.g_cat_type_doc
                THEN
                    -- The nurse can request to nurses or physicians
                    o_req_to_self  := pk_alert_constant.g_no;
                    o_req_to_other := pk_alert_constant.g_yes;
                
                ELSE
                    IF i_flg_resp_type = g_resp_episode
                    THEN
                        -- Get all episode responsibles of the current category
                        g_error        := 'GET LIST OF RESPONSIBLES ID';
                        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                               i_prof          => i_prof,
                                                                               i_id_episode    => i_id_episode,
                                                                               i_prof_cat      => i_prof_cat_req,
                                                                               i_hand_off_type => i_hand_off_type,
                                                                               i_flg_resp_type => g_resp_episode);
                    
                        IF pk_utils.search_table_number(i_table => l_responsibles, i_search => i_prof.id) > -1
                        THEN
                            l_is_epis_responsible := pk_alert_constant.g_yes;
                        END IF;
                    END IF;
                
                    IF i_flg_resp_type = g_resp_overall
                    THEN
                        -- Get the overall responsible
                        g_error        := 'GET LIST OF RESPONSIBLES ID';
                        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                               i_prof          => i_prof,
                                                                               i_id_episode    => i_id_episode,
                                                                               i_prof_cat      => i_prof_cat_req,
                                                                               i_hand_off_type => i_hand_off_type,
                                                                               i_flg_resp_type => g_resp_overall);
                    
                        IF pk_utils.search_table_number(i_table => l_responsibles, i_search => i_prof.id) > -1
                        THEN
                            l_is_overall_responsible := pk_alert_constant.g_yes;
                        ELSE
                            -- check if professional can assume mrp responsability
                            l_flg_mrp := pk_prof_utils.get_flg_mrp(i_lang, i_prof, i_id_profile_templ_req);
                        
                            SELECT t.id_professional
                              BULK COLLECT
                              INTO l_id_cur_main_prof_resp
                              FROM (SELECT empr.id_professional
                                      FROM episode e
                                      JOIN epis_multi_prof_resp empr
                                        ON empr.id_episode = e.id_episode
                                     WHERE e.id_episode = i_id_episode
                                       AND empr.flg_status = g_active
                                       AND empr.flg_profile = i_flg_profile
                                       AND empr.flg_resp_type = g_resp_overall
                                       AND empr.id_speciality = i_id_speciality
                                       AND empr.flg_main_responsible = pk_alert_constant.g_yes
                                     ORDER BY empr.dt_create DESC) t
                             WHERE rownum = 1;
                        
                            IF l_flg_mrp = pk_alert_constant.g_no
                               AND l_id_cur_main_prof_resp.count > 0
                            THEN
                                l_is_overall_responsible := pk_alert_constant.g_yes;
                            ELSE
                                l_is_overall_responsible := pk_alert_constant.g_no;
                            END IF;
                        END IF;
                    END IF;
                
                    IF i_flg_resp_type = g_resp_overall
                       AND l_is_overall_responsible = pk_alert_constant.g_yes
                    THEN
                        o_req_to_self := pk_alert_constant.g_no;
                    ELSIF i_flg_resp_type = g_resp_overall
                          AND l_is_overall_responsible = pk_alert_constant.g_no
                    THEN
                        o_req_to_self := pk_alert_constant.g_yes;
                    ELSIF i_flg_resp_type = g_resp_episode
                          AND l_is_epis_responsible = pk_alert_constant.g_yes
                    THEN
                        o_req_to_self := pk_alert_constant.g_no;
                    ELSIF i_flg_resp_type = g_resp_episode
                          AND l_is_epis_responsible = pk_alert_constant.g_no
                    THEN
                        o_req_to_self := pk_alert_constant.g_yes;
                    END IF;
                
                    o_req_to_other := pk_alert_constant.g_yes;
                END IF;
            
                o_full_permission := pk_alert_constant.g_yes;
            
            ELSE
                o_full_permission := pk_alert_constant.g_no;
            END IF;
        
        ELSE
            -- Professional doesn't have permission to make hand-off requests
            o_full_permission := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_request_permission;

    /********************************************************************************************
    * Returns the options to display in the hand-off internal button, 
    * for the ACTIONS/VIEWS buttons.
    *
    * This method is not intended to set permissions for each option. Insted this will be managed
    * by Flash according to the values of flags embedded in the cursors returned by GET_EPIS_PROF_RESP_ALL.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_flg_type                 Context of hand-off: physician or nurse hand-off
    * @param   o_id_epis_multi_prof_resp  New multiple hand-off record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          18-10-2010
    **********************************************************************************************/
    FUNCTION get_hand_off_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_prof_resp.flg_type%TYPE,
        o_actions  OUT pk_types.cursor_type,
        o_views    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HAND_OFF_OPTIONS';
        l_internal_error EXCEPTION;
    
        -- Actions to display    
        l_action_request   CONSTANT action.to_state%TYPE := 'R';
        l_action_cancel    CONSTANT action.to_state%TYPE := 'C';
        l_action_terminate CONSTANT action.to_state%TYPE := 'T';
        l_action_set_main  CONSTANT action.to_state%TYPE := 'M';
    
        l_hand_off_type sys_config.value%TYPE;
        l_flg_profile   profile_template.flg_profile%TYPE;
    
        l_tab_avail_options table_varchar := table_varchar();
    
        l_is_ambulatory_product NUMBER(6);
        --l_flg_mrp               profile_template.flg_mrp%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        -- Get type of hand-off
        g_error := 'GET CONFIGURATIONS';
        get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        -- Check if it's an ambulatory product
        IF i_prof.software = pk_alert_constant.g_soft_outpatient
        THEN
            l_is_ambulatory_product := 0;
        ELSE
            l_is_ambulatory_product := is_ambulatory_product(i_prof.software);
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        
            g_error := 'GET TYPE OF PROFILE';
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => l_profile_template,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        -- Views are common for all types of hand-off.
        g_error := 'GET VIEWS';
        IF NOT pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => 'HANDOFF_VIEWS',
                                     i_from_state => NULL,
                                     o_actions    => o_views,
                                     o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        /*
        IF l_flg_profile = g_specialist
        THEN
            l_flg_mrp := pk_prof_utils.get_flg_mrp(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_profile_template => l_profile_template);
        END IF;
        */
    
        -- Get available actions according to software or professional profile
        g_error := 'GET AVAILABLE ACTIONS';
        SELECT a.to_state
          BULK COLLECT
          INTO l_tab_avail_options
          FROM action a
         WHERE a.subject = 'HANDOFF_ACTIONS'
              -- Show options "Cancel" and "Terminate Responsability"?
           AND ((a.to_state NOT IN (l_action_terminate, l_action_cancel) AND l_is_ambulatory_product = 1) OR
               l_is_ambulatory_product = 0)
              -- Show option "Transfer responsability"?
           AND ((a.to_state <> l_action_request AND i_prof.software = pk_alert_constant.g_soft_oris) OR
               i_prof.software <> pk_alert_constant.g_soft_oris)
              -- Show option "Set main treatment physician"?
           AND ((a.to_state = l_action_set_main AND l_hand_off_type = pk_hand_off.g_handoff_multiple AND
               i_flg_type = pk_alert_constant.g_cat_type_doc /*AND l_flg_mrp = pk_alert_constant.g_yes*/
               ) OR a.to_state <> l_action_set_main);
    
        g_error := 'GET ACTIONS';
        IF NOT pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => table_varchar('HANDOFF_ACTIONS'),
                                     i_from_state => l_tab_avail_options,
                                     o_actions    => o_actions,
                                     o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            pk_types.open_my_cursor(o_views);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            pk_types.open_my_cursor(o_views);
            RETURN FALSE;
    END get_hand_off_options;

    /********************************************************************************************
    * Manages the multiple hand-off mechanism data. This function must be called when
    * a responsible for a patient is changed.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             New responsible for the patient
    * @param   i_flg_profile              Type of profile
    * @param   i_id_epis_prof_resp        Hand-off transfer request ID
    * @param   i_flg_status               Hand-off transfer request new status
    * @param   i_sysdate                  Current date
    * @param   i_hand_off_type            Type of hand-off mechanism (N)ormal (M)ultiple
    * @param   i_flg_main_responsible     Is main overall responsible? (Y) Yes (N) No - default.    
    * @param   i_id_speciality            Physician speciality. Null value for nurses.
    * @param   i_flg_resp_type            Responsability type: (E) Episode (O) Overall
    * @param   o_id_epis_multi_prof_resp  New multiple hand-off record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION set_multi_prof_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN professional.id_professional%TYPE,
        i_flg_profile             IN epis_multi_prof_resp.flg_profile%TYPE,
        i_id_epis_prof_resp       IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_status              IN epis_prof_resp.flg_status%TYPE,
        i_sysdate                 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_hand_off_type           IN sys_config.value%TYPE,
        i_flg_main_responsible    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT 'N',
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_resp_type           IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_priority                IN NUMBER DEFAULT NULL,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name               VARCHAR2(200) := 'SET_MULTI_PROF_RESP';
        l_new_multi_resp          epis_multi_prof_resp%ROWTYPE;
        l_new_flg_status          epis_multi_prof_resp.flg_status%TYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_param_error    EXCEPTION;
        l_data_error     EXCEPTION;
        l_internal_error EXCEPTION;
        l_rowids                   table_varchar;
        l_sysdate                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_hand_off_type            sys_config.value%TYPE := i_hand_off_type;
        l_id_speciality            speciality.id_speciality%TYPE;
        l_count                    NUMBER(6) := 0;
        l_new_id_emprh             epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE;
        l_new_emprh_ids            table_number;
        l_handoff_multi_spec       sys_config.id_sys_config%TYPE := 'MULTIPLE_HAND_OFF_MULTI_SPEC';
        l_handoff_multi_spec_value sys_config.value%TYPE;
    
    BEGIN
        -- Get type of hand-off
        g_error := 'GET CONFIGURATIONS';
        get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            -- Stop execution and return. This only applies to the multiple hand-off mechanism.
            RETURN TRUE;
        
        ELSIF i_prof.software IN (pk_alert_constant.g_soft_social,
                                  pk_alert_constant.g_soft_nutritionist,
                                  pk_alert_constant.g_soft_primary_care)
              AND i_flg_resp_type = g_resp_episode
        THEN
            -- In OUTPATIENT, EPISODE responsability must not be registered in the hand-off tables (only EPIS_INFO).
            RETURN TRUE;
        END IF;
    
        g_error := 'SET DATE';
        IF i_sysdate IS NULL
        THEN
            l_sysdate := current_timestamp;
        ELSE
            l_sysdate := i_sysdate;
        END IF;
    
        IF i_flg_profile = g_nurse
        THEN
            -- Data quality: Assure that the speciality is not registered in nurse hand-off.
            l_id_speciality := NULL;
        
        ELSIF i_flg_profile <> g_nurse
              AND i_id_speciality IS NULL
        THEN
            -- If medical profiles don't have an assigned speciality, raise an error.
            g_error := 'ID_SPECIALITY NOT ASSIGNED TO PROFESSIONAL';
            pk_alertlog.log_error(g_error);
            RAISE l_data_error;
        ELSE
            l_id_speciality := i_id_speciality;
        END IF;
    
        g_error := 'VALIDATE PARAMETERS';
        IF i_id_episode IS NULL
           OR i_flg_profile IS NULL
           OR i_flg_resp_type IS NULL
        THEN
            g_error := 'NULL PARAMETER FOUND';
            g_error := 'CALL TO CALL_SET_OVERALL_RESP i_id_episode:' || i_id_episode || 'i_id_prof_resp:' ||
                       i_id_prof_resp || 'i_flg_resp_type:' || i_flg_resp_type || ' i_flg_profile:' || i_flg_profile;
        
            RAISE l_param_error;
        
        ELSIF i_flg_resp_type = g_resp_overall
              AND i_flg_profile <> g_specialist
        THEN
            g_error := 'OVERALL RESPONSABILITY NOT SUPPORTED FOR THIS PROFILE';
            RAISE l_param_error;
        END IF;
    
        l_handoff_multi_spec_value := pk_sysconfig.get_config(i_code_cf => l_handoff_multi_spec, i_prof => i_prof);
        -- Process multi hand-off according to the status of EPIS_PROF_RESP
        -- 1) Status = 'F' ==> Multi status = 'A'. Transfer was accepted by the professional.
        -- 2) Status = 'R' ==> Multi status = 'H' - on hold. Transfer is waiting for acceptance.
        -- 3) Status in ('D', 'C', 'T') ==> Multi status = 'O' - outdated. Transfer was declined, cancelled or terminated.
        -- 4) If 'X' ==> Error. This state is only for transfers between service.
        g_error := 'ASSIGN NEW STATUS';
        CASE i_flg_status
            WHEN pk_hand_off.g_hand_off_f THEN
                -- Finished transfer (accepted)
                l_new_flg_status := g_active;
            WHEN pk_hand_off.g_hand_off_r THEN
                -- Request transfer
                l_new_flg_status := g_onhold;
            WHEN pk_hand_off.g_hand_off_d THEN
                -- Declined
                l_new_flg_status := g_outdated;
            WHEN pk_hand_off.g_hand_off_c THEN
                -- Cancelled
                l_new_flg_status := g_outdated;
            WHEN pk_hand_off.g_hand_off_t THEN
                -- Terminated responsability
                l_new_flg_status := g_outdated;
            WHEN pk_hand_off.g_hand_off_x THEN
                -- Executed (only supported in transfers between service)
                g_error := 'STATUS NOT APPLICABLE';
                RAISE l_param_error; -- Not applicable in this kind of hand-off
            ELSE
                g_error := 'INVALID STATUS FOUND';
                RAISE l_param_error;
        END CASE;
    
        IF l_new_flg_status = g_active
        THEN
            -- IMPORTANT!! The responsible changed, so let's outdate previous responsible
            -- for the patient, for the current profile.
            g_error := 'UPDATE EPIS_MULTI_PROF_RESP (1)';
            IF l_handoff_multi_spec_value = pk_alert_constant.g_no
            THEN
                ts_epis_multi_prof_resp.upd(flg_status_in           => g_outdated, -- OUTDATED!!
                                            flg_main_responsible_in => pk_alert_constant.g_no,
                                            where_in                => 'ID_EPISODE = ' || i_id_episode ||
                                                                       ' AND FLG_STATUS = ''' || g_active ||
                                                                       ''' AND FLG_PROFILE = ''' || i_flg_profile ||
                                                                       ''' AND NVL(ID_SPECIALITY, -1) = ' ||
                                                                       nvl(l_id_speciality, -1) ||
                                                                       ' AND FLG_RESP_TYPE = ''' || i_flg_resp_type || '''',
                                            rows_out                => l_rowids);
            END IF;
            -- Check if already exists a record with the current ID_EPIS_PROF_RESP
            g_error := 'GET NUMBER OF EXISTING RECORDS';
            SELECT COUNT(*)
              INTO l_count
              FROM epis_multi_prof_resp emrp
             WHERE emrp.id_epis_prof_resp = i_id_epis_prof_resp;
        
            IF l_count > 1
            THEN
                g_error := 'INVALID NUMBER OF RECORDS IN EPIS_MULTI_PROF_RESP';
                RAISE l_data_error;
            END IF;
        
            g_error := 'PROCESS UPDATE EPIS_MULTI_PROF_RESP (1)';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_MULTI_PROF_RESP',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- Set history for OUTDATED records
            g_error := 'SET HISTORY - UPDATE (1)';
            IF NOT set_multi_prof_resp_hist_rows(i_lang   => i_lang,
                                                 i_prof   => i_prof,
                                                 i_rowids => l_rowids,
                                                 o_ids    => l_new_emprh_ids,
                                                 o_error  => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            -- Reset variable for reuse
            l_rowids := table_varchar();
        
        END IF;
    
        IF (l_new_flg_status = g_active AND l_count = 0)
           OR l_new_flg_status = g_onhold
        THEN
            -- Create a new record:
            -- 1) New hand-off request
            -- 2) First responsible for the patient (when there is no pending request)
            l_new_multi_resp.id_epis_multi_prof_resp := ts_epis_multi_prof_resp.next_key;
            l_new_multi_resp.id_episode              := i_id_episode;
            l_new_multi_resp.flg_status              := l_new_flg_status;
            l_new_multi_resp.id_professional         := nvl(i_id_prof_resp, -1); -- Set "-1" in requests for "Any" professional
            l_new_multi_resp.flg_profile             := i_flg_profile;
            l_new_multi_resp.id_epis_prof_resp       := i_id_epis_prof_resp;
            l_new_multi_resp.dt_create               := l_sysdate;
            l_new_multi_resp.flg_main_responsible    := CASE l_new_flg_status
                                                            WHEN g_onhold THEN
                                                             'N'
                                                            ELSE
                                                             i_flg_main_responsible
                                                        END;
            l_new_multi_resp.id_speciality           := l_id_speciality;
            l_new_multi_resp.flg_resp_type           := i_flg_resp_type;
            l_new_multi_resp.priority                := i_priority;
            l_new_multi_resp.dt_update               := l_sysdate;
        
            g_error := 'INSERT EPIS_MULTI_PROF_RESP';
            ts_epis_multi_prof_resp.ins(rec_in => l_new_multi_resp, rows_out => l_rowids);
        
            l_id_epis_multi_prof_resp := l_new_multi_resp.id_epis_multi_prof_resp;
        
            g_error := 'PROCESS INSERT EPIS_MULTI_PROF_RESP';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_MULTI_PROF_RESP',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'SET HISTORY - INSERT';
            IF NOT set_multi_prof_resp_hist(i_lang                        => i_lang,
                                            i_prof                        => i_prof,
                                            i_epis_multi_rec              => l_new_multi_resp,
                                            o_id_epis_multi_profresp_hist => l_new_id_emprh,
                                            o_error                       => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        ELSE
            -- Update existing record:
            -- 1) Cancel/Decline existing request
            -- 2) Accept existing pending request
            g_error := 'GET RECORD ID';
            SELECT empr.id_epis_multi_prof_resp
              INTO l_id_epis_multi_prof_resp
              FROM epis_multi_prof_resp empr
             WHERE empr.id_episode = i_id_episode
               AND empr.id_epis_prof_resp = i_id_epis_prof_resp;
        
            g_error := 'UPDATE EPIS_MULTI_PROF_RESP (2)';
            ts_epis_multi_prof_resp.upd(id_epis_multi_prof_resp_in => l_id_epis_multi_prof_resp,
                                        flg_status_in              => l_new_flg_status,
                                        id_professional_in         => i_id_prof_resp,
                                        priority_in                => i_priority,
                                        dt_update_in               => l_sysdate,
                                        flg_main_responsible_in    => nvl(i_flg_main_responsible, pk_alert_constant.g_no),
                                        rows_out                   => l_rowids);
        
            IF NOT l_rowids.exists(1)
            THEN
                g_error := 'INVALID NUMBER OF UPDATED RECORDS IN EPIS_MULTI_PROF_RESP';
                pk_alertlog.log_error(g_error);
                RAISE l_data_error;
            END IF;
        
            g_error := 'PROCESS UPDATE EPIS_MULTI_PROF_RESP (2)';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_MULTI_PROF_RESP',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- Set history for UPDATED records
            g_error := 'SET HISTORY - UPDATE (1)';
            IF NOT set_multi_prof_resp_hist_rows(i_lang   => i_lang,
                                                 i_prof   => i_prof,
                                                 i_rowids => l_rowids,
                                                 o_ids    => l_new_emprh_ids,
                                                 o_error  => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        -- Update MAIN RESPONSIBLE in EPIS_INFO
        IF i_flg_main_responsible = pk_alert_constant.g_yes
           AND l_new_flg_status = g_active
           AND i_flg_profile = g_specialist
        THEN
            g_error := 'UPDATE EPIS_INFO';
            IF NOT call_set_epis_info_resp(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_episode          => i_id_episode,
                                           i_id_professional     => i_id_prof_resp,
                                           i_id_professional_nin => FALSE,
                                           i_prof_cat            => pk_alert_constant.g_cat_type_doc,
                                           i_flg_resp_type       => i_flg_resp_type,
                                           o_error               => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        END IF;
    
        o_id_epis_multi_prof_resp := l_id_epis_multi_prof_resp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_data_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'DATA ERROR',
                                              'INVALID DATA FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_multi_prof_resp;

    /********************************************************************************************
    * Sets history for the multiple hand-off responsability.
    *
    * @param   i_lang                           Language ID
    * @param   i_prof                           Professional data
    * @param   i_epis_multi_rec                 EPIS_MULTI_PROF_RESP row
    * @param   o_id_epis_multi_profresp_hist    History ID
    * @param   o_error                          Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          15-10-2010
    **********************************************************************************************/
    FUNCTION set_multi_prof_resp_hist
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_epis_multi_rec              IN epis_multi_prof_resp%ROWTYPE,
        o_id_epis_multi_profresp_hist OUT epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_MULTI_PROF_RESP_HIST';
    
        l_row    epis_multi_profresp_hist%ROWTYPE;
        l_rowids table_varchar;
    BEGIN
    
        l_row.id_epis_multi_profresp_hist := ts_epis_multi_profresp_hist.next_key;
        l_row.id_epis_multi_prof_resp     := i_epis_multi_rec.id_epis_multi_prof_resp;
        l_row.id_episode                  := i_epis_multi_rec.id_episode;
        l_row.flg_status                  := i_epis_multi_rec.flg_status;
        l_row.id_professional             := i_epis_multi_rec.id_professional;
        l_row.flg_profile                 := i_epis_multi_rec.flg_profile;
        l_row.dt_create                   := i_epis_multi_rec.dt_create;
        l_row.id_epis_prof_resp           := i_epis_multi_rec.id_epis_prof_resp;
        l_row.flg_main_responsible        := i_epis_multi_rec.flg_main_responsible;
        l_row.id_speciality               := i_epis_multi_rec.id_speciality;
        l_row.flg_resp_type               := i_epis_multi_rec.flg_resp_type;
        l_row.priority                    := i_epis_multi_rec.priority;
        l_row.dt_update                   := i_epis_multi_rec.dt_update;
    
        ts_epis_multi_profresp_hist.ins(rec_in => l_row, rows_out => l_rowids);
    
        g_error := 'PROCESS INSERT EPIS_MULTI_PROFRESP_HIST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_MULTI_PROFRESP_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_id_epis_multi_profresp_hist := l_row.id_epis_multi_profresp_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_multi_prof_resp_hist;

    /********************************************************************************************
    * Sets history for the multiple hand-off responsability, using rowids.
    *
    * @param   i_lang                           Language ID
    * @param   i_prof                           Professional data
    * @param   i_rowids                         Array with rowids
    * @param   o_ids                            Array with created history record ID's
    * @param   o_error                          Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          15-10-2010
    **********************************************************************************************/
    FUNCTION set_multi_prof_resp_hist_rows
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar,
        o_ids    OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_MULTI_PROF_RESP_HIST_ROWS';
        l_internal_error EXCEPTION;
    
        l_rec          epis_multi_prof_resp%ROWTYPE;
        l_new_ids      table_number := table_number();
        l_new_id_emprh epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE;
    
        l_exists_error BOOLEAN := FALSE;
    BEGIN
    
        IF i_rowids.exists(1)
        THEN
            -- Loop through updated records
            FOR i IN i_rowids.first .. i_rowids.last
            LOOP
                IF NOT l_exists_error
                THEN
                    g_error := 'GET EMPR RECORD (' || i || ')';
                    SELECT empr.*
                      INTO l_rec
                      FROM epis_multi_prof_resp empr
                     WHERE empr.rowid = i_rowids(i);
                
                    g_error := 'SET HISTORY - INSERT (' || i || ')';
                    IF NOT set_multi_prof_resp_hist(i_lang                        => i_lang,
                                                    i_prof                        => i_prof,
                                                    i_epis_multi_rec              => l_rec,
                                                    o_id_epis_multi_profresp_hist => l_new_id_emprh,
                                                    o_error                       => o_error)
                    THEN
                        l_exists_error := TRUE;
                    END IF;
                
                    l_new_ids.extend;
                    l_new_ids(l_new_ids.count) := l_new_id_emprh;
                
                END IF;
            END LOOP;
        END IF;
    
        IF l_exists_error
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_multi_prof_resp_hist_rows;

    /**
    * Format and return error message string
    *
    * @param   i_error        Error information
    *
    * @return                 Error information in string format
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_error_str(i_error IN t_error_out) RETURN VARCHAR2 IS
    BEGIN
        RETURN '### SQL_CODE: ' || i_error.ora_sqlcode || '; SQL_ERRM: ' || i_error.ora_sqlerrm || '; ERR_DESC: ' || i_error.err_desc || '; ERR_ACTION: ' || i_error.err_action || '; LOG_ID: ' || i_error.log_id || ';' || ' ###';
    END get_error_str;

    /**
    * Get responsability type
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_professional    id_professional to verify responsability
    * @param   i_handoff_type    Hand-off type
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   o_type            Responsability type
    * @param   o_error           Error information
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @value   o_type         {*} 'M' Main responsability
    *                         {*} 'O' Overrall responsiblility
    *                         {*} 'E' Episode responsability
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_professional   IN professional.id_professional%TYPE DEFAULT NULL,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        i_hand_off_type  IN sys_config.value%TYPE DEFAULT NULL,
        o_type           OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_RESP_TYPE';
        l_internal_error EXCEPTION;
        --
        l_flg_main_resp epis_multi_prof_resp.flg_main_responsible%TYPE;
        l_flg_resp_type epis_multi_prof_resp.flg_resp_type%TYPE;
        --l_prof_cat             category.flg_type%TYPE;
        --l_id_epis_prof_resp    epis_prof_resp.id_epis_prof_resp%TYPE;
        --l_id_professional_resp professional.id_professional%TYPE;
        --
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        IF i_hand_off_type IS NULL
        THEN
            g_error := 'GET TYPE OF HAND-OFF';
            pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        ELSE
            l_hand_off_type := i_hand_off_type;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            <<query_multi_prof_resp>>
            BEGIN
                --When id_epis_prof_resp is not null the call was made by detail or history functions so we only want to
                --return the type of the record 
                IF i_epis_prof_resp IS NOT NULL
                THEN
                    g_error := 'GET PROF_RESP - ID_EPIS_PROF_RESP: ' || i_epis_prof_resp || ';';
                    SELECT empr.flg_main_responsible, empr.flg_resp_type
                      INTO l_flg_main_resp, l_flg_resp_type
                      FROM epis_multi_prof_resp empr
                     WHERE empr.id_epis_prof_resp = i_epis_prof_resp;
                
                ELSIF i_episode IS NOT NULL
                      AND i_professional IS NOT NULL
                THEN
                    --When id_episode and id_professional are not null the call was made to verify if the professional is
                    --responsible (and what type of responsability it has) over the episode
                    g_error := 'GET PROF_RESP - ID_PROF: ' || i_professional || '; ID_EPISODE: ' || i_episode || ';';
                
                    SELECT flg_main_responsible, flg_resp_type
                      INTO l_flg_main_resp, l_flg_resp_type
                      FROM (SELECT empr.flg_main_responsible, empr.flg_resp_type
                              FROM epis_multi_prof_resp empr
                             WHERE empr.id_episode = i_episode
                               AND empr.id_professional = i_professional
                               AND empr.flg_status = pk_alert_constant.g_active
                             ORDER BY empr.flg_resp_type DESC)
                     WHERE rownum = 1;
                
                ELSE
                    l_flg_main_resp := NULL;
                    l_flg_resp_type := NULL;
                END IF;
            
                IF l_flg_main_resp = pk_alert_constant.g_yes
                   AND l_flg_resp_type = pk_hand_off_core.g_empr_flg_resp_type_o
                THEN
                    o_type := pk_hand_off_core.g_resp_type_m; --Main responsability
                ELSIF l_flg_main_resp = pk_alert_constant.g_no
                      AND l_flg_resp_type = pk_hand_off_core.g_empr_flg_resp_type_o
                THEN
                    o_type := pk_hand_off_core.g_resp_type_o; --Overrall responsiblility
                ELSIF l_flg_main_resp IS NULL
                      AND l_flg_resp_type IS NULL
                THEN
                    o_type := NULL;
                ELSE
                    o_type := pk_hand_off_core.g_resp_type_e; --Episode responsability
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    o_type := NULL; --Current professional is not responsibly by this patient/episode
            END query_multi_prof_resp;
        ELSE
            <<query_prof_resp>>
            BEGIN
                --When id_epis_prof_resp is not null the call was made by detail or history functions so we only want to
                --return the type of the record 
                IF i_epis_prof_resp IS NOT NULL
                THEN
                    g_error := 'GET PROF_RESP - ID_EPIS_PROF_RESP: ' || i_epis_prof_resp || ';';
                    SELECT pk_hand_off_core.g_resp_type_e
                      INTO o_type
                      FROM epis_prof_resp epr
                     WHERE epr.id_epis_prof_resp = i_epis_prof_resp;
                
                    --When id_episode and id_professional are not null the call was made to verify if the professional is
                    --responsible (and what type of responsability it has) over the episode
                ELSIF i_episode IS NOT NULL
                      AND i_professional IS NOT NULL
                THEN
                    --The professional can only have his id in one of the columns id_professional/id_first_nurse_resp
                    --so the following query returns 0 or 1 record
                    g_error := 'GET PROF_RESP - ID_PROF: ' || i_professional || '; ID_EPISODE: ' || i_episode ||
                               '; (OTHER)';
                    SELECT pk_hand_off_core.g_resp_type_e
                      INTO o_type
                      FROM epis_info ei
                     WHERE ei.id_episode = i_episode
                       AND (ei.id_professional = i_professional OR ei.id_first_nurse_resp = i_professional);
                ELSE
                    o_type := NULL;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    o_type := NULL; --Current professional is not responsibly by this episode
            END query_prof_resp;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_resp_type;

    /**
    * Get responsability type
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_professional    id_professional to verify responsability
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   i_handoff_type    Hand-off type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_professional   IN professional.id_professional%TYPE DEFAULT NULL,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        i_hand_off_type  IN sys_config.value%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_RESP_TYPE';
        --
        l_type  VARCHAR2(1);
        l_error t_error_out;
    BEGIN
        g_error := 'GET RESP_TYPE';
        IF NOT pk_hand_off_core.get_resp_type(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_professional   => i_professional,
                                              i_hand_off_type  => i_hand_off_type,
                                              i_epis_prof_resp => i_epis_prof_resp,
                                              o_type           => l_type,
                                              o_error          => l_error)
        THEN
            g_error := 'ERROR GETTING RESP_TYPE - I_EPISODE: ' || i_episode || '; I_PROF: PROFESSIONAL(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '); ' || get_error_str(l_error);
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            l_type := NULL;
        END IF;
    
        RETURN l_type;
    END get_resp_type;

    /**
    * Get responsability icons
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_handoff_type Hand-off type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 Array with the responsability icons
    *
    * @raises                 g_resp_type_exception Error when getting responsability type for the episode/i_prof
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_icons
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_handoff_type IN sys_config.value%TYPE
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_RESP_ICONS';
        --
        l_resp_type    VARCHAR2(1);
        l_error        t_error_out;
        l_handoff_type sys_config.value%TYPE;
        --
        l_icon_main_resp CONSTANT VARCHAR2(20) := 'MainRespIcon';
        l_icon_over_resp CONSTANT VARCHAR2(20) := 'OverallRespIcon';
        l_icon_epi_resp  CONSTANT VARCHAR2(20) := 'EpisodeRespIcon';
        --
        l_ret table_varchar := table_varchar();
        --
        FUNCTION get_curr_prof_cat RETURN category.flg_type%TYPE IS
        BEGIN
            IF g_resp_icons_prof_cat IS NULL
            THEN
                g_resp_icons_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
            END IF;
        
            RETURN g_resp_icons_prof_cat;
        END get_curr_prof_cat;
    BEGIN
        g_error := 'VERIFY EPIS';
        IF i_episode IS NOT NULL
        THEN
            g_error := 'GET HANDOFF TYPE';
            IF i_handoff_type IS NULL
            THEN
                pk_hand_off_core.get_hand_off_type(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   io_hand_off_type => l_handoff_type);
            ELSE
                l_handoff_type := i_handoff_type;
            END IF;
        
            IF l_handoff_type = pk_hand_off.g_handoff_multiple
               AND get_curr_prof_cat() = pk_alert_constant.g_cat_type_doc
            THEN
                g_error := 'GET PROF_RESP';
                IF NOT pk_hand_off_core.get_resp_type(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_episode       => i_episode,
                                                      i_professional  => i_prof.id,
                                                      i_hand_off_type => l_handoff_type,
                                                      o_type          => l_resp_type,
                                                      o_error         => l_error)
                THEN
                    g_error := 'GET PROF_RESP - ' || get_error_str(i_error => l_error);
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    RAISE pk_hand_off_core.g_resp_type_exception;
                END IF;
            
                g_error := 'SET RETURN VALUE';
                IF l_resp_type IS NOT NULL
                THEN
                    --if l_resp_type is not null means that the current professional is at least responsibly by the episode
                    l_ret := table_varchar();
                
                    IF l_resp_type = pk_hand_off_core.g_resp_type_m
                    THEN
                        --Current professional is the main responsible in all specialties
                        l_ret.extend();
                        l_ret(l_ret.count) := l_icon_main_resp;
                    ELSIF l_resp_type = pk_hand_off_core.g_resp_type_o
                    THEN
                        --Current professional has the overrall responsiblility
                        l_ret.extend();
                        l_ret(l_ret.count) := l_icon_over_resp;
                    ELSIF l_resp_type = pk_hand_off_core.g_resp_type_e
                    THEN
                        --Current professional is responsible by the episode
                        l_ret.extend();
                        l_ret(l_ret.count) := l_icon_epi_resp;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN pk_hand_off_core.g_resp_type_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN l_ret;
    END get_resp_icons;

    /**
    * Get responsability type description
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   i_handoff_type    Hand-off type
    *
    * @return                 Responsability type description
    *
    * @raises                 g_resp_type_exception Error when getting responsability type for the episode/i_prof
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_type_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_handoff_type   IN sys_config.value%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_RESP_TYPE_DESC';
        --
        l_code_msg_main_resp CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M029';
        l_code_msg_over_resp CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M030';
        l_code_msg_epis_resp CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M031';
        --
        l_type VARCHAR2(1);
        --
        l_ret_msg sys_message.desc_message%TYPE;
        l_error   t_error_out;
    BEGIN
        IF NOT pk_hand_off_core.get_resp_type(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_epis_prof_resp => i_epis_prof_resp,
                                              i_hand_off_type  => i_handoff_type,
                                              o_type           => l_type,
                                              o_error          => l_error)
        THEN
            g_error := 'GET PROF_RESP - ' || get_error_str(i_error => l_error);
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE pk_hand_off_core.g_resp_type_exception;
        END IF;
    
        g_error   := 'FILL RET MSG';
        l_ret_msg := CASE
                         WHEN l_type = pk_hand_off_core.g_resp_type_m THEN
                          pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_main_resp)
                         WHEN l_type = pk_hand_off_core.g_resp_type_o THEN
                          pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_over_resp)
                         WHEN l_type = pk_hand_off_core.g_resp_type_e THEN
                          pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_epis_resp)
                         ELSE
                          NULL
                     END;
    
        RETURN l_ret_msg;
    EXCEPTION
        WHEN pk_hand_off_core.g_resp_type_exception THEN
            RAISE;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_resp_type_desc;

    /**
    * Get profile template description
    *
    * @param   i_lang            Professional preferred language
    * @param   i_profile_template            Profile template
    *
    * @return                 Profile template description
    *
    *
    * @author  Ana Moita
    * @version v2.8.0.2
    * @since   30-09-2020
    */
    FUNCTION get_profile_template_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
    
        l_code_profile_template VARCHAR2(200);
        l_ret_msg               sys_message.desc_message%TYPE;
    
    BEGIN
        SELECT pt.code_profile_template
          INTO l_code_profile_template
          FROM profile_template pt
         WHERE pt.id_profile_template = i_profile_template;
    
        l_ret_msg := pk_message.get_message(i_lang, l_code_profile_template);
    
        RETURN l_ret_msg;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_profile_template_desc;

    /**
    * Get responsability grid
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_flg_hist        Get history responsability?
    * @param   i_flg_show        Professional category type to be returned
    * @param   i_flg_same_cat    Indicates if the grid should only contain professionals from the same category as the logged user. Default - No. (used with Y in check_prof_resp)
    * @param   o_grid            Responsability grid
    * @param   o_has_responsible 'Y' if o_grid cursor has values otherwise 'N'
    * @param   o_error           Error information
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @value   i_flg_show     {*} 'A' All
    *                         {*} 'D' Only physicians
    *                         {*} 'N' Only nurses
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_grid
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_hist        IN VARCHAR2,
        i_flg_show        IN VARCHAR2 DEFAULT pk_hand_off_core.g_cur_resp_grid_flg_show_a,
        i_flg_same_cat    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_grid            OUT pk_types.cursor_type,
        o_has_responsible OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_RESP_GRID';
        l_internal_error EXCEPTION;
        --
        l_domain_empr_flg_prof CONSTANT sys_domain.code_domain%TYPE := 'EPIS_MULTI_PROF_RESP.FLG_PROFILE';
        l_order_rank_0         CONSTANT PLS_INTEGER := 0;
        l_order_rank_1         CONSTANT PLS_INTEGER := 1;
        l_order_rank_2         CONSTANT PLS_INTEGER := 2;
        --
        l_hand_off_type sys_config.value%TYPE;
        l_tbl_epr       table_number;
        --
        l_has_permission_overall VARCHAR2(1 CHAR);
        l_req_overall_self       VARCHAR2(1 CHAR);
        l_req_overall_other      VARCHAR2(1 CHAR);
        l_id_speciality          speciality.id_speciality%TYPE;
        l_flg_profile            profile_template.flg_profile%TYPE;
        l_prof_cat               category.flg_type%TYPE;
        l_profile_template       profile_template.id_profile_template%TYPE;
        l_flg_type               epis_prof_resp.flg_type%TYPE;
        l_flg_mrp                profile_template.flg_mrp%TYPE;
    BEGIN
        g_error := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error         := 'GET PROF SPECIALITY';
        l_id_speciality := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof);
    
        g_error    := 'GET CATEGORY';
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error            := 'GET PROFESSIONAL PROFILE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'GET FLG_PROFILE';
        IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_profile_template => l_profile_template,
                                                o_flg_profile      => l_flg_profile,
                                                o_error            => o_error)
        THEN
            g_error := 'INTERNAL ERROR - ' || get_error_str(i_error => o_error);
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
        END IF;
    
        IF i_flg_show = pk_hand_off_core.g_cur_resp_grid_flg_show_a
        THEN
            -- If all records will be shown, set type as NULL.
            l_flg_type := NULL;
        ELSE
            l_flg_type := i_flg_show;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Don't check permissions to set overall responsability if type of transfer is not set
            IF l_flg_type IS NOT NULL
            THEN
                g_error := 'CHECK REQUEST PERMISSION (OVERALL)';
                IF NOT pk_hand_off_core.check_request_permission(i_lang                 => i_lang,
                                                                 i_prof                 => i_prof,
                                                                 i_id_episode           => i_episode,
                                                                 i_id_profile_templ_req => l_profile_template,
                                                                 i_prof_cat_req         => l_prof_cat,
                                                                 i_flg_type             => l_flg_type,
                                                                 i_flg_resp_type        => pk_hand_off_core.g_resp_overall,
                                                                 i_flg_profile          => l_flg_profile,
                                                                 i_hand_off_type        => l_hand_off_type,
                                                                 i_id_speciality        => l_id_speciality,
                                                                 o_full_permission      => l_has_permission_overall,
                                                                 o_req_to_self          => l_req_overall_self,
                                                                 o_req_to_other         => l_req_overall_other,
                                                                 o_error                => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
            l_flg_mrp := pk_prof_utils.get_flg_mrp(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_profile_template => l_profile_template);
        
            g_error := 'GET EPIS_PROF_RESP ID''s';
            SELECT epr.id_epis_prof_resp
              BULK COLLECT
              INTO l_tbl_epr
              FROM epis_prof_resp epr
              JOIN epis_multi_prof_resp empr
                ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
             WHERE epr.id_episode = i_episode
               AND ((i_flg_hist = pk_alert_constant.g_yes AND
                   epr.flg_status IN (pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_t)) OR
                   (i_flg_hist = pk_alert_constant.g_no AND epr.flg_status = pk_hand_off.g_hand_off_f))
               AND epr.flg_transf_type IN
                   (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_o, pk_hand_off.g_flg_transf_a)
               AND ((i_flg_hist = pk_alert_constant.g_no AND empr.flg_status = pk_hand_off_core.g_active) OR
                   i_flg_hist = pk_alert_constant.g_yes)
               AND (i_flg_show = pk_hand_off_core.g_cur_resp_grid_flg_show_a OR epr.flg_type = i_flg_show);
        
            -- "Multiple" hand-off: get all responsible professionals stored in EPIS_MULTI_PROF_RESP
            g_error := 'OPEN O_GRID (1)';
            OPEN o_grid FOR
                SELECT epr.id_epis_prof_resp,
                       empr.flg_resp_type,
                       pk_hand_off_core.get_resp_type_desc(i_lang, i_prof, empr.id_epis_prof_resp, l_hand_off_type) desc_resp_type,
                       pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                             i_prof,
                                                             epr.id_clinical_service_dest,
                                                             epr.id_department_dest,
                                                             empr.id_speciality) desc_spec,
                       empr.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, empr.id_professional) prof_name,
                       empr.flg_profile,
                       CASE
                            WHEN epr.id_profile_template IS NOT NULL THEN
                             pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                            ELSE
                             pk_sysdomain.get_domain(l_domain_empr_flg_prof, empr.flg_profile, i_lang)
                        END desc_profile,
                       decode(empr.flg_main_responsible,
                              pk_alert_constant.g_yes,
                              l_order_rank_0,
                              decode(empr.flg_resp_type, pk_hand_off_core.g_resp_overall, l_order_rank_1, l_order_rank_2)) rank_for_sorting,
                       pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_begin,
                       pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_begin,
                       pk_date_utils.dt_chr_tsz(i_lang, epr.dt_end_transfer_tstz, i_prof) date_end,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        epr.dt_end_transfer_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_end,
                       pk_hand_off_core.get_start_evt(i_lang, epr.flg_transfer, epr.id_prof_prev) start_evt,
                       pk_hand_off_core.get_end_evt(i_lang, epr.dt_end_transfer_tstz, epr.flg_status) end_evt,
                       epr.flg_type,
                       -- Set permissions for each request:
                       -- Cancel button
                       decode(l_flg_type,
                              NULL,
                              pk_alert_constant.g_no,
                              pk_hand_off_core.get_button_permission(i_lang,
                                                                     i_prof,
                                                                     pk_hand_off_core.g_button_cancel,
                                                                     epr.flg_status,
                                                                     epr.id_prof_req,
                                                                     epr.id_prof_to,
                                                                     epr.id_prof_comp,
                                                                     empr.flg_profile,
                                                                     l_flg_profile,
                                                                     l_flg_type,
                                                                     l_prof_cat,
                                                                     l_hand_off_type,
                                                                     empr.id_speciality,
                                                                     l_id_speciality,
                                                                     epr.id_episode,
                                                                     empr.flg_main_responsible)) flg_cancel,
                       -- OK button
                       decode(l_flg_type,
                              NULL,
                              pk_alert_constant.g_no,
                              pk_hand_off_core.get_button_permission(i_lang,
                                                                     i_prof,
                                                                     pk_hand_off_core.g_button_ok,
                                                                     epr.flg_status,
                                                                     epr.id_prof_req,
                                                                     epr.id_prof_to,
                                                                     epr.id_prof_comp,
                                                                     empr.flg_profile,
                                                                     l_flg_profile,
                                                                     l_flg_type,
                                                                     l_prof_cat,
                                                                     l_hand_off_type,
                                                                     empr.id_speciality,
                                                                     l_id_speciality,
                                                                     epr.id_episode,
                                                                     empr.flg_main_responsible)) flg_ok,
                       -- Action TRANSFER RESPONSABILITY
                       decode(epr.flg_status,
                               pk_hand_off.g_hand_off_f,
                               decode(epr.id_prof_comp,
                                       i_prof.id,
                                       -- If it's a main responsible, the professional can only transfer responsability after
                                     -- assign another main responsible.
                                     decode(empr.flg_main_responsible,
                                            pk_alert_constant.g_yes,
                                            pk_alert_constant.g_no,
                                            pk_alert_constant.g_yes),
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_action_transfer,
                       -- Action TERMINATE RESPONSABILITY
                       decode(epr.flg_status,
                               pk_hand_off.g_hand_off_f,
                               decode(epr.id_prof_comp,
                                       i_prof.id,
                                       -- If it's a main responsible, the professional can only terminate responsability after
                                     -- assign another main responsible.
                                     decode(empr.flg_main_responsible,
                                            pk_alert_constant.g_yes,
                                            pk_alert_constant.g_no,
                                            pk_alert_constant.g_yes),
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_action_terminate,
                       -- Action SET MAIN RESPONSIBLE
                       -- Only allowed for OVERALL responsability, for professionals with permission to make such requests,
                       --  and with the possibility to assign specialists that aren't MAIN responsibles.
                       decode(epr.flg_status,
                              pk_hand_off.g_hand_off_f,
                              decode(epr.flg_transf_type,
                                     g_resp_overall,
                                     decode(l_flg_mrp,
                                            pk_alert_constant.g_yes,
                                            decode(l_has_permission_overall,
                                                   pk_alert_constant.g_yes,
                                                   decode(empr.flg_main_responsible,
                                                          pk_alert_constant.g_no,
                                                          decode(pk_prof_utils.get_flg_mrp(i_lang,
                                                                                           profissional(empr.id_professional,
                                                                                                        i_prof.institution,
                                                                                                        i_prof.software),
                                                                                           NULL),
                                                                 pk_alert_constant.g_yes,
                                                                 l_req_overall_other,
                                                                 pk_alert_constant.g_no),
                                                          pk_alert_constant.g_no),
                                                   pk_alert_constant.g_no),
                                            pk_alert_constant.g_no),
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_action_set_main,
                       decode(empr.id_speciality,
                              pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof),
                              decode(empr.flg_resp_type, g_resp_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_same_category
                  FROM epis_prof_resp epr
                  JOIN epis_multi_prof_resp empr
                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                 WHERE epr.id_epis_prof_resp IN (SELECT column_value id_epis_prof_resp
                                                   FROM TABLE(l_tbl_epr))
                   AND epr.flg_status != pk_hand_off.g_hand_off_c --ALERT-189901 - Cancelled responsibility records shouldn't appear in the responsibility history
                   AND ((pk_prof_utils.get_id_category(i_lang => i_lang,
                                                       i_prof => profissional(empr.id_professional,
                                                                              i_prof.institution,
                                                                              i_prof.software)) =
                       pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof) AND
                       i_flg_same_cat = pk_alert_constant.g_yes) OR (i_flg_same_cat = pk_alert_constant.g_no) OR
                       (pk_prof_utils.get_id_category(i_lang => i_lang,
                                                       i_prof => profissional(empr.id_professional,
                                                                              i_prof.institution,
                                                                              i_prof.software)) IN
                       (g_prof_id_category_physician, g_prof_id_category_midwife) AND
                       pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof) IN
                       (g_prof_id_category_physician, g_prof_id_category_midwife)))
                 ORDER BY rank_for_sorting, epr.dt_comp_tstz DESC, prof_name ASC;
        ELSE
            g_error := 'GET EPIS_PROF_RESP ID''s';
            SELECT t2.id_epis_prof_resp
              BULK COLLECT
              INTO l_tbl_epr
              FROM (SELECT t.id_epis_prof_resp
                      FROM (SELECT epr.id_epis_prof_resp, row_number() over(ORDER BY epr.dt_comp_tstz DESC) line_number
                              FROM epis_prof_resp epr
                              JOIN prof_cat pc
                                ON pc.id_professional = epr.id_prof_comp
                               AND pc.id_institution = i_prof.institution
                              JOIN category c
                                ON c.id_category = pc.id_category
                             WHERE epr.id_episode = i_episode
                               AND ((i_flg_hist = pk_alert_constant.g_no AND
                                   epr.id_prof_comp = (SELECT ei.id_professional
                                                           FROM epis_info ei
                                                          WHERE ei.id_episode = i_episode)) OR
                                   i_flg_hist = pk_alert_constant.g_yes)
                               AND (i_flg_show = pk_hand_off_core.g_cur_resp_grid_flg_show_a OR c.flg_type = i_flg_show)) t
                     WHERE ((t.line_number = g_dft_line_number AND i_flg_hist = pk_alert_constant.g_no) OR
                           i_flg_hist = pk_alert_constant.g_yes)
                    UNION ALL
                    SELECT t.id_epis_prof_resp
                      FROM (SELECT epr.id_epis_prof_resp, row_number() over(ORDER BY epr.dt_comp_tstz DESC) line_number
                              FROM epis_prof_resp epr
                              JOIN prof_cat pc
                                ON pc.id_professional = epr.id_prof_comp
                               AND pc.id_institution = i_prof.institution
                              JOIN category c
                                ON c.id_category = pc.id_category
                             WHERE epr.id_episode = i_episode
                               AND ((i_flg_hist = pk_alert_constant.g_no AND
                                   epr.id_prof_comp = (SELECT ei.id_first_nurse_resp id_professional
                                                           FROM epis_info ei
                                                          WHERE ei.id_episode = i_episode)) OR
                                   i_flg_hist = pk_alert_constant.g_yes)
                               AND (i_flg_show = pk_hand_off_core.g_cur_resp_grid_flg_show_a OR c.flg_type = i_flg_show)) t
                     WHERE ((t.line_number = g_dft_line_number AND i_flg_hist = pk_alert_constant.g_no) OR
                           i_flg_hist = pk_alert_constant.g_yes)) t2;
        
            g_error := 'OPEN O_GRID (2)';
            OPEN o_grid FOR
                SELECT epr.id_epis_prof_resp,
                       g_empty_str flg_resp_type,
                       g_empty_str desc_resp_type,
                       pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                             i_prof,
                                                             epr.id_clinical_service_dest,
                                                             epr.id_department_dest,
                                                             (SELECT p.id_speciality
                                                                FROM professional p
                                                               WHERE p.id_professional = epr.id_prof_comp)) desc_spec,
                       epr.id_prof_comp,
                       epr.id_prof_comp id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(epr.id_prof_to, epr.id_prof_comp)) prof_name,
                       g_empty_str flg_profile,
                       CASE
                            WHEN epr.id_profile_template IS NOT NULL THEN
                             pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                            ELSE
                             pk_prof_utils.get_desc_category(i_lang, i_prof, epr.id_prof_comp, pc.id_institution)
                        END desc_profile,
                       decode(c.flg_type, pk_alert_constant.g_cat_type_doc, l_order_rank_0, l_order_rank_1) rank_for_sorting,
                       pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_begin,
                       pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_begin,
                       pk_date_utils.dt_chr_tsz(i_lang, epr.dt_end_transfer_tstz, i_prof) date_end,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        epr.dt_end_transfer_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_end,
                       pk_hand_off_core.get_start_evt(i_lang, epr.flg_transfer, epr.id_prof_prev) start_evt,
                       pk_hand_off_core.get_end_evt(i_lang, epr.dt_end_transfer_tstz, epr.flg_status) end_evt,
                       epr.flg_type,
                       -- Set permissions for each request:
                       -- Cancel button
                       decode(l_flg_type,
                              NULL,
                              pk_alert_constant.g_no,
                              pk_hand_off_core.get_button_permission(i_lang,
                                                                     i_prof,
                                                                     pk_hand_off_core.g_button_cancel,
                                                                     epr.flg_status,
                                                                     epr.id_prof_req,
                                                                     epr.id_prof_to,
                                                                     epr.id_prof_comp,
                                                                     NULL,
                                                                     l_flg_profile,
                                                                     l_flg_type,
                                                                     l_prof_cat,
                                                                     l_hand_off_type,
                                                                     NULL,
                                                                     l_id_speciality,
                                                                     epr.id_episode,
                                                                     NULL)) flg_cancel,
                       -- OK button
                       decode(l_flg_type,
                              NULL,
                              pk_alert_constant.g_no,
                              pk_hand_off_core.get_button_permission(i_lang,
                                                                     i_prof,
                                                                     pk_hand_off_core.g_button_ok,
                                                                     epr.flg_status,
                                                                     epr.id_prof_req,
                                                                     epr.id_prof_to,
                                                                     epr.id_prof_comp,
                                                                     NULL,
                                                                     l_flg_profile,
                                                                     l_flg_type,
                                                                     l_prof_cat,
                                                                     l_hand_off_type,
                                                                     NULL,
                                                                     l_id_speciality,
                                                                     epr.id_episode,
                                                                     NULL)) flg_ok,
                       -- Action TRANSFER RESPONSABILITY
                       decode(epr.flg_status,
                              pk_hand_off.g_hand_off_f,
                              decode(epr.id_prof_comp,
                                     i_prof.id,
                                     decode((SELECT COUNT(*)
                                              FROM epis_prof_resp epr2
                                             WHERE epr2.id_episode = epr.id_episode
                                               AND epr2.flg_status = pk_hand_off.g_hand_off_r),
                                            0,
                                            pk_alert_constant.g_yes,
                                            pk_alert_constant.g_no),
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_action_transfer,
                       -- Action TERMINATE RESPONSABILITY
                       decode(epr.flg_status,
                              pk_hand_off.g_hand_off_f,
                              decode(epr.id_prof_comp, i_prof.id, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_action_terminate,
                       -- Action SET MAIN RESPONSIBLE: Not available for this type of hand-off
                       pk_alert_constant.g_no flg_action_set_main,
                       decode(epr.id_speciality,
                              pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof),
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) flg_same_category
                  FROM epis_prof_resp epr
                  JOIN prof_cat pc
                    ON pc.id_professional = epr.id_prof_comp
                   AND pc.id_institution = i_prof.institution
                  JOIN category c
                    ON c.id_category = pc.id_category
                 WHERE epr.id_epis_prof_resp IN (SELECT column_value id_epis_prof_resp
                                                   FROM TABLE(l_tbl_epr))
                   AND ((i_flg_hist = pk_alert_constant.g_no AND epr.flg_status != pk_hand_off.g_hand_off_c) OR
                       i_flg_hist = pk_alert_constant.g_yes)
                   AND epr.flg_status != pk_hand_off.g_hand_off_c --ALERT-189901 - Cancelled responsibility records shouldn't appear in the responsibility history
                   AND ((pk_prof_utils.get_id_category(i_lang => i_lang,
                                                       i_prof => profissional(epr.id_prof_comp,
                                                                              i_prof.institution,
                                                                              i_prof.software)) =
                       pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof) AND
                       i_flg_same_cat = pk_alert_constant.g_yes) OR (i_flg_same_cat = pk_alert_constant.g_no) OR
                       (pk_prof_utils.get_id_category(i_lang => i_lang,
                                                       i_prof => profissional(epr.id_prof_comp,
                                                                              i_prof.institution,
                                                                              i_prof.software)) IN
                       (g_prof_id_category_physician, g_prof_id_category_midwife) AND
                       pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof) IN
                       (g_prof_id_category_physician, g_prof_id_category_midwife)))
                 ORDER BY rank_for_sorting, epr.dt_comp_tstz DESC, prof_name ASC;
        END IF;
    
        o_has_responsible := CASE
                                 WHEN l_tbl_epr IS NOT NULL
                                      AND l_tbl_epr.count > 0 THEN
                                  pk_alert_constant.g_yes
                                 ELSE
                                  pk_alert_constant.g_no
                             END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_resp_grid;

    /**
    * Get current responsability grid
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_flg_show        Professional category type to be returned
    * @param   o_grid            Current Responsability grid
    * @param   o_has_responsible 'Y' if o_grid cursor has values otherwise 'N'
    * @param   o_error           Error information
    *
    * @value   i_flg_show     {*} 'A' All
    *                         {*} 'D' Only physicians
    *                         {*} 'N' Only nurses
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_current_resp_grid
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_show        IN VARCHAR2 DEFAULT 'A',
        o_grid            OUT pk_types.cursor_type,
        o_has_responsible OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_CURRENT_RESP_GRID';
    BEGIN
        g_error := 'GET RESP_GRID';
        IF NOT get_resp_grid(i_lang            => i_lang,
                             i_prof            => i_prof,
                             i_episode         => i_episode,
                             i_flg_hist        => pk_alert_constant.g_no,
                             i_flg_show        => i_flg_show,
                             i_flg_same_cat    => pk_alert_constant.g_yes,
                             o_grid            => o_grid,
                             o_has_responsible => o_has_responsible,
                             o_error           => o_error)
        THEN
            g_error := 'ERROR ON GET_RESP_GRID - ' || get_error_str(i_error => o_error);
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE pk_hand_off.g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_current_resp_grid;

    /**
    * Get current responsability grid
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_flg_show        Professional category type to be returned
    * @param   o_grid            Current Responsability grid
    * @param   o_error           Error information
    *
    * @value   i_flg_show     {*} 'A' All
    *                         {*} 'P' Only physicians
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_hist_resp_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_show IN VARCHAR2 DEFAULT 'A',
        o_grid     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_HIST_RESP_GRID';
        --
        l_has_responsible VARCHAR2(1);
    BEGIN
        g_error := 'GET RESP_GRID';
        IF NOT get_resp_grid(i_lang            => i_lang,
                             i_prof            => i_prof,
                             i_episode         => i_episode,
                             i_flg_hist        => pk_alert_constant.g_yes,
                             i_flg_show        => i_flg_show,
                             o_grid            => o_grid,
                             o_has_responsible => l_has_responsible,
                             o_error           => o_error)
        THEN
            g_error := 'ERROR ON GET_RESP_GRID - ' || get_error_str(i_error => o_error);
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE pk_hand_off.g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_hist_resp_grid;

    /**
    * Gets previous responsible professional
    *
    * @param   i_episode              Episode id
    * @param   i_curr_epis_prof_resp  Current id_epis_prof_resp
    * @param   i_curr_dt_comp         Current dt_comp_tstz
    * @param   i_curr_flg_type        Current flg_type
    * @param   i_flg_profile          Multi_Prof flg_profile
    * @param   i_hand_off_type        Hand off type
    *
    * @return                 Previous id_epis_prof_resp
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_prev_resp
    (
        i_episode             IN episode.id_episode%TYPE,
        i_curr_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_curr_dt_comp        IN epis_prof_resp.dt_comp_tstz%TYPE,
        i_curr_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile         IN epis_multi_prof_resp.flg_profile%TYPE,
        i_hand_off_type       IN sys_config.value%TYPE
    ) RETURN epis_prof_resp.id_epis_prof_resp%TYPE IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_PREV_RESP';
        --
        l_epis_prof_resp epis_prof_resp.id_epis_prof_resp%TYPE;
    BEGIN
        <<previous_responsible>>
        BEGIN
            g_error := 'GET PREVIOUS_RESP';
            SELECT epis_pr.id_epis_prof_resp
              INTO l_epis_prof_resp
              FROM (SELECT ep.id_epis_prof_resp, row_number() over(ORDER BY ep.dt_comp_tstz DESC) line_number
                      FROM epis_prof_resp ep
                     WHERE ep.id_episode = i_episode
                       AND ep.id_epis_prof_resp != i_curr_epis_prof_resp
                       AND ep.dt_comp_tstz < i_curr_dt_comp
                       AND ep.flg_status = pk_hand_off.g_hand_off_f
                       AND ep.flg_type = i_curr_flg_type
                       AND ep.flg_transf_type IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_a)
                       AND ((i_hand_off_type = pk_hand_off.g_handoff_multiple AND
                           ep.id_epis_prof_resp IN (SELECT empr.id_epis_prof_resp
                                                        FROM epis_multi_prof_resp empr
                                                       WHERE empr.id_episode = ep.id_episode
                                                         AND empr.flg_profile = i_flg_profile)) OR
                           i_hand_off_type = pk_hand_off.g_handoff_normal)) epis_pr
             WHERE epis_pr.line_number <= g_dft_line_number;
        EXCEPTION
            WHEN no_data_found THEN
                g_error          := 'PREVIOUS_RESP NOT FOUND';
                l_epis_prof_resp := NULL;
        END previous_responsible;
    
        RETURN l_epis_prof_resp;
    END get_prev_resp;

    /**
    * Get message type (Used on history grid)
    *
    * @param   i_prof_prev    Previous responsible professional
    * @param   i_prof_comp    Current responsible professional
    * @param   i_dt_request   Request date
    * @param   i_flg_transfer Transfer?
    *
    * @return                 Previous id_epis_prof_resp
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_msg_type
    (
        i_prof_prev    IN epis_prof_resp.id_prof_prev%TYPE,
        i_prof_comp    IN epis_prof_resp.id_prof_comp%TYPE,
        i_dt_request   IN epis_prof_resp.dt_request_tstz%TYPE,
        i_flg_transfer IN epis_prof_resp.flg_transfer%TYPE,
        i_flg_status   IN VARCHAR2 DEFAULT NULL --, I_DT_END_TRANSF IN EPIS_PROF_RESP.DT_END_TRANSFER_TSTZ%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_MSG_TYPE';
        --
        --l_one CONSTANT PLS_INTEGER := 1;
        --
        l_msg_type VARCHAR2(1);
    BEGIN
        g_error := 'GET MSG_TYPE';
        SELECT CASE
                   WHEN i_prof_prev IS NULL
                        AND i_flg_status IS NULL THEN
                    pk_hand_off_core.g_msg_type_b
                   WHEN i_prof_prev IS NULL
                        AND i_flg_status IN ('T', 'F') THEN
                    i_flg_status
                   WHEN i_flg_transfer = pk_alert_constant.g_no
                        AND i_flg_status IS NOT NULL THEN
                    i_flg_status
                   WHEN i_flg_transfer = pk_alert_constant.g_yes
                   /*
                     OR EXISTS (SELECT l_one
                        FROM epis_prof_resp epr2
                       WHERE epr2.flg_transfer = pk_alert_constant.g_yes
                         AND epr2.dt_cancel_tstz = i_dt_request
                         AND epr2.id_prof_cancel = i_prof_comp)
                   */
                    THEN
                    CASE
                        WHEN i_flg_status != 'R' THEN
                         'F'
                        ELSE
                         'R'
                    END
               
                   ELSE
                    pk_hand_off_core.g_msg_type_s
               END
          INTO l_msg_type
          FROM dual;
    
        RETURN l_msg_type;
    END get_msg_type;

    /**
    * Gets responsability history
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   o_resp_hist       Responsability history grid
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_epis_prof_resp_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_resp_hist      OUT pk_types.cursor_type,
        o_sbar_note      OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_EPIS_PROF_RESP_HIST';
        --
        l_msg_opn_m001  sys_message.desc_message%TYPE;
        l_msg_hoff_m003 sys_message.desc_message%TYPE;
        l_msg_hoff_m004 sys_message.desc_message%TYPE;
        l_msg_hoff_m005 sys_message.desc_message%TYPE;
        l_msg_hoff_m006 sys_message.desc_message%TYPE;
        --
        l_code_msg_hoff_m036 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M036'; --Beginning of responsability
        l_msg_hoff_m036 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m055 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M055'; --Transfer of responsibility
        l_msg_hoff_m055 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m056 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M056'; --Responsibility shift
        l_msg_hoff_m056 sys_message.desc_message%TYPE;
        --
        l_tbl_epr       table_number;
        l_hand_off_type sys_config.value%TYPE;
        l_flg_resp_type epis_multi_prof_resp.flg_resp_type%TYPE;
        l_spec          epis_multi_prof_resp.id_speciality%TYPE;
        l_flg_profile   epis_multi_prof_resp.flg_profile%TYPE;
        l_episode       epis_prof_resp.id_episode%TYPE;
        l_flg_type      epis_prof_resp.flg_type%TYPE;
        l_dt_comp       epis_prof_resp.dt_comp_tstz%TYPE;
        --
        l_sbar_note sys_config.value%TYPE;
    BEGIN
        g_error     := 'GET SBAR CONFIG';
        l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        g_error        := 'GET SYS_MESSAGES';
        l_msg_opn_m001 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_opn_m001);
    
        l_msg_hoff_m003 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m003);
        l_msg_hoff_m004 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m004);
        l_msg_hoff_m005 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m005);
        l_msg_hoff_m006 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m006);
    
        l_msg_hoff_m036 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m036);
        l_msg_hoff_m055 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m055);
        l_msg_hoff_m056 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m056);
    
        g_error := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        <<get_group_vars>>
        BEGIN
            IF l_hand_off_type = pk_hand_off.g_handoff_multiple
            THEN
                g_error := 'GET GROUP BY VARS - MULTI_RESP';
                SELECT empr.id_episode,
                       empr.flg_resp_type,
                       empr.id_speciality,
                       empr.flg_profile,
                       epr.flg_type,
                       epr.dt_comp_tstz
                  INTO l_episode, l_flg_resp_type, l_spec, l_flg_profile, l_flg_type, l_dt_comp
                  FROM epis_multi_prof_resp empr
                  JOIN epis_prof_resp epr
                    ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
                 WHERE empr.id_epis_prof_resp = i_epis_prof_resp;
            ELSE
                g_error := 'GET GROUP BY VARS - SINGLE_RESP';
                SELECT epr.id_episode,
                       pk_hand_off_core.get_resp_type(i_lang,
                                                      i_prof,
                                                      epr.id_episode,
                                                      epr.id_prof_comp,
                                                      epr.id_epis_prof_resp) flg_resp_type,
                       p.id_speciality,
                       NULL,
                       epr.flg_type,
                       epr.dt_comp_tstz
                  INTO l_episode, l_flg_resp_type, l_spec, l_flg_profile, l_flg_type, l_dt_comp
                  FROM epis_prof_resp epr
                  JOIN professional p
                    ON p.id_professional = epr.id_prof_comp
                 WHERE epr.id_epis_prof_resp = i_epis_prof_resp;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'NO_DATA_FOUND FOR ID_EPIS_PROF_RESP: ' || i_epis_prof_resp || '; HAND_OFF_TYPE: ' ||
                           l_hand_off_type;
                alertlog.pk_alertlog.log_warn(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                l_episode       := NULL;
                l_flg_resp_type := NULL;
                l_spec          := NULL;
                l_flg_profile   := NULL;
        END get_group_vars;
    
        g_error := 'GET ALL ID_EPIS_PROF_RESP';
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            SELECT empr.id_epis_prof_resp
              BULK COLLECT
              INTO l_tbl_epr
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_episode = l_episode
               AND empr.flg_resp_type = l_flg_resp_type
               AND (empr.id_speciality = l_spec OR epr.flg_type = pk_alert_constant.g_cat_type_nurse)
               AND empr.flg_profile = l_flg_profile
               AND epr.flg_status != pk_hand_off.g_hand_off_x
               AND epr.flg_transf_type IN
                   (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_o, pk_hand_off.g_flg_transf_a);
        ELSE
            SELECT epr.id_epis_prof_resp
              BULK COLLECT
              INTO l_tbl_epr
              FROM epis_prof_resp epr
              JOIN professional p
                ON p.id_professional = epr.id_prof_comp
             WHERE epr.id_episode = l_episode
               AND epr.flg_status != pk_hand_off.g_hand_off_x
               AND epr.flg_type = l_flg_type
               AND epr.flg_transf_type IN
                   (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_o, pk_hand_off.g_flg_transf_a);
        END IF;
    
        g_error := 'OPEN O_RESP_HIST CURSOR - SINGLE_RESP';
        OPEN o_resp_hist FOR
            SELECT epr.id_epis_prof_resp,
                   epr.id_prof_req,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req)) name_prof_req,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          NULL,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           epr.id_prof_req,
                                                           epr.dt_request_tstz,
                                                           epr.id_episode)) desc_spec_r,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          NULL,
                          pk_translation.get_translation_dtchk(i_lang,
                                                               g_code_trans_clin_serv || epr.id_clinical_service_orig)) desc_clinsrv_r,
                   decode(epr.id_prof_prev,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, resp_prev.id_prof_comp),
                          pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_prev)) name_prof_prev,
                   decode(epr.id_prof_prev,
                          NULL,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           resp_prev.id_prof_comp,
                                                           resp_prev.dt_request_tstz,
                                                           resp_prev.id_episode),
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           epr.id_prof_prev,
                                                           epr.dt_request_tstz,
                                                           epr.id_episode)) desc_spec_prev,
                   pk_hand_off_core.get_cs_dep_spec_label(i_lang,
                                                          i_prof,
                                                          epr.id_clinical_service_orig,
                                                          epr.id_department_orig,
                                                          pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                                               profissional(epr.id_prof_req,
                                                                                                            i_prof.institution,
                                                                                                            i_prof.software)),
                                                          l_hand_off_type,
                                                          pk_prof_utils.get_category(i_lang,
                                                                                     profissional(epr.id_prof_req,
                                                                                                  i_prof.institution,
                                                                                                  i_prof.software))) label_orig,
                   pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                         i_prof,
                                                         epr.id_clinical_service_dest,
                                                         epr.id_department_dest,
                                                         pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                                              profissional(epr.id_prof_req,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software))) desc_orig,
                   epr.id_prof_to,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to), l_msg_opn_m001) name_prof_to,
                   pk_hand_off_core.get_cs_dep_spec_label(i_lang,
                                                          i_prof,
                                                          epr.id_clinical_service_dest,
                                                          epr.id_department_dest,
                                                          empr.id_speciality,
                                                          l_hand_off_type,
                                                          pk_prof_utils.get_category(i_lang,
                                                                                     profissional(epr.id_prof_to,
                                                                                                  i_prof.institution,
                                                                                                  i_prof.software))) label_dest_t,
                   pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                         i_prof,
                                                         epr.id_clinical_service_dest,
                                                         epr.id_department_dest,
                                                         empr.id_speciality) desc_dest_t,
                   epr.id_clinical_service_dest,
                   epr.id_department_dest,
                   epr.id_prof_comp,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, epr.id_prof_comp, epr.dt_comp_tstz, epr.id_episode) desc_spec_comp,
                   epr.flg_status,
                   decode(epr.flg_status,
                          pk_hand_off.g_hand_off_r,
                          l_msg_hoff_m003,
                          pk_hand_off.g_hand_off_f,
                          l_msg_hoff_m004,
                          pk_hand_off.g_hand_off_d,
                          l_msg_hoff_m005,
                          l_msg_hoff_m006) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_decline_tstz, i_prof) date_target_d,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_decline_tstz, i_prof.institution, i_prof.software) hour_target_d,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_cancel_tstz, i_prof) date_target_c,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_c,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_target_comp,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_target_comp,
                   epr.notes_clob notes,
                   epr.notes_cancel,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) desc_cancel_reason,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_cancel) name_prof_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_decline) name_prof_decline,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(epr.id_prof_comp, epr.id_prof_to),
                                                    decode(epr.id_prof_comp, NULL, epr.dt_request_tstz, epr.dt_comp_tstz),
                                                    epr.id_episode) desc_spec_to,
                   CASE
                        WHEN epr.id_profile_template IS NOT NULL THEN
                         pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                        ELSE
                         pk_hand_off_core.get_desc_category(i_lang,
                                                            i_prof,
                                                            l_hand_off_type,
                                                            nvl(epr.id_prof_comp, epr.id_prof_to),
                                                            pk_hand_off_core.g_prof_type_to,
                                                            empr.flg_profile,
                                                            epr.flg_type)
                    END desc_cat_to,
                   pk_hand_off_core.get_desc_category(i_lang,
                                                      i_prof,
                                                      l_hand_off_type,
                                                      epr.id_prof_req,
                                                      pk_hand_off_core.g_prof_type_req,
                                                      empr.flg_profile,
                                                      epr.flg_type) desc_cat_req,
                   CASE
                        WHEN epr.id_profile_template IS NOT NULL THEN
                         pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                        ELSE
                         pk_hand_off_core.get_desc_category(i_lang,
                                                            i_prof,
                                                            l_hand_off_type,
                                                            epr.id_prof_comp,
                                                            pk_hand_off_core.g_prof_type_to,
                                                            empr.flg_profile,
                                                            epr.flg_type)
                    END desc_cat_comp,
                   empr.flg_resp_type,
                   decode(empr.flg_resp_type,
                          NULL,
                          NULL,
                          pk_hand_off_core.get_resp_type_desc(i_lang, i_prof, empr.id_epis_prof_resp, l_hand_off_type)) desc_resp_type,
                   pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                 epr.id_prof_comp,
                                                 epr.dt_request_tstz,
                                                 epr.flg_transfer) flg_msg_title,
                   decode(pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                        epr.id_prof_comp,
                                                        epr.dt_request_tstz,
                                                        epr.flg_transfer),
                          pk_hand_off_core.g_msg_type_b,
                          l_msg_hoff_m036,
                          pk_hand_off_core.g_msg_type_t,
                          l_msg_hoff_m055,
                          l_msg_hoff_m056) msg_title,
                   CASE l_sbar_note
                       WHEN pk_alert_constant.g_yes THEN
                        epr.sbar_notes
                       ELSE
                        NULL
                   END sbar_note
              FROM epis_prof_resp epr
              LEFT JOIN epis_prof_resp resp_prev
                ON resp_prev.id_epis_prof_resp =
                   pk_hand_off_core.get_prev_resp(epr.id_episode,
                                                  epr.id_epis_prof_resp,
                                                  nvl(epr.dt_comp_tstz, epr.dt_request_tstz),
                                                  epr.flg_type,
                                                  l_flg_profile,
                                                  l_hand_off_type)
              LEFT JOIN epis_multi_prof_resp empr
                ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
             WHERE epr.id_epis_prof_resp IN (SELECT column_value id_epis_prof_resp
                                               FROM TABLE(l_tbl_epr))
             ORDER BY epr.dt_request_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_resp_hist);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_prof_resp_hist;

    /**
    * Checks if current episode has and needs a overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   o_flg_show_error  Is or isn't to show error message
    * @param   o_error_title     Error title
    * @param   o_error_message   Error message
    * @param   o_error           Error information
    *
    * @value   o_flg_show_error  {*} 'Y' Yes
    *                            {*} 'N' No
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION check_overall_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_flg_show_error OUT VARCHAR2,
        o_error_title    OUT sys_message.desc_message%TYPE,
        o_error_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_OVERALL_RESPONSIBLE';
        --
        l_code_msg_err_title CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_T049';
        l_code_msg_err_msg   CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M058';
        l_sys_conf_overall   CONSTANT sys_config.id_sys_config%TYPE := 'HAND_OFF_OVERALL_TO_DISCHARGE';
        l_val_conf_overall sys_config.value%TYPE;
        --
        l_hand_off_type sys_config.value%TYPE;
        l_overall_prof  epis_info.id_professional%TYPE;
    BEGIN
        g_error          := 'INITIALIZE VAR';
        o_flg_show_error := pk_alert_constant.g_no;
    
        g_error := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error            := 'GET CONF - ' || l_sys_conf_overall;
            l_val_conf_overall := pk_sysconfig.get_config(i_code_cf => l_sys_conf_overall, i_prof => i_prof);
        
            IF l_val_conf_overall = pk_alert_constant.g_yes
            THEN
                <<get_overall_prof>>
                BEGIN
                    g_error := 'GET OVERALL PROF';
                    SELECT empr.id_professional
                      INTO l_overall_prof
                      FROM epis_multi_prof_resp empr
                     WHERE empr.id_episode = i_episode
                       AND empr.flg_status = g_active
                       AND empr.flg_profile = g_specialist
                       AND empr.flg_resp_type = g_resp_overall
                       AND empr.flg_main_responsible = pk_alert_constant.g_yes;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_overall_prof := NULL;
                END get_overall_prof;
            
                IF l_overall_prof IS NULL
                THEN
                    g_error := 'EPISODE ' || i_episode || ' HAS''NT OVERALL PROF';
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    o_error_title    := pk_message.get_message(i_lang, l_code_msg_err_title);
                    o_error_message  := pk_message.get_message(i_lang, l_code_msg_err_msg);
                    o_flg_show_error := pk_alert_constant.g_yes;
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
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_overall_responsible;

    /**
    * Gets the available tabs when selecting the overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_patient         Patient id
    * @param   o_tabs            Available tabs
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_overall_resp_tabs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_tabs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_OVERALL_RESP_TABS';
        --
        --l_sys_cfg_show_dbc CONSTANT sys_config.id_sys_config%TYPE := 'MULTIPLE_HAND_OFF_SHOW_DBC_OWNERS';
        l_sys_val_show_dbc sys_config.id_sys_config%TYPE;
        --
        l_code_msg_m060 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M060'; --On call physicians
        l_code_msg_m061 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M061'; --Previous responsibles
        l_code_msg_m062 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M062'; --All specialists
        --
        l_rank_0 CONSTANT PLS_INTEGER := 10;
        l_rank_1 CONSTANT PLS_INTEGER := 20;
        l_rank_2 CONSTANT PLS_INTEGER := 30;
        --
        l_msg_m060 sys_message.desc_message%TYPE;
        l_msg_m061 sys_message.desc_message%TYPE;
        l_msg_m062 sys_message.desc_message%TYPE;
        --
        l_prof_cat        category.flg_type%TYPE;
        l_handoff_type    sys_config.value%TYPE;
        l_total_prev_resp PLS_INTEGER;
    BEGIN
        g_error := 'GET CONF';
        --For now the show dbc tab is going to be replace by previous responsibles tab which is to be shown always
        --l_sys_val_show_dbc := pk_sysconfig.get_config(i_code_cf => l_sys_cfg_show_dbc, i_prof => i_prof);
        l_sys_val_show_dbc := pk_alert_constant.g_yes;
    
        g_error := 'GET MESSAGES';
        IF i_prof.software = pk_alert_constant.g_soft_edis
        THEN
            l_msg_m060 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_m060);
        END IF;
        IF l_sys_val_show_dbc = pk_alert_constant.g_yes
        THEN
            l_msg_m061 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_m061);
        END IF;
        l_msg_m062 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_m062);
    
        g_error    := 'GET PROF CAT';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error           := 'GET TOTAL PREVIOUS RESPONSIBLES';
        l_total_prev_resp := get_pat_profs_int(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode, i_patient => i_patient, i_prof_cat => l_prof_cat, i_handoff_type => l_handoff_type).count;
    
        g_error := 'OPEN O_TABS';
        OPEN o_tabs FOR
            SELECT t.flg_tab, t.desc_tab, t.total_rows
              FROM (SELECT pk_hand_off_core.g_overall_tab_oncall flg_tab,
                           l_msg_m060 desc_tab,
                           l_rank_0 rank,
                           pk_hand_off_core.get_handoff_oncall_profs_count(i_lang, i_prof, i_episode) total_rows
                      FROM dual
                     WHERE i_prof.software = pk_alert_constant.g_soft_edis
                    UNION ALL
                    SELECT pk_hand_off_core.g_overall_tab_prev flg_tab,
                           l_msg_m061                          desc_tab,
                           l_rank_1                            rank,
                           l_total_prev_resp                   total_rows
                      FROM dual
                     WHERE l_sys_val_show_dbc = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT pk_hand_off_core.g_overall_tab_spec flg_tab, l_msg_m062 desc_tab, l_rank_2 rank, 0 total_rows
                      FROM dual) t
             ORDER BY t.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_tabs);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_overall_resp_tabs;

    /**********************************************************************************************
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_all
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_PROF_RESP_ALL';
        --
        l_code_dom_cat_flg_type   CONSTANT sys_domain.code_domain%TYPE := 'CATEGORY.FLG_TYPE';
        l_code_dom_pt_flg_profile CONSTANT sys_domain.code_domain%TYPE := 'PROFILE_TEMPLATE.FLG_PROFILE';
        --l_code_dom_epr_flg_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_PROF_RESP.FLG_STATUS';
        --
        l_code_msg_common_m008 CONSTANT sys_message.code_message%TYPE := 'COMMON_M008';
        --
        l_desc_msg_common_m008 sys_message.desc_message%TYPE;
        l_msg_opn_m001         sys_message.desc_message%TYPE;
        l_msg_hoff_m003        sys_message.desc_message%TYPE;
        l_msg_hoff_m004        sys_message.desc_message%TYPE;
        l_msg_hoff_m005        sys_message.desc_message%TYPE;
        l_msg_hoff_m006        sys_message.desc_message%TYPE;
        --
        l_hand_off_type    sys_config.value%TYPE;
        l_id_speciality    speciality.id_speciality%TYPE;
        l_flg_profile      profile_template.flg_profile%TYPE;
        l_prof_cat         category.flg_type%TYPE;
        l_prof_cat_desc    sys_domain.desc_val%TYPE;
        l_has_responsible  VARCHAR2(1);
        l_profile_template profile_template.id_profile_template%TYPE;
        --
        l_internal_error EXCEPTION;
        l_config_error   EXCEPTION;
    
        l_sbar_note sys_config.value%TYPE;
    BEGIN
        g_error     := 'GET SBAR CONFIG';
        l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type); -- Get the type of hand-off
    
        g_error         := 'GET PROF SPECIALITY';
        l_id_speciality := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof);
    
        g_error         := 'GET CATEGORY';
        l_prof_cat      := pk_prof_utils.get_category(i_lang, i_prof);
        l_prof_cat_desc := pk_sysdomain.get_domain(i_code_dom => l_code_dom_cat_flg_type,
                                                   i_val      => i_flg_type, -- The category of the transfer!!
                                                   i_lang     => i_lang);
    
        g_error            := 'GET PROFESSIONAL PROFILE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'GET FLG_PROFILE';
        IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_profile_template => l_profile_template,
                                                o_flg_profile      => l_flg_profile,
                                                o_error            => o_error)
        THEN
            g_error := 'INTERNAL ERROR - ' || get_error_str(i_error => o_error);
            alertlog.pk_alertlog.log_warn(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        END IF;
        --EB comentado por causa dos reports
        --       IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        --          AND l_flg_profile IS NULL
        --       THEN
        --           g_error := 'INVALID PROFILE AND/OR HAND-OFF TYPE';
        --           alertlog.pk_alertlog.log_error(text            => g_error,
        --                                          object_name     => g_package_name,
        --                                          sub_object_name => l_func_name);
        --          RAISE l_config_error;
        --       END IF;
    
        g_error        := 'GET MSG''s';
        l_msg_opn_m001 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_opn_m001);
    
        l_msg_hoff_m003 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m003);
        l_msg_hoff_m004 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m004);
        l_msg_hoff_m005 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m005);
        l_msg_hoff_m006 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m006);
    
        l_desc_msg_common_m008 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_common_m008);
    
        g_error := 'GET RESP CURSOR';
        IF NOT get_resp_grid(i_lang            => i_lang,
                             i_prof            => i_prof,
                             i_episode         => i_episode,
                             i_flg_hist        => i_flg_hist,
                             i_flg_show        => i_flg_type,
                             o_grid            => o_resp_grid,
                             o_has_responsible => l_has_responsible,
                             o_error           => o_error)
        THEN
            g_error := 'ERROR ON GET_RESP_GRID - ' || get_error_str(i_error => o_error);
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE pk_hand_off.g_exception;
        END IF;
    
        g_error := 'OPEN TRANSF CURSOR';
        OPEN o_transf_grid FOR
            SELECT epr.id_epis_prof_resp,
                   epr.id_prof_req,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          g_empty_str,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req)) name_prof_req,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          g_empty_str,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           epr.id_prof_to,
                                                           epr.dt_request_tstz,
                                                           epr.id_episode)) desc_spec_r,
                   pk_hand_off_core.get_cs_dep_spec_label(i_lang,
                                                          i_prof,
                                                          epr.id_clinical_service_orig,
                                                          epr.id_department_orig,
                                                          pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                                               profissional(epr.id_prof_req,
                                                                                                            i_prof.institution,
                                                                                                            i_prof.software)),
                                                          l_hand_off_type,
                                                          pk_prof_utils.get_category(i_lang,
                                                                                     profissional(epr.id_prof_req,
                                                                                                  i_prof.institution,
                                                                                                  i_prof.software))) label_orig,
                   pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                         i_prof,
                                                         epr.id_clinical_service_orig,
                                                         epr.id_department_orig,
                                                         pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                                              profissional(epr.id_prof_req,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software))) desc_orig,
                   epr.id_prof_to,
                   coalesce(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to), l_msg_opn_m001) name_prof_to,
                   pk_hand_off_core.get_cs_dep_spec_label(i_lang,
                                                          i_prof,
                                                          epr.id_clinical_service_dest,
                                                          epr.id_department_dest,
                                                          empr.id_speciality,
                                                          l_hand_off_type,
                                                          pk_prof_utils.get_category(i_lang,
                                                                                     profissional(epr.id_prof_to,
                                                                                                  i_prof.institution,
                                                                                                  i_prof.software))) label_dest_t,
                   pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                         i_prof,
                                                         epr.id_clinical_service_dest,
                                                         epr.id_department_dest,
                                                         empr.id_speciality) desc_dest_t,
                   epr.flg_status,
                   pk_sysdomain.get_img(i_lang, g_domain_hoff_status, epr.flg_status) icon_name,
                   decode(epr.flg_status,
                          pk_hand_off.g_hand_off_r,
                          l_msg_hoff_m003,
                          pk_hand_off.g_hand_off_f,
                          l_msg_hoff_m004,
                          pk_hand_off.g_hand_off_t,
                          l_msg_hoff_m004,
                          pk_hand_off.g_hand_off_d,
                          l_msg_hoff_m005,
                          l_msg_hoff_m006) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_target_a,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_target_a,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_cancel_tstz, i_prof) date_target_c,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_c,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_decline_tstz, i_prof) date_target_d,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_decline_tstz, i_prof.institution, i_prof.software) hour_target_d,
                   decode(epr.flg_status,
                          pk_hand_off.g_hand_off_r,
                          epr.dt_request_tstz,
                          pk_hand_off.g_hand_off_f,
                          epr.dt_comp_tstz,
                          pk_hand_off.g_hand_off_t,
                          epr.dt_comp_tstz,
                          pk_hand_off.g_hand_off_c,
                          epr.dt_cancel_tstz,
                          epr.dt_decline_tstz) date_order_tstz,
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                      decode(epr.flg_status,
                                                             pk_hand_off.g_hand_off_r,
                                                             epr.dt_request_tstz,
                                                             pk_hand_off.g_hand_off_f,
                                                             epr.dt_comp_tstz,
                                                             pk_hand_off.g_hand_off_t,
                                                             epr.dt_comp_tstz,
                                                             pk_hand_off.g_hand_off_c,
                                                             epr.dt_cancel_tstz,
                                                             epr.dt_decline_tstz),
                                                      pk_hand_off.g_date_mask) date_order,
                   decode(epr.flg_status,
                           pk_hand_off.g_hand_off_c,
                           decode(epr.notes_cancel, g_empty_str, g_empty_str, l_desc_msg_common_m008),
                           pk_hand_off.g_hand_off_r,
                           CASE
                               WHEN epr.notes_clob IS NULL THEN
                                g_empty_str
                               ELSE
                                l_desc_msg_common_m008
                           END) notes_desc,
                   -- decode(epr.notes_clob, g_empty_str, g_empty_str, l_desc_msg_common_m008)) notes_desc,
                   -- Multiple hand-off support
                   empr.flg_profile flg_profile,
                   decode(l_hand_off_type,
                           pk_hand_off.g_handoff_multiple,
                           CASE
                               WHEN epr.id_profile_template IS NOT NULL THEN
                                pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                               ELSE
                                pk_sysdomain.get_domain(l_code_dom_pt_flg_profile, empr.flg_profile, i_lang)
                           END,
                           CASE
                               WHEN epr.id_profile_template IS NOT NULL THEN
                                pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                               ELSE
                                l_prof_cat_desc
                           END) flg_profile_desc,
                   -- Set permissions for each request:
                   -- Cancel button
                   pk_hand_off_core.get_button_permission(i_lang,
                                                          i_prof,
                                                          pk_hand_off_core.g_button_cancel,
                                                          epr.flg_status,
                                                          epr.id_prof_req,
                                                          epr.id_prof_to,
                                                          epr.id_prof_comp,
                                                          empr.flg_profile,
                                                          l_flg_profile,
                                                          i_flg_type,
                                                          l_prof_cat,
                                                          l_hand_off_type,
                                                          empr.id_speciality,
                                                          l_id_speciality,
                                                          epr.id_episode,
                                                          empr.flg_main_responsible) flg_cancel,
                   -- OK button
                   pk_hand_off_core.get_button_permission(i_lang,
                                                          i_prof,
                                                          pk_hand_off_core.g_button_ok,
                                                          epr.flg_status,
                                                          epr.id_prof_req,
                                                          epr.id_prof_to,
                                                          epr.id_prof_comp,
                                                          empr.flg_profile,
                                                          l_flg_profile,
                                                          i_flg_type,
                                                          l_prof_cat,
                                                          l_hand_off_type,
                                                          empr.id_speciality,
                                                          l_id_speciality,
                                                          epr.id_episode,
                                                          empr.flg_main_responsible) flg_ok,
                   -- Action TRANSFER RESPONSABILITY: Not available for records in the state "requested"
                   pk_alert_constant.g_no flg_action_transfer,
                   -- Action TERMINATE RESPONSABILITY: Not available for records in the state "requested"
                   pk_alert_constant.g_no flg_action_terminate,
                   -- Action SET MAIN RESPONSIBLE: Not available for records in the state "requested"
                   pk_alert_constant.g_no flg_action_set_main,
                   nvl(empr.flg_resp_type, g_empty_str) flg_resp_type,
                   decode(empr.flg_resp_type,
                          NULL,
                          g_empty_str,
                          pk_hand_off_core.get_resp_type_desc(i_lang, i_prof, empr.id_epis_prof_resp, l_hand_off_type)) desc_resp_type,
                   CASE
                        WHEN epr.id_profile_template IS NOT NULL THEN
                         pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                        ELSE
                         pk_hand_off_core.get_desc_category(i_lang,
                                                            i_prof,
                                                            l_hand_off_type,
                                                            nvl(epr.id_prof_comp, epr.id_prof_to),
                                                            pk_hand_off_core.g_prof_type_to,
                                                            empr.flg_profile,
                                                            epr.flg_type)
                    END desc_cat_to,
                   pk_hand_off_core.get_desc_category(i_lang,
                                                      i_prof,
                                                      l_hand_off_type,
                                                      epr.id_prof_req,
                                                      pk_hand_off_core.g_prof_type_req,
                                                      empr.flg_profile,
                                                      epr.flg_type) desc_cat_req,
                   -- fields to be used by the REPORTS team
                   epr.notes_clob notes,
                   epr.notes_cancel,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) desc_cancel_reason,
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) dt_req,
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) dt_comp,
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   pk_date_utils.date_char_tsz(i_lang, epr.dt_decline_tstz, i_prof.institution, i_prof.software) dt_decline,
                   CASE l_sbar_note
                       WHEN pk_alert_constant.g_yes THEN
                        epr.sbar_notes
                       ELSE
                        NULL
                   END sbar_note
              FROM epis_prof_resp epr
              LEFT JOIN epis_multi_prof_resp empr
                ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
             WHERE epr.id_episode = i_episode
               AND (epr.id_prof_to IS NULL AND epr.flg_type = i_flg_type OR
                   epr.id_prof_to IN (SELECT pc.id_professional
                                         FROM prof_cat pc, category c
                                        WHERE pc.id_professional = epr.id_prof_to
                                          AND pc.id_category = c.id_category
                                          AND pc.id_institution = i_prof.institution
                                          AND c.flg_type = i_flg_type))
               AND epr.flg_status <> pk_hand_off.g_hand_off_x
               AND ((i_flg_hist = pk_alert_constant.g_no AND epr.flg_status = pk_hand_off.g_hand_off_r) OR
                   i_flg_hist = pk_alert_constant.g_yes)
               AND epr.flg_transf_type IN
                   (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_o, pk_hand_off.g_flg_transf_a)
             ORDER BY pk_sysdomain.get_rank(i_lang, g_domain_hoff_status, epr.flg_status),
                      epr.dt_comp_tstz DESC NULLS FIRST,
                      epr.dt_request_tstz DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_config_error THEN
            <<config_error>>
            DECLARE
                l_err_cfg  CONSTANT VARCHAR2(30) := 'CONFIG ERROR';
                l_err_desc CONSTANT VARCHAR2(30) := 'INVALID CONFIGURATION FOUND';
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  l_err_cfg,
                                                  l_err_desc,
                                                  g_error,
                                                  g_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END config_error;
            pk_types.open_my_cursor(o_resp_grid);
            pk_types.open_my_cursor(o_transf_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_resp_grid);
            pk_types.open_my_cursor(o_transf_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_resp_grid);
            pk_types.open_my_cursor(o_transf_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_prof_resp_all;

    /**********************************************************************************************
    * Get start event (Internal function used to obtain the description of start event in the responsability grid)
    *
    * @param   i_lang                 Language id
    * @param   i_flg_transfer         Flag transfer
    * @param   i_prof_prev            Previous responsible professional id
    *
    * @return                         Event description
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_start_evt
    (
        i_lang         IN language.id_language%TYPE,
        i_flg_transfer IN epis_prof_resp.flg_transfer%TYPE,
        i_prof_prev    IN epis_prof_resp.id_prof_prev%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_START_EVT';
        --
        l_msg_hoff_m069 sys_message.desc_message%TYPE;
        l_msg_hoff_m070 sys_message.desc_message%TYPE;
        l_msg_hoff_m071 sys_message.desc_message%TYPE;
        --
        l_ret sys_message.desc_message%TYPE;
    BEGIN
        g_error         := 'GET MSG''s';
        l_msg_hoff_m069 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m069);
        l_msg_hoff_m070 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m070);
        l_msg_hoff_m071 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m071);
    
        g_error := 'SET RET VALUE';
        l_ret := CASE
                     WHEN nvl(i_flg_transfer, pk_alert_constant.g_no) = pk_alert_constant.g_no
                          AND i_prof_prev IS NULL THEN
                      l_msg_hoff_m069
                     WHEN i_flg_transfer = pk_alert_constant.g_no
                          AND i_prof_prev IS NOT NULL THEN
                      l_msg_hoff_m070
                     WHEN i_flg_transfer = pk_alert_constant.g_yes THEN
                      l_msg_hoff_m071
                     ELSE
                      g_empty_str
                 END;
    
        RETURN l_ret;
    END get_start_evt;

    /**********************************************************************************************
    * Get end event (Internal function used to obtain the description of end event in the responsability grid)
    *
    * @param   i_lang                 Language id
    * @param   i_dt_end_transfer_tstz End of resp.
    * @param   i_flg_status           Status flag
    *
    * @return                         Event description
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_end_evt
    (
        i_lang                 IN language.id_language%TYPE,
        i_dt_end_transfer_tstz IN epis_prof_resp.dt_end_transfer_tstz%TYPE,
        i_flg_status           IN epis_prof_resp.flg_status%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_END_EVT';
        --
        l_msg_hoff_m071 sys_message.desc_message%TYPE;
        l_msg_hoff_m072 sys_message.desc_message%TYPE;
        --
        l_ret sys_message.desc_message%TYPE;
    BEGIN
        g_error         := 'GET MSG''s';
        l_msg_hoff_m071 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m071);
        l_msg_hoff_m072 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m072);
    
        g_error := 'SET RET VALUE';
        l_ret := CASE
                     WHEN i_dt_end_transfer_tstz IS NULL THEN
                      g_empty_str
                     WHEN i_flg_status = pk_hand_off.g_hand_off_t THEN
                      l_msg_hoff_m072
                     WHEN i_flg_status = pk_hand_off.g_hand_off_f THEN
                      l_msg_hoff_m071
                     ELSE
                      g_empty_str
                 END;
    
        RETURN l_ret;
    END get_end_evt;

    /********************************************************************************************
    * Set main overall responsability for a patient.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_new_resp              New main overall responsible ID
    * @param   i_id_epis_prof_resp        Hand-off request ID
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION call_set_main_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_new_resp       IN professional.id_professional%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(200 CHAR) := 'CALL_SET_MAIN_RESP';
        l_error_message VARCHAR2(200 CHAR);
        l_data_error     EXCEPTION;
        l_internal_error EXCEPTION;
    
        l_rowids        table_varchar := table_varchar();
        l_new_emprh_ids table_number;
    
        l_new_id_hist epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE;
        l_rec_empr    epis_multi_prof_resp%ROWTYPE;
        l_flg_profile profile_template.flg_profile%TYPE;
    
    BEGIN
    
        IF i_id_new_resp IS NULL
           OR i_id_epis_prof_resp IS NULL
           OR i_id_episode IS NULL
        THEN
            l_error_message := 'INVALID ID';
            RAISE l_data_error;
        END IF;
    
        g_error := 'GET PROFILE';
        IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                i_prof             => profissional(i_id_new_resp,
                                                                                   i_prof.institution,
                                                                                   i_prof.software),
                                                i_profile_template => NULL,
                                                o_flg_profile      => l_flg_profile,
                                                o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_flg_profile <> pk_hand_off_core.g_specialist
        THEN
            l_error_message := 'INVALID proFILE';
            RAISE l_data_error;
        END IF;
    
        g_error := 'GET PREVIOUS MAIN RESP DATA';
        BEGIN
            -- Main responsible should be registered as ACTIVE in EPIS_MULTI_PROF_RESP and correspond with EPIS_INFO.ID_PROFESSIONAL
            SELECT empr.*
              INTO l_rec_empr
              FROM epis_multi_prof_resp empr
             WHERE empr.id_episode = i_id_episode
               AND empr.flg_status = pk_hand_off_core.g_active
               AND empr.flg_profile = pk_hand_off_core.g_specialist
               AND empr.flg_main_responsible = pk_alert_constant.g_yes
               AND empr.flg_resp_type = pk_hand_off_core.g_resp_overall
                  -- Ignore EPIS_INFO in OUTPATIENT
               AND (i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                                        pk_alert_constant.g_soft_social,
                                        pk_alert_constant.g_soft_nutritionist,
                                        pk_alert_constant.g_soft_primary_care) OR EXISTS
                    (SELECT ei.id_professional
                       FROM epis_info ei
                      WHERE ei.id_episode = i_id_episode
                        AND ei.id_professional = empr.id_professional
                        AND i_prof.software NOT IN (pk_alert_constant.g_soft_outpatient,
                                                    pk_alert_constant.g_soft_social,
                                                    pk_alert_constant.g_soft_nutritionist,
                                                    pk_alert_constant.g_soft_primary_care)));
        EXCEPTION
            WHEN no_data_found THEN
                l_error_message := 'COULD NOT FIND MAIN RESPONSIBLE';
                RAISE l_data_error;
        END;
    
        -- UPDATE RECORD, and remove main responsability.
        l_rec_empr.flg_main_responsible := pk_alert_constant.g_no;
    
        -- Remove "main overall responsability" from the current main responsible
        g_error := 'UPDATE EPIS_MULTI_PROF_RESP - REMOVE MAIN RESP.';
        ts_epis_multi_prof_resp.upd(id_epis_multi_prof_resp_in => l_rec_empr.id_epis_multi_prof_resp,
                                    flg_main_responsible_in    => l_rec_empr.flg_main_responsible,
                                    flg_main_responsible_nin   => FALSE,
                                    rows_out                   => l_rowids);
    
        g_error := 'SET HISTORY (1)';
        IF NOT pk_hand_off_core.set_multi_prof_resp_hist(i_lang                        => i_lang,
                                                         i_prof                        => i_prof,
                                                         i_epis_multi_rec              => l_rec_empr,
                                                         o_id_epis_multi_profresp_hist => l_new_id_hist,
                                                         o_error                       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'PROCESS UPDATE EPIS_MULTI_PROF_RESP';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_MULTI_PROF_RESP',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- Reset variable for reuse 
        l_rowids := table_varchar();
    
        -- Set the new main responsible
        g_error := 'UPDATE EPIS_MULTI_PROF_RESP - SET NEW MAIN RESP.';
        ts_epis_multi_prof_resp.upd(flg_main_responsible_in  => pk_alert_constant.g_yes,
                                    flg_main_responsible_nin => FALSE,
                                    where_in                 => 'id_episode = ' || i_id_episode || --
                                                                ' AND id_epis_prof_resp = ' || i_id_epis_prof_resp || --
                                                                ' AND id_professional = ' || i_id_new_resp || --
                                                                ' AND flg_resp_type = ''' ||
                                                                pk_hand_off_core.g_resp_overall || --
                                                                ''' AND flg_status = ''' || pk_hand_off_core.g_active || '''',
                                    rows_out                 => l_rowids);
    
        g_error := 'SET HISTORY (2)';
        IF NOT pk_hand_off_core.set_multi_prof_resp_hist_rows(i_lang   => i_lang,
                                                              i_prof   => i_prof,
                                                              i_rowids => l_rowids,
                                                              o_ids    => l_new_emprh_ids,
                                                              o_error  => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'PROCESS UPDATE EPIS_MULTI_PROF_RESP';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_MULTI_PROF_RESP',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --l_rowids := table_varchar();
    
        -- Set the new main responsible in EPIS_INFO
        g_error := 'UPDATE EPIS_INFO';
        IF NOT call_set_epis_info_resp(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_episode          => i_id_episode,
                                       i_id_professional     => i_id_new_resp,
                                       i_id_professional_nin => FALSE,
                                       i_prof_cat            => pk_alert_constant.g_cat_type_doc,
                                       i_flg_resp_type       => pk_hand_off_core.g_resp_overall,
                                       o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_data_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'DATA ERROR',
                                              l_error_message,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_main_resp;

    /********************************************************************************************
    * Terminate responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Responsability transfer request ID
    * @param   i_flg_type                 Type of hand-off: Physician / Nurse
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION call_set_terminate_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type          IN epis_prof_resp.flg_type%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'CALL_SET_TERMINATE_RESP';
        l_internal_error EXCEPTION;
        l_param_error    EXCEPTION;
        l_refresh_mview        VARCHAR2(1 CHAR);
        l_error_messsage       VARCHAR2(200 CHAR);
        l_flg_main_responsible epis_multi_prof_resp.flg_main_responsible%TYPE;
        l_handoff_type         sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL TO GET_HAND_OFF_TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type); -- Get the type of hand-off
    
        IF l_handoff_type = pk_hand_off.g_handoff_multiple
           AND i_flg_type = pk_hand_off.g_prof_cat_doc
        THEN
            g_error := 'CHECK MAIN RESPONSABILITY';
            SELECT empr.flg_main_responsible
              INTO l_flg_main_responsible
              FROM epis_multi_prof_resp empr
             WHERE empr.id_epis_prof_resp = i_id_epis_prof_resp;
        
            IF l_flg_main_responsible = pk_alert_constant.g_yes
            THEN
                -- This shouldn't happen. If a professional is the main overall responsible, a new main responsible must
                -- be assigned before terminating responsability.
                l_error_messsage := 'PROFESSIONAL IS MAIN OVERALL RESPONSIBLE';
                RAISE l_param_error;
            END IF;
        END IF;
    
        g_error := 'CALL_SET_EPIS_PROF_RESP';
        IF NOT pk_hand_off.call_set_epis_prof_resp(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_tot_epis         => table_number(1),
                                                   i_epis_prof_resp   => table_varchar(i_id_epis_prof_resp),
                                                   i_flg_status       => pk_hand_off.g_hand_off_t, -- "Terminate" responsability
                                                   i_flg_type         => i_flg_type,
                                                   i_notes            => NULL,
                                                   i_sysdate          => NULL,
                                                   i_hand_off_type    => NULL,
                                                   i_id_cancel_reason => NULL,
                                                   o_refresh_mview    => l_refresh_mview,
                                                   o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              l_error_messsage,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_terminate_resp;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   i_flg_epis_respons         Flag that indicates if the professional also takes episode responsability
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION call_set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        i_dt_reg                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_epis_respons        IN VARCHAR2,
        i_flg_update_resp         IN VARCHAR2 DEFAULT 'N',
        i_flg_main_responsible    IN VARCHAR2 DEFAULT NULL,
        i_priority                IN NUMBER DEFAULT NULL,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        -- Errors, exception and other vars
        l_func_name       VARCHAR2(200 CHAR) := 'CALL_SET_OVERALL_RESP';
        l_param_error_msg VARCHAR2(200 CHAR);
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
        l_dummy      episode.flg_status%TYPE;
        l_dummy_name professional.name%TYPE;
    
        l_id_sys_alert NUMBER;
    
        -- Auxiliary vars
        l_prof            profissional;
        l_sysdate         TIMESTAMP WITH LOCAL TIME ZONE;
        l_handoff_type    sys_config.value%TYPE;
        l_self_request    BOOLEAN := FALSE;
        l_create_new_resp BOOLEAN := FALSE;
        l_is_responsible  VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        -- Data vars
        l_prof_cat             category.flg_type%TYPE;
        l_id_patient           patient.id_patient%TYPE;
        l_flg_profile          profile_template.flg_profile%TYPE;
        l_id_speciality        epis_multi_prof_resp.id_speciality%TYPE;
        l_flg_main_responsible epis_multi_prof_resp.flg_main_responsible%TYPE := pk_alert_constant.g_no;
        --l_is_main_responsible      epis_multi_prof_resp.flg_main_responsible%TYPE;
        l_id_current_prof_resp     professional.id_professional%TYPE;
        l_id_cur_main_prof_resp    professional.id_professional%TYPE;
        l_epr_req                  epis_prof_resp%ROWTYPE;
        l_id_prof_to               epis_prof_resp.id_prof_to%TYPE;
        l_id_prof_comp             epis_prof_resp.id_prof_comp%TYPE;
        l_flg_status               epis_prof_resp.flg_status%TYPE;
        l_dt_comp                  epis_prof_resp.dt_comp_tstz%TYPE;
        l_prof_name_orig           professional.name%TYPE;
        l_responsible              table_number := table_number();
        l_software                 epis_info.id_software%TYPE;
        l_handoff_multi_spec       sys_config.id_sys_config%TYPE := 'MULTIPLE_HAND_OFF_MULTI_SPEC';
        l_handoff_multi_spec_value sys_config.value%TYPE;
        l_flg_mrp                  profile_template.flg_mrp%TYPE;
        l_profile_template         profile_template.id_profile_template%TYPE;
        l_flg_show                 VARCHAR2(1);
        l_msg_title                sys_message.desc_message%TYPE;
        l_msg_body                 sys_message.desc_message%TYPE;
    
    BEGIN
        --------------------------------------------------------------------
        -- 0) Initialization
        --------------------------------------------------------------------
        IF i_dt_reg IS NULL
        THEN
            l_sysdate := current_timestamp;
        ELSE
            l_sysdate := i_dt_reg;
        END IF;
    
        o_flg_show := 'N';
    
        g_error := 'GET EPISODE ID';
        SELECT epis.id_patient
          INTO l_id_patient
          FROM episode epis
         WHERE epis.id_episode = i_id_episode;
    
        --------------------------------------------------------------------
        -- 1) Check preconditions
        --------------------------------------------------------------------
        -- Check destination professional
        IF i_id_prof_resp IS NULL
        THEN
            l_param_error_msg := 'i_id_prof_resp';
            RAISE l_param_error;
        END IF;
    
        -- IMPORTANT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        SELECT a.id_software
          INTO l_software
          FROM epis_info a
         WHERE a.id_episode = i_id_episode;
    
        g_error := 'CHECK PROFESSIONAL';
        IF i_prof.id <> i_id_prof_resp
           OR i_prof.software <> l_software
        THEN
        
            -- Current professional is making the request to a specialist, so build a PROFESSIONAL object
            l_prof         := profissional(id          => i_id_prof_resp,
                                           institution => i_prof.institution,
                                           software    => l_software);
            l_self_request := FALSE;
        ELSE
            l_prof         := i_prof;
            l_self_request := TRUE; -- Professional who is calling the method is the same as the destination professional.
        END IF;
    
        g_error            := 'GET PROF CATEGORY';
        l_prof_cat         := pk_prof_utils.get_category(i_lang => i_lang, i_prof => l_prof);
        l_profile_template := pk_prof_utils.get_prof_profile_template(l_prof);
        g_error            := 'GET HAND-OFF TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang, l_prof, l_handoff_type);
    
        IF l_handoff_type <> pk_hand_off.g_handoff_multiple
        THEN
            -- Action only supported for multiple hand-off type
            l_param_error_msg := 'l_handoff_type';
            RAISE l_param_error;
        END IF;
        l_handoff_multi_spec_value := pk_sysconfig.get_config(l_handoff_multi_spec, l_prof);
        IF i_id_prof_resp = -1
        THEN
            -- Transfer for "Any" professional
            l_flg_profile := g_specialist;
        
        ELSE
            -- Check profile of the destination professional
            g_error := 'GET KIND OF PROFILE';
            IF NOT get_flg_profile(i_lang => i_lang,
                                   -- Will get the FLG_PROFILE of the current professional (if it's a self request)..
                                   -- or the destination professional (if it's a request by another professional).
                                   i_prof             => l_prof,
                                   i_profile_template => l_profile_template,
                                   o_flg_profile      => l_flg_profile,
                                   o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'CHECK OVERALL RESPONSABILITY i_prof ' || l_prof.id || ',' || l_prof.software ||
                       ' l_flg_profile:' || l_flg_profile || ' i_flg_epis_respons:' || i_flg_epis_respons;
            -- Get the overall responsible
            l_responsible := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_id_episode    => i_id_episode,
                                                                  i_prof_cat      => l_prof_cat,
                                                                  i_hand_off_type => l_handoff_type,
                                                                  i_flg_resp_type => g_resp_overall);
        
            IF pk_utils.search_table_number(i_table => l_responsible, i_search => i_id_prof_resp) > -1
            THEN
                l_is_responsible := pk_alert_constant.g_yes;
            END IF;
        
            IF l_is_responsible = pk_alert_constant.g_yes
               AND nvl(i_flg_update_resp, pk_alert_constant.g_no) = pk_alert_constant.g_no
            THEN
                -- This must not happen. If destination professional is already responsible, 
                -- something went wrong with the methods returing the list of destination professionals.
                l_param_error_msg := 'DUPLICATED RESPONSABILITY';
                RAISE l_param_error;
            END IF;
        END IF;
    
        IF l_flg_profile <> pk_hand_off_core.g_specialist
        THEN
            -- Action only supported for specialist physicians
            l_param_error_msg := 'l_flg_profile';
            RAISE l_param_error;
        END IF;
    
        -- Set speciality
        IF l_self_request
           AND i_id_speciality IS NULL
        THEN
            g_error         := 'GET_PROF_SPECIALITY_ID';
            l_id_speciality := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof);
        
        ELSIF i_id_speciality IS NULL
        THEN
            -- Speciality must be specified
            l_param_error_msg := 'i_id_speciality';
            RAISE l_param_error;
        ELSE
            l_id_speciality := i_id_speciality;
        END IF;
    
        --------------------------------------------------------------------
        -- 2) Check responsability
        --------------------------------------------------------------------
    
        -- Check if exists an overall responsible for the current professional's speciality.
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_PROF_RESP_BY_TYPE';
        IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_episode => i_id_episode,
                                                      i_prof_cat   => pk_hand_off.g_prof_cat_doc,
                                                      -- Check for responsible specialist
                                                      i_flg_profile   => pk_hand_off_core.g_specialist,
                                                      i_hand_off_type => l_handoff_type,
                                                      i_flg_resp_type => pk_hand_off_core.g_resp_overall,
                                                      i_id_speciality => l_id_speciality,
                                                      -- Check for all overall responsibles, not just the main responsible.
                                                      -- This will check if there is a responsible for the current speciality.
                                                      i_only_main_overall => 'N',
                                                      o_epis_status       => l_dummy,
                                                      o_id_prof_resp      => l_id_current_prof_resp,
                                                      o_prof_name         => l_dummy_name,
                                                      o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --------------------------------------------------------------------
        -- 3) Check existing requested hand-off
        --------------------------------------------------------------------
    
        -- Check if there's an existing request, for the current speciality.
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_EXISTING_HANDOFF_REQ';
        IF NOT pk_hand_off_core.get_existing_handoff_req(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_episode     => i_id_episode,
                                                         i_req_status     => pk_hand_off.g_hand_off_r, -- Requested transfer
                                                         i_transf_type    => pk_hand_off.g_flg_transf_o, -- OVERALL responsability
                                                         i_flg_type       => 'D', -- Physician hand-off
                                                         i_flg_profile    => l_flg_profile,
                                                         i_hand_off_type  => l_handoff_type,
                                                         i_id_speciality  => l_id_speciality,
                                                         o_epis_prof_resp => l_epr_req,
                                                         o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        IF l_epr_req.id_epis_prof_resp IS NULL
           AND l_handoff_multi_spec_value = pk_alert_constant.g_yes
        THEN
            IF NOT pk_hand_off_core.get_existing_handoff_req(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_episode      => i_id_episode,
                                                             i_req_status      => g_active, -- Requested transfer
                                                             i_transf_type     => pk_hand_off.g_flg_transf_o, -- OVERALL responsability
                                                             i_flg_type        => 'D', -- Physician hand-off
                                                             i_flg_profile     => l_flg_profile,
                                                             i_hand_off_type   => l_handoff_type,
                                                             i_id_speciality   => l_id_speciality,
                                                             i_id_professional => i_id_prof_resp,
                                                             o_epis_prof_resp  => l_epr_req,
                                                             o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
        IF l_epr_req.id_epis_prof_resp IS NOT NULL
           AND l_epr_req.id_prof_to <> i_id_prof_resp
        THEN
            -- 3.1) Exists a request, but for a different professional. Show warning message.
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M080');
            o_msg_body  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_M034');
            RETURN TRUE;
        
        ELSIF l_epr_req.id_epis_prof_resp IS NOT NULL
              AND l_epr_req.id_prof_to = i_id_prof_resp
        THEN
            IF l_self_request
            THEN
                -- 3.2.1) Exists a request, for THIS professional. Accept it.
                l_epr_req.flg_status   := pk_hand_off.g_hand_off_f;
                l_epr_req.id_prof_comp := i_id_prof_resp;
                l_epr_req.dt_comp_tstz := l_sysdate;
            
            ELSE
                IF l_handoff_multi_spec_value = pk_alert_constant.g_no
                THEN
                    -- 3.2.2) Duplicated request, already exists a request for the specified professional. Show warning message.
                    o_flg_show  := 'Y';
                    o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M080');
                    o_msg_body  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_M035');
                    RETURN TRUE;
                ELSE
                    l_epr_req.dt_comp_tstz := l_sysdate;
                END IF;
            END IF;
        
        ELSIF l_epr_req.id_epis_prof_resp IS NULL
        THEN
            -- 3.3) There is no request. Create a new one.
            l_epr_req.id_epis_prof_resp := seq_epis_prof_resp.nextval;
        
            IF i_id_prof_resp = -1
            THEN
                -- Transfer to any professional
                l_id_prof_to   := NULL;
                l_id_prof_comp := NULL;
                l_flg_status   := pk_hand_off.g_hand_off_r;
                l_dt_comp      := NULL;
            
            ELSE
                -- One-step process: transfer to a specific physician should be automatically accepted.
                l_id_prof_to   := i_id_prof_resp;
                l_id_prof_comp := CASE l_self_request
                                      WHEN TRUE THEN
                                       i_prof.id
                                      ELSE
                                       i_id_prof_resp
                                  END;
                l_flg_status   := pk_hand_off.g_hand_off_f;
                l_dt_comp      := l_sysdate;
            END IF;
        
            l_epr_req.id_episode   := i_id_episode;
            l_epr_req.id_prof_req  := i_prof.id;
            l_epr_req.id_prof_to   := l_id_prof_to;
            l_epr_req.id_prof_comp := l_id_prof_comp;
            l_epr_req.notes_clob   := i_notes;
            l_epr_req.flg_type     := pk_hand_off.g_flg_type_d;
            -- If professional is making a self-request, set as 'finalized'.
            l_epr_req.flg_status          := l_flg_status;
            l_epr_req.id_prof_prev        := l_id_current_prof_resp;
            l_epr_req.id_profile_template := l_profile_template;
            -- If there was no responsible, then this is the first responsible. Otherwise, there was a responsability transfer.
        
            IF l_id_current_prof_resp IS NULL
            THEN
                l_epr_req.flg_transfer := pk_hand_off.g_transfer_n;
            ELSE
                IF i_flg_update_resp = pk_alert_constant.g_yes
                THEN
                    l_epr_req.flg_transfer := pk_hand_off.g_transfer_n;
                ELSE
                    l_epr_req.flg_transfer := pk_hand_off.g_transfer_y;
                END IF;
            END IF;
        
            l_epr_req.flg_transf_type          := pk_hand_off_core.g_resp_overall;
            l_epr_req.id_clinical_service_dest := NULL;
            l_epr_req.dt_request_tstz          := l_sysdate;
            l_epr_req.dt_comp_tstz             := l_dt_comp;
        
            l_create_new_resp := TRUE;
        
        END IF;
    
        --------------------------------------------------------------------
        -- 4) Set request
        --------------------------------------------------------------------
    
        IF l_create_new_resp
        THEN
            g_error := 'CREATE NEW RECORD - EPIS_PROF_RESP';
            INSERT INTO epis_prof_resp
            VALUES l_epr_req;
        
            -- cmf
            ins_epis_prof_resp_h(i_row => l_epr_req);
        
            -- cmf 
            IF l_epr_req.flg_status IN (pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_r)
            THEN
                -- Get name of the professional making the request
                l_prof_name_orig := pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id);
            
                IF l_epr_req.flg_status = pk_hand_off.g_hand_off_f
                THEN
                    l_id_sys_alert := 340;
                END IF;
            
                IF l_epr_req.flg_status = pk_hand_off.g_hand_off_r
                THEN
                    l_id_sys_alert := 32;
                END IF;
            
                -- If it's a new request, set the alert to the destination professional
                g_error := 'CALL INSERT_SYS_ALERT_EVENT';
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => l_id_sys_alert,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_record           => l_epr_req.id_epis_prof_resp,
                                                        i_dt_record           => l_sysdate,
                                                        i_id_professional     => l_epr_req.id_prof_to,
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => NULL,
                                                        i_flg_type_dest       => NULL,
                                                        i_replace1            => NULL,
                                                        i_replace2            => l_prof_name_orig,
                                                        o_error               => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
        ELSIF l_epr_req.id_epis_prof_resp IS NOT NULL
        THEN
            g_error := 'UPDATE RECORD - EPIS_PROF_RESP';
            UPDATE epis_prof_resp epr
               SET ROW = l_epr_req
             WHERE epr.id_epis_prof_resp = l_epr_req.id_epis_prof_resp;
        
            g_error := 'DELETE ALERT EVENT';
            pk_hand_off.delete_hand_off_event(i_lang, i_prof, i_id_episode, l_epr_req.id_epis_prof_resp);
        
        END IF;
    
        IF l_epr_req.flg_status = pk_hand_off.g_hand_off_f
        THEN
            l_flg_mrp := pk_prof_utils.get_flg_mrp(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_profile_template => l_profile_template);
        
            -- If the request is being finalized (accepted), check if there is main overall responsible.
            g_error := 'CALL TO PK_HAND_OFF_CORE.GET_PROF_RESP_BY_TYPE (2)';
            IF i_flg_main_responsible IS NOT NULL
            THEN
                l_flg_main_responsible := i_flg_main_responsible;
            ELSE
                IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_episode => i_id_episode,
                                                              i_prof_cat   => pk_hand_off.g_prof_cat_doc,
                                                              -- Get the MAIN OVERALL responsible specialist
                                                              i_flg_profile   => pk_hand_off_core.g_specialist,
                                                              i_hand_off_type => l_handoff_type,
                                                              i_flg_resp_type => pk_hand_off_core.g_resp_overall,
                                                              i_id_speciality => NULL,
                                                              -- Check for MAIN OVERALL RESPONSIBLE
                                                              i_only_main_overall => 'Y',
                                                              o_epis_status       => l_dummy,
                                                              o_id_prof_resp      => l_id_cur_main_prof_resp,
                                                              o_prof_name         => l_dummy_name,
                                                              o_error             => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
                g_error := 'SET FLG_MAIN_RESPONSIBLE';
                IF l_id_cur_main_prof_resp IS NULL
                   AND l_flg_mrp = pk_alert_constant.g_yes
                THEN
                    l_flg_main_responsible := pk_alert_constant.g_yes;
                ELSE
                    BEGIN
                        SELECT decode(empr.id_speciality,
                                      l_id_speciality,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no)
                          INTO l_flg_main_responsible
                          FROM epis_multi_prof_resp empr
                         WHERE empr.id_episode = i_id_episode
                           AND empr.flg_main_responsible = pk_alert_constant.g_yes
                           AND empr.flg_status = g_active;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_flg_main_responsible := pk_alert_constant.g_no;
                    END;
                END IF;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_HAND_OFF_CORE.SET_MULTI_PROF_RESP l_flg_profile :' || l_flg_profile;
        IF NOT pk_hand_off_core.set_multi_prof_resp(i_lang                    => i_lang,
                                                    i_prof                    => i_prof,
                                                    i_id_episode              => i_id_episode,
                                                    i_id_prof_resp            => i_id_prof_resp,
                                                    i_flg_profile             => l_flg_profile,
                                                    i_id_epis_prof_resp       => l_epr_req.id_epis_prof_resp,
                                                    i_flg_status              => l_epr_req.flg_status,
                                                    i_sysdate                 => l_sysdate,
                                                    i_hand_off_type           => l_handoff_type,
                                                    i_flg_main_responsible    => l_flg_main_responsible,
                                                    i_id_speciality           => l_id_speciality,
                                                    i_flg_resp_type           => pk_hand_off_core.g_resp_overall,
                                                    i_priority                => i_priority,
                                                    o_id_epis_multi_prof_resp => o_id_epis_multi_prof_resp,
                                                    o_error                   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Set end date of previous responsability, if a new responsability is being accepted
        g_error := 'SET END DATE';
        IF NOT pk_hand_off_core.call_set_end_responsability(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_epis_prof_resp       => l_epr_req.id_epis_prof_resp,
                                                            i_id_epis_multi_prof_resp => o_id_epis_multi_prof_resp,
                                                            i_hand_off_type           => l_handoff_type,
                                                            i_dt_end_transfer         => l_sysdate,
                                                            o_error                   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        o_id_epis_prof_resp := l_epr_req.id_epis_prof_resp;
    
        IF i_flg_epis_respons = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL TO PK_HAND_OFF.CREATE_EPIS_PROF_RESP';
            IF NOT pk_hand_off.create_epis_prof_resp(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_prof_to    => table_varchar(i_id_prof_resp),
                                                     i_tot_epis   => table_number(1),
                                                     i_epis_pat   => table_number(i_id_episode),
                                                     i_cs_or_dept => table_number(NULL),
                                                     i_notes      => table_varchar(i_notes),
                                                     i_flg_type   => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                i_prof => i_prof),
                                                     -- Called in grids
                                                     i_flg_resp    => 'G',
                                                     i_flg_profile => NULL,
                                                     i_sysdate     => NULL,
                                                     -- Not needed, will calculate the speciality of the current professional.
                                                     i_id_speciality => NULL,
                                                     i_sbar_note     => NULL,
                                                     o_flg_show      => l_flg_show,
                                                     o_msg_title     => l_msg_title,
                                                     o_msg_body      => l_msg_body,
                                                     
                                                     o_error => o_error)
            
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER OR VARIABLE FOUND: ' || l_param_error_msg,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_overall_resp;

    /********************************************************************************************
    * Set the end date for a responsability record.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Responsability ID
    * @param   i_id_epis_multi_prof_resp  Multiple responsability ID
    * @param   i_hand_off_type            Type of hand-off
    * @param   i_dt_end_transfer          Responsability end date
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          10-11-2010
    **********************************************************************************************/
    FUNCTION call_set_end_responsability
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_prof_resp       IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_id_epis_multi_prof_resp IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        i_hand_off_type           IN sys_config.value%TYPE,
        i_dt_end_transfer         IN epis_prof_resp.dt_end_transfer_tstz%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CALL_SET_END_RESPONSABILITY';
        l_internal_error EXCEPTION;
        l_param_error    EXCEPTION;
        l_error_message VARCHAR2(200 CHAR);
    
        l_epr                   epis_prof_resp%ROWTYPE;
        l_empr                  epis_multi_prof_resp%ROWTYPE;
        l_old_id_epis_prof_resp epis_prof_resp.id_epis_prof_resp%TYPE;
    
    BEGIN
    
        -- Check parameters
        IF i_dt_end_transfer IS NULL
        THEN
            l_error_message := 'INVALID END DATE';
            RAISE l_param_error;
        ELSIF i_id_epis_prof_resp IS NULL
        THEN
            l_error_message := 'INVALID RESPONSABILITY ID';
            RAISE l_param_error;
        ELSIF i_hand_off_type IS NULL
        THEN
            l_error_message := 'INVALID HAND-OFF TYPE';
            RAISE l_param_error;
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
              AND i_id_epis_multi_prof_resp IS NULL
        THEN
            l_error_message := 'INVALID RESPONSABILITY ID (MULTI)';
            RAISE l_param_error;
        END IF;
    
        -- Get all data of the current responsability
        g_error := 'GET RESP ROW';
        SELECT epr.*
          INTO l_epr
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp;
    
        IF l_epr.flg_status <> pk_hand_off.g_hand_off_f
        THEN
            -- If new responsability is not being accepted, just exit the function.
            RETURN TRUE;
        END IF;
    
        ---------------------------------------------------------------------------------------------------
        -- Following statements will get the last responsability of the same type.
        -- Queries can return more than one result, since before 2.6.0.3.4 the end date was not registered.
        ---------------------------------------------------------------------------------------------------
        IF i_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            BEGIN
                g_error := 'GET LAST RESP (1)';
                SELECT t.id_epis_prof_resp
                  INTO l_old_id_epis_prof_resp
                  FROM (SELECT epr.id_epis_prof_resp,
                               epr.flg_type,
                               epr.id_episode,
                               row_number() over(PARTITION BY epr.id_episode ORDER BY epr.dt_comp_tstz DESC) row_number
                          FROM epis_prof_resp epr
                         WHERE epr.flg_status = pk_hand_off.g_hand_off_f
                           AND epr.id_prof_comp IS NOT NULL
                           AND epr.dt_end_transfer_tstz IS NULL
                           AND epr.flg_type = l_epr.flg_type
                           AND epr.id_epis_prof_resp <> i_id_epis_prof_resp) t
                 WHERE t.id_episode = l_epr.id_episode
                   AND t.row_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_old_id_epis_prof_resp := NULL;
            END;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET MULTI RESP ROW';
            SELECT empr.*
              INTO l_empr
              FROM epis_multi_prof_resp empr
             WHERE empr.id_epis_prof_resp = l_epr.id_epis_prof_resp
               AND empr.id_epis_multi_prof_resp = i_id_epis_multi_prof_resp;
        
            BEGIN
                g_error := 'GET LAST RESP (2)';
                SELECT t.id_epis_prof_resp
                  INTO l_old_id_epis_prof_resp
                  FROM (SELECT epr.id_epis_prof_resp,
                               epr.flg_type,
                               epr.id_episode,
                               row_number() over(PARTITION BY epr.id_episode ORDER BY epr.dt_comp_tstz DESC) row_number
                          FROM epis_prof_resp epr
                          JOIN epis_multi_prof_resp empr
                            ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                         WHERE epr.flg_status = pk_hand_off.g_hand_off_f
                           AND epr.id_prof_comp IS NOT NULL
                           AND epr.dt_end_transfer_tstz IS NULL
                           AND epr.id_epis_prof_resp <> i_id_epis_prof_resp
                           AND epr.flg_type = l_epr.flg_type
                           AND empr.id_epis_multi_prof_resp <> i_id_epis_multi_prof_resp
                           AND empr.flg_status = g_outdated -- At this point the previous record is OUTDATED
                           AND empr.flg_profile = l_empr.flg_profile
                           AND (empr.id_speciality = l_empr.id_speciality OR
                               (empr.flg_profile = g_nurse AND empr.id_speciality IS NULL))
                           AND empr.flg_resp_type = l_empr.flg_resp_type) t
                  JOIN epis_multi_prof_resp empr
                    ON empr.id_epis_prof_resp = t.id_epis_prof_resp
                 WHERE t.id_episode = l_epr.id_episode
                   AND t.row_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_old_id_epis_prof_resp := NULL;
            END;
        END IF;
    
        IF l_old_id_epis_prof_resp IS NOT NULL
        THEN
            -- Set the responsability end date
            g_error := 'SET END DATE (1)';
            UPDATE epis_prof_resp epr
               SET epr.dt_end_transfer_tstz = i_dt_end_transfer
             WHERE epr.id_epis_prof_resp = l_old_id_epis_prof_resp;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              l_error_message,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_end_responsability;

    /********************************************************************************************
    * Checks if current professional has any type of responsability over the episode, whether
    * its OVERALL or EPISODE responsability.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_prof_resp             Professional ID to check
    * @param   i_prof_cat                 Professional category
    * @param   i_id_episode               Episode ID
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    *                        
    * @return  (Y) Yes, it's responsible. (N) No, it's not.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_prof_responsible
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_prof_resp  IN professional.id_professional%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_hand_off_type IN sys_config.value%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200 CHAR) := 'IS_PROF_RESPONSIBLE';
        l_internal_error EXCEPTION;
        l_error          t_error_out;
        l_responsibles   table_number := table_number();
        l_is_responsible VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_count          NUMBER(6) := 0;
        l_epis_status    episode.flg_status%TYPE;
        l_prof           professional.id_professional%TYPE;
        l_prof_name      professional.name%TYPE;
    BEGIN
    
        IF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get all responsibles of the current category
            g_error        := 'GET LIST OF RESPONSIBLES ID';
            l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_id_episode    => i_id_episode,
                                                                   i_prof_cat      => i_prof_cat,
                                                                   i_hand_off_type => i_hand_off_type);
        
            IF l_responsibles.exists(1)
            THEN
                -- Check if 'i_id_prof_resp' is one of the responsibles
                g_error := 'CHECK RESPONSABILITY';
                SELECT COUNT(*)
                  INTO l_count
                  FROM (SELECT column_value
                          FROM TABLE(l_responsibles)) t
                 WHERE t.column_value = i_id_prof_resp;
            END IF;
        
            IF l_count > 0
            THEN
                l_is_responsible := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            g_error := 'GET CURRENT RESPONSIBLE';
            IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_episode    => i_id_episode,
                                                          i_prof_cat      => i_prof_cat,
                                                          i_flg_profile   => NULL,
                                                          i_hand_off_type => i_hand_off_type,
                                                          i_flg_resp_type => 'E',
                                                          i_id_speciality => NULL,
                                                          o_epis_status   => l_epis_status,
                                                          o_id_prof_resp  => l_prof,
                                                          o_prof_name     => l_prof_name,
                                                          o_error         => l_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_prof IS NULL
               OR l_prof != i_prof.id
            THEN
                l_is_responsible := pk_alert_constant.g_no;
            
            ELSIF l_prof = i_prof.id
            THEN
                l_is_responsible := pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        RETURN l_is_responsible;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END is_prof_responsible;

    /********************************************************************************************
    * Checks if professional 'i_prof.id' has any type of responsability over the episode, whether
    * its OVERALL or EPISODE responsability.
    * NOTE: Function called in MCDT packages: pk_analysis, pk_exam, pk_exam_core.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    *                        
    * @return  Value of 'I_PROF.ID' if is responsible; Value '-1' if is not.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_prof_responsible_current
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE
    ) RETURN NUMBER IS
        l_func_name      VARCHAR2(200 CHAR) := 'IS_PROF_RESPONSIBLE_CURRENT';
        l_hand_off_type  sys_config.value%TYPE;
        l_is_resp        VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_responsability professional.id_professional%TYPE;
        l_error          t_error_out;
    BEGIN
    
        IF i_hand_off_type IS NULL
        THEN
            -- Get type of hand-off
            get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
        ELSE
            l_hand_off_type := i_hand_off_type;
        END IF;
    
        -- Check if current professional is responsible has any kind of responsability
        g_error   := 'CHECK RESPONSABILITY OF CURRENT PROFESSIONAL';
        l_is_resp := is_prof_responsible(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_prof_resp  => i_prof.id,
                                         i_prof_cat      => i_prof_cat,
                                         i_id_episode    => i_id_episode,
                                         i_hand_off_type => l_hand_off_type);
    
        CASE l_is_resp
            WHEN pk_alert_constant.g_yes THEN
                -- Current professional is responsible
                l_responsability := i_prof.id;
            ELSE
                -- Current professional is not responsible
                l_responsability := -1;
        END CASE;
    
        RETURN l_responsability;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END is_prof_responsible_current;

    /********************************************************************************************
    * Checks if professional is a DBC owner.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_prof                  Professional ID
    *                        
    * @return  NULL: error. 0: Not a DBC owner. Other: is a DBC owner.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_dbc_owner
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(200 CHAR) := 'IS_DBC_OWNER';
        l_error     t_error_out;
        l_count     NUMBER(6) := 0;
    BEGIN
    
        /*****************
        TODO: INVOCAR API DO CODING
        *****************/
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END is_dbc_owner;

    /********************************************************************************************
    * Checks if professional is a on-call physician.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_prof                  Professional ID
    * @param   i_on_call_list             List of on-call physicians ID
    *                        
    * @return  NULL: error. 0: Not a on-call physician. Other: is a on-call physician.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_on_call
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof      IN professional.id_professional%TYPE,
        i_on_call_list IN table_number
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(200 CHAR) := 'IS_ON_CALL';
        l_error     t_error_out;
        l_count     NUMBER(6);
    BEGIN
        -- Check if professional is an active on-call physician.
        IF i_on_call_list.exists(1)
        THEN
            g_error := 'CHECK ON CALL PHYSICIAN LIST ';
            SELECT COUNT(*)
              INTO l_count
              FROM (SELECT column_value val
                      FROM TABLE(i_on_call_list)) t
             WHERE t.val = i_id_prof;
        
        ELSE
            l_count := 0;
        END IF;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END is_on_call;

    /**********************************************************************************************
    * Lista serviços clinicos, ou departamentos, para filtrar profissionais para os quais o profissional 
      actual pode transferir a responsabilidade de pacientes seus
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               tipo de transferência: D - médico, N - enfermeiro
    * @param i_flg_resp_type          Type of responsability: (E) Episode (O) Overall
    * @param o_dests_header           cabeçalho da coluna dos destinos
    * @param o_profs_header           cabeçalho da coluna dos profissionais
    * @param o_dests                  cursor with types departament or clinical service
    * @param o_handoff_type           type of hand-off configured in the institution
    * @param o_handoff_nurse          configuration for nurse hand-off (clinical service or department)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/06/05
    *
    * @alter                          Jos?Brito
    * @version                        2.6.0.4 
    * @since                          2010/10/19
    **********************************************************************************************/
    FUNCTION get_handoff_dest
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN category.flg_type%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        o_dests_header  OUT VARCHAR2,
        o_profs_header  OUT VARCHAR2,
        o_dests         OUT pk_types.cursor_type,
        o_handoff_type  OUT sys_config.value%TYPE,
        o_handoff_nurse OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(200) := 'GET_HANDOFF_DEST';
        l_handoff_type  sys_config.value%TYPE;
        l_handoff_nurse sys_config.value%TYPE;
    
        l_profile_template       profile_template.id_profile_template%TYPE;
        l_tab_dest_profile_templ table_number := table_number();
        l_intern_resp            sys_config.value%TYPE;
        l_internal_error EXCEPTION;
        l_exception      EXCEPTION;
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type);
        o_handoff_type  := l_handoff_type;
        l_handoff_nurse := pk_sysconfig.get_config('HANDOFF_NURSE', i_prof.institution, i_prof.software);
        o_handoff_nurse := l_handoff_nurse;
    
        g_error := 'GET HEADERS';
        IF i_flg_type = pk_edis_list.g_prof_cat_doc
        THEN
            o_profs_header := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_T001');
        ELSIF i_flg_type = pk_edis_list.g_prof_cat_nrs
        THEN
            o_profs_header := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_T031');
        ELSE
            g_error := 'INVALID PROF CAT';
            RAISE l_exception;
        END IF;
    
        -- Check if intern physicians are allowed to take over responsability
        g_error       := 'GET CONFIGURATIONS (INTERN PHYSICIAN HAND OFF)';
        l_intern_resp := pk_sysconfig.get_config('INTERN_TAKE_OVER_RESPONSABILITY', i_prof);
    
        g_error            := 'GET CURRENT PROFILE TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        -- Get the profile ID's for which the professional can make a hand-off request.
        g_error := 'CALL TO PK_HAND_OFF.GET_ALLOWED_PROFILE_TYPES';
        IF NOT get_allowed_profiles(i_lang                 => i_lang,
                                    i_prof                 => i_prof,
                                    i_id_profile_templ_req => l_profile_template,
                                    i_flg_type             => i_flg_type,
                                    i_flg_resp_type        => i_flg_resp_type,
                                    o_profiles             => l_tab_dest_profile_templ,
                                    o_error                => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_handoff_type = pk_hand_off.g_handoff_multiple
           AND i_flg_type = pk_edis_list.g_prof_cat_doc
        THEN
            -- Check for SPECIALITIES, rather than clinical services.
            o_dests_header := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_T009');
        
            g_error := 'OPEN O_DESTS (0)';
            OPEN o_dests FOR
                SELECT t.id_speciality id_dest,
                       pk_translation.get_translation(i_lang, t.code_speciality) desc_dest,
                       'S' flg_type
                  FROM (SELECT DISTINCT spec.id_speciality, spec.code_speciality
                          FROM speciality spec
                          JOIN professional p
                            ON p.id_speciality = spec.id_speciality
                          JOIN prof_institution pi
                            ON pi.id_professional = p.id_professional
                          JOIN prof_cat pc
                            ON pc.id_professional = p.id_professional
                          JOIN category c
                            ON c.id_category = pc.id_category
                          JOIN prof_profile_template ppt
                            ON ppt.id_professional = p.id_professional
                          JOIN profile_template pt
                            ON pt.id_profile_template = ppt.id_profile_template
                         WHERE spec.flg_available = pk_alert_constant.g_yes
                           AND p.id_professional != i_prof.id -- Exclude current professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = pk_edis_list.g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pc.id_institution = i_prof.institution
                           AND c.flg_type = i_flg_type
                           AND c.flg_available = pk_alert_constant.g_yes
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND pt.flg_type !=
                               decode(nvl(l_intern_resp, 'Y'), 'N', pk_edis_list.g_flg_profile_type_intern, 'DUMMY')
                              -- Check permissions
                           AND pt.id_profile_template IN
                               (SELECT column_value
                                  FROM TABLE(l_tab_dest_profile_templ))) t
                 ORDER BY desc_dest ASC;
        
        ELSIF i_flg_type = pk_edis_list.g_prof_cat_doc
              OR
              (i_flg_type = pk_edis_list.g_prof_cat_nrs AND l_handoff_nurse = pk_edis_list.g_handoff_nurse_clin_serv)
        THEN
            o_dests_header := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_T032');
        
            g_error := 'OPEN O_DESTS (1)';
            OPEN o_dests FOR
                SELECT DISTINCT dcs.id_clinical_service id_dest,
                                pk_translation.get_translation(i_lang,
                                                               'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                               dcs.id_clinical_service) desc_dest,
                                'CS' flg_type
                  FROM dept d, software_dept sd, dep_clin_serv dcs, department dt
                 WHERE d.id_institution = i_prof.institution
                   AND sd.id_dept = d.id_dept
                   AND sd.id_software = i_prof.software
                   AND EXISTS
                 (SELECT 1
                          FROM prof_dep_clin_serv    pdcs,
                               dep_clin_serv         dcs_prof,
                               prof_institution      pi,
                               prof_cat              pc,
                               category              c,
                               profile_template      pt,
                               prof_profile_template ppt
                         WHERE dcs_prof.id_clinical_service = dcs.id_clinical_service
                           AND dcs_prof.id_dep_clin_serv = pdcs.id_dep_clin_serv
                           AND pdcs.id_professional != i_prof.id
                           AND pdcs.id_professional = pc.id_professional
                           AND pc.id_category = c.id_category
                           AND pc.id_institution = i_prof.institution
                           AND c.flg_type = i_flg_type
                           AND pdcs.flg_status = pk_edis_list.g_prof_dcs_status_active -- Clinical service is selected by the professional
                           AND pi.id_professional = pdcs.id_professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = pk_edis_list.g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND ppt.id_professional = pdcs.id_professional
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_profile_template = pt.id_profile_template
                           AND pt.flg_type !=
                               decode(nvl(l_intern_resp, 'Y'), 'N', pk_edis_list.g_flg_profile_type_intern, 'DUMMY')
                           AND pt.id_profile_template IN
                               (SELECT column_value
                                  FROM TABLE(l_tab_dest_profile_templ)) -- Check permissions
                           AND pdcs.id_institution = i_prof.institution)
                   AND dt.id_dept = d.id_dept
                   AND dcs.id_department = dt.id_department
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND dt.flg_available = pk_alert_constant.g_yes
                 ORDER BY desc_dest ASC;
        
        ELSIF l_handoff_nurse = pk_edis_list.g_handoff_nurse_department
        THEN
            o_dests_header := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_T032');
        
            g_error := 'OPEN O_DESTS (2)';
            OPEN o_dests FOR
                SELECT dt.id_department id_dest,
                       pk_translation.get_translation(i_lang, dt.code_department) desc_dest,
                       'D' flg_type
                  FROM dept d, software_dept sd, department dt
                 WHERE d.id_institution = i_prof.institution
                   AND sd.id_dept = d.id_dept
                   AND sd.id_software = i_prof.software
                   AND EXISTS
                 (SELECT 1
                          FROM prof_dep_clin_serv    pdcs,
                               dep_clin_serv         dcs_prof,
                               prof_institution      pi,
                               prof_cat              pc,
                               category              c,
                               profile_template      pt,
                               prof_profile_template ppt
                         WHERE dcs_prof.id_department = dt.id_department
                           AND dcs_prof.id_dep_clin_serv = pdcs.id_dep_clin_serv
                           AND pdcs.id_professional != i_prof.id
                           AND pdcs.id_professional = pc.id_professional
                           AND pc.id_category = c.id_category
                           AND pc.id_institution = i_prof.institution
                           AND c.flg_type = i_flg_type
                           AND pdcs.flg_status = pk_edis_list.g_prof_dcs_status_active -- Clinical service is selected by the professional
                           AND pi.id_professional = pdcs.id_professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = pk_edis_list.g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND ppt.id_professional = pdcs.id_professional
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_profile_template = pt.id_profile_template
                           AND pt.flg_type !=
                               decode(nvl(l_intern_resp, 'Y'), 'N', pk_edis_list.g_flg_profile_type_intern, 'DUMMY')
                           AND pt.id_profile_template IN
                               (SELECT column_value
                                  FROM TABLE(l_tab_dest_profile_templ)) -- Check permissions
                           AND pdcs.id_institution = i_prof.institution)
                   AND dt.id_dept = d.id_dept
                 ORDER BY desc_dest ASC;
        ELSE
            g_error := 'INVALID HANDOFF_NURSE PARAM (' || l_handoff_nurse || ')';
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dests);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dests);
            RETURN FALSE;
    END get_handoff_dest;

    /**********************************************************************************************
    * Get the profile types (Specialist, Resident, Intern, Nurse, etc.)
    * to which the professional can make a hand-off request.
    *
    * NOTE: Used only for EPISODE responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_flg_type               type of category (D) Physician (N) Nurse
    * @param o_profiles               list of profile types
    * @param o_error                  error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profiles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN category.flg_type%TYPE,
        o_profiles   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(200) := 'GET_HANDOFF_DEST_PROFILES';
        l_domain           sys_domain.code_domain%TYPE := 'PROFILE_TEMPLATE.FLG_PROFILE';
        l_profile_template profile_template.id_profile_template%TYPE;
        l_tab_flg_profiles table_varchar;
        l_flg_resp_type    epis_multi_prof_resp.flg_resp_type%TYPE;
        l_config_error   EXCEPTION;
        l_internal_error EXCEPTION;
    BEGIN
        g_error            := 'GET CURRENT PROFILE TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        -- Profile selection only available to EPISODE responsability
        l_flg_resp_type := pk_hand_off_core.g_resp_episode;
    
        -- Get the profile types for which the professional can make a hand-off request
        g_error := 'CALL TO PK_HAND_OFF.GET_ALLOWED_PROFILE_TYPES';
        IF NOT pk_hand_off_core.get_allowed_profile_types(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_id_profile_templ_req => l_profile_template,
                                                          i_flg_type             => i_flg_type,
                                                          i_flg_resp_type        => l_flg_resp_type,
                                                          o_flg_profiles         => l_tab_flg_profiles,
                                                          o_error                => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'OPEN O_DESTS (1)';
        OPEN o_profiles FOR
            SELECT sd.val data, sd.desc_val label
              FROM sys_domain sd
             WHERE sd.id_language = i_lang
               AND sd.flg_available = pk_alert_constant.g_yes
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.code_domain = l_domain
               AND sd.val IN (SELECT column_value
                                FROM TABLE(l_tab_flg_profiles))
                  -- Don't include profiles that have a request "on hold".
               AND NOT EXISTS (SELECT 0
                      FROM epis_multi_prof_resp empr
                     WHERE empr.id_episode = i_id_episode
                       AND empr.flg_status = pk_hand_off_core.g_onhold
                       AND empr.flg_profile = sd.val
                       AND empr.flg_resp_type = l_flg_resp_type)
             ORDER BY sd.rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profiles);
            RETURN FALSE;
        WHEN l_config_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'CONFIG ERROR',
                                              'INVALID CONFIGURATION FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profiles);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profiles);
            RETURN FALSE;
    END get_handoff_dest_profiles;

    /**********************************************************************************************
    * Get the destination professionals for the current responsability transfer, filtered
    * according to the destination clinical service/department/speciality.
    *
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_dest                   ID of the destination clinical service/department/speciality
    * @param i_episode                Episode ID
    * @param i_flg_type               Type of category (D) Physician (N) Nurse
    * @param i_handoff_type           Type of hand-off: (N) Normal (M) Multiple
    * @param i_handoff_nurse          Configuration for nurse hand-off (clinical service or department)
    * @param i_flg_profile            Type of profile (specialist, resident, intern, nurse)
    * @param i_flg_resp_type          Type of responsability (E) Episode (O) Overall
    * @param i_flg_assign_supervisor  Flag that indicates if this is a supervisor assignment
    * @param o_profs                  List of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    *
    * @alter                          Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profs
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_dest                  IN dep_clin_serv.id_clinical_service%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_type              IN category.flg_type%TYPE,
        i_handoff_type          IN VARCHAR2,
        i_handoff_nurse         IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE,
        i_flg_resp_type         IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        o_profs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name              VARCHAR2(200) := 'GET_HANDOFF_DEST_PROFS';
        l_handoff_nurse          sys_config.value%TYPE;
        l_allow_any              sys_config.value%TYPE;
        l_handoff_type           sys_config.value%TYPE := i_handoff_type;
        l_intern_resp            sys_config.value%TYPE;
        l_any_msg                sys_message.desc_message%TYPE;
        i_flg_screen             VARCHAR2(10) := 'OUT';
        l_profile_template       profile_template.id_profile_template%TYPE;
        l_tab_dest_profile_templ table_number := table_number();
        l_tab_on_call            table_number := table_number();
        --l_epis_status            episode.flg_status%TYPE;
        --l_id_prof_responsible    professional.id_professional%TYPE;
        l_on_call_phy_desc pk_translation.t_desc_translation;
        l_flg_profile      profile_template.flg_profile%TYPE;
        --l_id_speciality          epis_multi_prof_resp.id_speciality%TYPE;
        --l_flg_resp_type          epis_multi_prof_resp.flg_resp_type%TYPE;
        l_dbc_owner_desc sys_message.desc_message%TYPE;
        l_responsibles   table_number := table_number();
        l_internal_error EXCEPTION;
        l_exception      EXCEPTION;
    BEGIN
        l_any_msg          := pk_message.get_message(i_lang, 'COMMON_M059');
        l_on_call_phy_desc := lower(pk_translation.get_translation(i_lang, 'FOLLOW_UP_ENTITY.CODE_FOLLOW_UP_ENTITY.1'));
        l_dbc_owner_desc   := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M057');
    
        g_error := 'GET CONFIGURATIONS (HAND-OFF TYPE)';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type);
    
        g_error := 'GET CONFIGURATIONS (HAND-OFF NURSE)';
        IF i_handoff_nurse IS NULL
        THEN
            l_handoff_nurse := pk_sysconfig.get_config('HANDOFF_NURSE', i_prof.institution, i_prof.software);
        ELSE
            l_handoff_nurse := i_handoff_nurse;
        END IF;
    
        -- Check if intern physicians are allowed to take over responsability
        g_error       := 'GET CONFIGURATIONS (INTERN PHYSICIAN HAND OFF)';
        l_intern_resp := pk_sysconfig.get_config('INTERN_TAKE_OVER_RESPONSABILITY', i_prof);
    
        IF i_flg_assign_supervisor = pk_alert_constant.g_yes
        THEN
            l_allow_any := pk_alert_constant.g_no;
        ELSE
            IF i_flg_screen = 'OUT'
            THEN
                l_allow_any := pk_sysconfig.get_config('EDIS_HAND_OFF_OUT', i_prof);
            ELSE
                l_allow_any := pk_sysconfig.get_config('EDIS_HAND_OFF_IN', i_prof);
            END IF;
        END IF;
    
        g_error            := 'GET CURRENT PROFILE TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        -- Get the type of profile: (S) specialist (R) resident (I) intern (N) nurse
        IF l_handoff_type = pk_hand_off.g_handoff_multiple
           AND i_flg_profile IS NULL
        THEN
            -- Get the type of profile of the current professional.
            g_error := 'GET CURRENT PROFILE TYPE';
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => l_profile_template,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            l_flg_profile := i_flg_profile;
        END IF;
    
        -- Get the profile ID's for which the professional can make a hand-off request.
        g_error := 'CALL TO PK_HAND_OFF.GET_ALLOWED_PROFILE_TYPES';
        IF NOT pk_hand_off_core.get_allowed_profiles(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_id_profile_templ_req => l_profile_template,
                                                     i_flg_type             => i_flg_type,
                                                     i_flg_resp_type        => i_flg_resp_type,
                                                     o_profiles             => l_tab_dest_profile_templ,
                                                     o_error                => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error        := 'CALL TO GET_PROF_RESP_BY_TYPE';
        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => i_episode,
                                                               i_prof_cat      => i_flg_type,
                                                               i_hand_off_type => l_handoff_type);
    
        -- Add current professional to the list of current responsibles professionals
        l_responsibles := l_responsibles MULTISET UNION table_number(i_prof.id);
    
        IF i_flg_type = pk_edis_list.g_prof_cat_doc
           AND l_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'CALL TO GET_ON_CALL_PHYSICIAN_ID_LIST (0)';
            IF NOT pk_on_call_physician.get_on_call_physician_id_list(i_lang     => i_lang,
                                                                      i_prof     => i_prof,
                                                                      o_id_profs => l_tab_on_call,
                                                                      o_error    => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'OPEN O_PROFS (0)';
            OPEN o_profs FOR
                SELECT prof.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) ||
                       decode(is_dbc_owner(i_lang, i_prof, prof.id_professional),
                              0,
                              decode(is_on_call(i_lang, i_prof, prof.id_professional, l_tab_on_call),
                                     0,
                                     NULL,
                                     ' (' || l_on_call_phy_desc || ')'),
                              ' (' || l_dbc_owner_desc || ')') prof_name,
                       1 rank
                  FROM (SELECT DISTINCT p.id_professional
                           FROM speciality spec
                           JOIN professional p
                             ON p.id_speciality = spec.id_speciality
                           JOIN prof_institution pi
                             ON pi.id_professional = p.id_professional
                           JOIN prof_cat pc
                             ON pc.id_professional = p.id_professional
                           JOIN category c
                             ON c.id_category = pc.id_category
                           JOIN prof_profile_template ppt
                             ON ppt.id_professional = p.id_professional
                           JOIN profile_template pt
                             ON pt.id_profile_template = ppt.id_profile_template
                          WHERE spec.id_speciality = i_dest
                               -- Exclude current professional and all responsibles
                            AND p.id_professional NOT IN (SELECT column_value
                                                            FROM TABLE(l_responsibles))
                            AND pi.id_institution = i_prof.institution
                            AND pi.flg_state = pk_edis_list.g_prof_active
                            AND pi.dt_end_tstz IS NULL
                            AND pc.id_institution = i_prof.institution
                            AND c.flg_type = i_flg_type
                            AND c.flg_available = pk_alert_constant.g_yes
                            AND ppt.id_software = i_prof.software
                            AND ppt.id_institution = i_prof.institution
                            AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                                pk_alert_constant.g_yes
                            AND EXISTS
                          (SELECT 0
                                   FROM prof_soft_inst psi
                                  WHERE psi.id_professional = pc.id_professional
                                    AND psi.id_institution = i_prof.institution
                                    AND psi.id_software = i_prof.software
                                    AND (psi.flg_log = pk_alert_constant.g_yes OR
                                        -- Jos?Brito 29/10/2009 ALERT-39320  Specialists should be available even if they
                                        --                                    aren't at the institution facilities.
                                        (l_flg_profile = pk_hand_off_core.g_specialist AND
                                        psi.flg_log = pk_alert_constant.g_no)))
                           AND pt.flg_type !=
                               decode(nvl(l_intern_resp, 'Y'), 'N', pk_edis_list.g_flg_profile_type_intern, 'DUMMY')
                              -- Check permissions
                           AND pt.id_profile_template IN
                               (SELECT column_value
                                  FROM TABLE(l_tab_dest_profile_templ))
                           AND ((l_flg_profile = pt.flg_profile AND l_handoff_type = pk_hand_off.g_handoff_multiple) OR
                               l_handoff_type = pk_hand_off.g_handoff_normal)) prof
                UNION ALL
                SELECT -1 id_professional, l_any_msg prof_name, 0 rank
                  FROM dual
                 WHERE l_allow_any = 'A'
                 ORDER BY rank, prof_name;
        
        ELSIF (i_flg_type = pk_edis_list.g_prof_cat_doc AND l_handoff_type = pk_hand_off.g_handoff_normal)
              OR
              (i_flg_type = pk_edis_list.g_prof_cat_nrs AND l_handoff_nurse = pk_edis_list.g_handoff_nurse_clin_serv)
        THEN
            -- The on-call physician list is only applicable to EDIS,
            -- and for hand-off requests destinated to physicians.
            IF i_prof.software = pk_alert_constant.g_soft_edis
               AND i_flg_type = pk_edis_list.g_prof_cat_doc
            THEN
                g_error := 'CALL TO GET_ON_CALL_PHYSICIAN_ID_LIST (1)';
                IF NOT pk_on_call_physician.get_on_call_physician_id_list(i_lang     => i_lang,
                                                                          i_prof     => i_prof,
                                                                          o_id_profs => l_tab_on_call,
                                                                          o_error    => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            g_error := 'OPEN O_PROFS (1)';
            OPEN o_profs FOR
                SELECT pdcs.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) ||
                       decode(is_on_call(i_lang, i_prof, pdcs.id_professional, l_tab_on_call),
                              0,
                              NULL,
                              ' (' || l_on_call_phy_desc || ')') prof_name,
                       1 rank
                  FROM prof_dep_clin_serv    pdcs,
                       prof_cat              pc,
                       category              c,
                       dep_clin_serv         dcs,
                       prof_profile_template ppt,
                       profile_template      pt
                 WHERE dcs.id_clinical_service = i_dest
                   AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                   AND pdcs.id_professional NOT IN (SELECT column_value
                                                      FROM TABLE(l_responsibles))
                   AND pc.id_professional = pdcs.id_professional
                   AND pdcs.flg_status = pk_edis_list.g_prof_dcs_status_active
                   AND pc.id_institution = i_prof.institution
                   AND pc.id_category = c.id_category
                   AND c.flg_type = i_flg_type
                   AND pdcs.id_institution = i_prof.institution
                   AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, i_prof.institution) =
                       pk_alert_constant.g_yes
                   AND EXISTS (SELECT 0
                          FROM prof_institution
                         WHERE flg_state = pk_edis_list.g_prof_active
                           AND dt_end_tstz IS NULL
                           AND id_institution = i_prof.institution
                           AND id_professional = pdcs.id_professional)
                   AND EXISTS
                 (SELECT 0
                          FROM prof_soft_inst psi
                         WHERE psi.id_professional = pc.id_professional
                           AND psi.id_institution = i_prof.institution
                           AND psi.id_software = i_prof.software
                              --ainda est?em turno
                           AND (psi.flg_log = pk_alert_constant.g_yes OR
                               -- Jos?Brito 29/10/2009 ALERT-39320  Specialists should be available even if they
                               --                                    aren't at the institution facilities.
                                (l_flg_profile = pk_hand_off_core.g_specialist AND psi.flg_log = pk_alert_constant.g_no)))
                   AND ppt.id_professional = pc.id_professional
                   AND ppt.id_software = i_prof.software
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_profile_template = pt.id_profile_template
                   AND pt.flg_type !=
                       decode(nvl(l_intern_resp, 'Y'), 'N', pk_edis_list.g_flg_profile_type_intern, 'DUMMY')
                      -- Jos?Brito 07/10/2009 ALERT-39320 Support for multiple and normal hand-off
                   AND pt.id_profile_template IN (SELECT column_value
                                                    FROM TABLE(l_tab_dest_profile_templ)) -- Check permissions
                   AND ((l_flg_profile = pt.flg_profile AND l_handoff_type = pk_hand_off.g_handoff_multiple) OR
                       l_handoff_type = pk_hand_off.g_handoff_normal)
                 GROUP BY pdcs.id_professional
                UNION ALL
                SELECT -1 id_professional, l_any_msg prof_name, 0 rank
                  FROM dual
                 WHERE l_allow_any = 'A'
                 ORDER BY rank, prof_name;
        
        ELSIF i_flg_type = pk_edis_list.g_prof_cat_nrs
              AND l_handoff_nurse = pk_edis_list.g_handoff_nurse_department
        THEN
            g_error := 'OPEN O_PROFS (2)';
            OPEN o_profs FOR
                SELECT pc.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_professional) prof_name,
                       1 rank
                  FROM prof_cat pc, category c, prof_profile_template ppt, profile_template pt
                 WHERE pc.id_professional IN
                       (SELECT pdcs.id_professional
                          FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                         WHERE dcs.id_department = i_dest
                           AND pdcs.id_professional NOT IN (SELECT column_value
                                                              FROM TABLE(l_responsibles))
                           AND pdcs.flg_status = pk_edis_list.g_prof_dcs_status_active
                           AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND pdcs.id_institution = i_prof.institution)
                   AND pc.id_institution = i_prof.institution
                   AND pc.id_category = c.id_category
                   AND c.flg_type = i_flg_type
                   AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pc.id_professional, i_prof.institution) =
                       pk_alert_constant.g_yes
                   AND EXISTS (SELECT 0
                          FROM prof_institution
                         WHERE flg_state = pk_edis_list.g_prof_active
                           AND dt_end_tstz IS NULL
                           AND id_institution = i_prof.institution
                           AND id_professional = pc.id_professional)
                   AND EXISTS
                 (SELECT 0
                          FROM prof_soft_inst psi
                         WHERE psi.id_professional = pc.id_professional
                           AND psi.id_institution = i_prof.institution
                           AND psi.id_software = i_prof.software
                              --ainda est?em turno
                           AND psi.flg_log = pk_edis_list.g_yes)
                      -- Jos?Brito 07/10/2009 ALERT-39320 Support for multiple and normal hand-off
                   AND ppt.id_professional = pc.id_professional
                   AND ppt.id_profile_template = pt.id_profile_template
                   AND ppt.id_software = i_prof.software
                   AND ppt.id_institution = i_prof.institution
                   AND pt.id_software = i_prof.software
                   AND pt.flg_available = pk_alert_constant.g_yes
                   AND pt.id_profile_template IN (SELECT column_value
                                                    FROM TABLE(l_tab_dest_profile_templ)) -- Check permissions
                   AND ((l_flg_profile = pt.flg_profile AND l_handoff_type = pk_hand_off.g_handoff_multiple) OR
                       l_handoff_type = pk_hand_off.g_handoff_normal)
                
                UNION ALL
                SELECT -1 id_professional, l_any_msg prof_name, 0 rank
                  FROM dual
                 WHERE l_allow_any = 'A'
                 ORDER BY rank, prof_name;
        
        ELSIF i_flg_type NOT IN (pk_edis_list.g_prof_cat_doc, pk_edis_list.g_prof_cat_nrs)
        THEN
            g_error := 'INVALID PROF CAT';
            RAISE l_exception;
        ELSE
            g_error := 'INVALID HANDOFF_NURSE PARAM';
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_dest_profs;

    /**********************************************************************************************
    * Returns the list of DBC owners to display in the overall responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_profs                  List of DBC owners
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dbc_profs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_profs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'GET_HANDOFF_DBC_PROFS';
        l_internal_error EXCEPTION;
    BEGIN
    
        /*****************
        TODO: S?PARA TESTES, DEPOIS INVOCAR API DO CODING
        *****************/
        IF NOT get_handoff_oncall_profs_data(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_profs      => o_profs,
                                             o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        /*****************
        end TODO: S?PARA TESTES, DEPOIS INVOCAR API DO CODING
        *****************/
    
        /* OPEN o_profs FOR
        SELECT 1
          FROM dual;*/
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_dbc_profs;

    /**********************************************************************************************
    * Returns the list of on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param o_profs                  List of on-call physicians ID's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_profs OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'GET_HANDOFF_ONCALL_PROFS';
        l_internal_error EXCEPTION;
        l_tab_on_call table_number := table_number();
    BEGIN
        -- Get a list with the current on-call physicians
        g_error := 'CALL TO GET_ON_CALL_PHYSICIAN_ID_LIST';
        IF NOT pk_on_call_physician.get_on_call_physician_id_list(i_lang     => i_lang,
                                                                  i_prof     => i_prof,
                                                                  o_id_profs => l_tab_on_call,
                                                                  o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Get professional data
        g_error := 'GET PROFS';
        SELECT p.id_professional
          BULK COLLECT
          INTO o_profs
          FROM (SELECT column_value id_prof
                  FROM TABLE(l_tab_on_call)) t
          JOIN professional p
            ON p.id_professional = t.id_prof
          JOIN prof_profile_template ppt
            ON ppt.id_professional = p.id_professional
          JOIN profile_template pt
            ON pt.id_profile_template = ppt.id_profile_template
         WHERE ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND pt.flg_profile = pk_hand_off_core.g_specialist;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_handoff_oncall_profs;

    /**********************************************************************************************
    * Returns the number of available on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    *
    * @return                         Number of available on-call physicians
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        --l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HANDOFF_ONCALL_PROFS_COUNT';
        --
        l_zero CONSTANT PLS_INTEGER := 0;
        l_internal_error EXCEPTION;
        l_error        t_error_out;
        l_profs        table_number;
        l_responsibles table_number;
        l_aux          table_number;
        l_handoff_type sys_config.value%TYPE;
        l_prof_count   PLS_INTEGER;
    BEGIN
        g_error := 'GET HAND OFF TYPE';
        get_hand_off_type(i_lang, i_prof, l_handoff_type);
    
        g_error := 'CALL TO GET_HANDOFF_ONCALL_PROFS';
        IF NOT get_handoff_oncall_profs(i_lang => i_lang, i_prof => i_prof, o_profs => l_profs, o_error => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error        := 'CALL TO GET_PROF_RESP_BY_TYPE';
        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => i_id_episode,
                                                               i_prof_cat      => pk_alert_constant.g_cat_type_doc,
                                                               i_hand_off_type => l_handoff_type);
    
        g_error := 'REMOVE ALREADY RESPONSIBLES PROFS';
        SELECT column_value
          BULK COLLECT
          INTO l_aux
          FROM (SELECT column_value
                  FROM TABLE(l_profs)
                MINUS
                SELECT column_value
                  FROM TABLE(l_responsibles));
    
        g_error := 'CALL TO GET_HANDOFF_ONCALL_PROFS';
        IF l_aux IS NOT NULL
        THEN
            l_prof_count := l_aux.count;
        ELSE
            l_prof_count := l_zero;
        END IF;
    
        RETURN l_prof_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_zero;
    END get_handoff_oncall_profs_count;

    /**********************************************************************************************
    * Returns all data relative to on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_profs                  List of on-call physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_profs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HANDOFF_ONCALL_PROFS_COUNT';
        l_internal_error EXCEPTION;
        l_profs        table_number;
        l_responsibles table_number;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
    
        g_error := 'GET HAND OFF TYPE';
        get_hand_off_type(i_lang, i_prof, l_handoff_type);
    
        g_error := 'CALL TO GET_HANDOFF_ONCALL_PROFS';
        IF NOT get_handoff_oncall_profs(i_lang => i_lang, i_prof => i_prof, o_profs => l_profs, o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error        := 'CALL TO GET_PROF_RESP_BY_TYPE';
        l_responsibles := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => i_id_episode,
                                                               i_prof_cat      => pk_alert_constant.g_cat_type_doc,
                                                               i_hand_off_type => l_handoff_type);
    
        -- Add current professional to the list of current responsibles professionals
        l_responsibles := l_responsibles MULTISET UNION table_number(i_prof.id);
    
        -- Get professional data
        g_error := 'GET PROFS';
        OPEN o_profs FOR
            SELECT p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, ppt.id_institution, ppt.id_software)) prof_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   p.id_speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) prof_spec
              FROM professional p
              JOIN prof_profile_template ppt
                ON ppt.id_professional = p.id_professional
              JOIN profile_template pt
                ON pt.id_profile_template = ppt.id_profile_template
             WHERE p.id_professional IN (SELECT column_value id_prof
                                           FROM TABLE(l_profs))
               AND p.id_professional NOT IN (SELECT column_value
                                               FROM TABLE(l_responsibles))
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND pt.id_software = ppt.id_software;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_oncall_profs_data;

    /**
    * Get all episodes where i_profs are responsible (Used on search criteria)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_prof_cat        Professional category    
    * @param   i_hand_off_type   Type of hand-off (N) Normal (M) Multiple
    * @param   i_profs           Array with id_prof's
    *
    * @return                 Array with id_episode's
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_prof_episodes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_profs         IN table_number
    ) RETURN table_number IS
        l_func_name VARCHAR2(30) := 'GET_PROF_EPISODES';
        --
        l_episodes table_number := NULL;
        --
        l_error t_error_out;
    BEGIN
        IF nvl(i_hand_off_type, pk_hand_off.g_handoff_normal) = pk_hand_off.g_handoff_normal
        THEN
            g_error := 'GET EPISODES NORMAL HAND_OFF (OTHER)';
            SELECT t.id_episode
              BULK COLLECT
              INTO l_episodes
              FROM (SELECT ei.id_episode,
                           decode(i_prof_cat,
                                  pk_hand_off.g_flg_type_d,
                                  ei.id_professional,
                                  pk_hand_off.g_flg_type_n,
                                  ei.id_first_nurse_resp) id_prof
                      FROM epis_info ei) t
             WHERE t.id_prof IN (SELECT column_value id_prof
                                   FROM TABLE(i_profs));
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET EPISODES MULTI HAND_OFF';
            SELECT empr.id_episode
              BULK COLLECT
              INTO l_episodes
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_professional IN (SELECT column_value id_prof
                                              FROM TABLE(i_profs))
               AND empr.flg_status = g_active
               AND ((empr.flg_resp_type = g_resp_episode AND
                   nvl(get_show_overall_resp(i_prof, i_prof_cat), pk_alert_constant.g_no) = pk_alert_constant.g_no) OR
                   empr.flg_resp_type IN (pk_hand_off_core.g_resp_episode, pk_hand_off_core.g_resp_overall))
               AND epr.flg_type = i_prof_cat
               AND epr.flg_status = pk_hand_off.g_hand_off_f;
        ELSE
            g_error    := 'INVALID HAND OFF';
            l_episodes := NULL;
        END IF;
    
        RETURN l_episodes;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_prof_episodes;

    /**
    * Get patient previous professionals
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_patient                Patient id
    * @param i_prof_cat               Professional category
    * @param i_handoff_type           Handoff type
    *
    * @return                 Array with professionals
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_pat_profs_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_prof_cat     IN category.flg_type%TYPE,
        i_handoff_type IN sys_config.value%TYPE
    ) RETURN table_number IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_PAT_PROFS_INT';
        --
        l_profs     table_number;
        l_ret       table_number;
        l_prof_resp table_number;
        --
        l_soft software.id_software%TYPE;
        l_inst institution.id_institution%TYPE;
    BEGIN
    
        g_error     := 'GET CURRENT RESPONSIBLES';
        l_prof_resp := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_id_episode    => i_episode,
                                                            i_prof_cat      => i_prof_cat,
                                                            i_hand_off_type => i_handoff_type);
    
        g_error := 'GET INST AND SOFT VARS';
        SELECT id_institution, id_software
          INTO l_inst, l_soft
          FROM (SELECT ppt.id_institution,
                       ppt.id_software,
                       row_number() over(ORDER BY decode(ppt.id_institution, i_prof.institution, 1, 2), decode(ppt.id_software, i_prof.software, 1, 2)) line_number
                  FROM prof_profile_template ppt
                 WHERE ppt.id_institution IN (0, i_prof.institution)
                   AND ppt.id_software IN (0, i_prof.software))
         WHERE line_number = 1;
    
        IF i_handoff_type = pk_hand_off.g_handoff_normal
        THEN
            g_error := 'GET PROF LST - NORMAL HAND_OFF';
            SELECT DISTINCT decode(i_prof_cat,
                                   pk_alert_constant.g_cat_type_doc,
                                   ei.id_professional,
                                   pk_alert_constant.g_cat_type_nurse,
                                   ei.id_first_nurse_resp)
              BULK COLLECT
              INTO l_profs
              FROM epis_info ei
              JOIN episode epis
                ON epis.id_episode = ei.id_episode
             WHERE epis.id_patient = i_patient
               AND epis.id_episode != i_episode;
        
        ELSIF i_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET PROF LST - MULTIPLE HAND_OFF';
            SELECT DISTINCT empr.id_professional
              BULK COLLECT
              INTO l_profs
              FROM episode epis
              JOIN epis_multi_prof_resp empr
                ON empr.id_episode = epis.id_episode
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE epis.id_patient = i_patient
               AND epis.id_episode != i_episode
               AND ((empr.flg_resp_type = g_resp_episode AND
                   nvl(get_show_overall_resp(i_prof, i_prof_cat), pk_alert_constant.g_no) = pk_alert_constant.g_no) OR
                   empr.flg_resp_type IN (g_resp_episode, g_resp_overall))
               AND epr.flg_type = i_prof_cat
               AND epr.flg_status IN (pk_hand_off.g_hand_off_f, pk_hand_off.g_hand_off_t);
        ELSE
            g_error := 'SET PROF LST TO NULL - INVALID HAND_OFF';
            l_profs := NULL;
        END IF;
    
        g_error := 'REMOVE CURRENT RESPONSIBLES';
        l_profs := l_profs MULTISET except DISTINCT l_prof_resp;
    
        g_error := 'REMOVE NULL VALUES';
        SELECT /*+ opt_estimate(table p rows=10)*/
         column_value
          BULK COLLECT
          INTO l_ret
          FROM TABLE(l_profs) p
          JOIN prof_profile_template ppt
            ON ppt.id_professional = p.column_value
           AND ppt.id_software = l_soft
           AND ppt.id_institution = l_inst
          JOIN profile_template pt
            ON pt.id_profile_template = ppt.id_profile_template
           AND pt.id_software = l_soft
          JOIN prof_institution pi
            ON pi.id_professional = p.column_value
           AND pi.id_institution = i_prof.institution
           AND pi.flg_state = pk_edis_list.g_prof_active
           AND pi.dt_end_tstz IS NULL
         WHERE p.column_value IS NOT NULL;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_profs_int;

    /**
    * Get patient previous responsibles
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param o_profs                  List of on-call physicians ID's
    * @param o_error                  Error message
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_previous_responsibles
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_PREVIOUS_RESPONSIBLES';
        --
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
        l_patient      patient.id_patient%TYPE;
        l_profs        table_number;
    BEGIN
        g_error    := 'GET PROF CAT';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET PATIENT ID';
        SELECT epis.id_patient
          INTO l_patient
          FROM episode epis
         WHERE epis.id_episode = i_episode;
    
        g_error := 'GET PREVIOUS PAT PROFS';
        l_profs := get_pat_profs_int(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_episode      => i_episode,
                                     i_patient      => l_patient,
                                     i_prof_cat     => l_prof_cat,
                                     i_handoff_type => l_handoff_type);
    
        g_error := 'GET TYPE OF HAND-OFF';
        OPEN o_profs FOR
            SELECT p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) prof_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   p.id_speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) prof_spec
              FROM professional p
             WHERE p.id_professional IN (SELECT column_value id_prof
                                           FROM TABLE(l_profs))
             ORDER BY prof_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_previous_responsibles;

    /**
    * Get clin_serv or department or speciality label
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_clin_serv              Clinical service id
    * @param i_department             Department id
    * @param i_speciality             Speciality id
    * @param i_handoff_type           Handoff type
    * @param i_prof_cat               Professional category
    *
    * @return                 corresponding label
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_cs_dep_spec_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_department   IN department.id_department%TYPE,
        i_speciality   IN speciality.id_speciality%TYPE,
        i_handoff_type IN sys_config.value%TYPE DEFAULT NULL,
        i_prof_cat     IN category.flg_type%TYPE DEFAULT NULL
    ) RETURN sys_message.desc_message%TYPE IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_CS_DEP_SPEC_LABEL';
        --
        l_cs_dep_spec_label sys_message.desc_message%TYPE;
        --
        FUNCTION get_msg_clin_serv RETURN sys_message.desc_message%TYPE IS
            l_code_msg_clin_serv CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M048'; -- Clinical Service:
        BEGIN
            g_error := 'GET Clinical Service';
            IF g_desc_msg_clin_serv IS NULL
            THEN
                g_desc_msg_clin_serv := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_clin_serv);
            END IF;
        
            RETURN g_desc_msg_clin_serv;
        END get_msg_clin_serv;
    
        FUNCTION get_msg_service RETURN sys_message.desc_message%TYPE IS
            l_code_msg_service CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M081'; -- Service
        BEGIN
            g_error := 'GET Service';
            IF g_desc_msg_service IS NULL
            THEN
                g_desc_msg_service := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_service) || ':';
            END IF;
        
            RETURN g_desc_msg_service;
        END get_msg_service;
    
        FUNCTION get_msg_department RETURN sys_message.desc_message%TYPE IS
            l_code_msg_department CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M080'; -- Department:
        BEGIN
            g_error := 'GET Department';
            IF g_desc_msg_department IS NULL
            THEN
                g_desc_msg_department := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_department);
            END IF;
        
            RETURN g_desc_msg_department;
        END get_msg_department;
    
        FUNCTION get_msg_speciality RETURN sys_message.desc_message%TYPE IS
            l_code_msg_speciality CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M049'; -- Speciality:
        BEGIN
            g_error := 'GET Clinical Service';
            IF g_desc_msg_speciality IS NULL
            THEN
                g_desc_msg_speciality := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_speciality);
            END IF;
        
            RETURN g_desc_msg_speciality;
        END get_msg_speciality;
    BEGIN
        g_error             := 'GET LABEL AND DESCRIPTION';
        l_cs_dep_spec_label := CASE
                                   WHEN i_prof_cat = pk_alert_constant.g_cat_type_doc
                                        AND i_handoff_type = pk_hand_off.g_handoff_multiple THEN
                                    get_msg_speciality()
                                   WHEN i_prof_cat = pk_alert_constant.g_cat_type_doc
                                        AND i_handoff_type = pk_hand_off.g_handoff_normal THEN
                                    get_msg_clin_serv()
                                   WHEN i_prof_cat = pk_alert_constant.g_cat_type_nurse THEN
                                    get_msg_service()
                                   WHEN i_clin_serv IS NOT NULL THEN
                                    get_msg_clin_serv()
                                   WHEN i_department IS NOT NULL THEN
                                    get_msg_department()
                                   WHEN i_speciality IS NOT NULL THEN
                                    get_msg_speciality()
                                   ELSE
                                    NULL
                               END;
    
        RETURN l_cs_dep_spec_label;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cs_dep_spec_label;

    /**
    * Get clin_serv or department or speciality description
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_clin_serv              Clinical service id
    * @param i_department             Department id
    * @param i_speciality             Speciality id
    *
    * @return                         Description
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_cs_dep_spec_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_clin_serv  IN clinical_service.id_clinical_service%TYPE,
        i_department IN department.id_department%TYPE,
        i_speciality IN speciality.id_speciality%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_CS_DEP_SPEC_DESC';
        --
        l_cs_dep_spec_desc pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET LABEL AND DESCRIPTION';
        SELECT coalesce(decode(i_clin_serv,
                               NULL,
                               NULL,
                               (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                  FROM clinical_service cs
                                 WHERE cs.id_clinical_service = i_clin_serv)),
                        decode(i_department,
                               NULL,
                               NULL,
                               (SELECT pk_translation.get_translation(i_lang, d.code_department)
                                  FROM department d
                                 WHERE d.id_department = i_department)),
                        decode(i_speciality,
                               NULL,
                               NULL,
                               (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                  FROM speciality s
                                 WHERE s.id_speciality = i_speciality))) description
          INTO l_cs_dep_spec_desc
          FROM dual;
    
        RETURN l_cs_dep_spec_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cs_dep_spec_desc;

    /********************************************************************************************
    * Get category description of given professional
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_handoff_type              Hand off type
    * @param i_prof_id                   Professional who made the record
    * @param i_prof_type                 Professional type
    * @param i_flg_profile               Epis_multi_prof_resp flag profile
    * @param i_flg_type                  Epis_prof_resp flag type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @value   i_prof_type    {*} 'R' Request
    *                         {*} 'T' To
    *
    * @return                            Category description
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_desc_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_handoff_type IN sys_config.value%TYPE,
        i_prof_id      IN professional.id_professional%TYPE,
        i_prof_type    IN VARCHAR2,
        i_flg_profile  IN epis_multi_prof_resp.flg_profile%TYPE,
        i_flg_type     IN epis_prof_resp.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        --l_func_name CONSTANT VARCHAR2(50) := 'GET_DES_CATEGORY';
        --
        l_code_dom_pt_flg_profile CONSTANT sys_domain.code_domain%TYPE := 'PROFILE_TEMPLATE.FLG_PROFILE';
        l_code_dom_epr_flg_type   CONSTANT sys_domain.code_domain%TYPE := 'EPIS_PROF_RESP.FLG_TYPE';
        --
        l_desc pk_translation.t_desc_translation;
        l_prof profissional := profissional(id          => i_prof_id,
                                            institution => i_prof.institution,
                                            software    => i_prof.software);
    BEGIN
        g_error := 'IN VAR''s - i_lang: ' || i_lang || '; i_prof: (' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '); i_handoff_type: ' || i_handoff_type || '; i_prof_id: ' || i_prof_id ||
                   '; i_prof_type: ' || i_prof_type || '; i_flg_profile: ' || i_flg_profile || '; i_flg_type: ' ||
                   i_flg_type || ';';
    
        IF i_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
            IF i_prof_type = pk_hand_off_core.g_prof_type_to
               AND i_flg_profile IS NOT NULL
            THEN
                g_error := 'GET EMPR FLG_PROFILE DOMAIN';
                l_desc  := pk_sysdomain.get_domain(i_code_dom => l_code_dom_pt_flg_profile,
                                                   i_val      => i_flg_profile,
                                                   i_lang     => i_lang);
            ELSIF i_prof_type = pk_hand_off_core.g_prof_type_req
            THEN
                BEGIN
                    g_error := 'GET PT FLG_PROFILE DOMAIN';
                    SELECT pk_sysdomain.get_domain(l_code_dom_pt_flg_profile, pt.flg_profile, i_lang)
                      INTO l_desc
                      FROM profile_template pt
                     WHERE pt.id_profile_template = pk_prof_utils.get_prof_profile_template(l_prof);
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'GET EMPR FLG_PROFILE DOMAIN - NO_DATA_FOUND';
                        l_desc  := NULL;
                END;
            ELSE
                g_error := 'MULTIPLE - INVALID OPTION';
                l_desc  := NULL;
            END IF;
        ELSIF i_handoff_type = pk_hand_off.g_handoff_normal
        THEN
            IF i_prof_type = pk_hand_off_core.g_prof_type_to
               AND i_flg_type IS NOT NULL
            THEN
                g_error := 'GET EPR FLG_TYPE DOMAIN';
                l_desc  := pk_sysdomain.get_domain(i_code_dom => l_code_dom_epr_flg_type,
                                                   i_val      => i_flg_type,
                                                   i_lang     => i_lang);
            ELSIF i_prof_type = pk_hand_off_core.g_prof_type_req
            THEN
                g_error := 'GET PK_PROF_UTILS.GET_DESC_CATEGORY';
                l_desc  := pk_prof_utils.get_desc_category(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_prof_id   => i_prof_id,
                                                           i_prof_inst => i_prof.institution);
            ELSE
                g_error := 'NORMAL - INVALID OPTION';
                l_desc  := NULL;
            END IF;
        ELSE
            g_error := 'INVALID HANDOFF';
            l_desc  := NULL;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_category;

    /**
    * Get hand off configuration vars
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_flg_type               Transf. type
    * @param o_label                  Speciality or Clinical Service or Department
    * @param o_handoff_type           Hand off type
    * @param o_error                  Error message
    *
    * @value   i_flg_type     {*} 'D' Physician
    *                         {*} 'N' Nurse
    *
    * @value   o_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_hand_off_vars
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN category.flg_type%TYPE,
        o_label        OUT sys_message.code_message%TYPE,
        o_handoff_type OUT sys_config.value%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_HAND_OFF_VARS';
        --
        l_sys_conf_handoff_nurse CONSTANT sys_config.id_sys_config%TYPE := 'HANDOFF_NURSE';
        --
        l_code_msg_clin_serv  CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_T032'; -- Clinical Service
        l_code_msg_department CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M081'; -- Service
        l_code_msg_speciality CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_T009'; -- Speciality
        --
        l_handoff_nurse sys_config.value%TYPE;
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => o_handoff_type);
        l_handoff_nurse := pk_sysconfig.get_config(l_sys_conf_handoff_nurse, i_prof.institution, i_prof.software);
    
        IF o_handoff_type = pk_hand_off.g_handoff_multiple
           AND i_flg_type = pk_edis_list.g_prof_cat_doc
        THEN
            g_error := 'GET MSG SPEC';
            o_label := l_code_msg_speciality;
        ELSIF i_flg_type = pk_edis_list.g_prof_cat_doc
              OR
              (i_flg_type = pk_edis_list.g_prof_cat_nrs AND l_handoff_nurse = pk_edis_list.g_handoff_nurse_clin_serv)
        THEN
            g_error := 'GET MSG CLIN_SERV';
            o_label := l_code_msg_clin_serv;
        ELSIF l_handoff_nurse = pk_edis_list.g_handoff_nurse_department
        THEN
            g_error := 'GET MSG DEPART';
            o_label := l_code_msg_department;
        ELSE
            g_error := 'INVALID OPTION';
            o_label := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_hand_off_vars;

    /********************************************************************************************
    * Set the responsible professionals in EPIS_INFO.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Professional ID
    * @param   i_id_professional_nin      Ignore NULL values: TRUE/FALSE
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_resp_type            Type of responsability
    * @param   o_error                    Error message
    *
    * @value   i_flg_resp_type            {*} E - Episode responsability
    *                                     {*} O - Overall responsability
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          17-12-2010
    **********************************************************************************************/
    FUNCTION call_set_epis_info_resp
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_professional_nin IN BOOLEAN,
        i_prof_cat            IN category.flg_type%TYPE,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CALL_SET_EPIS_INFO_RESP';
        l_hand_off_type sys_config.value%TYPE;
        l_rowids        table_varchar;
    BEGIN
    
        IF i_prof.software IN ( --pk_alert_constant.g_soft_outpatient,
                               pk_alert_constant.g_soft_social,
                               pk_alert_constant.g_soft_nutritionist,
                               pk_alert_constant.g_soft_primary_care)
        THEN
            g_error := 'GET TYPE OF HAND-OFF';
            get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        
            IF l_hand_off_type = pk_hand_off.g_handoff_multiple
               AND i_flg_resp_type = g_resp_overall
            THEN
                -- In OUTPATIENT, the OVERALL responsability should not be registered in EPIS_INFO.
                -- Exit function and do nothing.
                RETURN TRUE;
            END IF;
        END IF;
    
        IF i_prof_cat = pk_alert_constant.g_cat_type_nurse
        THEN
            g_error := 'UPDATE EPIS_INFO (N)';
            ts_epis_info.upd(id_episode_in           => i_id_episode,
                             id_first_nurse_resp_in  => i_id_professional,
                             id_first_nurse_resp_nin => i_id_professional_nin,
                             rows_out                => l_rowids);
        
        ELSE
            g_error := 'UPDATE EPIS_INFO (OTHER)';
            ts_epis_info.upd(id_episode_in       => i_id_episode,
                             id_professional_in  => i_id_professional,
                             id_professional_nin => i_id_professional_nin,
                             rows_out            => l_rowids);
        END IF;
    
        g_error := 'PROCESS UPDATE EPIS_INFO';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rowids,
                                      i_list_columns => table_varchar('ID_PROFESSIONAL', 'ID_FIRST_NURSE_RESP'),
                                      o_error        => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_epis_info_resp;

    /********************************************************************************************
    * Set all responsible professionals in EPIS_INFO.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Professional ID
    * @param   i_id_professional_nin      Ignore NULL values: TRUE/FALSE
    * @param   i_prof_cat                 Professional category of 'i_id_professional'
    * @param   i_id_prof_nurse            Nurse professional ID
    * @param   i_id_prof_nurse_nin        Ignore NULL values: TRUE/FALSE
    * @param   i_flg_resp_type            Type of responsability
    * @param   o_error                    Error message
    *
    * @value   i_flg_resp_type            {*} E - Episode responsability
    *                                     {*} O - Overall responsability
    *
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          17-12-2010
    **********************************************************************************************/
    FUNCTION call_set_epis_info_resp_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_professional_nin IN BOOLEAN,
        i_prof_cat            IN category.flg_type%TYPE,
        i_id_prof_nurse       IN professional.id_professional%TYPE,
        i_id_prof_nurse_nin   IN BOOLEAN,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CALL_SET_EPIS_INFO_RESP_ALL';
    
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'UPDATE EPIS_INFO (1)';
        IF NOT call_set_epis_info_resp(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_episode          => i_id_episode,
                                       i_id_professional     => i_id_professional,
                                       i_id_professional_nin => i_id_professional_nin,
                                       i_prof_cat            => i_prof_cat,
                                       i_flg_resp_type       => i_flg_resp_type,
                                       o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'UPDATE EPIS_INFO (2)';
        IF NOT call_set_epis_info_resp(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_episode          => i_id_episode,
                                       i_id_professional     => i_id_prof_nurse,
                                       i_id_professional_nin => i_id_prof_nurse_nin,
                                       i_prof_cat            => pk_alert_constant.g_cat_type_nurse,
                                       i_flg_resp_type       => i_flg_resp_type,
                                       o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_epis_info_resp_all;

    /********************************************************************************************
    * Get the most recent responsability record ID and responsible professional ID
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_flg_transf_type          Type of responsability: (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability Speciality ID
    * @param   i_flg_profile              Type of profile: (S)Specialist (R)Resident (I)Intern (N)Nurse
    * @param   i_hand_off_type            Type of hand-off: (N) Normal (M) Multiple
    * @param   o_id_epis_prof_resp        Responsability ID
    * @param   o_id_prof_resp             Responsible professional ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          17-12-2010
    **********************************************************************************************/
    FUNCTION get_current_epis_prof_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_type          IN epis_prof_resp.flg_type%TYPE,
        i_flg_transf_type   IN epis_prof_resp.flg_transf_type%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_profile       IN epis_multi_prof_resp.flg_profile%TYPE,
        i_hand_off_type     IN VARCHAR2,
        o_id_epis_prof_resp OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_prof_resp      OUT epis_prof_resp.id_prof_comp%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_CURRENT_EPIS_PROF_RESP';
        l_param_error EXCEPTION;
    
        l_id_epis_prof_resp epis_prof_resp.id_epis_prof_resp%TYPE;
        l_id_prof_resp      epis_prof_resp.id_prof_comp%TYPE;
    BEGIN
    
        IF i_hand_off_type = pk_hand_off.g_handoff_multiple
           AND i_flg_transf_type = pk_hand_off.g_flg_transf_o
        THEN
        
            -- OVERALL responsability only returns the MAIN overall responsible
            BEGIN
                g_error := 'GET LAST RESP (1)';
                SELECT empr.id_epis_prof_resp, empr.id_professional
                  INTO l_id_epis_prof_resp, l_id_prof_resp
                  FROM epis_multi_prof_resp empr
                  JOIN epis_prof_resp epr
                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                 WHERE empr.id_episode = i_id_episode
                   AND empr.flg_status = g_active
                   AND empr.flg_main_responsible = pk_alert_constant.g_yes
                   AND empr.flg_resp_type = i_flg_transf_type
                   AND epr.flg_type = i_flg_type;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_prof_resp := NULL;
                    l_id_prof_resp      := NULL;
            END;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
              AND i_flg_transf_type IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_a)
        THEN
        
            IF i_flg_profile IS NULL
               OR (i_flg_profile <> pk_hand_off_core.g_nurse AND i_id_speciality IS NULL)
            THEN
                g_error := 'MISSING FLG_PROFILE OR ID_SPECIALITY';
                RAISE l_param_error;
            END IF;
        
            BEGIN
                g_error := 'GET LAST RESP (1)';
                SELECT empr.id_epis_prof_resp, empr.id_professional
                  INTO l_id_epis_prof_resp, l_id_prof_resp
                  FROM epis_multi_prof_resp empr
                  JOIN epis_prof_resp epr
                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                 WHERE empr.id_episode = i_id_episode
                   AND empr.flg_status = g_active
                   AND empr.flg_resp_type = pk_hand_off_core.g_resp_episode
                   AND empr.flg_profile = i_flg_profile
                   AND (empr.id_speciality = i_id_speciality OR
                       empr.id_speciality IS NULL AND i_flg_type = pk_hand_off_core.g_nurse)
                   AND epr.flg_type = i_flg_type;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_prof_resp := NULL;
                    l_id_prof_resp      := NULL;
            END;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
        
            BEGIN
                g_error := 'GET LAST RESP (2)';
                SELECT t.id_epis_prof_resp, t.id_prof_comp
                  INTO l_id_epis_prof_resp, l_id_prof_resp
                  FROM (SELECT epr.id_epis_prof_resp,
                               epr.id_prof_comp,
                               epr.id_episode,
                               row_number() over(PARTITION BY epr.id_episode ORDER BY epr.dt_comp_tstz DESC) row_number
                          FROM epis_prof_resp epr
                         WHERE epr.flg_status = pk_hand_off.g_hand_off_f
                           AND epr.id_prof_comp IS NOT NULL
                           AND epr.dt_end_transfer_tstz IS NULL
                           AND epr.flg_transf_type = i_flg_transf_type
                           AND epr.flg_type = i_flg_type) t
                 WHERE t.id_episode = i_id_episode
                   AND t.row_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_prof_resp := NULL;
                    l_id_prof_resp      := NULL;
            END;
        
        ELSE
            g_error := 'PARAMETER ERROR';
            RAISE l_param_error;
        
        END IF;
    
        o_id_epis_prof_resp := l_id_epis_prof_resp;
        o_id_prof_resp      := l_id_prof_resp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              g_error,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_current_epis_prof_resp;

    /********************************************************************************************
    * Function that matches to episodes responsibles physicians/nurses records
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 17-12-2010
    ********************************************************************************************/
    FUNCTION set_resp_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_RESP_MATCH';
        --
        l_tbl_epr      table_number;
        l_count        PLS_INTEGER;
        l_handoff_type sys_config.value%TYPE;
        --
        PROCEDURE del_epr(i_del_epr IN table_number) IS
            --l_proc_name CONSTANT VARCHAR2(30) := 'DEL_EPR';
        BEGIN
            g_error := 'DELETE EPIS_PROF_RESP: ' || pk_utils.concat_table(i_tab => i_del_epr);
            DELETE FROM epis_prof_resp epr
             WHERE epr.id_epis_prof_resp IN (SELECT column_value id_epis_prof_resp
                                               FROM TABLE(i_del_epr));
        END del_epr;
        --
        PROCEDURE del_empr(i_del_empr IN table_number) IS
            --l_proc_name CONSTANT VARCHAR2(30) := 'DEL_EMPR';
        BEGIN
            g_error := 'DELETE EPIS_MULTI_PROF_RESP: ' || pk_utils.concat_table(i_tab => i_del_empr);
            DELETE FROM epis_multi_prof_resp empr
             WHERE empr.id_epis_prof_resp IN (SELECT column_value id_epis_prof_resp
                                                FROM TABLE(i_del_empr));
        END del_empr;
        --
        PROCEDURE del_empr_hist(i_del_empr_hist IN table_number) IS
            --l_proc_name CONSTANT VARCHAR2(30) := 'DEL_EMPR_HIST';
        BEGIN
            g_error := 'DELETE EPIS_MULTI_PROFRESP_HIST: ' || pk_utils.concat_table(i_tab => i_del_empr_hist);
            DELETE FROM epis_multi_profresp_hist empr
             WHERE empr.id_epis_prof_resp IN (SELECT column_value id_epis_prof_resp
                                                FROM TABLE(i_del_empr_hist));
        END del_empr_hist;
        --
        PROCEDURE del_resp(i_tbl_resp IN table_number) IS
            --l_proc_name CONSTANT VARCHAR2(30) := 'DEL_RESP';
        BEGIN
            g_error := 'DELETE EPIS_MULTI_PROFRESP_HIST';
            del_empr_hist(i_del_empr_hist => i_tbl_resp);
        
            g_error := 'DELETE EPIS_MULTI_PROF_RESP';
            del_empr(i_del_empr => i_tbl_resp);
        
            g_error := 'DELETE EPIS_PROF_RESP';
            del_epr(i_del_epr => i_tbl_resp);
        END del_resp;
    BEGIN
        g_error := 'Init';
        g_error := 'GET HANDOFF TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --Handle duplicated responsibilities records
        --Get temporary episode responsibles that already exists on the definitive episode
        g_error := 'GET DUPLICATED CURRENT RESPONSIBLES';
        SELECT epr_tmp.id_epis_prof_resp
          BULK COLLECT
          INTO l_tbl_epr
          FROM epis_prof_resp epr
          JOIN epis_prof_resp epr_tmp
            ON epr_tmp.id_prof_comp = epr.id_prof_comp --This equality means that in both episodes the responsible professional already exists
         WHERE epr.id_episode = i_episode
           AND epr_tmp.id_episode = i_episode_temp;
    
        --Delete duplicated responsabilities
        g_error := 'DELETE DUPLICATED CURRENT RESPONSIBLES';
        del_resp(i_tbl_resp => l_tbl_epr);
    
        --The normal handoff type can only have one request per episode
        g_error := 'HANDOFF TYPE: ' || l_handoff_type;
        IF l_handoff_type = pk_hand_off.g_handoff_normal
        THEN
            --Count total requests of the definitive episode
            g_error := 'TOTAL DEFINITIVE_EPIS REQUESTS';
            SELECT COUNT(*)
              INTO l_count
              FROM epis_prof_resp epr
             WHERE epr.id_episode = i_episode
               AND epr.flg_status = pk_hand_off.g_hand_off_r;
        
            --Initizalize array
            l_tbl_epr := table_number();
            --Get requests of the temporary episode
            g_error := 'GET TEMPORARY_EPIS REQUESTS';
            SELECT epr.id_epis_prof_resp
              BULK COLLECT
              INTO l_tbl_epr
              FROM epis_prof_resp epr
             WHERE epr.id_episode = i_episode_temp
               AND epr.flg_status = pk_hand_off.g_hand_off_r;
        
            --If there isn't any request in the definitive episode just update the temporary episode id to the definitive episode id.
            --If there isn't any request in the temporary episode there isn't nothing to do.
            IF l_count > 0
               AND l_tbl_epr.count > 0
            THEN
                --Delete duplicated requests
                g_error := 'DELETE DUPLICATED REQUESTS';
                del_resp(i_tbl_resp => l_tbl_epr);
            END IF;
        ELSIF l_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
            --Initizalize array
            l_tbl_epr := table_number();
        
            --Get requests of the temporary episode that exists on definitive episode
            g_error := 'GET DUPLICATED TEMPORARY_EPIS REQUESTS';
            SELECT empr.id_epis_prof_resp
              BULK COLLECT
              INTO l_tbl_epr
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_episode = i_episode_temp
               AND epr.flg_status = pk_hand_off.g_hand_off_r
               AND EXISTS (SELECT 1
                      FROM epis_multi_prof_resp empr2
                      JOIN epis_prof_resp epr2
                        ON epr2.id_epis_prof_resp = empr2.id_epis_prof_resp
                     WHERE empr2.id_episode = i_episode
                       AND empr2.id_speciality = empr.id_speciality --Requests that exists on both episodes for the same speciality
                       AND epr2.flg_status = pk_hand_off.g_hand_off_r);
        
            IF l_tbl_epr.count > 0
            THEN
                --Delete duplicated requests
                g_error := 'DELETE DUPLICATED REQUESTS';
                del_resp(i_tbl_resp => l_tbl_epr);
            END IF;
        END IF;
    
        --Update temporary episode id to definitive one
        g_error := 'UPDT EPIS_MULTI_PROFRESP_HIST EPISODE. FROM: ' || i_episode_temp || '; TO: ' || i_episode;
        UPDATE epis_multi_profresp_hist emprh
           SET emprh.id_episode = i_episode
         WHERE emprh.id_episode = i_episode_temp;
    
        g_error := 'UPDT EPIS_MULTI_PROF_RESP EPISODE. FROM: ' || i_episode_temp || '; TO: ' || i_episode;
        UPDATE epis_multi_prof_resp empr
           SET empr.id_episode = i_episode
         WHERE empr.id_episode = i_episode_temp;
    
        g_error := 'UPDT EPIS_PROF_RESP EPISODE. FROM: ' || i_episode_temp || '; TO: ' || i_episode;
        UPDATE epis_prof_resp epr
           SET epr.id_episode = i_episode
         WHERE epr.id_episode = i_episode_temp;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_resp_match;

    /********************************************************************************************
    * Function that checks the episode responsible in EPIS_INFO.
    * Used mostly for OUTPATIENT hand-off logic.
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_episode            Episode ID
    * @param i_prof_cat              Professional category
    * @param o_id_professional       Responsible professional ID
    * @param o_error                 Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Jos?Brito
    * @version               2.6
    * @since                 12-01-2011
    ********************************************************************************************/
    FUNCTION get_epis_info_resp
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_prof_cat        IN category.flg_type%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE DEFAULT NULL,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_EPIS_INFO_RESP';
        l_prof_id table_number;
    BEGIN
    
        SELECT decode(i_prof_cat,
                      pk_alert_constant.g_cat_type_doc,
                      ei.id_professional,
                      pk_alert_constant.g_cat_type_nurse,
                      ei.id_first_nurse_resp,
                      ei.id_professional)
          BULK COLLECT
          INTO l_prof_id
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        IF i_epis_type = pk_alert_constant.g_epis_type_rehab_session
           AND o_id_professional IS NULL
        THEN
            SELECT rsn.id_resp_professional
              BULK COLLECT
              INTO l_prof_id
              FROM rehab_sch_need rsn
              JOIN rehab_epis_encounter re
                ON re.id_rehab_sch_need = rsn.id_rehab_sch_need
             WHERE re.id_episode_rehab = i_id_episode;
        
        END IF;
        IF l_prof_id.count > 0
        THEN
            o_id_professional := l_prof_id(1);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_info_resp;

    /********************************************************************************************
    * Cancel a SPECIALIST PHYSICIAN responsability record that is in "finalized" state.
    * Used by INTER-
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_professional         Specialist physician ID
    * @param i_notes                   Cancellation notes
    * @param i_id_cancel_reason        Cancel reason ID
    * @param i_dt_cancel               Cancellation date
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           13-Jul-2011
    *
    **********************************************************************************************/
    FUNCTION cancel_responsability_spec
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CANCEL_RESPONSABILITY_SPEC';
    
        l_hand_off_type       sys_config.value%TYPE;
        l_id_epis_prof_resp   epis_prof_resp.id_epis_prof_resp%TYPE;
        l_current_responsible professional.id_professional%TYPE;
    
        l_internal_error EXCEPTION;
        l_param_error    EXCEPTION;
        l_error_message VARCHAR2(200 CHAR);
    
    BEGIN
    
        g_error := 'GET HAND_OFF TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
    
        -- Check parameters
        IF i_id_professional IS NULL
        THEN
            l_error_message := 'PROFESSIONAL ID IS NULL';
            RAISE l_param_error;
        ELSIF i_id_episode IS NULL
        THEN
            l_error_message := 'EPISODE ID IS NULL';
            RAISE l_param_error;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            -- In "NORMAL" hand-off, check EPIS_INFO for responsability.
            g_error := 'CHECK MAIN RESPONSABILITY';
            SELECT ei.id_professional
              INTO l_current_responsible
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF l_current_responsible <> i_id_professional
            THEN
                l_error_message := 'PROFESSIONAL ID IS NOT RESPONSIBLE FOR EPISODE';
                RAISE l_param_error;
            END IF;
        
            g_error := 'CHECK RESPONSABILITY RECORD (1)';
            BEGIN
                SELECT t.id_epis_prof_resp
                  INTO l_id_epis_prof_resp
                  FROM (SELECT epr.id_epis_prof_resp
                          FROM epis_prof_resp epr
                         WHERE epr.id_episode = i_id_episode
                           AND epr.id_prof_comp = i_id_professional
                           AND epr.flg_type = pk_alert_constant.g_cat_type_doc
                           AND epr.flg_status = pk_hand_off.g_hand_off_f
                           AND epr.flg_transf_type IN (pk_hand_off.g_flg_transf_i, pk_hand_off.g_flg_transf_a)
                           AND epr.dt_end_transfer_tstz IS NULL
                         ORDER BY epr.dt_comp_tstz) t
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_prof_resp := NULL;
            END;
        
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- A responsible specialist must meet all these conditions.
            g_error := 'CHECK RESPONSABILITY RECORD (2)';
            SELECT empr.id_epis_prof_resp
              INTO l_id_epis_prof_resp
              FROM epis_multi_prof_resp empr
             WHERE empr.id_professional = i_id_professional
               AND empr.id_episode = i_id_episode
               AND empr.flg_status = g_active
               AND empr.flg_profile = g_specialist;
        
        ELSE
            l_error_message := 'INVALID HAND-OFF TYPE';
            RAISE l_param_error;
        END IF;
    
        IF l_id_epis_prof_resp IS NULL
        THEN
            l_error_message := 'RESPONSABILITY RECORD ID NOT FOUND';
            RAISE l_param_error;
        END IF;
    
        g_error := 'CALL TO CALL_CANCEL_RESPONSABILITY';
        IF NOT call_cancel_responsability(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_epis_prof_resp   => l_id_epis_prof_resp,
                                          i_flg_type         => pk_alert_constant.g_cat_type_doc,
                                          i_notes            => i_notes,
                                          i_id_cancel_reason => i_id_cancel_reason,
                                          i_dt_cancel        => i_dt_cancel,
                                          o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              l_error_message,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_responsability_spec;

    /********************************************************************************************
    * Cancel a responsability record that is in "finalized" state.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1
    * @since                          07-06-2011
    **********************************************************************************************/
    FUNCTION cancel_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'CANCEL_RESPONSABILITY';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO CALL_CANCEL_RESPONSABILITY';
        IF NOT call_cancel_responsability(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_epis_prof_resp   => i_epis_prof_resp,
                                          i_flg_type         => i_flg_type,
                                          i_notes            => i_notes,
                                          i_id_cancel_reason => i_id_cancel_reason,
                                          i_dt_cancel        => NULL,
                                          o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_responsability;

    /********************************************************************************************
    * Cancel a responsability record that is in "finalized" state.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param i_dt_cancel               Cancellation date
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1
    * @since                          07-06-2011
    **********************************************************************************************/
    FUNCTION call_cancel_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CALL_CANCEL_RESPONSABILITY';
        --
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
        --
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_rowids       table_varchar;
        --
        l_hand_off_type           sys_config.value%TYPE;
        l_epr                     epis_prof_resp%ROWTYPE;
        l_empr                    epis_multi_prof_resp%ROWTYPE;
        l_epis_flg_status         episode.flg_status%TYPE;
        l_dt_first_obs            epis_info.dt_first_obs_tstz%TYPE;
        l_dt_first_nurse_obs      epis_info.dt_first_nurse_obs_tstz%TYPE;
        l_epis_info_doc_resp      epis_info.id_professional%TYPE;
        l_epis_info_nurse_resp    epis_info.id_first_nurse_resp%TYPE;
        l_can_refresh_mview_str   VARCHAR2(1 CHAR);
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
    BEGIN
        g_error := 'Init';
    
        l_sysdate_tstz := nvl(i_dt_cancel, current_timestamp);
    
        g_error := 'GET HAND_OFF TYPE';
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
    
        g_error := 'GET EPIS_PROF_RESP ROW';
        SELECT epr.*
          INTO l_epr
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp = i_epis_prof_resp;
    
        g_error := 'GET EPISODE STATUS, DT_FIRST_OBS AND DT_FIRST_NURSE_OBS';
        SELECT epis.flg_status,
               ei.dt_first_obs_tstz,
               ei.dt_first_nurse_obs_tstz,
               ei.id_professional,
               ei.id_first_nurse_resp
          INTO l_epis_flg_status, l_dt_first_obs, l_dt_first_nurse_obs, l_epis_info_doc_resp, l_epis_info_nurse_resp
          FROM episode epis
          JOIN epis_info ei
            ON ei.id_episode = epis.id_episode
         WHERE epis.id_episode = l_epr.id_episode;
    
        IF l_epis_flg_status <> pk_alert_constant.g_active
        THEN
            -- Episode must be active in order to cancel a responsability record.
            g_error := 'INVALID EPISODE STATUS';
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE l_param_error;
        END IF;
    
        IF l_epr.flg_status = pk_hand_off.g_hand_off_c
        THEN
            g_error := 'HANDOFF ALREADY CANCELED';
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE l_param_error;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            g_error := 'CANCEL REQUEST RESP';
            IF NOT pk_hand_off.call_set_epis_prof_resp(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_tot_epis         => table_number(1),
                                                       i_epis_prof_resp   => table_varchar(i_epis_prof_resp),
                                                       i_flg_status       => pk_hand_off.g_hand_off_c,
                                                       i_flg_type         => i_flg_type,
                                                       i_notes            => i_notes,
                                                       i_sysdate          => NULL,
                                                       i_hand_off_type    => NULL,
                                                       i_one_step_process => 'N',
                                                       i_id_cancel_reason => i_id_cancel_reason,
                                                       o_refresh_mview    => l_can_refresh_mview_str,
                                                       o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        ELSIF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET MULTIPLE RESPONSABILITY DATA';
            SELECT empr.*
              INTO l_empr
              FROM epis_multi_prof_resp empr
             WHERE empr.id_epis_prof_resp = i_epis_prof_resp;
        
            g_error := 'UPDATE EPIS_PROF_RESP';
            UPDATE epis_prof_resp
               SET dt_cancel_tstz   = l_sysdate_tstz,
                   flg_status       = pk_hand_off.g_hand_off_c,
                   id_prof_cancel   = i_prof.id,
                   notes_cancel     = i_notes,
                   id_cancel_reason = i_id_cancel_reason
             WHERE id_epis_prof_resp = i_epis_prof_resp;
        
            g_error := 'MANAGE MULTI HAND-OFF MECHANISM';
            IF NOT pk_hand_off_core.set_multi_prof_resp(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_id_episode              => l_epr.id_episode,
                                                        i_id_prof_resp            => l_empr.id_professional,
                                                        i_flg_profile             => l_empr.flg_profile,
                                                        i_id_epis_prof_resp       => i_epis_prof_resp,
                                                        i_flg_status              => pk_hand_off.g_hand_off_c,
                                                        i_sysdate                 => l_sysdate_tstz,
                                                        i_hand_off_type           => l_hand_off_type,
                                                        i_flg_main_responsible    => l_empr.flg_main_responsible,
                                                        i_id_speciality           => l_empr.id_speciality,
                                                        i_flg_resp_type           => l_empr.flg_resp_type,
                                                        o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                        o_error                   => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        ELSE
            g_error := 'INVALID HANDOFF TYPE';
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RAISE l_param_error;
        END IF;
    
        -- Clear EPIS_INFO if current responsability is being cancelled.
        IF ((l_epr.id_prof_comp = nvl(l_epis_info_doc_resp, 0) AND i_flg_type = pk_alert_constant.g_cat_type_doc) OR
           (l_epr.id_prof_comp = nvl(l_epis_info_nurse_resp, 0) AND i_flg_type = pk_alert_constant.g_cat_type_nurse))
           AND l_epr.flg_status = pk_hand_off.g_hand_off_f
        THEN
            g_error := 'CLEAR EPIS_INFO RESPONSABILITY';
            IF NOT call_set_epis_info_resp(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_episode          => l_epr.id_episode,
                                           i_id_professional     => NULL,
                                           i_id_professional_nin => FALSE,
                                           i_prof_cat            => i_flg_type,
                                           i_flg_resp_type       => CASE l_hand_off_type
                                                                        WHEN pk_hand_off.g_handoff_multiple THEN
                                                                         l_empr.flg_resp_type
                                                                        ELSE
                                                                         NULL
                                                                    END,
                                           o_error               => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF i_flg_type = pk_alert_constant.g_cat_type_doc
           AND l_dt_first_obs = l_epr.dt_comp_tstz
        THEN
            g_error := 'CLEAN DT_FIRST_OBS_TSTZ';
            ts_epis_info.upd(id_episode_in         => l_epr.id_episode,
                             dt_first_obs_tstz_in  => NULL,
                             dt_first_obs_tstz_nin => FALSE,
                             rows_out              => l_rowids);
        
        ELSIF i_flg_type = pk_alert_constant.g_cat_type_nurse
              AND l_dt_first_nurse_obs = l_epr.dt_comp_tstz
        THEN
            g_error := 'CLEAN DT_FIRST_NURSE_OBS_TSTZ';
            ts_epis_info.upd(id_episode_in               => l_epr.id_episode,
                             dt_first_nurse_obs_tstz_in  => NULL,
                             dt_first_nurse_obs_tstz_nin => FALSE,
                             rows_out                    => l_rowids);
        
        END IF;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rowids,
                                      i_list_columns => table_varchar('DT_FIRST_OBS_TSTZ', 'DT_FIRST_NURSE_OBS_TSTZ'),
                                      o_error        => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_cancel_responsability;

    /********************************************************************************************
    * Returns a list of professionals assigned to the specified clinical service.
    * Used to select the responsible physician when admitting a patient to another software.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_institution              Destination institution ID
    * @param   i_software                 Destination software ID
    * @param   i_dest_service             Destination clinical service ID
    * @param   o_prof_list                List of professionals 
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.1
    * @since                          07-07-2011
    **********************************************************************************************/
    FUNCTION get_admission_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_dest_service IN clinical_service.id_clinical_service%TYPE,
        o_prof_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ADMISSION_PROF_LIST';
        l_handoff_type sys_config.value%TYPE;
    BEGIN
    
        g_error := 'GET CONFIGURATIONS (HAND-OFF TYPE)';
        pk_hand_off_core.get_hand_off_type(i_lang, profissional(i_prof.id, i_institution, i_software), l_handoff_type);
    
        IF i_dest_service IS NOT NULL
        THEN
            g_error := 'GET PROFESSIONAL LIST (1)';
            OPEN o_prof_list FOR
                SELECT prof.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_name
                  FROM (SELECT DISTINCT p.id_professional
                          FROM professional p
                          JOIN prof_institution pi
                            ON pi.id_professional = p.id_professional
                          JOIN prof_cat pc
                            ON pc.id_professional = p.id_professional
                          JOIN category c
                            ON c.id_category = pc.id_category
                          JOIN prof_profile_template ppt
                            ON ppt.id_professional = p.id_professional
                          JOIN profile_template pt
                            ON pt.id_profile_template = ppt.id_profile_template
                          JOIN prof_dep_clin_serv pdcs
                            ON pdcs.id_professional = p.id_professional
                          JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                         WHERE dcs.id_clinical_service = i_dest_service
                              -- Filter by FLG_PROFILE in MULTIPLE hand-off
                           AND ((pt.flg_profile = g_specialist AND l_handoff_type = pk_hand_off.g_handoff_multiple AND
                               pk_prof_utils.get_flg_mrp(i_lang, i_prof, pt.id_profile_template) =
                               pk_alert_constant.g_yes) OR (l_handoff_type = pk_hand_off.g_handoff_normal))
                           AND pi.id_institution = i_institution
                           AND pi.flg_state = pk_edis_list.g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pc.id_institution = i_institution
                           AND c.flg_type = pk_alert_constant.g_cat_type_doc
                           AND c.flg_available = pk_alert_constant.g_yes
                           AND ppt.id_software = i_software
                           AND ppt.id_institution = i_institution
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_institution) =
                               pk_alert_constant.g_yes
                           AND pdcs.flg_status = pk_edis_list.g_prof_dcs_status_active
                           AND pdcs.id_institution = i_institution
                           AND EXISTS (SELECT 0
                                  FROM prof_soft_inst psi
                                 WHERE psi.id_professional = pc.id_professional
                                   AND psi.id_institution = i_institution
                                   AND psi.id_software = i_software)) prof
                 ORDER BY prof_name;
        
        ELSE
            -- Destination clinical service was not specified
            g_error := 'GET PROFESSIONAL LIST (2)';
            OPEN o_prof_list FOR
                SELECT prof.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_name
                  FROM (SELECT DISTINCT p.id_professional
                          FROM professional p
                          JOIN prof_institution pi
                            ON pi.id_professional = p.id_professional
                          JOIN prof_cat pc
                            ON pc.id_professional = p.id_professional
                          JOIN category c
                            ON c.id_category = pc.id_category
                          JOIN prof_profile_template ppt
                            ON ppt.id_professional = p.id_professional
                          JOIN profile_template pt
                            ON pt.id_profile_template = ppt.id_profile_template
                         WHERE ((pt.flg_profile = g_specialist AND l_handoff_type = pk_hand_off.g_handoff_multiple AND
                               pk_prof_utils.get_flg_mrp(i_lang, i_prof, pt.id_profile_template) =
                               pk_alert_constant.g_yes) OR (l_handoff_type = pk_hand_off.g_handoff_normal)) -- Filter by FLG_PROFILE in MULTIPLE hand-off
                           AND pi.id_institution = i_institution
                           AND pi.flg_state = pk_edis_list.g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pc.id_institution = i_institution
                           AND c.flg_type = pk_alert_constant.g_cat_type_doc
                           AND c.flg_available = pk_alert_constant.g_yes
                           AND ppt.id_software = i_software
                           AND ppt.id_institution = i_institution
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_institution) =
                               pk_alert_constant.g_yes
                           AND EXISTS (SELECT 0
                                  FROM prof_soft_inst psi
                                 WHERE psi.id_professional = pc.id_professional
                                   AND psi.id_institution = i_institution
                                   AND psi.id_software = i_software)) prof
                 ORDER BY prof_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_admission_prof_list;

    /********************************************************************************************
    * Check if current software is an ambulatory product.
    *
    * @param i_software                Software ID
    * 
    * @return                          1 if TRUE, 0 if FALSE.
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           15-Nov-2011
    *
    **********************************************************************************************/
    FUNCTION is_ambulatory_product(i_software IN software.id_software%TYPE) RETURN NUMBER IS
        --l_func_name CONSTANT VARCHAR2(200 CHAR) := 'IS_AMBULATORY_PRODUCT';
        l_result NUMBER(6) := 0;
    BEGIN
    
        IF i_software IN (pk_alert_constant.g_soft_outpatient,
                          pk_alert_constant.g_soft_primary_care,
                          pk_alert_constant.g_soft_private_practice)
        THEN
            l_result := 1;
        END IF;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END is_ambulatory_product;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.10
    * @since                          20-Set-2012
    **********************************************************************************************/
    FUNCTION call_set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        i_dt_reg                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CALL_SET_OVERALL_RESP';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO CALL_SET_OVERALL_RESP i_id_episode:' || i_id_episode || 'i_id_prof_resp:' || i_id_prof_resp;
        IF NOT call_set_overall_resp(i_lang                    => i_lang,
                                     i_prof                    => i_prof,
                                     i_id_episode              => i_id_episode,
                                     i_id_prof_resp            => i_id_prof_resp,
                                     i_id_speciality           => i_id_speciality,
                                     i_notes                   => i_notes,
                                     i_dt_reg                  => i_dt_reg,
                                     i_flg_epis_respons        => pk_alert_constant.g_no,
                                     o_flg_show                => o_flg_show,
                                     o_msg_title               => o_msg_title,
                                     o_msg_body                => o_msg_body,
                                     o_id_epis_prof_resp       => o_id_epis_prof_resp,
                                     o_id_epis_multi_prof_resp => o_id_epis_multi_prof_resp,
                                     o_error                   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END call_set_overall_resp;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode/overall responsability, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_my_patients              Called from a 'My patients' grid: (Y) Yes (N) No - default
    * @param   i_resp_type                Responsability type
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.10
    * @since                          20-Set-2012
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE
    ) RETURN table_number IS
        l_func_name VARCHAR2(40) := 'GET_EPIS_RESPONSIBLES_ID';
        l_error     t_error_out;
        l_tab_resp  table_number := table_number();
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
        l_current_amb_responsible_id professional.id_professional%TYPE;
    BEGIN
    
        IF nvl(i_hand_off_type, pk_hand_off.g_handoff_normal) = pk_hand_off.g_handoff_normal
           OR i_prof_cat NOT IN (pk_hand_off.g_flg_type_d, pk_hand_off.g_flg_type_n) -- Add support for other categories with hand-off 
        THEN
        
            g_error := 'GET RESPONSIBLES (N)';
            SELECT nvl(t.id_professional, -1)
              BULK COLLECT
              INTO l_tab_resp
              FROM (SELECT decode(i_prof_cat,
                                  pk_hand_off.g_flg_type_d,
                                  nvl(ei.id_professional, sr.id_professional),
                                  pk_hand_off.g_flg_type_n,
                                  ei.id_first_nurse_resp,
                                  nvl(ei.id_professional, sr.id_professional)) id_professional
                      FROM epis_info ei
                      LEFT JOIN sch_resource sr
                        ON ei.id_schedule = sr.id_schedule
                     WHERE ei.id_episode = i_id_episode) t;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
        
            IF i_flg_resp_type = pk_hand_off_core.g_resp_episode
               AND i_prof.software = pk_alert_constant.g_soft_outpatient
            THEN
                g_error := 'CHECK AMBULATORY EPISODE RESPONSIBLE';
                IF NOT
                    get_epis_info_resp(i_lang            => i_lang,
                                       i_prof            => i_prof,
                                       i_id_episode      => i_id_episode,
                                       i_prof_cat        => pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof),
                                       o_id_professional => l_current_amb_responsible_id,
                                       o_error           => l_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF l_current_amb_responsible_id IS NOT NULL
                THEN
                    l_tab_resp.extend();
                    l_tab_resp(l_tab_resp.count) := l_current_amb_responsible_id;
                END IF;
            
            ELSE
                g_error := 'GET RESPONSIBLES (M)';
                SELECT aux.id_professional
                  BULK COLLECT
                  INTO l_tab_resp
                  FROM (SELECT empr.id_professional
                          FROM epis_multi_prof_resp empr
                          JOIN epis_prof_resp epr
                            ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
                         WHERE empr.id_episode = i_id_episode
                           AND empr.flg_status = g_active
                           AND empr.flg_resp_type = i_flg_resp_type
                           AND epr.flg_type = i_prof_cat
                           AND epr.flg_status = pk_hand_off.g_hand_off_f
                        UNION ALL
                        SELECT nvl(t.id_professional, -1) id_professional
                          FROM (SELECT decode(i_prof_cat,
                                              pk_hand_off.g_flg_type_d,
                                              ei.id_professional,
                                              pk_hand_off.g_flg_type_n,
                                              ei.id_first_nurse_resp,
                                              ei.id_professional) id_professional
                                  FROM epis_info ei
                                 WHERE ei.id_episode = i_id_episode
                                   AND i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                                                           pk_alert_constant.g_soft_social,
                                                           pk_alert_constant.g_soft_nutritionist,
                                                           pk_alert_constant.g_soft_primary_care)
                                   AND i_my_patients = pk_alert_constant.g_yes) t) aux;
            END IF;
        
        ELSE
            g_error    := 'INVALID HAND-OFF TYPE (' || i_hand_off_type || ')';
            l_tab_resp := NULL;
        END IF;
    
        RETURN l_tab_resp;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_responsibles_id;

    /*********************************************************************************************************************
    * Assigns main/overall responsible of an episode.
    * This function overrides regular responsabilty rules and should only be used in exceptions to the normal workflow
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    *
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Sergio Dias
    * @version                        2.6.3.8.2
    * @since                          7-Oct-2013
    **********************************************************************************************************************/
    FUNCTION override_main_responsible
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_prof_resp IN epis_multi_prof_resp.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'OVERRIDE_MAIN_RESPONSIBLE';
        --
        l_flg_show                VARCHAR2(1);
        l_msg_title               sys_message.desc_message%TYPE;
        l_msg_body                sys_message.desc_message%TYPE;
        l_id_epis_prof_resp       epis_prof_resp.id_epis_prof_resp%TYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_refresh_mview           VARCHAR2(1 CHAR);
        --
        l_prof           profissional;
        l_prof_specialty speciality.id_speciality%TYPE;
        l_id_outdated    table_varchar;
        l_aux            NUMBER;
    BEGIN
        -- check if it is necessary to override the hand off rules
        g_error := 'CHECK MAIN RESPONSIBLE';
        SELECT COUNT(1)
          INTO l_aux
          FROM epis_multi_prof_resp empr
          JOIN epis_prof_resp epr
            ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
         WHERE empr.flg_resp_type = pk_hand_off_core.g_resp_overall
           AND empr.id_episode = i_id_episode
           AND empr.id_professional = i_id_prof_resp
           AND empr.flg_status = g_active
           AND empr.flg_main_responsible = pk_alert_constant.g_yes;
    
        IF l_aux > 0
        THEN
            -- the professional is already the main responsible, no need to override
            RETURN TRUE;
        ELSE
            l_prof           := profissional(id          => i_id_prof_resp,
                                             institution => i_prof.institution,
                                             software    => i_prof.software);
            l_prof_specialty := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => l_prof);
        
            -- Find records to terminate
            -- records created by this professional, which means, records created using the admission screen
            g_error := 'GET L_ID_OUTDATED';
            SELECT epr.id_epis_prof_resp
              BULK COLLECT
              INTO l_id_outdated
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.flg_resp_type = g_resp_overall
               AND empr.id_episode = i_id_episode
               AND epr.id_prof_req = i_prof.id
               AND empr.flg_status = g_active
             ORDER BY empr.id_epis_multi_prof_resp ASC;
        
            IF l_id_outdated.exists(1)
            THEN
                g_error := 'CALL_SET_EPIS_PROF_RESP';
                IF NOT pk_hand_off.call_set_epis_prof_resp(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_tot_epis         => table_number(1),
                                                           i_epis_prof_resp   => l_id_outdated,
                                                           i_flg_status       => pk_hand_off.g_hand_off_t, -- "Terminate" responsability
                                                           i_flg_type         => pk_alert_constant.g_cat_type_doc,
                                                           i_notes            => NULL,
                                                           i_sysdate          => NULL,
                                                           i_hand_off_type    => NULL,
                                                           i_id_cancel_reason => NULL,
                                                           o_refresh_mview    => l_refresh_mview,
                                                           o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'OVERRIDE MAIN RESPONSIBLE';
        
            -- if there still is a main responsible, outdate it so a new record can be created
            UPDATE epis_multi_prof_resp empr
               SET empr.flg_main_responsible = pk_alert_constant.g_no
             WHERE empr.flg_main_responsible = pk_alert_constant.g_yes
               AND empr.id_episode = i_id_episode;
        
            g_error := 'PK_HAND_OFF_CORE.CALL_SET_OVERALL_RESP';
            IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_id_episode              => i_id_episode,
                                                          i_id_prof_resp            => i_id_prof_resp,
                                                          i_id_speciality           => l_prof_specialty,
                                                          i_notes                   => NULL,
                                                          i_dt_reg                  => current_timestamp,
                                                          o_flg_show                => l_flg_show,
                                                          o_msg_title               => l_msg_title,
                                                          o_msg_body                => l_msg_body,
                                                          o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                          o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                          o_error                   => o_error)
            THEN
                RETURN FALSE; -- direct return in order to keep possible user error messages
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END override_main_responsible;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_first_nurse_resp         Episode first nurse responsible
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_resp_doctor_nurse
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT professional.id_professional%TYPE,
        o_first_nurse_resp OUT professional.id_professional%TYPE
    ) RETURN BOOLEAN IS
        l_prof_cat category.flg_type%TYPE;
    BEGIN
        IF i_id_episode IS NOT NULL
        THEN
            SELECT ei.id_professional, ei.id_first_nurse_resp
              INTO o_resp_doctor, o_first_nurse_resp
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF o_resp_doctor IS NOT NULL
            THEN
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang,
                                                         i_prof => profissional(o_resp_doctor,
                                                                                i_prof.institution,
                                                                                i_prof.software));
            
                IF o_resp_doctor = o_first_nurse_resp
                   OR l_prof_cat = pk_alert_constant.g_cat_type_nurse
                THEN
                    o_resp_doctor := NULL;
                ELSIF o_resp_doctor IS NULL
                      AND i_prof.software = pk_alert_constant.g_soft_primary_care
                THEN
                    o_resp_doctor := pk_patient.get_designated_provider(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_patient => i_id_patient,
                                                                        i_episode => i_id_episode);
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_resp_doctor_nurse;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_resp_doctor_spec         Responsible physician speciality
    * @param   o_resp_nurse               Episode responsible nurse
    * @param   o_error                    Error message
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_epis_responsibles
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT VARCHAR,
        o_resp_doctor_spec OUT VARCHAR,
        o_resp_nurse       OUT VARCHAR,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(50) := 'GET_EPIS_RESPONSIBLES';
        --
        l_resp_doctor      professional.id_professional%TYPE;
        l_first_nurse_resp professional.id_professional%TYPE;
    BEGIN
        g_error := 'CALL GET_RESP_DOCTOR_NURSE';
        IF get_resp_doctor_nurse(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_episode       => i_id_episode,
                                 i_id_patient       => i_id_patient,
                                 o_resp_doctor      => l_resp_doctor,
                                 o_first_nurse_resp => l_first_nurse_resp)
        THEN
        
            g_error       := 'CALL PK_PROF_UTILS.GET_NAME - DOCTOR';
            o_resp_doctor := pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => l_resp_doctor);
        
            g_error            := 'CALL PK_PROF_UTILS.GET_PROF_SPECIALITY';
            o_resp_doctor_spec := pk_prof_utils.get_prof_speciality(i_lang => i_lang,
                                                                    i_prof => profissional(l_resp_doctor,
                                                                                           i_prof.institution,
                                                                                           i_prof.software));
        
            g_error      := 'CALL PK_PROF_UTILS.GET_NAME - NURSE';
            o_resp_nurse := pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => l_first_nurse_resp);
        
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_responsibles;

    /**********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF FUNCTION GET_EPIS_PROF_RESP_ALL BUT ALSO CHECKS IN EPIS_INFO FOR OUTP
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Sergio Dias
    * @version v2.6.3.8.3
    * @since   17-Oct-2013
    **********************************************************************************************/
    FUNCTION get_responsibles
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_RESPONSIBLES';
        l_internal_error EXCEPTION;
        l_count NUMBER := -1;
        l_prof  profissional;
    BEGIN
    
        g_error := 'COUNT TABLE RESPONSIBLES';
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT epr.id_epis_prof_resp
                  FROM epis_prof_resp epr
                 WHERE epr.id_episode = i_episode
                   AND epr.flg_status = pk_hand_off.g_hand_off_f
                UNION ALL
                SELECT empr.id_epis_multi_prof_resp
                  FROM epis_multi_prof_resp empr
                 WHERE empr.id_episode = i_episode
                   AND empr.flg_status = g_active);
    
        IF l_count <= 0
           AND i_prof.software = pk_alert_constant.g_soft_outpatient
        THEN
            -- if the handoff tables didn't return any responsibles and this is OUTP, check epis_info por responsible
            g_error := 'OPEN O_RESP_GRID';
            OPEN o_resp_grid FOR
                SELECT ei.id_professional id_epis_prof_resp,
                       g_resp_episode flg_resp_type,
                       pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_M031') desc_resp_type,
                       pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                             profissional(id          => ei.id_professional,
                                                                          institution => i_prof.institution,
                                                                          software    => i_prof.software),
                                                             NULL,
                                                             NULL,
                                                             p.id_speciality) desc_spec,
                       ei.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, l_prof, ei.id_professional) prof_name,
                       get_flg_profile(i_lang             => i_lang,
                                       i_prof             => profissional(id          => ei.id_professional,
                                                                          institution => i_prof.institution,
                                                                          software    => i_prof.software),
                                       i_profile_template => NULL) flg_profile,
                       pk_sysdomain.get_domain('EPIS_MULTI_PROF_RESP.FLG_PROFILE',
                                               get_flg_profile(i_lang             => i_lang,
                                                               i_prof             => profissional(id          => ei.id_professional,
                                                                                                  institution => i_prof.institution,
                                                                                                  software    => i_prof.software),
                                                               i_profile_template => NULL),
                                               i_lang) desc_profile,
                       pk_date_utils.dt_chr_tsz(i_lang, ei.dt_first_sch, l_prof) date_begin,
                       pk_date_utils.date_char_hour_tsz(i_lang, ei.dt_first_sch, i_prof.institution, i_prof.software) hour_begin,
                       NULL date_end,
                       NULL hour_end,
                       NULL start_evt,
                       NULL end_evt
                  FROM epis_info ei
                  LEFT JOIN professional p
                    ON p.id_professional = ei.id_professional
                 WHERE ei.id_episode = i_episode;
        
            pk_types.open_my_cursor(o_transf_grid);
        ELSE
            -- calls the regular function that returns the responsibles list
            g_error := 'CALL PK_HAND_OFF_CORE.GET_EPIS_PROF_RESP_ALL';
            IF NOT pk_hand_off_core.get_epis_prof_resp_all(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_episode     => i_episode,
                                                           i_flg_type    => i_flg_type,
                                                           i_flg_hist    => i_flg_hist,
                                                           o_resp_grid   => o_resp_grid,
                                                           o_transf_grid => o_transf_grid,
                                                           o_error       => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_resp_grid);
            pk_types.open_my_cursor(o_transf_grid);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_resp_grid);
            pk_types.open_my_cursor(o_transf_grid);
            RETURN FALSE;
    END get_responsibles;
    /********************************************************************************************
    * Gets the professional responsible for admission
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_episode                  Episode identifier
    *                        
    * @return  professional name and speciality
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.7.1.0
    * @since                          26/04/2017
    **********************************************************************************************/
    FUNCTION get_admission_prof_resp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_resp VARCHAR2(4000);
    BEGIN
        SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(t.id_prof_to, t.id_prof_comp)) || ' (' ||
               pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                     i_prof,
                                                     t.id_clinical_service_dest,
                                                     t.id_department_dest,
                                                     (SELECT p.id_speciality
                                                        FROM professional p
                                                       WHERE p.id_professional = t.id_prof_comp)) || ') '
          INTO l_prof_resp
          FROM (SELECT epr.*, rank() over(PARTITION BY epr.id_episode ORDER BY epr.dt_request_tstz ASC) AS rank1
                  FROM epis_prof_resp epr
                 WHERE epr.flg_status = 'F'
                   AND epr.flg_type = 'D'
                   AND epr.id_episode = i_episode) t
         WHERE t.rank1 = 1;
    
        RETURN l_prof_resp;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_admission_prof_resp;

    /********************************************************************************************
    * Gets the list of professional responsible for admission (doctors)
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_episode                  Episode identifier
    * @param   o_prof_resp                List od professional responsible for episode                   
    * @return  true/faslse
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.7.1.0
    * @since                          28/04/2017
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_prof_resp OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_PROF_RESP_LIST';
        --l_profs_id     table_number;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type);
        IF l_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
        
            OPEN o_prof_resp FOR
                SELECT data, label
                  FROM (SELECT empr.id_professional data,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, empr.id_professional) || ' (' ||
                               pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                                     i_prof,
                                                                     epr.id_clinical_service_dest,
                                                                     epr.id_department_dest,
                                                                     empr.id_speciality) || ')' label,
                               row_number() over(PARTITION BY empr.id_professional ORDER BY epr.dt_request_tstz ASC) rn
                          FROM epis_prof_resp epr
                          JOIN epis_multi_prof_resp empr
                            ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                         WHERE epr.id_episode = i_episode
                           AND epr.flg_status = pk_hand_off.g_hand_off_f
                           AND epr.flg_type = pk_hand_off.g_prof_cat_doc
                         ORDER BY epr.dt_request_tstz ASC)
                 WHERE rn = 1;
        ELSE
            OPEN o_prof_resp FOR
                SELECT data, label
                  FROM (SELECT nvl(epr.id_prof_to, epr.id_prof_comp) data,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(epr.id_prof_to, epr.id_prof_comp)) || ' (' ||
                               pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                                     i_prof,
                                                                     epr.id_clinical_service_dest,
                                                                     epr.id_department_dest,
                                                                     (SELECT p.id_speciality
                                                                        FROM professional p
                                                                       WHERE p.id_professional = epr.id_prof_comp)) || ')' label,
                               row_number() over(PARTITION BY nvl(epr.id_prof_to, epr.id_prof_comp) ORDER BY epr.dt_request_tstz ASC) rn
                          FROM epis_prof_resp epr
                         WHERE epr.id_episode = i_episode
                           AND epr.flg_status = pk_hand_off.g_hand_off_f
                           AND epr.flg_type = pk_hand_off.g_prof_cat_doc
                         ORDER BY epr.dt_request_tstz ASC)
                 WHERE rn = 1;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_prof_resp);
            RETURN FALSE;
    END get_epis_prof_resp_list;

    FUNCTION get_handoff_actions_sp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_action_sp action.subject%TYPE := 'HANDOFF_SINGLEPAGE';
        l_func_name CONSTANT VARCHAR2(30) := 'GET_HANDOFF_ACTIONS_SP';
    
    BEGIN
        IF NOT pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => l_action_sp,
                                     i_from_state => NULL,
                                     o_actions    => o_actions,
                                     o_error      => o_error)
        THEN
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_handoff_actions_sp;

    FUNCTION set_prof_resp_outdated
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_prof_list     IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids        table_varchar;
        l_handoff_type  sys_config.value%TYPE;
        l_prof_list     VARCHAR2(200 CHAR);
        l_new_emprh_ids table_number;
        l_internal_error EXCEPTION;
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type);
        IF l_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
            l_prof_list := pk_utils.concat_table(i_prof_list, i_delim => ',');
            ts_epis_multi_prof_resp.upd(flg_status_in           => g_outdated, -- OUTDATED!!
                                        flg_main_responsible_in => pk_alert_constant.g_no,
                                        where_in                => 'ID_EPISODE = ' || i_episode ||
                                                                   ' AND FLG_STATUS = ''' || g_active ||
                                                                   ''' AND FLG_RESP_TYPE = ''' || i_flg_resp_type ||
                                                                   ''' AND ID_PROFESSIONAL NOT IN (' || l_prof_list || ' )',
                                        rows_out                => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_MULTI_PROF_RESP',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            -- Set history for OUTDATED records
            g_error := 'SET HISTORY - UPDATE (1)';
            IF NOT set_multi_prof_resp_hist_rows(i_lang   => i_lang,
                                                 i_prof   => i_prof,
                                                 i_rowids => l_rowids,
                                                 o_ids    => l_new_emprh_ids,
                                                 o_error  => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            NULL;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END set_prof_resp_outdated;

    /********************************************************************************************
    * Get the last service transfer date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Maximum comfirm request date
    *
    * @author                         Amanda Lee
    * @version                        2.7.2
    * @since                          25-12-2017
    **********************************************************************************************/
    FUNCTION get_last_trans_service_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_prof_resp.dt_end_transfer_tstz%TYPE IS
        l_error        t_error_out;
        l_ret          epis_prof_resp.dt_comp_tstz%TYPE;
        l_flg_transf_s VARCHAR2(1 CHAR) := 'S';
    BEGIN
        SELECT MAX(epr1.dt_end_transfer_tstz)
          INTO l_ret
          FROM epis_prof_resp epr1
         WHERE epr1.id_episode = i_episode
           AND epr1.flg_transf_type = l_flg_transf_s
           AND epr1.dt_end_transfer_tstz IS NOT NULL;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_LAST_TRANS_SERVICE_DATE',
                                              l_error);
            RETURN NULL;
    END get_last_trans_service_date;

    /********************************************************************************************
    * Get the last transfer out clinical service.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Last transfer out clinical service
    *
    * @author                         Lillian Lu
    * @version                        2.7.3
    * @since                          16-01-2018
    **********************************************************************************************/
    FUNCTION get_last_transf_cs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_clin_service pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                     i_prof,
                                                     t.id_clinical_service_dest,
                                                     t.id_department_dest,
                                                     (SELECT p.id_speciality
                                                        FROM professional p
                                                       WHERE p.id_professional = t.id_prof_comp))
          INTO l_clin_service
          FROM (SELECT epr.id_clinical_service_dest,
                       epr.id_department_dest,
                       epr.id_prof_comp,
                       rank() over(PARTITION BY epr.id_episode ORDER BY epr.dt_request_tstz DESC) AS rank1
                  FROM epis_prof_resp epr
                  JOIN room r
                    ON r.id_room = epr.id_room_execute
                 WHERE epr.flg_status <> pk_alert_constant.g_cancelled
                   AND epr.flg_transf_type = g_trans_type_s
                   AND epr.id_episode = i_episode) t
         WHERE t.rank1 = 1;
        RETURN l_clin_service;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_transf_cs;

    /********************************************************************************************
    * Get Attending physicians list on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Attending physicians on an episode
    *
    * @author                         Amanda Lee
    * @version                        2.7.3
    * @since                          19-01-2018
    **********************************************************************************************/
    FUNCTION get_attending_physicians
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        --l_func_name VARCHAR2(32) := 'GET_ATTENDING_PHYSICIANS';
        l_note VARCHAR2(4000 CHAR) := NULL;
    BEGIN
        SELECT listagg(pk_alert_constant.g_status_rpl_chr_icon || t.priority || pk_prog_notes_constants.g_space ||
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(t.id_prof_to, t.id_prof_comp)) ||
                       pk_prog_notes_constants.g_new_line) within GROUP(ORDER BY t.priority)
          INTO l_note
          FROM (SELECT e.id_prof_to, e.id_prof_comp, mlt.flg_main_responsible, mlt.priority
                  FROM epis_multi_prof_resp mlt
                  JOIN epis_prof_resp e
                    ON e.id_episode = mlt.id_episode
                   AND e.id_epis_prof_resp = mlt.id_epis_prof_resp
                 WHERE mlt.id_episode = i_id_episode
                   AND mlt.flg_resp_type = g_resp_type_o
                   AND mlt.flg_status = g_flg_status_a) t;
        RETURN l_note;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_attending_physicians;

    FUNCTION get_speciality_label
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_resp_type IN VARCHAR2,
        i_flg_type      IN epis_prof_resp.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_speciality sys_message.desc_message%TYPE;
    BEGIN
        IF i_flg_resp_type = pk_hand_off.g_handoff_multiple
        THEN
            IF i_flg_type = 'D'
            THEN
                l_speciality := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'EDIS_HAND_OFF_T009');
            ELSE
                l_speciality := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'EDIS_HAND_OFF_M081');
            END IF;
        
        ELSE
            IF i_flg_type = 'D'
            THEN
                l_speciality := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'EDIS_HAND_OFF_T032');
            ELSE
                l_speciality := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'EDIS_HAND_OFF_M081');
            END IF;
        
        END IF;
        RETURN l_speciality;
    END get_speciality_label;

    FUNCTION get_epis_prof_resp_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_flg_resp_type epis_multi_prof_resp.flg_resp_type%TYPE;
        l_spec          epis_multi_prof_resp.id_speciality%TYPE;
        l_flg_profile   epis_multi_prof_resp.flg_profile%TYPE;
        l_episode       epis_prof_resp.id_episode%TYPE;
        l_flg_type      epis_prof_resp.flg_type%TYPE;
        l_dt_comp       epis_prof_resp.dt_comp_tstz%TYPE;
        --
        --l_sbar_note sys_config.value%TYPE;
    
        l_tab_dd_block_data t_tab_dd_block_data;
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    
        l_label_speciality sys_message.desc_message%TYPE;
    
    BEGIN
        g_error := 'GET SBAR CONFIG';
        --l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        g_error := 'GET SYS_MESSAGES';
        g_error := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET GROUP BY VARS - MULTI_RESP';
            SELECT empr.id_episode,
                   empr.flg_resp_type,
                   empr.id_speciality,
                   empr.flg_profile,
                   epr.flg_type,
                   epr.dt_comp_tstz
              INTO l_episode, l_flg_resp_type, l_spec, l_flg_profile, l_flg_type, l_dt_comp
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_epis_prof_resp = i_epis_prof_resp;
        ELSE
            g_error := 'GET GROUP BY VARS - SINGLE_RESP';
            SELECT epr.id_episode,
                   pk_hand_off_core.get_resp_type(i_lang,
                                                  i_prof,
                                                  epr.id_episode,
                                                  epr.id_prof_comp,
                                                  epr.id_epis_prof_resp) flg_resp_type,
                   p.id_speciality,
                   NULL,
                   epr.flg_type,
                   epr.dt_comp_tstz
              INTO l_episode, l_flg_resp_type, l_spec, l_flg_profile, l_flg_type, l_dt_comp
              FROM epis_prof_resp epr
              LEFT JOIN professional p
                ON p.id_professional = epr.id_prof_comp
             WHERE epr.id_epis_prof_resp = i_epis_prof_resp;
        END IF;
        l_label_speciality := get_speciality_label(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_flg_resp_type => l_hand_off_type,
                                                   i_flg_type      => l_flg_type);
    
        l_tab_dd_block_data := get_tab_dd_block_data_m02(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_epis_prof_resp => i_epis_prof_resp,
                                                         i_hand_off_type  => l_hand_off_type,
                                                         i_flg_profile    => l_flg_profile);
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => data_code_message)
                                  WHEN data_source = 'SPECIALITY' THEN
                                   l_label_speciality
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   data_source_val
                                  ELSE
                                   NULL
                              
                              END, --DESCR
                              CASE
                              --For L1, it will only show the message available in dd_code_source.
                              --If there is no message configured in dd_code_source, it will instead show
                              --the info from data_source_val
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   NULL
                                  ELSE
                                   CASE
                                       WHEN flg_clob = pk_alert_constant.g_yes THEN
                                        NULL
                                       ELSE
                                        data_source_val
                                   END
                              END, --VAL
                              flg_type,
                              flg_html,
                              CASE
                                  WHEN flg_clob = pk_alert_constant.g_yes THEN
                                   get_epis_prof_resp_clob(internal_name, data_source_val)
                                  ELSE
                                   NULL
                              END,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       db.id_dd_block,
                       ddc.flg_html,
                       ddc.internal_name,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_hand_off
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL') --white lines from follow-up notes 
                UNION
                --New lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       ddb.rank              rnk,
                       ddc.rank,
                       ddb.id_dd_block,
                       ddc.flg_html,
                       ddc.internal_name,
                       ddc.flg_clob
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_hand_off
                  JOIN (SELECT DISTINCT id_dd_block --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_hand_off
                   AND ddc.flg_type = 'WL'
                   AND ddb.id_dd_block <> 4)
         ORDER BY rnk, rank;
    
        OPEN o_detail FOR
            SELECT dt.descr, dt.val, dt.flg_type, dt.flg_html, dt.val_clob, dt.flg_clob
              FROM (SELECT CASE
                                WHEN d.descr IS NULL THEN
                                 NULL
                                WHEN flg_type <> 'L1' THEN
                                 d.descr || ': '
                                ELSE
                                 d.descr
                            END descr,
                           --d.descr,
                           d.val,
                           d.flg_type,
                           d.flg_html,
                           d.val_clob,
                           d.flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn) dt
             WHERE ((dt.val IS NOT NULL) OR (dt.val_clob IS NOT NULL) OR (dbms_lob.getlength(dt.val_clob) > 0))
                OR (dt.flg_type IN ('L1', 'WL'))
             ORDER BY rn;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'get_epis_prof_resp_detail',
                                              o_error);
            RETURN FALSE;
    END get_epis_prof_resp_detail;

    FUNCTION get_epis_prof_resp_signature
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_prof_resp  IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_detail             IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_epis_multi_hist IN epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_msg_hoff_m003 sys_message.desc_message%TYPE;
        l_msg_hoff_m004 sys_message.desc_message%TYPE;
    
        l_msg_label           sys_message.desc_message%TYPE;
        l_resp_name_signature sys_message.desc_message%TYPE;
        l_resp_spec_signature sys_message.desc_message%TYPE;
        l_resp_dt_signature   sys_message.desc_message%TYPE;
        l_epis_prof_signature sys_message.desc_message%TYPE;
    BEGIN
        l_msg_hoff_m003 := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M127');
        l_msg_hoff_m004 := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M107');
    
        SELECT decode(epr.flg_status,
                      pk_hand_off.g_hand_off_r,
                      l_msg_hoff_m004,
                      pk_hand_off.g_hand_off_f,
                      decode(epr.id_prof_req,
                             epr.id_prof_to,
                             l_msg_hoff_m004,
                             decode(epr.dt_request_tstz,
                                    epr.dt_comp_tstz,
                                    l_msg_hoff_m004,
                                    decode(i_detail, pk_alert_constant.g_no, l_msg_hoff_m004, l_msg_hoff_m003))),
                      pk_hand_off.g_hand_off_d,
                      l_msg_hoff_m003,
                      decode(i_detail, pk_alert_constant.g_no, l_msg_hoff_m004, l_msg_hoff_m003)) desc_status,
               decode(epr.flg_status,
                      pk_hand_off.g_hand_off_r,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req),
                      pk_hand_off.g_hand_off_f,
                      decode(epr.dt_request_tstz,
                             epr.dt_comp_tstz,
                             pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req),
                             decode(i_detail,
                                    pk_alert_constant.g_no,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req),
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp))),
                      pk_hand_off.g_hand_off_d,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_decline),
                      pk_hand_off.g_hand_off_t,
                      pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req),
                      pk_hand_off.g_hand_off_c,
                      decode(i_detail,
                             pk_alert_constant.g_no,
                             pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req),
                             pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_cancel))) name_signature,
               decode(epr.flg_status,
                      pk_hand_off.g_hand_off_r,
                      pk_prof_utils.get_spec_signature(i_lang,
                                                       i_prof,
                                                       epr.id_prof_req,
                                                       epr.dt_request_tstz,
                                                       epr.id_episode),
                      pk_hand_off.g_hand_off_f,
                      decode(epr.dt_request_tstz,
                             epr.dt_comp_tstz,
                             pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              epr.id_prof_req,
                                                              epr.dt_request_tstz,
                                                              epr.id_episode),
                             decode(i_detail,
                                    pk_alert_constant.g_no,
                                    pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     epr.id_prof_req,
                                                                     epr.dt_request_tstz,
                                                                     epr.id_episode),
                                    pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     epr.id_prof_comp,
                                                                     epr.dt_comp_tstz,
                                                                     epr.id_episode))),
                      pk_hand_off.g_hand_off_d,
                      pk_prof_utils.get_spec_signature(i_lang,
                                                       i_prof,
                                                       epr.id_prof_decline,
                                                       epr.dt_decline_tstz,
                                                       epr.id_episode),
                      pk_hand_off.g_hand_off_c,
                      decode(i_detail,
                             pk_alert_constant.g_no,
                             pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              epr.id_prof_req,
                                                              epr.dt_request_tstz,
                                                              epr.id_episode),
                             pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              epr.id_prof_cancel,
                                                              epr.dt_cancel_tstz,
                                                              epr.id_episode))) spec_signature,
               -- *********************
               pk_hand_off_core.get_dt_signature(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_flg_status  => epr.flg_status,
                                                 i_dt_request  => epr.dt_request_tstz,
                                                 i_dt_comp     => epr.dt_comp_tstz,
                                                 i_dt_decline  => epr.dt_decline_tstz,
                                                 i_dt_transfer => epr.dt_end_transfer_tstz,
                                                 i_dt_cancel   => epr.dt_cancel_tstz,
                                                 i_detail      => i_detail) dt_signature
          INTO l_msg_label, l_resp_name_signature, l_resp_spec_signature, l_resp_dt_signature
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp;
    
        l_epis_prof_signature := l_msg_label || ' ' || l_resp_name_signature;
        IF l_resp_spec_signature IS NOT NULL
        THEN
            l_epis_prof_signature := l_epis_prof_signature || ' (' || l_resp_spec_signature || '); ';
        ELSE
            l_epis_prof_signature := l_epis_prof_signature || '; ';
        END IF;
        l_epis_prof_signature := l_epis_prof_signature || l_resp_dt_signature;
    
        RETURN l_epis_prof_signature;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_prof_resp_signature;

    FUNCTION get_epis_prof_resp_clob
    (
        i_field IN dd_content.internal_name%TYPE,
        i_value IN VARCHAR2
    ) RETURN CLOB IS
        l_clob CLOB;
    BEGIN
    
        IF i_field = 'SBAR_NOTE'
        THEN
            SELECT epr.sbar_notes
              INTO l_clob
              FROM epis_prof_resp epr
             WHERE epr.id_epis_prof_resp = i_value;
        ELSIF i_field = 'NOTES'
        THEN
            SELECT epr.notes_clob
              INTO l_clob
              FROM epis_prof_resp epr
             WHERE epr.id_epis_prof_resp = i_value;
        END IF;
    
        IF dbms_lob.getlength(l_clob) = 0
        THEN
            l_clob := NULL;
        END IF;
    
        RETURN l_clob;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_prof_resp_clob;

    FUNCTION get_prof_resp_status
    (
        i_lang           IN language.id_language%TYPE,
        i_flg_status     IN epis_prof_resp.flg_status%TYPE,
        i_flg_status_old IN epis_prof_resp.flg_status%TYPE,
        i_flg_status_epr IN epis_prof_resp.flg_status%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_hoff_m003 sys_message.desc_message%TYPE;
        l_msg_hoff_m004 sys_message.desc_message%TYPE;
        l_msg_hoff_m006 sys_message.desc_message%TYPE;
        l_msg_hoff_m069 sys_message.desc_message%TYPE;
    
        l_status sys_message.desc_message%TYPE;
    BEGIN
    
        l_msg_hoff_m003 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m003);
        l_msg_hoff_m004 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m004);
        l_msg_hoff_m006 := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m006);
        l_msg_hoff_m069 := pk_message.get_message(i_lang => i_lang, i_code_mess => 'TRANSFER_M115');
    
        CASE
        -- cmf
            WHEN i_flg_status = i_flg_status_old
                 AND i_flg_status_epr = 'F' THEN
                l_status := l_msg_hoff_m004;
                -- cmf
            WHEN i_flg_status = i_flg_status_old
                 AND i_flg_status IN ('R', g_onhold) THEN
                l_status := l_msg_hoff_m003;
            WHEN i_flg_status <> i_flg_status_old
                 AND i_flg_status = g_active THEN
                l_status := l_msg_hoff_m004;
            WHEN i_flg_status <> i_flg_status_old
                 AND i_flg_status_epr = pk_hand_off.g_hand_off_c THEN
                l_status := l_msg_hoff_m006;
            WHEN i_flg_status <> i_flg_status_old
                 AND i_flg_status_epr = pk_hand_off.g_hand_off_t THEN
                l_status := l_msg_hoff_m004;
            WHEN i_flg_status <> i_flg_status_old
                 AND i_flg_status_old = pk_hand_off.g_hand_off_r THEN
                l_status := l_msg_hoff_m003;
            
            WHEN i_flg_status = i_flg_status_old
                 AND i_flg_status_epr = pk_hand_off.g_hand_off_t THEN
                l_status := l_msg_hoff_m069;
            WHEN i_flg_status <> i_flg_status_old
                 AND i_flg_status_epr = pk_hand_off.g_hand_off_f THEN
                l_status := NULL;
            
            ELSE
                --l_status := 'i_flg_status:'||i_flg_status||' - i_flg_status_old:'||i_flg_status_old||' - i_flg_status_epr:'||i_flg_status_epr;
                l_status := 'NOT_AVAILABLE';
        END CASE;
        RETURN l_status;
    
    END get_prof_resp_status;

    FUNCTION get_epis_prof_resp_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
        l_flg_resp_type epis_multi_prof_resp.flg_resp_type%TYPE;
        l_spec          epis_multi_prof_resp.id_speciality%TYPE;
        l_flg_profile   epis_multi_prof_resp.flg_profile%TYPE;
        l_episode       epis_prof_resp.id_episode%TYPE;
        l_flg_type      epis_prof_resp.flg_type%TYPE;
        l_dt_comp       epis_prof_resp.dt_comp_tstz%TYPE;
        --
        --l_sbar_note sys_config.value%TYPE;
    
        l_tab_dd_block_data t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    
        l_label_speciality sys_message.desc_message%TYPE;
    
    BEGIN
        g_error := 'GET SBAR CONFIG';
        --l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        g_error := 'GET SYS_MESSAGES';
        g_error := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            g_error := 'GET GROUP BY VARS - MULTI_RESP';
            SELECT empr.id_episode,
                   empr.flg_resp_type,
                   empr.id_speciality,
                   empr.flg_profile,
                   epr.flg_type,
                   epr.dt_comp_tstz
              INTO l_episode, l_flg_resp_type, l_spec, l_flg_profile, l_flg_type, l_dt_comp
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_epis_prof_resp = i_epis_prof_resp;
        ELSE
            g_error := 'GET GROUP BY VARS - SINGLE_RESP';
            SELECT epr.id_episode,
                   pk_hand_off_core.get_resp_type(i_lang,
                                                  i_prof,
                                                  epr.id_episode,
                                                  epr.id_prof_comp,
                                                  epr.id_epis_prof_resp) flg_resp_type,
                   p.id_speciality,
                   NULL,
                   epr.flg_type,
                   epr.dt_comp_tstz
              INTO l_episode, l_flg_resp_type, l_spec, l_flg_profile, l_flg_type, l_dt_comp
              FROM epis_prof_resp epr
              LEFT JOIN professional p
                ON p.id_professional = epr.id_prof_comp
             WHERE epr.id_epis_prof_resp = i_epis_prof_resp;
        END IF;
        l_label_speciality := get_speciality_label(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_flg_resp_type => l_hand_off_type,
                                                   i_flg_type      => l_flg_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
        
            l_tab_dd_block_data := get_tab_dd_block_data_m01(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_epis_prof_resp => i_epis_prof_resp,
                                                             i_hand_off_type  => l_hand_off_type,
                                                             i_flg_profile    => l_flg_profile);
        
        ELSE
        
            l_tab_dd_block_data := get_tab_dd_block_data_n01(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_epis_prof_resp => i_epis_prof_resp,
                                                             i_hand_off_type  => l_hand_off_type,
                                                             i_flg_profile    => l_flg_profile);
        
        END IF;
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN data_source = 'SPECIALITY' THEN
                                   l_label_speciality
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   data_source_val
                                  ELSE
                                   NULL
                              
                              END, --DESCR
                              CASE
                              --For L1, it will only show the message available in dd_code_source.
                              --If there is no message configured in dd_code_source, it will instead show
                              --the info from data_source_val
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   NULL
                                  ELSE
                                   CASE
                                       WHEN flg_clob = pk_alert_constant.g_yes THEN
                                        NULL
                                       ELSE
                                        data_source_val
                                   END
                              END, --VAL
                              flg_type,
                              flg_html,
                              CASE
                                  WHEN flg_clob = pk_alert_constant.g_yes THEN
                                   get_epis_prof_resp_clob(internal_name, data_source_val)
                                  ELSE
                                   NULL
                              END,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob,
                       ddc.internal_name
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_hand_off
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL') --white lines from follow-up notes 
                UNION
                --New lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       t.rnk                 rnk,
                       ddc.rank,
                       ddb.id_dd_block,
                       flg_html,
                       flg_clob,
                       ddc.internal_name
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_hand_off
                  JOIN (SELECT DISTINCT id_dd_block, rnk --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_hand_off
                   AND ddc.flg_type = 'WL')
         ORDER BY rnk, rank;
    
        OPEN o_detail FOR
            SELECT xx.descr, xx.val, xx.flg_type, xx.flg_html, xx.val_clob, xx.flg_clob
              FROM (SELECT CASE
                                WHEN d.descr IS NULL THEN
                                 NULL
                            
                                WHEN flg_type <> 'L1' THEN
                                 d.descr || ': '
                                ELSE
                                 d.descr
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn) xx
             WHERE ((xx.val IS NOT NULL) OR (xx.val_clob IS NOT NULL) OR (dbms_lob.getlength(xx.val_clob) > 0))
                OR (xx.flg_type IN ('L1', 'WL'))
            
             ORDER BY xx.rn;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'get_epis_prof_resp_history',
                                              o_error);
            RETURN FALSE;
    END get_epis_prof_resp_history;

    FUNCTION get_responsibles_str_to_sort
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_cat            IN category.flg_type%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_hand_off_type       IN sys_config.value%TYPE,
        i_format              IN VARCHAR2,
        i_only_show_epis_resp IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_func_name        VARCHAR2(200) := 'GET_RESPONSIBLES_STR';
        l_error            t_error_out;
        l_number_resp      NUMBER(6);
        l_tab_responsibles table_number;
        l_tab_names        table_varchar;
        l_bool             BOOLEAN;
    
        l_format_g CONSTANT VARCHAR2(1) := 'G'; -- Show in grids
        l_format_t CONSTANT VARCHAR2(1) := 'T'; -- Show in tooltips
    
        l_title_overall sys_domain.desc_val%TYPE;
        l_title_epis    sys_domain.desc_val%TYPE;
        l_title_nurse   sys_domain.desc_val%TYPE;
        l_title_main    sys_message.desc_message%TYPE;
    
        l_overall_responsibles VARCHAR2(4000 CHAR) := NULL;
        l_epis_responsibles    VARCHAR2(4000 CHAR) := NULL;
        l_nurse_responsible    VARCHAR2(4000 CHAR) := NULL;
        l_responsibles         VARCHAR2(4000 CHAR) := NULL;
    
        l_param_error EXCEPTION;
    
        --********************************
        PROCEDURE concat_responsibles IS
        BEGIN
        
            g_error := 'GET TABLE WITH NAMES';
            SELECT pk_prof_utils.get_nickname(i_lang, t.column_value)
              BULK COLLECT
              INTO l_tab_names
              FROM TABLE(l_tab_responsibles) t;
        
            g_error        := 'CONCATENATE NAMES';
            l_responsibles := pk_utils.concat_table(l_tab_names, '; ');
        
        END concat_responsibles;
    
        --*******************************
        PROCEDURE l_process_error
        (
            i_code IN VARCHAR2,
            i_errm IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_code,
                                              i_errm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
        END l_process_error;
    
    BEGIN
    
        g_error := 'VALIDATE PARAMETERS';
        IF i_hand_off_type IS NULL
           OR i_format NOT IN (l_format_g, l_format_t)
        THEN
            g_error := 'INVALID PARAM (' || i_format || '/' || i_hand_off_type || ')';
            RAISE l_param_error;
        END IF;
    
        IF i_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the ID's of the responsibles for the patient, for the given category
            g_error := 'GET RESPONSIBLES COUNT';
            SELECT empr.id_professional
              BULK COLLECT
              INTO l_tab_responsibles
              FROM epis_multi_prof_resp empr
              JOIN epis_prof_resp epr
                ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
             WHERE empr.id_episode = i_id_episode
               AND empr.flg_status = g_active
               AND epr.flg_type = i_prof_cat
               AND epr.flg_status = pk_hand_off.g_hand_off_f
               AND (i_format = l_format_t OR
                   (i_format = l_format_g AND (i_only_show_epis_resp = pk_alert_constant.g_no OR
                   (i_only_show_epis_resp = pk_alert_constant.g_yes AND
                   empr.flg_resp_type = pk_hand_off_core.g_resp_episode))));
        
            l_number_resp := 0;
            IF l_tab_responsibles.exists(1)
            THEN
                l_number_resp := l_tab_responsibles.count;
            END IF;
        
            IF i_format = l_format_g -- Show responsibles in GRIDS
            THEN
            
                l_bool := (i_only_show_epis_resp = pk_alert_constant.g_no);
                l_bool := l_bool AND i_id_professional IS NOT NULL;
            
                IF l_bool
                THEN
                    l_responsibles := pk_prof_utils.get_nickname(i_lang, i_id_professional);
                ELSE
                    concat_responsibles();
                END IF;
            
            ELSIF i_format = l_format_t
                  AND nvl(l_number_resp, -1) > 0 -- Show responsibles in TOOLTIPS
            THEN
            
                IF i_prof_cat = pk_alert_constant.g_cat_type_doc
                THEN
                    -- Get required titles
                    l_title_overall := pk_sysdomain.get_domain(i_code_dom => 'EPIS_MULTI_PROF_RESP.FLG_RESP_TYPE',
                                                               i_val      => g_resp_overall,
                                                               i_lang     => i_lang);
                
                    l_title_main := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_M075');
                
                    l_title_epis := pk_sysdomain.get_domain(i_code_dom => 'EPIS_MULTI_PROF_RESP.FLG_RESP_TYPE',
                                                            i_val      => g_resp_episode,
                                                            i_lang     => i_lang);
                
                    -- Get list of OVERALL responsibles
                    g_error := 'CONCAT OVERALL';
                    SELECT pk_utils.concatenate_list(CURSOR (SELECT t.prof_name
                                                        FROM (SELECT pk_prof_utils.get_nickname(i_lang,
                                                                                                empr.id_professional) ||
                                                                     decode(empr.flg_main_responsible,
                                                                            pk_alert_constant.g_yes,
                                                                            ' - ' || l_title_main || ' (',
                                                                            ' (') ||
                                                                     pk_prof_utils.get_spec_signature(i_lang,
                                                                                                      i_prof,
                                                                                                      empr.id_professional,
                                                                                                      NULL,
                                                                                                      NULL) || ')' prof_name,
                                                                     decode(empr.flg_main_responsible,
                                                                            pk_alert_constant.g_yes,
                                                                            0,
                                                                            1) rank
                                                                FROM epis_multi_prof_resp empr
                                                               WHERE empr.id_episode = i_id_episode
                                                                 AND empr.flg_status = g_active
                                                                 AND empr.flg_resp_type = g_resp_overall
                                                               ORDER BY rank, priority, prof_name) t),
                                                     chr(13))
                      INTO l_overall_responsibles
                      FROM dual;
                
                    IF l_overall_responsibles IS NOT NULL
                    THEN
                        l_overall_responsibles := '<b>' || l_title_overall || ':</b>' || chr(13) ||
                                                  l_overall_responsibles || chr(13);
                    END IF;
                
                    -- Get list of EPISODE responsibles
                    g_error := 'CONCAT EPISODE';
                    SELECT pk_utils.concatenate_list(CURSOR (SELECT t.prof_name
                                                        FROM (SELECT pk_prof_utils.get_nickname(i_lang,
                                                                                                empr.id_professional) || ' (' ||
                                                                     pk_prof_utils.get_spec_signature(i_lang,
                                                                                                      i_prof,
                                                                                                      empr.id_professional,
                                                                                                      NULL,
                                                                                                      NULL) || ')' prof_name,
                                                                     decode(empr.flg_profile,
                                                                            g_specialist,
                                                                            0,
                                                                            g_resident,
                                                                            1,
                                                                            g_intern,
                                                                            2) rank
                                                                FROM epis_multi_prof_resp empr
                                                               WHERE empr.id_episode = i_id_episode
                                                                 AND empr.flg_status = g_active
                                                                 AND empr.flg_resp_type = g_resp_episode
                                                                 AND empr.flg_profile <> g_nurse -- Only physicians
                                                               ORDER BY rank, priority) t),
                                                     chr(13))
                      INTO l_epis_responsibles
                      FROM dual;
                
                    IF l_epis_responsibles IS NOT NULL
                    THEN
                        l_epis_responsibles := '<b>' || l_title_epis || ':</b>' || chr(13) || l_epis_responsibles;
                    END IF;
                
                    -- Concatenate all responsability strings
                    l_responsibles := l_overall_responsibles || l_epis_responsibles;
                
                ELSIF i_prof_cat = pk_alert_constant.g_cat_type_nurse
                THEN
                
                    l_title_nurse := pk_sysdomain.get_domain(i_code_dom => 'PROFILE_TEMPLATE.FLG_PROFILE',
                                                             i_val      => g_nurse,
                                                             i_lang     => i_lang);
                
                    -- Get responsible NURSE
                    g_error := 'CONCAT NURSE';
                    SELECT pk_prof_utils.get_nickname(i_lang, empr.id_professional) prof_name
                      INTO l_nurse_responsible
                      FROM epis_multi_prof_resp empr
                     WHERE empr.id_episode = i_id_episode
                       AND empr.flg_status = g_active
                       AND empr.flg_resp_type = g_resp_episode
                       AND empr.flg_profile = g_nurse;
                
                    IF l_nurse_responsible IS NOT NULL
                    THEN
                        l_nurse_responsible := '<b>' || l_title_nurse || ':</b>' || chr(13) || l_nurse_responsible;
                    END IF;
                
                    -- Concatenate all responsability strings
                    l_responsibles := l_nurse_responsible;
                
                END IF;
            END IF;
        
        ELSIF i_hand_off_type = pk_hand_off.g_handoff_normal
        THEN
            -- In normal hand-off, only the name of the professional is shown, regardless of the format.
            g_error        := 'FORMAT RESPONSIBLE TEXT (NORMAL HAND-OFF)';
            l_responsibles := pk_prof_utils.get_nickname(i_lang, i_id_professional);
        END IF;
    
        RETURN l_responsibles;
    
    EXCEPTION
        WHEN l_param_error THEN
            l_process_error('PARAM ERROR', 'INVALID PARAMETER FOUND');
            RETURN NULL;
        WHEN OTHERS THEN
            l_process_error(SQLCODE, SQLERRM);
            RETURN NULL;
    END get_responsibles_str_to_sort;

    FUNCTION get_tab_dd_block_data_m01
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type  IN VARCHAR2,
        i_flg_profile    IN VARCHAR2
    ) RETURN t_tab_dd_block_data IS
        l_tab_dd_block_data t_tab_dd_block_data;
    
        l_msg_opn_m001  sys_message.desc_message%TYPE;
        l_msg_hoff_m003 sys_message.desc_message%TYPE;
        l_msg_hoff_m004 sys_message.desc_message%TYPE;
        l_msg_hoff_m005 sys_message.desc_message%TYPE;
        l_msg_hoff_m006 sys_message.desc_message%TYPE;
    
        l_code_msg_hoff_m036 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M036'; --Beginning of responsability
        l_msg_hoff_m036 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m055 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M055'; --Transfer of responsibility
        l_msg_hoff_m055 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m056 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M056'; --Responsibility shift
        l_msg_hoff_m056    sys_message.desc_message%TYPE;
        l_status_completed sys_message.desc_message%TYPE;
    
        l_code_msg_hoff_m097 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M097'; --End of resposability
        l_msg_hoff_m097 sys_message.desc_message%TYPE;
    
        l_hand_off_type VARCHAR2(4000) := i_hand_off_type;
        l_flg_profile   VARCHAR2(4000) := i_flg_profile;
        l_sbar_note     VARCHAR2(4000);
    
        l_count NUMBER;
    
    BEGIN
    
        l_count := get_count_new_history(i_epis_prof_resp);
    
        l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        l_msg_hoff_m003    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m003);
        l_msg_hoff_m004    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m004);
        l_msg_hoff_m005    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m005);
        l_msg_hoff_m006    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m006);
        l_status_completed := pk_sysdomain.get_domain(i_code_dom => 'EPIS_PROF_RESP.FLG_STATUS',
                                                      i_val      => 'T',
                                                      i_lang     => i_lang);
    
        l_msg_hoff_m036 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m036);
        l_msg_hoff_m055 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m055);
        l_msg_hoff_m056 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m056);
        l_msg_hoff_m097 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m097);
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank * rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT rn, data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT rn,
                                       hand_off_title,
                                       CASE
                                            WHEN flg_status = flg_status_old THEN
                                             name_prof_to
                                            ELSE
                                             NULL
                                        END name_prof_to,
                                       CASE
                                            WHEN flg_status = flg_status_old THEN
                                             speciality
                                            ELSE
                                             NULL
                                        END speciality,
                                       /*
                                       CASE
                                            WHEN flg_status = flg_status_old THEN
                                             desc_resp_type
                                            ELSE
                                             NULL
                                             
                                        END desc_resp_type,
                                        */
                                       desc_resp_type,
                                       CASE
                                            WHEN flg_status = flg_status_old THEN
                                             desc_profile
                                            ELSE
                                             NULL
                                        END desc_profile,
                                       
                                       CASE
                                            WHEN flg_status = g_onhold
                                                 AND l_count = 0 THEN
                                             sbar_note
                                            WHEN flg_status = pk_hand_off.g_hand_off_r
                                                 AND l_count <> 0 THEN
                                             sbar_note
                                        
                                            ELSE
                                             NULL
                                        END sbar_note,
                                       CASE
                                            WHEN flg_status = g_onhold
                                                 AND l_count = 0 THEN
                                             notes
                                            WHEN flg_status = pk_hand_off.g_hand_off_r
                                                 AND l_count <> 0 THEN
                                            
                                             notes
                                            ELSE
                                             NULL
                                        END notes,
                                       CASE
                                            WHEN flg_status = g_outdated
                                                 AND l_count = 0
                                                 AND flg_status_epr = pk_hand_off.g_hand_off_c THEN
                                             cancel_reason
                                            WHEN flg_status <> flg_status_old
                                                 AND l_count <> 0
                                                 AND flg_status_epr = pk_hand_off.g_hand_off_c THEN
                                             cancel_reason
                                        
                                            ELSE
                                             NULL
                                        END cancel_reason_new,
                                       CASE
                                            WHEN flg_status = g_outdated
                                                 AND l_count = 0
                                                 AND flg_status_epr = pk_hand_off.g_hand_off_c THEN
                                             cancel_notes
                                            WHEN flg_status <> flg_status_old
                                                 AND l_count <> 0
                                                 AND flg_status_epr = pk_hand_off.g_hand_off_c THEN
                                             cancel_notes
                                            ELSE
                                             NULL
                                        END cancel_notes_new,
                                       CASE
                                            WHEN flg_status <> flg_status_old THEN
                                             status
                                            ELSE
                                             NULL
                                        END status_new,
                                       pk_hand_off_core.get_prof_resp_status(i_lang,
                                                                             flg_status,
                                                                             flg_status_old,
                                                                             flg_status_epr) status,
                                       pk_hand_off_core.get_epis_prof_resp_signature(i_lang,
                                                                                     i_prof,
                                                                                     id_epis_prof_resp,
                                                                                     decode(rcount,
                                                                                            rn,
                                                                                            pk_alert_constant.g_no,
                                                                                            pk_alert_constant.g_yes)) registered
                                  FROM (SELECT row_number() over(ORDER BY empr.dt_update DESC, empr.flg_status DESC) rn,
                                               COUNT(*) over(ORDER BY epr.id_epis_prof_resp) rcount,
                                               epr.id_epis_prof_resp,
                                               nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                                                   l_msg_opn_m001) name_prof_to,
                                               pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                                                     i_prof,
                                                                                     epr.id_clinical_service_dest,
                                                                                     epr.id_department_dest,
                                                                                     empr.id_speciality) speciality,
                                               decode(epr.flg_status,
                                                      pk_hand_off.g_hand_off_r,
                                                      l_msg_hoff_m003,
                                                      pk_hand_off.g_hand_off_f,
                                                      l_msg_hoff_m004,
                                                      pk_hand_off.g_hand_off_d,
                                                      l_msg_hoff_m005,
                                                      pk_hand_off.g_hand_off_t,
                                                      l_status_completed,
                                                      l_msg_hoff_m006) status,
                                               --first_value(empr.flg_status) over(ORDER BY empr.dt_update, empr.flg_status rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_old,
                                               first_value(epr.flg_status) over(ORDER BY epr.dt_creation rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_old,
                                               CASE
                                                    WHEN l_count > 0 THEN
                                                     epr.flg_status
                                                    ELSE
                                                     empr.flg_status
                                                END flg_status,
                                               epr.flg_status flg_status_epr,
                                               to_char(epr.id_epis_prof_resp) notes,
                                               epr.notes_cancel cancel_notes,
                                               pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) cancel_reason,
                                               CASE
                                                    WHEN epr.id_profile_template IS NOT NULL THEN
                                                     pk_hand_off_core.get_profile_template_desc(i_lang,
                                                                                                epr.id_profile_template)
                                                    ELSE
                                                     pk_hand_off_core.get_desc_category(i_lang,
                                                                                        i_prof,
                                                                                        l_hand_off_type,
                                                                                        epr.id_prof_comp,
                                                                                        pk_hand_off_core.g_prof_type_to,
                                                                                        empr.flg_profile,
                                                                                        epr.flg_type)
                                                END desc_profile,
                                               empr.flg_resp_type,
                                               decode(empr.flg_resp_type,
                                                      NULL,
                                                      NULL,
                                                      pk_hand_off_core.get_resp_type_desc(i_lang,
                                                                                          i_prof,
                                                                                          empr.id_epis_prof_resp,
                                                                                          l_hand_off_type)) desc_resp_type,
                                               pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                             epr.id_prof_comp,
                                                                             epr.dt_request_tstz,
                                                                             epr.flg_transfer) flg_msg_title,
                                               decode(pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev,
                                                                                        resp_prev.id_prof_comp),
                                                                                    epr.id_prof_comp,
                                                                                    epr.dt_request_tstz,
                                                                                    epr.flg_transfer,
                                                                                    epr.flg_status),
                                                      pk_hand_off_core.g_msg_type_b,
                                                      l_msg_hoff_m036,
                                                      'F',
                                                      l_msg_hoff_m036,
                                                      pk_hand_off_core.g_msg_type_t,
                                                      l_msg_hoff_m097,
                                                      'R',
                                                      l_msg_hoff_m055,
                                                      l_msg_hoff_m056) hand_off_title,
                                               CASE l_sbar_note
                                                   WHEN pk_alert_constant.g_yes THEN
                                                    to_char(epr.id_epis_prof_resp)
                                                   ELSE
                                                    NULL
                                               END sbar_note
                                          FROM (SELECT vepr.*
                                                  FROM v_epis_prof_resp_f vepr
                                                 WHERE l_count = 0
                                                UNION ALL
                                                SELECT veprh.*
                                                  FROM v_epis_prof_resp_h veprh
                                                 WHERE l_count > 0) epr
                                          LEFT JOIN epis_prof_resp resp_prev
                                            ON resp_prev.id_epis_prof_resp =
                                               pk_hand_off_core.get_prev_resp(epr.id_episode,
                                                                              epr.id_epis_prof_resp,
                                                                              nvl(epr.dt_comp_tstz, epr.dt_request_tstz),
                                                                              epr.flg_type,
                                                                              l_flg_profile,
                                                                              l_hand_off_type)
                                          LEFT JOIN epis_multi_profresp_hist empr
                                            ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                                           AND ((empr.flg_status = 'A' AND l_count > 0) OR (l_count = 0))
                                         WHERE epr.id_epis_prof_resp = i_epis_prof_resp)) unpivot include NULLS(data_source_val FOR data_source IN(hand_off_title,
                                                                                                                                                   name_prof_to,
                                                                                                                                                   speciality,
                                                                                                                                                   desc_resp_type,
                                                                                                                                                   desc_profile,
                                                                                                                                                   status,
                                                                                                                                                   status_new,
                                                                                                                                                   sbar_note,
                                                                                                                                                   notes,
                                                                                                                                                   cancel_reason_new,
                                                                                                                                                   cancel_notes_new,
                                                                                                                                                   registered)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HAND_OFF'
           AND ddb.internal_name = 'REQUESTED'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_tab_dd_block_data;
    
    END get_tab_dd_block_data_m01;

    FUNCTION get_tab_dd_block_data_n01
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type  IN VARCHAR2,
        i_flg_profile    IN VARCHAR2
    ) RETURN t_tab_dd_block_data IS
        l_return t_tab_dd_block_data;
    
        l_msg_opn_m001  sys_message.desc_message%TYPE;
        l_msg_hoff_m003 sys_message.desc_message%TYPE;
        l_msg_hoff_m004 sys_message.desc_message%TYPE;
        l_msg_hoff_m005 sys_message.desc_message%TYPE;
        l_msg_hoff_m006 sys_message.desc_message%TYPE;
    
        l_code_msg_hoff_m036 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M036'; --Beginning of responsability
        l_msg_hoff_m036 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m055 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M055'; --Transfer of responsibility
        l_msg_hoff_m055 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m056 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M056'; --Responsibility shift
        l_msg_hoff_m056 sys_message.desc_message%TYPE;
    
        l_code_msg_hoff_m097 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M097'; --End of resposability
        l_msg_hoff_m097 sys_message.desc_message%TYPE;
    
        l_status_completed sys_message.desc_message%TYPE;
    
        l_hand_off_type VARCHAR2(4000) := i_hand_off_type;
        l_flg_profile   VARCHAR2(4000) := i_flg_profile;
        l_sbar_note     VARCHAR2(4000);
    
        l_count NUMBER;
    
    BEGIN
    
        l_count := get_count_new_history(i_epis_prof_resp);
    
        l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        l_msg_hoff_m003    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m003);
        l_msg_hoff_m004    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m004);
        l_msg_hoff_m005    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m005);
        l_msg_hoff_m006    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m006);
        l_status_completed := pk_sysdomain.get_domain(i_code_dom => 'EPIS_PROF_RESP.FLG_STATUS',
                                                      i_val      => 'T',
                                                      i_lang     => i_lang);
    
        l_msg_hoff_m036 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m036);
        l_msg_hoff_m055 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m055);
        l_msg_hoff_m056 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m056);
        l_msg_hoff_m097 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m097);
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank * rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   dd.data_source_val_old)
          BULK COLLECT
          INTO l_return
          FROM (SELECT rank rn,
                       data_source,
                       data_source_val,
                       lag(data_source_val) over(PARTITION BY data_source ORDER BY rank ASC) AS data_source_val_old
                  FROM (SELECT *
                          FROM (SELECT 3 rank, -- REQUISIÇÃO
                                       epr.id_epis_prof_resp,
                                       nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                                           l_msg_opn_m001) name_prof_to,
                                       pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                                             i_prof,
                                                                             epr.id_clinical_service_dest,
                                                                             epr.id_department_dest,
                                                                             epr.id_speciality) speciality,
                                       decode(epr.flg_status,
                                              pk_hand_off.g_hand_off_c,
                                              decode(epr.id_prof_req,
                                                     epr.id_prof_to,
                                                     pk_hand_off.g_hand_off_f,
                                                     pk_hand_off.g_hand_off_r)) flg_status,
                                       decode(epr.flg_status,
                                              pk_hand_off.g_hand_off_c,
                                              decode(epr.id_prof_req, epr.id_prof_to, l_msg_hoff_m004, l_msg_hoff_m003),
                                              pk_hand_off.g_hand_off_r,
                                              l_msg_hoff_m003,
                                              pk_hand_off.g_hand_off_f,
                                              --decode(epr.id_prof_req, epr.id_prof_to, l_msg_hoff_m004, l_msg_hoff_m003),
                                              l_msg_hoff_m004,
                                              pk_hand_off.g_hand_off_t,
                                              l_status_completed,
                                              l_msg_hoff_m005) status,
                                       NULL status_new,
                                       to_char(epr.id_epis_prof_resp) notes,
                                       NULL cancel_notes_new,
                                       NULL cancel_reason_new,
                                       CASE
                                            WHEN epr.id_profile_template IS NOT NULL THEN
                                             pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                                            ELSE
                                             pk_hand_off_core.get_desc_category(i_lang,
                                                                                i_prof,
                                                                                l_hand_off_type,
                                                                                epr.id_prof_comp,
                                                                                pk_hand_off_core.g_prof_type_to,
                                                                                NULL,
                                                                                epr.flg_type)
                                        END desc_profile,
                                       NULL desc_resp_type,
                                       pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                     epr.id_prof_comp,
                                                                     epr.dt_request_tstz,
                                                                     epr.flg_transfer) flg_msg_title,
                                       decode(pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                            epr.id_prof_comp,
                                                                            epr.dt_request_tstz,
                                                                            epr.flg_transfer,
                                                                            epr.flg_status),
                                              pk_hand_off_core.g_msg_type_b,
                                              l_msg_hoff_m036,
                                              'F',
                                              l_msg_hoff_m097,
                                              pk_hand_off_core.g_msg_type_t,
                                              --l_msg_hoff_m055,
                                              l_msg_hoff_m036,
                                              l_msg_hoff_m056) hand_off_title,
                                       CASE l_sbar_note
                                           WHEN pk_alert_constant.g_yes THEN
                                            to_char(epr.id_epis_prof_resp)
                                           ELSE
                                            NULL
                                       END sbar_note,
                                       pk_hand_off_core.get_epis_prof_resp_signature(i_lang,
                                                                                     i_prof,
                                                                                     epr.id_epis_prof_resp,
                                                                                     pk_alert_constant.g_no) registered
                                  FROM (SELECT vepr.*
                                          FROM v_epis_prof_resp_f vepr
                                         WHERE l_count = 0
                                        UNION ALL
                                        SELECT veprh.*
                                          FROM v_epis_prof_resp_h veprh
                                         WHERE l_count > 0) epr
                                  LEFT JOIN epis_prof_resp resp_prev
                                    ON resp_prev.id_epis_prof_resp =
                                       pk_hand_off_core.get_prev_resp(epr.id_episode,
                                                                      epr.id_epis_prof_resp,
                                                                      nvl(epr.dt_comp_tstz, epr.dt_request_tstz),
                                                                      epr.flg_type,
                                                                      l_flg_profile,
                                                                      l_hand_off_type)
                                 WHERE epr.id_epis_prof_resp = i_epis_prof_resp
                                UNION ALL -- CANCELAMENTO
                                SELECT 1 rank,
                                       epr.id_epis_prof_resp,
                                       NULL name_prof_to,
                                       NULL speciality,
                                       pk_hand_off.g_hand_off_c flg_status,
                                       decode(epr.flg_status,
                                              pk_hand_off.g_hand_off_c,
                                              decode(epr.id_prof_req, epr.id_prof_to, l_msg_hoff_m004, l_msg_hoff_m003),
                                              pk_hand_off.g_hand_off_r,
                                              l_msg_hoff_m003,
                                              pk_hand_off.g_hand_off_f,
                                              l_msg_hoff_m004,
                                              l_msg_hoff_m005) status,
                                       l_msg_hoff_m006 status_new,
                                       NULL notes,
                                       epr.notes_cancel cancel_notes_new,
                                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) cancel_reason_new,
                                       NULL desc_profile,
                                       NULL desc_resp_type,
                                       pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                     epr.id_prof_comp,
                                                                     epr.dt_request_tstz,
                                                                     epr.flg_transfer) flg_msg_title,
                                       decode(pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                            epr.id_prof_comp,
                                                                            epr.dt_request_tstz,
                                                                            epr.flg_transfer,
                                                                            epr.flg_status),
                                              pk_hand_off_core.g_msg_type_b,
                                              l_msg_hoff_m036,
                                              'F',
                                              l_msg_hoff_m036,
                                              pk_hand_off_core.g_msg_type_t,
                                              --l_msg_hoff_m055,
                                              l_msg_hoff_m097,
                                              l_msg_hoff_m056) hand_off_title,
                                       NULL sbar_note,
                                       pk_hand_off_core.get_epis_prof_resp_signature(i_lang, i_prof, epr.id_epis_prof_resp) registered
                                  FROM (SELECT vepr.*
                                          FROM v_epis_prof_resp_f vepr
                                         WHERE l_count = 0
                                        UNION ALL
                                        SELECT veprh.*
                                          FROM v_epis_prof_resp_h veprh
                                         WHERE l_count > 0) epr
                                  LEFT JOIN epis_prof_resp resp_prev
                                    ON resp_prev.id_epis_prof_resp =
                                       pk_hand_off_core.get_prev_resp(epr.id_episode,
                                                                      epr.id_epis_prof_resp,
                                                                      nvl(epr.dt_comp_tstz, epr.dt_request_tstz),
                                                                      epr.flg_type,
                                                                      l_flg_profile,
                                                                      l_hand_off_type)
                                 WHERE epr.id_epis_prof_resp = i_epis_prof_resp
                                   AND epr.flg_status = pk_hand_off.g_hand_off_c
                                UNION ALL -- ACEITAR
                                SELECT 2 rank,
                                       epr.id_epis_prof_resp,
                                       NULL name_prof_to,
                                       NULL speciality,
                                       pk_hand_off.g_hand_off_c flg_status,
                                       decode(epr.flg_status,
                                              pk_hand_off.g_hand_off_c,
                                              decode(epr.id_prof_req, epr.id_prof_to, l_msg_hoff_m004, l_msg_hoff_m003),
                                              pk_hand_off.g_hand_off_r,
                                              l_msg_hoff_m003,
                                              pk_hand_off.g_hand_off_f,
                                              decode(epr.id_prof_req, epr.id_prof_to, l_msg_hoff_m004, l_msg_hoff_m003),
                                              l_msg_hoff_m005) status,
                                       l_msg_hoff_m004 status_new,
                                       
                                       NULL notes,
                                       epr.notes_cancel cancel_notes_new,
                                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) cancel_reason_new,
                                       NULL desc_profile,
                                       NULL desc_resp_type,
                                       pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                     epr.id_prof_comp,
                                                                     epr.dt_request_tstz,
                                                                     epr.flg_transfer) flg_msg_title,
                                       decode(pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                            epr.id_prof_comp,
                                                                            epr.dt_request_tstz,
                                                                            epr.flg_transfer),
                                              pk_hand_off_core.g_msg_type_b,
                                              l_msg_hoff_m036,
                                              pk_hand_off_core.g_msg_type_t,
                                              l_msg_hoff_m055,
                                              l_msg_hoff_m056) hand_off_title,
                                       NULL sbar_note,
                                       pk_hand_off_core.get_epis_prof_resp_signature(i_lang, i_prof, epr.id_epis_prof_resp) registered
                                  FROM (SELECT vepr.*
                                          FROM v_epis_prof_resp_f vepr
                                         WHERE l_count = 0
                                        UNION ALL
                                        SELECT veprh.*
                                          FROM v_epis_prof_resp_h veprh
                                         WHERE l_count > 0) epr
                                  LEFT JOIN epis_prof_resp resp_prev
                                    ON resp_prev.id_epis_prof_resp =
                                       pk_hand_off_core.get_prev_resp(epr.id_episode,
                                                                      epr.id_epis_prof_resp,
                                                                      nvl(epr.dt_comp_tstz, epr.dt_request_tstz),
                                                                      epr.flg_type,
                                                                      l_flg_profile,
                                                                      l_hand_off_type)
                                 WHERE epr.id_epis_prof_resp = i_epis_prof_resp
                                   AND epr.flg_status = pk_hand_off.g_hand_off_f
                                   AND epr.id_prof_req <> epr.id_prof_to
                                   AND epr.dt_request_tstz <> epr.dt_comp_tstz) unpivot include NULLS(data_source_val FOR data_source IN(hand_off_title,
                                                                                                                                         name_prof_to,
                                                                                                                                         speciality,
                                                                                                                                         desc_resp_type,
                                                                                                                                         desc_profile,
                                                                                                                                         status,
                                                                                                                                         status_new,
                                                                                                                                         sbar_note,
                                                                                                                                         notes,
                                                                                                                                         cancel_reason_new,
                                                                                                                                         cancel_notes_new,
                                                                                                                                         registered)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HAND_OFF'
           AND ddb.internal_name = 'REQUESTED'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_return;
    
    END get_tab_dd_block_data_n01;

    FUNCTION get_tab_dd_block_data_m02
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type  IN VARCHAR2,
        i_flg_profile    IN VARCHAR2
    ) RETURN t_tab_dd_block_data IS
        l_return t_tab_dd_block_data;
    
        l_msg_opn_m001  sys_message.desc_message%TYPE;
        l_msg_hoff_m003 sys_message.desc_message%TYPE;
        l_msg_hoff_m004 sys_message.desc_message%TYPE;
        l_msg_hoff_m005 sys_message.desc_message%TYPE;
        l_msg_hoff_m006 sys_message.desc_message%TYPE;
    
        l_code_msg_hoff_m036 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M036'; --Beginning of responsability
        l_msg_hoff_m036 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m055 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M055'; --Transfer of responsibility
        l_msg_hoff_m055 sys_message.desc_message%TYPE;
        l_code_msg_hoff_m056 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M056'; --Responsibility shift
        l_msg_hoff_m056    sys_message.desc_message%TYPE;
        l_status_completed sys_message.desc_message%TYPE;
    
        l_code_msg_hoff_m097 CONSTANT sys_message.code_message%TYPE := 'EDIS_HAND_OFF_M097'; --End of resposability
        l_msg_hoff_m097 sys_message.desc_message%TYPE;
    
        l_hand_off_type VARCHAR2(4000) := i_hand_off_type;
        l_flg_profile   VARCHAR2(4000) := i_flg_profile;
        l_sbar_note     VARCHAR2(4000);
    
        --l_count NUMBER;
    
    BEGIN
    
        --l_count := get_count_new_history(i_epis_prof_resp);
    
        l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        l_msg_hoff_m003    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m003);
        l_msg_hoff_m004    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m004);
        l_msg_hoff_m005    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m005);
        l_msg_hoff_m006    := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_hoff_m006);
        l_status_completed := pk_sysdomain.get_domain(i_code_dom => 'EPIS_PROF_RESP.FLG_STATUS',
                                                      i_val      => 'T',
                                                      i_lang     => i_lang);
    
        l_msg_hoff_m036 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m036);
        l_msg_hoff_m055 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m055);
        l_msg_hoff_m056 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m056);
        l_msg_hoff_m097 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_hoff_m097);
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_return
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT epr.id_epis_prof_resp,
                                       nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                                           l_msg_opn_m001) name_prof_to,
                                       pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                                             i_prof,
                                                                             epr.id_clinical_service_dest,
                                                                             epr.id_department_dest,
                                                                             empr.id_speciality) speciality,
                                       decode(epr.flg_status,
                                              pk_hand_off.g_hand_off_r,
                                              l_msg_hoff_m003,
                                              pk_hand_off.g_hand_off_f,
                                              l_msg_hoff_m004,
                                              pk_hand_off.g_hand_off_d,
                                              l_msg_hoff_m005,
                                              pk_hand_off.g_hand_off_t,
                                              l_status_completed,
                                              l_msg_hoff_m006) status,
                                       NULL status_new,
                                       to_char(epr.id_epis_prof_resp) notes,
                                       epr.notes_cancel cancel_notes,
                                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) cancel_reason,
                                       CASE
                                            WHEN epr.id_profile_template IS NOT NULL THEN
                                             pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                                            ELSE
                                             pk_hand_off_core.get_desc_category(i_lang,
                                                                                i_prof,
                                                                                l_hand_off_type,
                                                                                epr.id_prof_comp,
                                                                                pk_hand_off_core.g_prof_type_to,
                                                                                empr.flg_profile,
                                                                                epr.flg_type)
                                        END desc_profile,
                                       empr.flg_resp_type,
                                       decode(empr.flg_resp_type,
                                              NULL,
                                              NULL,
                                              pk_hand_off_core.get_resp_type_desc(i_lang,
                                                                                  i_prof,
                                                                                  empr.id_epis_prof_resp,
                                                                                  l_hand_off_type)) desc_resp_type,
                                       pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                     epr.id_prof_comp,
                                                                     epr.dt_request_tstz,
                                                                     epr.flg_transfer) flg_msg_title,
                                       decode(pk_hand_off_core.get_msg_type(nvl(epr.id_prof_prev, resp_prev.id_prof_comp),
                                                                            epr.id_prof_comp,
                                                                            epr.dt_request_tstz,
                                                                            epr.flg_transfer,
                                                                            epr.flg_status),
                                              pk_hand_off_core.g_msg_type_b,
                                              l_msg_hoff_m036,
                                              'F',
                                              l_msg_hoff_m036,
                                              pk_hand_off_core.g_msg_type_t,
                                              l_msg_hoff_m097,
                                              'R',
                                              l_msg_hoff_m055,
                                              l_msg_hoff_m056) hand_off_title,
                                       CASE l_sbar_note
                                           WHEN pk_alert_constant.g_yes THEN
                                            to_char(epr.id_epis_prof_resp)
                                           ELSE
                                            NULL
                                       END sbar_note,
                                       pk_hand_off_core.get_epis_prof_resp_signature(i_lang, i_prof, epr.id_epis_prof_resp) registered
                                  FROM (SELECT vepr.*
                                          FROM v_epis_prof_resp_f vepr) epr
                                  LEFT JOIN epis_prof_resp resp_prev
                                    ON resp_prev.id_epis_prof_resp =
                                       pk_hand_off_core.get_prev_resp(epr.id_episode,
                                                                      epr.id_epis_prof_resp,
                                                                      nvl(epr.dt_comp_tstz, epr.dt_request_tstz),
                                                                      epr.flg_type,
                                                                      l_flg_profile,
                                                                      l_hand_off_type)
                                  LEFT JOIN epis_multi_prof_resp empr
                                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                                --AND ((empr.flg_status = 'A'))
                                 WHERE epr.id_epis_prof_resp = i_epis_prof_resp) unpivot include NULLS(data_source_val FOR data_source IN(hand_off_title,
                                                                                                                                          name_prof_to,
                                                                                                                                          speciality,
                                                                                                                                          desc_resp_type,
                                                                                                                                          desc_profile,
                                                                                                                                          status,
                                                                                                                                          status_new,
                                                                                                                                          sbar_note,
                                                                                                                                          notes,
                                                                                                                                          cancel_reason,
                                                                                                                                          cancel_notes,
                                                                                                                                          registered)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'HAND_OFF'
           AND ddb.internal_name = 'REQUESTED'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_return;
    
    END get_tab_dd_block_data_m02;

    PROCEDURE ins_epis_prof_resp_h(i_row IN epis_prof_resp%ROWTYPE) IS
    BEGIN
    
        INSERT INTO epis_prof_resp_h
            (id_epis_prof_resp_h,
             dt_creation,
             id_epis_prof_resp,
             id_episode,
             id_prof_req,
             id_prof_to,
             id_prof_comp,
             id_speciality,
             id_movement,
             --notes_old,
             flg_type,
             flg_status,
             id_prof_decline,
             id_prof_cancel,
             notes_cancel,
             trf_reason,
             trf_answer,
             id_room,
             id_bed,
             id_department_orig,
             id_department_dest,
             id_prof_execute,
             transport_notes,
             id_prof_prev,
             flg_transfer,
             id_bed_execute,
             id_room_execute,
             flg_escort,
             flg_transf_type,
             id_clinical_service_orig,
             id_clinical_service_dest,
             dt_request_tstz,
             dt_cancel_tstz,
             dt_decline_tstz,
             dt_comp_tstz,
             dt_trf_requested_tstz,
             dt_trf_accepted_tstz,
             dt_execute_tstz,
             dt_end_transfer_tstz,
             id_cancel_reason,
             --free_text_notes,
             flg_patient_consent,
             sbar_notes,
             notes_clob,
             id_epis_pn,
             id_profile_template)
        VALUES
            (seq_epis_prof_resp_h.nextval,
             current_timestamp,
             i_row.id_epis_prof_resp,
             i_row.id_episode,
             i_row.id_prof_req,
             i_row.id_prof_to,
             i_row.id_prof_comp,
             i_row.id_speciality,
             i_row.id_movement,
             --i_row.notes_old,
             i_row.flg_type,
             i_row.flg_status,
             i_row.id_prof_decline,
             i_row.id_prof_cancel,
             i_row.notes_cancel,
             i_row.trf_reason,
             i_row.trf_answer,
             i_row.id_room,
             i_row.id_bed,
             i_row.id_department_orig,
             i_row.id_department_dest,
             i_row.id_prof_execute,
             i_row.transport_notes,
             i_row.id_prof_prev,
             i_row.flg_transfer,
             i_row.id_bed_execute,
             i_row.id_room_execute,
             i_row.flg_escort,
             i_row.flg_transf_type,
             i_row.id_clinical_service_orig,
             i_row.id_clinical_service_dest,
             i_row.dt_request_tstz,
             i_row.dt_cancel_tstz,
             i_row.dt_decline_tstz,
             i_row.dt_comp_tstz,
             i_row.dt_trf_requested_tstz,
             i_row.dt_trf_accepted_tstz,
             i_row.dt_execute_tstz,
             i_row.dt_end_transfer_tstz,
             i_row.id_cancel_reason,
             --i_row.free_text_notes,
             i_row.flg_patient_consent,
             i_row.sbar_notes,
             i_row.notes_clob,
             i_row.id_epis_pn,
             i_row.id_profile_template);
    
    END ins_epis_prof_resp_h;

    FUNCTION set_epis_prof_resp_h(i_id IN NUMBER) RETURN epis_prof_resp%ROWTYPE IS
        xupd epis_prof_resp%ROWTYPE;
    BEGIN
    
        IF i_id IS NOT NULL
        THEN
            SELECT *
              INTO xupd
              FROM epis_prof_resp
             WHERE id_epis_prof_resp = i_id;
        END IF;
    
        RETURN xupd;
    
    END set_epis_prof_resp_h;

    FUNCTION get_count_new_history(i_epis_prof_resp IN NUMBER) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_prof_resp_h
         WHERE id_epis_prof_resp = i_epis_prof_resp;
    
        RETURN l_count;
    
    END get_count_new_history;

    FUNCTION get_dt_signature
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_dt_request  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_comp     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_decline  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_transfer IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_cancel   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_detail      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_no CONSTANT VARCHAR2(0010 CHAR) := pk_alert_constant.g_no;
        l_dt TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        CASE i_flg_status
            WHEN pk_hand_off.g_hand_off_r THEN
            
                l_return := pk_date_utils.date_char_tsz(i_lang, i_dt_request, i_prof.institution, i_prof.software);
            
            WHEN pk_hand_off.g_hand_off_f THEN
            
                IF i_dt_request = i_dt_comp
                THEN
                    l_dt := i_dt_comp;
                ELSE
                
                    IF i_detail = k_no
                    THEN
                        l_dt := i_dt_request;
                    ELSE
                        l_dt := i_dt_comp;
                    END IF;
                
                END IF;
                l_return := pk_date_utils.date_char_tsz(i_lang, l_dt, i_prof.institution, i_prof.software);
            
            WHEN pk_hand_off.g_hand_off_d THEN
            
                l_return := pk_date_utils.date_char_tsz(i_lang, i_dt_decline, i_prof.institution, i_prof.software);
            
            WHEN pk_hand_off.g_hand_off_t THEN
            
                IF i_dt_request = i_dt_transfer
                THEN
                    l_dt := i_dt_transfer;
                ELSE
                
                    IF i_detail = k_no
                    THEN
                        l_dt := i_dt_request;
                    ELSE
                        l_dt := i_dt_transfer;
                    END IF;
                END IF;
                l_return := pk_date_utils.date_char_tsz(i_lang, l_dt, i_prof.institution, i_prof.software);
            
            WHEN pk_hand_off.g_hand_off_c THEN
            
                IF i_detail = k_no
                THEN
                    l_dt := i_dt_request;
                ELSE
                    l_dt := i_dt_cancel;
                END IF;
                l_return := pk_date_utils.date_char_tsz(i_lang, l_dt, i_prof.institution, i_prof.software);
            
            ELSE
                l_return := 'X#' || i_flg_status || '#X';
        END CASE;
    
        RETURN l_return;
    
    END get_dt_signature;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package_name);
END pk_hand_off_core;
/
