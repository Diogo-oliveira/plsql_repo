/*-- Last Change Revision: $Rev: 2027441 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_med_hs AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_retval BOOLEAN;
    g_exception EXCEPTION;
    g_exception_np EXCEPTION;
    g_error        VARCHAR2(1000 CHAR);
    g_sysdate_tstz TIMESTAMP
        WITH TIME ZONE;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    /**
    * Get available options for triage
    * Since version 1.1 (10-04-2007) allows changing status for requests with status (A)ccepted
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EXT_REQ request id. Only for updates.
    * @param   I_EXT_FLG_STATUS referral status
    * @param   I_DT_MODIFIED last modified date as provided by get_p1_detail
    * @param   O_STATUS available status (descriptions and values)
    *
    * @param   O_FLG_SHOW {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE message title
    * @param   O_MSG message text
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 1.1
    * @since   19-09-2006   
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_req     IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_p1 IS
            SELECT id_external_request,
                   dt_last_interaction_tstz,
                   flg_status,
                   id_dep_clin_serv,
                   id_inst_dest,
                   id_inst_orig,
                   id_speciality,
                   id_prof_redirected,
                   id_prof_schedule,
                   id_prof_triage,
                   id_external_sys,
                   id_workflow,
                   id_patient
              FROM referral_ea
             WHERE id_external_request = i_ext_req;
        l_exr_row c_p1%ROWTYPE;
    
        l_config VARCHAR2(1 CHAR);
        l_gender patient.gender%TYPE;
        l_age    patient.age%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------     
        g_error := 'Init get_status_options / ID_REF=' || i_ext_req || ' DT_MODIFIED=' || i_dt_modified;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------     
        g_error  := 'Call pk_ref_status.check_config_enabled / ID_REF=' || i_ext_req || ' CONFIG=' ||
                    pk_ref_constant.g_ref_decline_reg_enabled;
        l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_config => pk_ref_constant.g_ref_decline_reg_enabled);
    
        ----------------------
        -- FUNC
        ----------------------     
        OPEN c_p1;
        FETCH c_p1
            INTO l_exr_row;
        CLOSE c_p1;
    
        g_error  := 'Call pk_ref_core.get_pat_age_gender / ID_REF=' || i_ext_req || ' ID_PAT=' || l_exr_row.id_patient;
        g_retval := pk_ref_core.get_pat_age_gender(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => l_exr_row.id_patient,
                                                   o_gender  => l_gender,
                                                   o_age     => l_age,
                                                   o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error    := 'Validate dt_last_interaction_tstz / ID_REF=' || l_exr_row.id_external_request ||
                      ' ID_DEP_CLIN_SERV=' || l_exr_row.id_dep_clin_serv || ' FLG_STATUS=' || l_exr_row.flg_status;
        o_flg_show := pk_ref_constant.g_no;
        IF pk_date_utils.trunc_insttimezone(i_prof, l_exr_row.dt_last_interaction_tstz, 'SS') >
           pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_t008);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_t007);
            o_button    := pk_ref_constant.g_button_read;
            pk_types.open_my_cursor(o_status);
            RETURN TRUE;
        END IF;
    
        g_error := 'OPEN o_status / ID_REF=' || l_exr_row.id_external_request || ' ID_DEP_CLIN_SERV=' ||
                   l_exr_row.id_dep_clin_serv || ' FLG_STATUS=' || l_exr_row.flg_status;
        OPEN o_status FOR
            SELECT NULL                 id_workflow,
                   l_exr_row.flg_status status_begin,
                   data                 status_end,
                   icon,
                   label,
                   NULL                 rank,
                   data                 action
              FROM (SELECT label, data, icon
                      FROM (
                            -- specialty triage physician of this referral
                            SELECT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                              FROM p1_external_request exr, sys_domain sd
                             WHERE exr.id_external_request = l_exr_row.id_external_request
                               AND pk_ref_dest_phy.validate_dcs_func(i_prof,
                                                                     l_exr_row.id_dep_clin_serv,
                                                                     pk_ref_constant.g_func_d) = pk_ref_constant.g_yes
                               AND sd.code_domain = 'P1_STATUS_OPTIONS.MED_HS'
							   and sd.domain_owner = pk_sysdomain.k_default_schema
							   and sd.domain_owner = pk_sysdomain.k_default_schema
                               AND sd.id_language = i_lang
                               AND (
                                   -- T, R, A
                                    (l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_t,
                                                              pk_ref_constant.g_p1_status_r,
                                                              pk_ref_constant.g_p1_status_a) AND
                                    (sd.val IN (pk_ref_constant.g_ref_action_a,
                                                 pk_ref_constant.g_ref_action_r,
                                                 pk_ref_constant.g_ref_action_cs,
                                                 pk_ref_constant.g_ref_action_x) OR
                                    (sd.val = pk_ref_constant.g_ref_action_d AND
                                    nvl(exr.flg_import, pk_ref_constant.g_no) = pk_ref_constant.g_no) OR
                                    -- Decline to the registrar (configuration must be enabled)
                                    (l_config = pk_ref_constant.g_yes AND sd.val = pk_ref_constant.g_ref_action_dcl_r)))
                                   -- D
                                    OR (l_exr_row.flg_status = pk_ref_constant.g_p1_status_d AND
                                    sd.val = pk_ref_constant.g_ref_action_x)
                                   -- E
                                    OR
                                    (l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_e, pk_ref_constant.g_p1_status_w) AND
                                    sd.val = pk_ref_constant.g_ref_action_w))
                            
                            UNION
                            -- triage physician of this referral
                            SELECT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                              FROM p1_external_request exr, sys_domain sd
                             WHERE exr.id_external_request = l_exr_row.id_external_request
                               AND l_exr_row.id_prof_triage = i_prof.id
                               AND pk_ref_dest_phy.validate_dcs_func(i_prof,
                                                                     l_exr_row.id_dep_clin_serv,
                                                                     pk_ref_constant.g_func_t) = pk_ref_constant.g_yes
                               AND sd.code_domain = 'P1_STATUS_OPTIONS.MED_HS'
							   and sd.domain_owner = pk_sysdomain.k_default_schema
							   and sd.domain_owner = pk_sysdomain.k_default_schema
                               AND sd.id_language = i_lang
                               AND ((l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_t,
                                                              pk_ref_constant.g_p1_status_r,
                                                              pk_ref_constant.g_p1_status_a) AND
                                   (sd.val IN (pk_ref_constant.g_ref_action_a, pk_ref_constant.g_ref_action_x) OR
                                   (sd.val = pk_ref_constant.g_ref_action_d AND
                                   nvl(exr.flg_import, pk_ref_constant.g_no) = pk_ref_constant.g_no))) OR
                                   (l_exr_row.flg_status = pk_ref_constant.g_p1_status_d AND
                                   sd.val = pk_ref_constant.g_ref_action_x) OR
                                   (l_exr_row.flg_status IN
                                   (pk_ref_constant.g_p1_status_e, pk_ref_constant.g_p1_status_w) AND
                                   sd.val = pk_ref_constant.g_ref_action_w))
                            UNION
                            -- Referral scheduled physician
                            SELECT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                              FROM sys_domain sd
                             WHERE l_exr_row.id_prof_schedule = i_prof.id
                               AND pk_ref_dest_phy.validate_dcs_func(i_prof,
                                                                     l_exr_row.id_dep_clin_serv,
                                                                     table_number(pk_ref_constant.g_func_d,
                                                                                  pk_ref_constant.g_func_t,
                                                                                  pk_ref_constant.g_func_c)) =
                                   pk_ref_constant.g_yes
                               AND sd.code_domain = 'P1_STATUS_OPTIONS.MED_HS'
							   and sd.domain_owner = pk_sysdomain.k_default_schema
                               AND sd.id_language = i_lang
                               AND l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_e, pk_ref_constant.g_p1_status_w)
                               AND sd.val = pk_ref_constant.g_ref_action_w
                            UNION ALL
                            -- Pedido marcado para a especialidade e é médico do tipo de consulta agendado                    
                            SELECT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                              FROM sys_domain sd
                             WHERE l_exr_row.id_prof_schedule IS NULL
                               AND pk_ref_dest_phy.validate_dcs_func(i_prof,
                                                                     l_exr_row.id_dep_clin_serv,
                                                                     pk_ref_constant.g_func_c) = pk_ref_constant.g_yes
                               AND sd.code_domain = 'P1_STATUS_OPTIONS.MED_HS'
							   and sd.domain_owner = pk_sysdomain.k_default_schema
                               AND sd.id_language = i_lang
                               AND l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_e, pk_ref_constant.g_p1_status_w)
                               AND sd.val = pk_ref_constant.g_ref_action_w
                            UNION ALL
                            -- É Triador de especialidade do pedido e existe instituicao no centro hospitalar que 
                            SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
                              FROM sys_domain sd
                             WHERE EXISTS
                             (SELECT 1 -- institutions available to forward the referral
                                      FROM TABLE(CAST(pk_ref_dest_phy.get_inst_dcs_forward_p(i_lang         => i_lang,
                                                                                             i_prof         => i_prof,
                                                                                             i_id_spec      => l_exr_row.id_speciality,
                                                                                             i_id_workflow  => l_exr_row.id_workflow,
                                                                                             i_id_inst_orig => l_exr_row.id_inst_orig,
                                                                                             i_id_inst_dest => l_exr_row.id_inst_dest,
                                                                                             i_pat_gender   => l_gender,
                                                                                             i_pat_age      => l_age,
                                                                                             i_external_sys => l_exr_row.id_external_sys) AS
                                                      t_coll_ref_inst_dcs_fwd)))
                               AND i_prof.institution = l_exr_row.id_inst_dest
                               AND l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_t,
                                                            pk_ref_constant.g_p1_status_r,
                                                            pk_ref_constant.g_p1_status_a)
                               AND pk_ref_dest_phy.validate_dcs_func(i_prof,
                                                                     l_exr_row.id_dep_clin_serv,
                                                                     pk_ref_constant.g_func_d) = pk_ref_constant.g_yes
                               AND sd.code_domain = 'P1_STATUS_OPTIONS.MED_HS'
							   and sd.domain_owner = pk_sysdomain.k_default_schema
                               AND sd.id_language = i_lang
                               AND sd.val = pk_ref_constant.g_ref_action_di
                             ORDER BY rank));
    
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_status_options;

    /**
    * Changes referral status
    * Checks for changes using dt_last_interaction
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_id_p1           Referral identifier
    * @param   i_action          Triage decision: to schedule, Refuse, Decline, Forward, etc
    * @param   i_dep_clin_serv   Service id, used when changing clinical service
    * @param   i_notes           Decision notes
    * @param   i_dt_modified     Last modified date as provided by get_p1_detail
    * @param   i_mode            (V)alidate date modified or do(N)t
    * @param   i_reason_code     Refusing code (used by the interface)
    * @param   i_subtype         Flag used to mark refusals made by the interface
    * @param   i_inst_dest       New institution identifier, used when changing institution    
    * @param   i_date            Date of status change           
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   19-09-2006
    */
    FUNCTION set_status_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_p1         IN p1_external_request.id_external_request%TYPE,
        i_action        IN VARCHAR2,
        i_level         IN p1_external_request.decision_urg_level%TYPE,
        i_prof_dest     IN professional.id_professional%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes         IN VARCHAR2,
        i_dt_modified   IN VARCHAR2,
        i_mode          IN VARCHAR2,
        i_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_subtype       IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE,
        i_date          IN p1_tracking.dt_tracking_tstz%TYPE,
        o_track         OUT table_number,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_old_status VARCHAR2(30 CHAR);
    
        l_dt_last_interaction p1_external_request.dt_last_interaction_tstz%TYPE;
        l_exr_present_status  p1_external_request.flg_status%TYPE;
        l_id_spec_initial     p1_external_request.id_speciality%TYPE;
    
        l_track_row  p1_tracking%ROWTYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_config     VARCHAR2(1 CHAR);
        l_track_tab  table_number;
    
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_p1=' || i_id_p1 || ' i_action=' || i_action ||
                    ' i_level=' || i_level || ' i_prof_dest=' || i_prof_dest || ' i_dep_clin_serv=' || i_dep_clin_serv ||
                    ' i_dt_modified=' || i_dt_modified || ' i_mode=' || i_mode || ' i_reason_code=' || i_reason_code ||
                    ' i_subtype=' || i_subtype || ' i_inst_dest=' || i_inst_dest;
        g_error  := 'Init set_status_internal / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        l_track_row.id_external_request := i_id_p1;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_p1,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_exr_present_status  := l_ref_row.flg_status;
        l_dt_last_interaction := l_ref_row.dt_last_interaction_tstz;
        l_id_spec_initial     := l_ref_row.id_speciality;
    
        -- check if referral was changed while editing
        g_error    := 'validate changes / ' || l_params;
        o_flg_show := pk_ref_constant.g_no;
        IF i_mode = pk_ref_constant.g_validate_changes
        THEN
        
            IF pk_date_utils.trunc_insttimezone(i_prof, l_dt_last_interaction, 'SS') >
               pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
            THEN
                o_flg_show  := pk_ref_constant.g_yes;
                o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => pk_ref_constant.g_sm_doctor_hs_t023);
                o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => pk_ref_constant.g_sm_doctor_hs_t024);
                RETURN TRUE;
            END IF;
        END IF;
    
        g_error := 'Fill l_detail_row / ' || l_params;
        IF i_notes IS NOT NULL
        THEN
            l_detail_row.id_external_request := i_id_p1;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := i_prof.id;
            l_detail_row.id_institution      := i_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate_tstz;
        END IF;
    
        g_error := 'IF action / ' || l_params;
        IF (i_action = pk_ref_constant.g_ref_action_a) -- ACCEPTED
        THEN
        
            IF (i_level IS NULL)
            THEN
                RAISE g_exception;
            END IF;
        
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            l_track_row.ext_req_status     := pk_ref_constant.g_p1_status_a;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_dep_clin_serv   := i_dep_clin_serv;
        
            IF l_exr_present_status = pk_ref_constant.g_p1_status_a
            THEN
                l_track_row.flg_subtype := pk_ref_constant.g_tracking_subtype_r; -- re-schedule
            END IF;
        
            l_track_row.id_prof_dest       := i_prof_dest;
            l_track_row.decision_urg_level := i_level;
        
            l_old_status := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                            pk_ref_constant.g_p1_status_a;
        
        ELSIF (i_action = pk_ref_constant.g_ref_action_cs) -- CHANGE_CS
        THEN
        
            IF (i_dep_clin_serv IS NULL)
            THEN
                RAISE g_exception;
            END IF;
        
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            l_track_row.ext_req_status     := pk_ref_constant.g_p1_status_t;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_c;
            l_track_row.id_dep_clin_serv   := i_dep_clin_serv;
            l_track_row.id_prof_dest       := 0; -- changes clinical service so removes the previous triage physician        
            l_old_status                   := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                                              pk_ref_constant.g_p1_status_a;
        
        ELSIF (i_action = pk_ref_constant.g_ref_action_d) -- DECLINE
        THEN
        
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            l_track_row.ext_req_status     := pk_ref_constant.g_p1_status_d;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_prof_dest       := i_prof.id;
            l_track_row.id_reason_code     := i_reason_code;
        
            IF l_exr_present_status = pk_ref_constant.g_p1_status_a
            THEN
                l_track_row.flg_subtype := pk_ref_constant.g_tracking_subtype_r; -- js, 2007-11-22: Marcar devolucoes de pedidos ja aceites 
            END IF;
            l_old_status := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                            pk_ref_constant.g_p1_status_a;
        
        ELSIF (i_action = pk_ref_constant.g_ref_action_dcl_r) -- DECLINE_TO_REG
        THEN
        
            g_error  := 'Call pk_ref_status.check_config_enabled / CONFIG=' ||
                        pk_ref_constant.g_ref_decline_reg_enabled || ' / ' || l_params;
            l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_config => pk_ref_constant.g_ref_decline_reg_enabled);
        
            IF l_config = pk_ref_constant.g_no
            THEN
                g_error      := 'Cannot decline referral to the registrar: this funcionality is not available / CONFIG=' ||
                                pk_ref_constant.g_ref_decline_reg_enabled || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            g_error                        := 'DECLINE_TO_REG / ' || l_params;
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            l_track_row.ext_req_status     := pk_ref_constant.g_p1_status_i;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_reason_code     := i_reason_code;
        
            l_old_status := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                            pk_ref_constant.g_p1_status_a;
        
            l_detail_row.flg_type := pk_ref_constant.g_detail_type_dcl_r;
        
        ELSIF (i_action = pk_ref_constant.g_ref_action_x) -- REFUSE
        THEN
        
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            l_track_row.ext_req_status     := pk_ref_constant.g_p1_status_x;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_prof_dest       := i_prof.id;
            l_track_row.id_reason_code     := i_reason_code;
        
            IF l_exr_present_status = pk_ref_constant.g_p1_status_a
            THEN
                l_track_row.flg_subtype := pk_ref_constant.g_tracking_subtype_r; -- js, 2007-11-22: Marcar recusa de pedidos ja aceites
            END IF;
        
            -- js, 2007-11-22: pode recusar pedidos devolvido e aceites.
            l_old_status := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                            pk_ref_constant.g_p1_status_a || pk_ref_constant.g_p1_status_d;
        
        ELSIF (i_action = pk_ref_constant.g_ref_action_r) -- FORWARD
        THEN
        
            g_error := 'UPDATE TRIAGE / ' || l_params;
            IF (i_prof_dest IS NULL)
            THEN
                RAISE g_exception;
            END IF;
        
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            l_track_row.ext_req_status     := pk_ref_constant.g_p1_status_r;
            l_track_row.flg_type           := pk_ref_constant.g_tracking_type_p;
            l_track_row.id_prof_dest       := i_prof_dest;
        
            l_old_status := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                            pk_ref_constant.g_p1_status_a;
        
        ELSIF (i_action = pk_ref_constant.g_ref_action_di) -- CHANGE_INST
        THEN
        
            g_error := 'CHANGE INSTITUTION / ' || l_params;
            IF (i_inst_dest IS NULL)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error  := 'Call pk_p1_core.set_dest_institution_int / ' || l_params;
            g_retval := pk_p1_core.set_dest_institution_int(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_ext_req   => i_id_p1,
                                                            i_inst_dest => i_inst_dest,
                                                            i_dcs_dest  => i_dep_clin_serv,
                                                            i_date      => g_sysdate_tstz,
                                                            o_track     => l_track_tab,
                                                            o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            ELSE
            
                o_track := o_track MULTISET UNION l_track_tab;
            
                -- JB 2009-05-22 ALERT-29134
                UPDATE p1_external_request
                   SET flg_forward_dcs = pk_ref_constant.g_yes
                 WHERE id_external_request = i_id_p1;
            
                IF l_detail_row.text IS NOT NULL
                THEN
                    g_error                  := 'Call pk_ref_api.set_p1_detail / ' || l_params;
                    l_detail_row.id_tracking := o_track(1); -- first iteration
                
                    g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_p1_detail => l_detail_row,
                                                         o_id_detail => l_id_detail,
                                                         o_error     => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
                RETURN TRUE;
            
            END IF;
        
        ELSE
            g_error := 'INVALID OPTION / ' || l_params;
            RAISE g_exception;
        END IF;
    
        g_error := 'l_exr_present_status=' || l_exr_present_status || ' / ' || l_params;
        IF l_exr_present_status = pk_ref_constant.g_p1_status_a
           AND i_action = pk_ref_constant.g_ref_action_a
        THEN
            -- re-schedule
            l_track_row.flg_subtype := pk_ref_constant.g_tracking_subtype_r;
        ELSE
            -- i_subtype not null: recusa recebida por interface
            -- js, 2007-11-22: se l_track_subtype nao nulo entao e':
            --    1. recusa por interface 
            --    2. remarcacao
            --    3. recusa ou devolucao de pedido ja aceite.
            l_track_row.flg_subtype := i_subtype;
        END IF;
    
        l_track_row.dt_tracking_tstz := g_sysdate_tstz;
    
        g_error  := 'Call pk_p1_core.update_status / ' || l_params;
        g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_track_row   => l_track_row,
                                             i_old_status  => l_old_status,
                                             i_flg_isencao => NULL,
                                             i_mcdt_nature => NULL,
                                             o_track       => l_track_tab,
                                             o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_track := o_track MULTISET UNION l_track_tab;
    
        IF l_detail_row.text IS NOT NULL
        THEN
            g_error                  := 'Call pk_ref_api.set_p1_detail / ' || l_params;
            l_detail_row.id_tracking := o_track(1); -- first iteration
        
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- getting speciality after changing status
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_p1,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_speciality != l_id_spec_initial
        THEN
            -- referral speciality has been changed, notify inter-alert
            g_error := 'Call pk_api_ref_event.set_ref_update / ID_SPEC_INITIAL=' || l_id_spec_initial ||
                       ' ID_SPEC_FINAL=' || l_ref_row.id_speciality || ' / ' || l_params;
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
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_STATUS_INTERNAL',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_status_internal;

    /**
    * Insert consultation doctor (NO COMMIT)
    *
    * @param   i_lang             Language identifier
    * @param   i_prof             Professional, institution and software
    * @param   i_exr              Referral identifier
    * @param   i_diagnosis        Selected diagnosis
    * @param   i_diag_desc        Diagnosis description, when entered in text mode
    * @param   i_answer           Observation, Therapy, Exam and Conclusion
    * @param   i_date             Operation date
    * @param   i_health_prob      Select Health Problem --NX
    * @param   i_health_prob_desc Health Problem description, when entered in text mode --NX
    
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION set_request_answer_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exr              IN p1_external_request.id_external_request%TYPE,
        i_diagnosis        IN table_number,
        i_diag_desc        IN table_varchar,
        i_answer           IN table_table_varchar,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_detail_type p1_detail.flg_type%TYPE;
        l_count       PLS_INTEGER;
        l_track_row   p1_tracking%ROWTYPE;
        o_track       table_number;
    BEGIN
        g_error        := '->Init set_request_answer_int / ID_REF=' || i_exr;
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        l_count := 0;
    
        g_error                         := 'UPDATE STATUS W / ID_REF=' || i_exr;
        l_track_row.id_external_request := i_exr;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_w;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_w);
    
        g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                    l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
        g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_track_row   => l_track_row,
                                             i_old_status  => pk_ref_constant.g_p1_status_e ||
                                                              pk_ref_constant.g_p1_status_w,
                                             i_flg_isencao => NULL,
                                             i_mcdt_nature => NULL,
                                             o_track       => o_track,
                                             o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'UPDATE p1_exr_diagnosis / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                   l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE flg_type IN (pk_ref_constant.g_exr_diag_type_a, pk_ref_constant.g_exr_diag_type_r)
           AND id_external_request = i_exr
           AND id_professional = i_prof.id;
    
        g_error := 'INSERT DIAGNOSIS / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                   l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type || ' i_diagnosis.count=' ||
                   i_diagnosis.count;
        FOR i IN 1 .. i_diagnosis.count
        LOOP
            l_count := l_count + 1;
        
            INSERT INTO p1_exr_diagnosis
                (id_exr_diagnosis,
                 id_external_request,
                 id_diagnosis,
                 dt_insert_tstz,
                 id_professional,
                 id_institution,
                 flg_type,
                 flg_status,
                 desc_diagnosis)
            VALUES
                (seq_p1_exr_diagnosis.nextval,
                 i_exr,
                 i_diagnosis(i),
                 g_sysdate_tstz,
                 i_prof.id,
                 i_prof.institution,
                 pk_ref_constant.g_exr_diag_type_a,
                 pk_ref_constant.g_active,
                 i_diag_desc(i));
        
        END LOOP;
    
        IF i_health_prob IS NOT NULL
        THEN
            g_error := 'INSERT DIAGNOSIS / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                       l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
        
            FOR i IN 1 .. i_health_prob.count
            LOOP
                l_count := l_count + 1;
            
                INSERT INTO p1_exr_diagnosis
                    (id_exr_diagnosis,
                     id_external_request,
                     id_diagnosis,
                     dt_insert_tstz,
                     id_professional,
                     id_institution,
                     flg_type,
                     flg_status,
                     desc_diagnosis)
                VALUES
                    (seq_p1_exr_diagnosis.nextval,
                     i_exr,
                     i_health_prob(i),
                     g_sysdate_tstz,
                     i_prof.id,
                     i_prof.institution,
                     pk_ref_constant.g_exr_diag_type_r,
                     pk_ref_constant.g_active,
                     i_health_prob_desc(i));
            END LOOP;
        END IF;
    
        g_error := 'UPDATE p1_detail / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                   l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
        UPDATE p1_detail
           SET flg_status = pk_ref_constant.g_detail_status_o
         WHERE id_external_request = i_exr
           AND flg_status = pk_ref_constant.g_detail_status_a
           AND flg_type IN (pk_ref_constant.g_detail_type_a_obs,
                            pk_ref_constant.g_detail_type_a_ter,
                            pk_ref_constant.g_detail_type_a_exa,
                            pk_ref_constant.g_detail_type_a_con,
                            pk_ref_constant.g_detail_type_answ_evol,
                            pk_ref_constant.g_detail_type_dt_come_back)
           AND id_professional = i_prof.id;
    
        FOR i IN 1 .. i_answer.count
        LOOP
        
            CASE i_answer(i) (1)
                WHEN pk_ref_constant.g_ref_answer_o THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_obs;
                WHEN pk_ref_constant.g_ref_answer_t THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_ter;
                WHEN pk_ref_constant.g_ref_answer_e THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_exa;
                WHEN pk_ref_constant.g_ref_answer_c THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_con;
                WHEN pk_ref_constant.g_ref_answer_ev THEN
                    --MX
                    l_detail_type := pk_ref_constant.g_detail_type_answ_evol;
                WHEN pk_ref_constant.g_ref_answer_dt_cb THEN
                    --MX
                    l_detail_type := pk_ref_constant.g_detail_type_dt_come_back;
                ELSE
                    l_detail_type := -1;
            END CASE;
        
            g_error := 'INSERT DETAIL / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                       l_track_row.ext_req_status || ' FLG_TYPE=' || l_detail_type || ' ID_TRACKING=' || o_track(1);
            IF i_answer(i) (2) IS NOT NULL
            THEN
                l_count := l_count + 1;
            
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
                     i_exr,
                     i_answer(i) (2),
                     g_sysdate_tstz,
                     l_detail_type,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_detail_status_a);
            END IF;
        
        END LOOP;
    
        -- Se l_count vazio não houve nenhum insert
        IF l_count > 0
        THEN
            NULL; -- ALERT-44578
        ELSE
            pk_utils.undo_changes;
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
                                              i_function => 'SET_REQUEST_ANSWER_INT',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_request_answer_int;

BEGIN

    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_med_hs;
/
