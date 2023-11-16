/*-- Last Change Revision: $Rev: 2027414 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_adm_hs AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_retval BOOLEAN;
    --g_found  BOOLEAN;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_error VARCHAR2(4000 CHAR);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Check if referral can change status to "No show"
    * 
    * @param   i_lang    Language associated to the professional executing the request
    * @param   i_prof    Professional, institution and software ids
    * @param   i_id_ref  Referral identifier    
    * @param   i_id_workflow              Workflow identifier
    * @param   i_flg_status               Referral status
    * @param   i_id_profile_template      Profile template identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-05-2012 
    */
    FUNCTION check_no_show
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_ref              IN p1_external_request.id_external_request%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR IS
        l_result         VARCHAR2(1 CHAR);
        l_dt_appointment schedule.dt_begin_tstz%TYPE;
        l_count          PLS_INTEGER;
    BEGIN
    
        -- check if configuration is available 
        -- todo: BEGIN - remove this configuration when all institutions receive this referral status)       
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT wtc.flg_visible
                  FROM wf_transition_config wtc
                 WHERE wtc.id_software IN (0, i_prof.software)
                   AND wtc.id_institution IN (0, i_prof.institution)
                   AND wtc.id_category IN (0, pk_ref_constant.g_cat_id_adm)
                   AND wtc.id_profile_template IN (0, i_id_profile_template)
                      -- AND wtc.id_functionality IN (0, i_id_functionality) -- this is the registrar
                   AND wtc.id_status_begin = pk_ref_status.convert_status_n(i_flg_status)
                   AND wtc.id_status_end = pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_f)
                   AND wtc.id_workflow_action = pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_f)
                   AND wtc.id_workflow = nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp)
                 ORDER BY id_institution      DESC,
                          id_software         DESC,
                          id_category         DESC,
                          id_profile_template DESC,
                          id_functionality    DESC)
         WHERE rownum = 1
           AND flg_visible = pk_ref_constant.g_yes;
    
        IF l_count = 0
        THEN
            RETURN pk_ref_constant.g_no;
        END IF;
        -- todo: END - remove this configuration when all institutions receive this referral status)
    
        g_error          := 'Call pk_ref_module.get_ref_sch_dt_generic / ID_REF=' || i_id_ref;
        l_dt_appointment := pk_ref_module.get_ref_sch_dt_generic(i_lang   => i_lang,
                                                                 i_prof   => i_prof,
                                                                 i_id_ref => i_id_ref);
    
        g_error  := 'Call pk_date_utils.compare_dates_tsz / ID_REF=' || i_id_ref;
        l_result := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                    i_date1 => l_dt_appointment, -- appointment date
                                                    i_date2 => current_timestamp -- actual date
                                                    );
    
        IF l_result IN (pk_ref_constant.g_date_lower, pk_ref_constant.g_date_equal)
        THEN
            RETURN pk_ref_constant.g_yes;
        END IF;
    
        RETURN pk_ref_constant.g_no;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN pk_ref_constant.g_no;
    END check_no_show;

    /**
    * Gets status change options
    * 
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_id_ext_req request id    
    * @param   I_DT_MODIFIED last modified date as provided by get_p1_detail
    * @param   o_status available options list
    * @param   O_FLG_SHOW {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE message title
    * @param   O_MSG message text
    * @param   o_button type of button to show with message
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   06-12-2007
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_p1 IS
            SELECT dt_last_interaction_tstz, flg_status, flg_import, id_workflow
              FROM p1_external_request
             WHERE id_external_request = i_id_ext_req;
        l_exr_row c_p1%ROWTYPE;
    
        l_match_available       VARCHAR2(1 CHAR);
        l_ref_schedule_3        VARCHAR2(1 CHAR);
        l_ref_efectivation_type VARCHAR2(1 CHAR);
        l_ref_schedule_type     VARCHAR2(1 CHAR);
        l_req_cancel_enabled    VARCHAR2(1 CHAR);
        l_id_profile_template   profile_template.id_profile_template%TYPE;
    BEGIN
        ----------------------
        -- CONFIG
        ----------------------        
        g_error              := 'Call pk_ref_status.check_config_enabled / ID_REF=' || i_id_ext_req || ' CONFIG=' ||
                                pk_ref_constant.g_ref_cancel_req_enabled;
        l_req_cancel_enabled := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                                   i_prof   => i_prof,
                                                                   i_config => pk_ref_constant.g_ref_cancel_req_enabled);
    
        l_match_available       := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                   i_id_sys_config => pk_ref_constant.g_ref_match_available),
                                       pk_ref_constant.g_no);
        l_ref_schedule_3        := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                   i_id_sys_config => pk_ref_constant.g_scheduler3_installed),
                                       pk_ref_constant.g_no);
        l_ref_efectivation_type := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                   i_id_sys_config => pk_ref_constant.g_ref_efectivation_type),
                                       pk_ref_constant.g_no);
        l_ref_schedule_type     := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                   i_id_sys_config => pk_ref_constant.g_ref_schedule_type),
                                       pk_ref_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------    
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'OPEN c_p1 / ID_REF=' || i_id_ext_req || ' / MATCH AVAILABLE=' || l_match_available ||
                   ' SCHEDULE_3 AVAILABLE=' || l_ref_schedule_3 || ' REFERRAL EFECTIVATION TYPE=' ||
                   l_ref_efectivation_type || ' REFERRAL SCHEDULE TYPE=' || l_ref_schedule_type;
        OPEN c_p1;
        FETCH c_p1
            INTO l_exr_row;
        CLOSE c_p1;
    
        o_flg_show := pk_ref_constant.g_no;
        IF pk_date_utils.trunc_insttimezone(i_prof, l_exr_row.dt_last_interaction_tstz, pk_ref_constant.g_ss) >
           pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_t008);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_t007);
            o_button    := pk_ref_constant.g_r;
            pk_types.open_my_cursor(o_status);
            RETURN TRUE;
        END IF;
    
        g_error := 'OPEN o_status / ID_REF=' || i_id_ext_req;
        OPEN o_status FOR
            SELECT NULL id_workflow, l_exr_row.flg_status status_begin, data status_end, icon, label, rank, data action
              FROM (
                    -- ALERT-27134: imported referrals cannot be declined
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                      FROM p1_external_request exr, p1_match m, sys_domain sd
                     WHERE exr.flg_status = pk_ref_constant.g_p1_status_i
                       AND exr.id_external_request = i_id_ext_req
                       AND exr.id_patient = m.id_patient(+)
                       AND m.id_institution(+) = exr.id_inst_dest
                       AND m.flg_status(+) = pk_ref_constant.g_match_status_a -- Rematch
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND ((sd.val IN
                           (pk_ref_constant.g_p1_status_b,
                              nvl2(m.sequential_number, pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_b)) AND
                           nvl(exr.flg_import, pk_ref_constant.g_no) = pk_ref_constant.g_no) OR
                           (sd.val = pk_ref_constant.g_p1_status_t AND m.sequential_number IS NOT NULL))
                    UNION -- Chile
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                      FROM p1_external_request exr, sys_domain sd
                     WHERE exr.flg_status = pk_ref_constant.g_p1_status_i
                       AND exr.id_external_request = i_id_ext_req
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.id_language = i_lang
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND l_match_available = pk_ref_constant.g_no
                       AND ((sd.val = pk_ref_constant.g_p1_status_t AND
                           nvl(exr.flg_import, pk_ref_constant.g_no) = pk_ref_constant.g_no) OR
                           (sd.val = pk_ref_constant.g_p1_status_t))
                    UNION ALL
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status = pk_ref_constant.g_p1_status_s
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_p1_status_m
                    UNION ALL
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_m, pk_ref_constant.g_p1_status_s)
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_p1_status_f
                       AND check_no_show(i_lang,
                                         i_prof,
                                         i_id_ext_req,
                                         l_exr_row.id_workflow,
                                         l_exr_row.flg_status,
                                         l_id_profile_template) = pk_ref_constant.g_yes
                    UNION ALL
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank -- for simulation only
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status = pk_ref_constant.g_p1_status_a
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_p1_status_s
                       AND (l_ref_schedule_type = pk_ref_constant.g_simulation OR
                           l_ref_schedule_3 = pk_ref_constant.g_yes)
                    UNION ALL
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank -- for simulation only
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status = pk_ref_constant.g_p1_status_m
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_p1_status_e
                       AND (l_ref_efectivation_type = pk_ref_constant.g_simulation OR
                           l_ref_schedule_3 = pk_ref_constant.g_yes)
                    
                    UNION
                    -- Request cancellation
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_n,
                                                    pk_ref_constant.g_p1_status_i,
                                                    pk_ref_constant.g_p1_status_b,
                                                    pk_ref_constant.g_p1_status_t,
                                                    pk_ref_constant.g_p1_status_a,
                                                    pk_ref_constant.g_p1_status_r,
                                                    pk_ref_constant.g_p1_status_d,
                                                    pk_ref_constant.g_p1_status_o,
                                                    pk_ref_constant.g_p1_status_p,
                                                    pk_ref_constant.g_p1_status_g)
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_ref_action_z
                       AND l_req_cancel_enabled = pk_ref_constant.g_yes
                    UNION
                    -- Avoid request cancellation
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status = pk_ref_constant.g_p1_status_z
                       AND sd.code_domain = pk_ref_constant.g_adm_hs_status_options
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_ref_action_zdn
                       AND l_req_cancel_enabled = pk_ref_constant.g_yes
                          -- this can only be done if it was this professional requesting the referral cancellation
                       AND i_prof.id = (SELECT id_professional
                                          FROM (SELECT id_professional
                                                  FROM p1_tracking t
                                                 WHERE t.id_external_request = i_id_ext_req
                                                   AND t.flg_type = pk_ref_constant.g_tracking_type_s
                                                   AND t.ext_req_status = pk_ref_constant.g_p1_status_z
                                                 ORDER BY t.dt_tracking_tstz DESC)
                                         WHERE rownum <= 1))
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_OPTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_status_options;

    /**
    * Change request status. 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_ext_req         Referral identifier
    * @param   i_status          Referral final flag status     
    * @param   i_notes           Notes of this transition
    * @param   i_reason_code     Decline reason identifier
    * @param   i_dcs             Destination department/clinical_service    
    * @param   i_date            Date of status change       
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION set_status_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_status         IN VARCHAR2,
        i_notes          IN VARCHAR2,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_det_type          p1_detail.flg_type%TYPE;
        l_track_row         p1_tracking%ROWTYPE;
        l_last_triage_track p1_tracking%ROWTYPE;
        e_invalid_status EXCEPTION;
        l_rowids           table_varchar;
        l_valid_status     VARCHAR2(50 CHAR);
        l_ref_row          p1_external_request%ROWTYPE;
        l_cancel_reason    cancel_reason.id_cancel_reason%TYPE;
        l_id_dep_clin_serv p1_tracking.id_dep_clin_serv%TYPE;
        l_curr_dcs         p1_external_request.id_dep_clin_serv%TYPE;
        l_id_spec_inital   p1_external_request.id_speciality%TYPE;
        l_config           VARCHAR2(1 CHAR);
        l_params           VARCHAR2(1000 CHAR);
        l_track_tab        table_number;
    BEGIN
        l_params := 'ID_REF=' || i_ext_req || ' i_status=' || i_status || ' i_reason_code=' || i_reason_code ||
                    ' i_dcs=' || i_dcs;
        g_error  := 'Init set_status_internal / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        -- getting speciality after changing status
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_id_spec_inital := l_ref_row.id_speciality;
    
        l_params := l_params || ' FLG_STATUS=' || l_ref_row.flg_status || ' ID_SPEC=' || l_ref_row.id_speciality;
    
        IF i_status = pk_ref_constant.g_p1_status_m
        THEN
        
            g_error                         := 'UPDATE STATUS M / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := i_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
            l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_m);
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_s,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSIF i_status = pk_ref_constant.g_p1_status_f
        THEN
        
            g_error                         := 'UPDATE STATUS F / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := i_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
            l_track_row.id_reason_code      := i_reason_code;
            l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_f);
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_s ||
                                                                  pk_ref_constant.g_p1_status_m,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- adding notes
            IF i_notes IS NOT NULL
            THEN
            
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_req_can_answ || ' / ' || l_params;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_ext_req,
                     i_notes,
                     g_sysdate_tstz,
                     pk_ref_constant.g_detail_type_miss,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_active);
            END IF;
        
            IF i_transaction_id IS NOT NULL
            THEN
                g_error  := 'Call pk_ref_core.get_no_show_id_reason / ' || l_params;
                g_retval := pk_ref_core.get_no_show_id_reason(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_p1_reason_code => i_reason_code,
                                                              o_value          => l_cancel_reason,
                                                              o_error          => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error  := 'Call pk_schedule_api_upstream.set_patient_no_show / ' || l_params || ' ID_SCHEDULE=' ||
                            l_ref_row.id_schedule || ' i_id_cancel_reason=' || l_cancel_reason;
                g_retval := pk_schedule_api_upstream.set_patient_no_show(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_transaction_id   => i_transaction_id,
                                                                         i_id_schedule      => l_ref_row.id_schedule,
                                                                         i_id_patient       => l_ref_row.id_patient,
                                                                         i_id_cancel_reason => l_cancel_reason,
                                                                         i_notes            => i_notes,
                                                                         o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        ELSIF i_status = pk_ref_constant.g_ref_action_z
        THEN
        
            g_error  := 'Call pk_ref_status.check_config_enabled / ' || l_params || ' CONFIG=' ||
                        pk_ref_constant.g_ref_cancel_req_enabled;
            l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_config => pk_ref_constant.g_ref_cancel_req_enabled);
        
            IF l_config = pk_ref_constant.g_no
            THEN
                g_error := 'Config ' || pk_ref_constant.g_ref_cancel_req_enabled || ' not enabled  / ' || l_params;
                RAISE g_exception_np;
            END IF;
        
            g_error                         := 'UPDATE STATUS Z / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_z;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_reason_code      := i_reason_code;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
            l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_z);
        
            -- same status as cancelling referral (by orig physician)
            g_error        := 'VALID_STATUS / ' || l_params;
            l_valid_status := pk_ref_constant.g_p1_status_n || pk_ref_constant.g_p1_status_i ||
                              pk_ref_constant.g_p1_status_b || pk_ref_constant.g_p1_status_t ||
                              pk_ref_constant.g_p1_status_a || pk_ref_constant.g_p1_status_r ||
                              pk_ref_constant.g_p1_status_d || pk_ref_constant.g_p1_status_o ||
                              pk_ref_constant.g_p1_status_p || pk_ref_constant.g_p1_status_g ||
                              pk_ref_constant.g_p1_status_l;
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params || ' l_valid_status=' || l_valid_status;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => l_valid_status,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- adding notes
            IF i_notes IS NOT NULL
            THEN
            
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_req_can || ' / ' || l_params;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_ext_req,
                     i_notes,
                     g_sysdate_tstz,
                     pk_ref_constant.g_detail_type_req_can,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_active);
            END IF;
        
        ELSIF i_status = pk_ref_constant.g_ref_action_zdn
        THEN
        
            -- Denying referral cancellation request
            g_error  := 'Call pk_ref_status.check_config_enabled / / ' || l_params || ' CONFIG=' ||
                        pk_ref_constant.g_ref_cancel_req_enabled;
            l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_config => pk_ref_constant.g_ref_cancel_req_enabled);
        
            IF l_config = pk_ref_constant.g_no
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- getting old tracking row
            g_error  := 'Call pk_ref_utils.get_prev_status_data / ' || l_params;
            g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                          i_prof   => i_prof,
                                                          i_id_ref => i_ext_req,
                                                          o_data   => l_track_row,
                                                          o_error  => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            g_error                        := 'l_track_row / ' || l_params;
            l_track_row.id_professional    := i_prof.id;
            l_track_row.id_institution     := i_prof.institution;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz   := g_sysdate_tstz;
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_zdn);
        
            l_valid_status := pk_ref_constant.g_p1_status_z;
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params || ' / EXT_REQ_STATUS=' ||
                        l_track_row.ext_req_status || ' OLD_STATUS=' || l_valid_status;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => l_valid_status,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- adding notes
            IF i_notes IS NOT NULL
            THEN
            
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_req_can_answ || ' / ' || l_params;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_ext_req,
                     i_notes,
                     g_sysdate_tstz,
                     pk_ref_constant.g_detail_type_req_can_answ,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_active);
            END IF;
        
        ELSE
        
            g_error := 'i_status=' || i_status || '  / ' || l_params;
            IF i_status = pk_ref_constant.g_p1_status_t
            THEN
                l_track_row.id_dep_clin_serv   := i_dcs;
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_t);
                l_det_type                     := pk_ref_constant.g_detail_type_ntri;
            
            ELSIF i_status = pk_ref_constant.g_p1_status_b
            THEN
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_b);
                l_det_type                     := pk_ref_constant.g_detail_type_bdcl;
            
            END IF;
        
            -- JS, 2007-DEZ-20: Obter ultimo estado de triagem (R ou T, se ja esteve em triagem)
            g_error             := 'Call pk_p1_utils.get_last_triage_status / ' || l_params;
            l_last_triage_track := pk_p1_utils.get_last_triage_status(i_ext_req);
        
            g_error                         := 'UPDATE STATUS / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := i_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_reason_code      := i_reason_code;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_i,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF i_status = pk_ref_constant.g_p1_status_t
            THEN
            
                -- JB 2009-05-21 ALERT-29134
                l_rowids := NULL;
                g_error  := 'Call ts_p1_external_request.upd / ' || l_params || ' FLG_FORWARD_DCS=' ||
                            pk_ref_constant.g_no;
                ts_p1_external_request.upd(id_external_request_in => i_ext_req,
                                           flg_forward_dcs_in     => pk_ref_constant.g_no,
                                           rows_out               => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'P1_EXTERNAL_REQUEST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
            IF i_notes IS NOT NULL
            THEN
            
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_ntri || ' / ' || l_params;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_ext_req,
                     i_notes,
                     g_sysdate_tstz,
                     l_det_type,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_active);
            
            END IF;
        
            -- JS, 2007-DEZ-20: Se ja esteve em triagem e foi reencaminhado deve ficar reencaminhado        
        
            IF i_status = pk_ref_constant.g_p1_status_t -- ALERT-119127 
               AND l_last_triage_track.ext_req_status = pk_ref_constant.g_p1_status_r
            THEN
                -- get id_dep_clin_serv when referral was forwarded
                g_error := 'SELECT id_dep_clin_serv / ' || l_params;
                BEGIN
                    SELECT id_dep_clin_serv
                      INTO l_id_dep_clin_serv
                      FROM (SELECT id_dep_clin_serv
                              FROM p1_tracking t
                             WHERE t.id_external_request = l_last_triage_track.id_external_request
                               AND t.dt_tracking_tstz < l_last_triage_track.dt_tracking_tstz
                               AND t.id_dep_clin_serv IS NOT NULL
                             ORDER BY t.dt_tracking_tstz DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_dep_clin_serv := NULL;
                END;
            
                g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params || ' l_id_dep_clin_serv=' ||
                            l_id_dep_clin_serv;
                g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                                     i_id_ref        => i_ext_req,
                                                                     o_dep_clin_serv => l_curr_dcs,
                                                                     o_error         => o_error);
            
                IF l_id_dep_clin_serv = nvl(i_dcs, l_curr_dcs)
                THEN
                
                    g_error                         := 'Fill l_track_row to UPDATE STATUS R / ' || l_params ||
                                                       ' l_id_dep_clin_serv=' || l_id_dep_clin_serv || ' l_curr_dcs=' ||
                                                       l_curr_dcs;
                    l_track_row.id_external_request := i_ext_req;
                    l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_r;
                    l_track_row.flg_type            := pk_ref_constant.g_tracking_type_p;
                    l_track_row.id_prof_dest        := l_last_triage_track.id_prof_dest;
                    l_track_row.dt_tracking_tstz    := g_sysdate_tstz + INTERVAL '1' SECOND;
                    l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_r);
                
                    g_error  := 'Call pk_p1_core.update_status / ' || l_params || ' l_id_dep_clin_serv=' ||
                                l_id_dep_clin_serv || ' l_curr_dcs=' || l_curr_dcs;
                    g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_track_row   => l_track_row,
                                                         i_old_status  => pk_ref_constant.g_p1_status_t,
                                                         i_flg_isencao => NULL,
                                                         i_mcdt_nature => NULL,
                                                         o_track       => l_track_tab,
                                                         o_error       => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    o_track := o_track MULTISET UNION l_track_tab;
                
                END IF;
            END IF;
        
        END IF;
    
        -- getting speciality after changing status
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_speciality != l_id_spec_inital
        THEN
            -- referral speciality has been changed, notify inter-alert
            g_error := 'Call pk_api_ref_event.set_ref_update / ' || l_params || ' ID_SPEC_FINAL=' ||
                       l_ref_row.id_speciality;
            pk_api_ref_event.set_ref_update(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_ref     => l_ref_row.id_external_request,
                                            i_flg_status => l_ref_row.flg_status, -- actual flg_status
                                            i_id_inst    => i_prof.institution);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_STATUS_INTERNAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_status_internal;

    /**
    * Checks if theres a process in the institution that matches the patient
    *
    * ATENTION: This function is used only for simulation purposes.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient id professional, institution and software ids
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_SNS National Health System number
    * @param   I_NAME patient name
    * @param   I_GENDER patient gender (M, F or I)
    * @param   I_DT_BIRTH patient date of birth                
    * @param   O_DATA_OUT patient data to be returned    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 3.0
    * @since   30-10-2007
    */
    FUNCTION get_match
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_sns      IN VARCHAR2,
        i_name     IN VARCHAR2,
        i_gender   IN VARCHAR2,
        i_dt_birth IN VARCHAR2,
        o_data_out OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_match / ID_PATIENT=' || i_pat || ' SNS=' || i_sns || ' NAME=' || i_name || ' GENDER=' ||
                   i_gender || ' DT_BIRTH=' || i_dt_birth;
        RETURN pk_ref_dest_reg.get_match(i_lang     => i_lang,
                                         i_prof     => i_prof,
                                         i_pat      => i_pat,
                                         i_sns      => i_sns,
                                         i_name     => i_name,
                                         i_gender   => i_gender,
                                         i_dt_birth => i_dt_birth,
                                         o_data_out => o_data_out,
                                         o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_MATCH',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data_out);
            RETURN FALSE;
    END get_match;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match_internal
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_match p1_match.id_match%TYPE;
    BEGIN
        g_error := 'Init set_match_internal / ID_PAT=' || i_pat || ' SEQ_NUM=' || i_seq_num || ' CLIN_REC=' ||
                   i_clin_rec || ' ID_EPISODE=' || i_epis;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Call pk_ref_dest_reg.set_match / ID_PAT=' || i_pat || ' SEQ_NUM=' || i_seq_num || ' CLIN_REC=' ||
                   i_clin_rec || ' ID_EPIS=' || i_epis;
        RETURN pk_ref_dest_reg.set_match(i_lang     => i_lang,
                                         i_prof     => i_prof,
                                         i_pat      => i_pat,
                                         i_seq_num  => i_seq_num,
                                         i_clin_rec => i_clin_rec,
                                         i_epis     => i_epis,
                                         o_id_match => l_id_match,
                                         o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH_INTERNAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_match_internal;

    /**
    * Sets the connection between the patient id and the hospital process.
    * Calls set_match internal and commits.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Call set_match_internal / i_seq_num=' || i_seq_num || ' i_clin_rec=' || i_clin_rec || ' i_epis=' ||
                   i_epis;
        IF NOT set_match_internal(i_lang     => i_lang,
                                  i_pat      => i_pat,
                                  i_prof     => i_prof,
                                  i_seq_num  => i_seq_num,
                                  i_clin_rec => i_clin_rec,
                                  i_epis     => i_epis,
                                  o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH_INTERNAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match;

    /**
    * Cancels match
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_pat patient id 
    * @param   i_prof professional id, institution and software
    * @param   i_id not in use
    * @param   i_id_ext_sys not in use    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION drop_match
    (
        i_lang       IN language.id_language%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_id         IN patient.id_patient%TYPE,
        i_id_ext_sys IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'Call pk_ref_dest_reg.drop_match / i_pat=' || i_pat || ' i_id=' || i_id || ' i_id_ext_sys=' ||
                    i_id_ext_sys;
        g_retval := pk_ref_dest_reg.drop_match(i_lang       => i_lang,
                                               i_pat        => i_pat,
                                               i_prof       => i_prof,
                                               i_id         => i_id,
                                               i_id_ext_sys => i_id_ext_sys,
                                               o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'DROP_MATCH',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END drop_match;

    /**
    * Get available genders list.
    * The difference from pk_list.get_gender_list is that it return the "Unknown" option which
    * is used by the match screen.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-10-2007
    */
    FUNCTION get_gender_list
    (
        i_lang   IN language.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_p1_adm_hs_t029 VARCHAR2(1000 CHAR);
    BEGIN
        l_p1_adm_hs_t029 := pk_message.get_message(i_lang, 'P1_ADM_HS_T029');
    
        g_error := 'GET CURSOR';
        OPEN o_gender FOR
            SELECT val, desc_val, rank
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = pk_ref_constant.g_domain_gender
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = pk_ref_constant.g_yes
            UNION ALL
            SELECT NULL val, l_p1_adm_hs_t029 desc_val, 99 rank
              FROM dual
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GENDER_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_gender);
            RETURN FALSE;
    END get_gender_list;

    /**
    * Gets number of available dcs for the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_count number of available dcs    
    * @param   o_id dcs id, when there's only one.
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Call get_clin_serv_forward_count / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call pk_p1_core.get_clin_serv_forward_count / ID_REF=' || l_exr_row.id_external_request ||
                   ' ID_DCS=' || l_exr_row.id_dep_clin_serv;
        IF NOT pk_p1_core.get_clin_serv_forward_count(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_exr_row => l_exr_row,
                                                      o_count   => o_count,
                                                      o_id      => o_id,
                                                      o_error   => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_COUNT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_clin_serv_forward_count;

    /**
    * Gets departments available for forwarding the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_dep department ids and description    
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_dep_forward_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_rec IN p1_external_request.id_external_request%TYPE,
        o_dep     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error  := 'Call pk_ref_dest_reg.get_dep_forward_list / ID_REF=' || i_ext_rec;
        g_retval := pk_ref_dest_reg.get_dep_forward_list(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_ext_req => i_ext_rec,
                                                         o_dep     => o_dep,
                                                         o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
    END get_dep_forward_list;

    /**
    * Gets clinical_services (the ids are dep_clin_serv) available for forwarding the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   i_dep department id    
    * @param   o_clin_serv dep_clin_serv ids and clinical services description    
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_rec   IN p1_external_request.id_external_request%TYPE,
        i_dep       IN department.id_department%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'Call pk_ref_dest_reg.get_clin_serv_forward_list / ID_REF=' || i_ext_rec || ' ID_DEP=' || i_dep;
        g_retval := pk_ref_dest_reg.get_clin_serv_forward_list(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_ext_req   => i_ext_rec,
                                                               i_dep       => i_dep,
                                                               o_clin_serv => o_clin_serv,
                                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_clin_serv);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_COUNT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_clin_serv);
            RETURN FALSE;
        
    END get_clin_serv_forward_list;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_adm_hs;
/
