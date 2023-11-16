/*-- Last Change Revision: $Rev: 1990372 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-05-26 17:42:47 +0100 (qua, 26 mai 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_list IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    /**
    * Gets referral detail
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Professional data
    * @param   i_ref_row        Referral data
    * @param   i_view_clin_data Flag indicating if professional can view clinical data
    * @param   o_mcdt           MCDTs information   
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_view_clin_data {*} Y- can view clinical data {*} N- otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_view_clin_data IN VARCHAR2,
        o_detail         OUT pk_ref_core.row_detail_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- wf
        l_status_info_row t_rec_wf_status_info := t_rec_wf_status_info();
        l_wf_param        table_varchar;
        l_flg_status_n    wf_status.id_status%TYPE;
        l_status_icon     VARCHAR2(500 CHAR);
        -- sys_messages
        l_code_msg_arr        table_varchar;
        l_desc_message_ibt    pk_ref_constant.ibt_varchar_varchar;
        l_sm_clinical_service sys_message.desc_message%TYPE; -- clinical service
        l_sm_speciality       sys_message.desc_message%TYPE; -- p1_speciality
        l_sm_sub_speciality   sys_message.desc_message%TYPE; -- sub-speciality (referral creation)
        -- config
        l_ref_adw_column       sys_config.desc_sys_config%TYPE;
        l_sc_other_institution sys_config.desc_sys_config%TYPE;
        -- adw
        l_wait_time       NUMBER;
        l_wait_days_label sys_message.desc_message%TYPE;
        l_wait_days       VARCHAR2(1000 CHAR);
        -- problem begin date
        l_dt_probl_begin_str   VARCHAR2(100 CHAR);
        l_dt_probl_begin_flash VARCHAR2(10 CHAR);
        l_comments_available   VARCHAR2(1 CHAR);
        l_flg_create_comment   VARCHAR2(1 CHAR);
        l_clues                institution_accounts.value%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        l_params             := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_ref_row.id_external_request;
        g_error              := 'Init get_referral_detail / ' || l_params;
        l_flg_create_comment := pk_ref_constant.g_no;
    
        ----------------------
        -- CONFIG
        ----------------------    
        g_error                := 'Call pk_sysconfig.get_config / ' || l_params || ' / SYS_CONFIG=' ||
                                  pk_ref_constant.g_sc_ref_adw_column;
        l_ref_adw_column       := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_adw_column, i_prof);
        l_sc_other_institution := pk_sysconfig.get_config(pk_ref_constant.g_sc_other_institution, i_prof);
    
        g_error               := 'Fill l_code_msg_arr / ' || l_params;
        l_sm_speciality       := pk_ref_constant.g_sm_p1_detail_t011; -- p1_speciality
        l_sm_sub_speciality   := pk_ref_constant.g_sm_ref_grid_t025; -- sub-speciality (refers to the clinical service)
        l_sm_clinical_service := pk_ref_constant.g_sm_ref_grid_t025; -- clinical service
    
        l_code_msg_arr := table_varchar(pk_ref_constant.g_ref_mark_req_t011,
                                        pk_ref_constant.g_sm_ref_grid_t009,
                                        pk_ref_constant.g_sm_doctor_cs_t119,
                                        pk_ref_constant.g_sm_doctor_req_t061,
                                        pk_ref_constant.g_sm_p1_detail_t035,
                                        pk_ref_constant.g_sm_doctor_req_t040,
                                        pk_ref_constant.g_sm_ref_devstatus_notes,
                                        pk_ref_constant.g_sm_ref_devstatus_reason,
                                        l_sm_sub_speciality,
                                        l_sm_speciality,
                                        l_sm_clinical_service,
                                        pk_ref_constant.g_sm_ref_waitingtime_t012,
                                        pk_ref_constant.g_sm_ref_waitingtime_t013,
                                        pk_ref_constant.g_sm_p1_info_t001,
                                        pk_ref_constant.g_sm_common_m20,
                                        pk_ref_constant.g_sm_ref_waitingtime_t014,
                                        pk_ref_constant.g_sm_ref_waitingtime_t015);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error              := 'Call pk_ref_core.check_comm_enabled / ' || l_params;
        l_comments_available := pk_ref_core.check_comm_enabled(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_id_inst_orig => i_ref_row.id_inst_orig,
                                                               i_id_inst_dest => i_ref_row.id_inst_dest);
    
        ----------------------
        -- FUNC
        ----------------------        
    
        g_error              := 'Call pk_ref_core.check_comm_create / ' || l_params;
        l_flg_create_comment := pk_ref_core.check_comm_create(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_id_cat             => i_prof_data.id_category,
                                                              i_id_workflow        => i_ref_row.id_workflow,
                                                              i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                              i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                              i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                              i_id_dcs             => i_ref_row.id_dep_clin_serv,
                                                              i_flg_comm_available => l_comments_available);
    
        -- l_wait_days_label
        IF l_ref_adw_column = pk_ref_constant.g_wait_time_avg_dd
        THEN
            l_wait_days_label := l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t015);
        ELSE
            l_wait_days_label := l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t014);
        END IF;
    
        g_error     := 'Calling pk_ref_waiting_time.get_waiting_time / ' || l_params || ' / REF_ADW_COLUMN=' ||
                       l_ref_adw_column || ' ID_INSTITUTION=' || i_ref_row.id_inst_dest || ' ID_SPECIALITY=' ||
                       i_ref_row.id_speciality;
        l_wait_time := pk_ref_waiting_time.get_waiting_time(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_ref_adw_column => l_ref_adw_column,
                                                            i_id_institution => i_ref_row.id_inst_dest,
                                                            i_id_speciality  => i_ref_row.id_speciality);
    
        -- l_wait_days
        IF l_wait_time IS NOT NULL
        THEN
            l_wait_days := l_wait_time || ' ' || l_desc_message_ibt(pk_ref_constant.g_sm_common_m20);
        END IF;
    
        -- getting status info        
        g_error    := 'Calling pk_ref_core.init_param_tab / ' || l_params;
        l_wf_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_ext_req            => i_ref_row.id_external_request,
                                                 i_id_patient         => i_ref_row.id_patient,
                                                 i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                 i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                 i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                                 i_id_speciality      => i_ref_row.id_speciality,
                                                 i_flg_type           => i_ref_row.flg_type,
                                                 i_decision_urg_level => i_ref_row.decision_urg_level,
                                                 i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                 i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                                 i_id_prof_status     => i_ref_row.id_prof_status,
                                                 i_external_sys       => i_ref_row.id_external_sys,
                                                 i_location           => pk_ref_constant.g_location_detail,
                                                 i_flg_status         => i_ref_row.flg_status);
    
        g_error        := 'Calling pk_ref_status.convert_status_n / ' || l_params || ' / FLG_STATUS=' ||
                          i_ref_row.flg_status;
        l_flg_status_n := pk_ref_status.convert_status_n(i_ref_row.flg_status);
    
        g_error  := 'Calling pk_workflow.get_status_info / ' || l_params;
        g_retval := pk_workflow.get_status_info(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                             pk_ref_constant.g_wf_pcc_hosp),
                                                i_id_status           => l_flg_status_n,
                                                i_id_category         => i_prof_data.id_category,
                                                i_id_profile_template => i_prof_data.id_profile_template,
                                                i_id_functionality    => i_prof_data.id_functionality,
                                                i_param               => l_wf_param,
                                                o_status_info         => l_status_info_row,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_status_info_row.icon IS NOT NULL
        THEN
            l_status_icon := lpad(l_status_info_row.rank, 6, '0') || l_status_info_row.icon;
        END IF;
    
        g_error                := 'Call pk_ref_utils.parse_dt_str_flash / ID_REF=' || i_ref_row.id_external_request ||
                                  ' YEAR_BEGIN=' || i_ref_row.year_begin || ' MONTH_BEGIN=' || i_ref_row.month_begin ||
                                  ' DAY_BEGIN=' || i_ref_row.day_begin || ' / ' || l_params;
        l_dt_probl_begin_flash := pk_ref_utils.parse_dt_str_flash(i_lang  => i_lang,
                                                                  i_prof  => i_prof,
                                                                  i_year  => i_ref_row.year_begin,
                                                                  i_month => i_ref_row.month_begin,
                                                                  i_day   => i_ref_row.day_begin);
    
        l_dt_probl_begin_str := pk_ref_utils.parse_dt_str_app(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_year  => i_ref_row.year_begin,
                                                              i_month => i_ref_row.month_begin,
                                                              i_day   => i_ref_row.day_begin);
    
        IF i_prof_data.id_market = pk_ref_constant.g_market_mx
        THEN
            g_error := 'Call pk_api_backoffice.get_inst_account_val / I_INSTITUTION=' || i_ref_row.id_inst_orig ||
                       ', I_ACCOUNT=' || 79;
            l_clues := pk_api_backoffice.get_inst_account_val(i_lang        => i_lang,
                                                              i_institution => i_ref_row.id_inst_orig,
                                                              i_account     => 78,
                                                              o_error       => o_error);
        ELSE
            l_clues := NULL;
        END IF;
    
        g_error := 'OPEN o_detail FOR / ' || l_params;
        OPEN o_detail FOR
            SELECT t.id_external_request id_external_request,
                   CASE
                        WHEN t.id_workflow IN (pk_ref_constant.g_wf_circle_normal, pk_ref_constant.g_wf_circle_cb) THEN
                         t.num_req
                        ELSE
                         to_char(t.id_external_request)
                    END id_p1,
                   t.flg_type flg_type,
                   t.num_req,
                   t.id_workflow, -- 5
                   t.id_episode,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                       t.id_external_request,
                                                                                       t.flg_status,
                                                                                       t.id_workflow),
                                                      i_prof) dt_p1,
                   l_status_icon status_icon,
                   t.flg_status,
                   l_status_info_row.color status_colors,
                   l_status_info_row.desc_status desc_status,
                   pk_ref_core.get_ref_priority_info(i_lang, i_prof, t.flg_priority) priority_info,
                   pk_ref_utils.get_domain_cached_img_name(i_lang, i_prof, pk_ref_constant.g_ref_prio, t.flg_priority) priority_icon,
                   pk_ref_core.get_ref_priority_desc(i_lang, i_prof, t.flg_priority) priority_desc,
                   pk_date_utils.get_elapsed_tsz(i_lang, t.dt_status_tstz, current_timestamp) dt_elapsed,
                   t.id_prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_requested) prof_name_request,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_prof_requested, t.id_inst_orig) prof_spec_request,
                   t.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_clinical_service_code || t.id_clinical_service) desc_clinical_service,
                   t.id_department,
                   pk_translation.get_translation(i_lang, pk_ref_constant.g_department_code || t.id_department) desc_department,
                   t.id_speciality id_speciality,
                   -- orig institution
                   t.id_inst_orig id_inst_orig,
                   l_clues inst_orig_clues,
                   decode(t.id_workflow, pk_ref_constant.g_wf_x_hosp, t.institution_name_roda, t.inst_orig_abbrev) inst_orig_abbrev,
                   pk_ref_core.get_inst_orig_name_detail(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_inst_orig        => t.id_inst_orig,
                                                         i_inst_name_roda      => t.institution_name_roda,
                                                         i_id_inst_orig_parent => t.inst_orig_parent) inst_orig_name,
                   -- dest institution
                   t.id_inst_dest,
                   decode(t.id_inst_dest, l_sc_other_institution, NULL, t.inst_dest_abbrev) inst_abbrev,
                   pk_ref_core.get_inst_name(i_lang,
                                             i_prof,
                                             t.flg_status,
                                             t.id_inst_dest,
                                             t.inst_dest_code,
                                             t.inst_dest_abbrev) inst_name,
                   pk_translation.get_translation(to_char(i_lang),
                                                  pk_ref_constant.g_clinical_service_code || t.id_clinical_service) dep_name,
                   pk_translation.get_translation(i_lang, pk_ref_constant.g_p1_speciality_code || t.id_speciality) spec_name,
                   pk_date_utils.dt_chr_tsz(i_lang, t.dt_schedule, i_prof) dt_schedule,
                   decode(i_view_clin_data,
                          pk_ref_constant.g_yes,
                          l_dt_probl_begin_str, -- ALERT-194568
                          NULL) dt_probl_begin,
                   decode(i_view_clin_data,
                          pk_ref_constant.g_yes,
                          l_dt_probl_begin_flash, -- ALERT-194568
                          NULL) dt_probl_begin_ts,
                   pk_ref_constant.g_field_dt_problem field_name, -- ALERT-276401
                   t.flg_priority,
                   t.flg_home,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_redirected) prof_redirected,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_last_interaction_tstz, i_prof) dt_last_interaction,
                   l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t011) label_institution,
                   l_desc_message_ibt(l_sm_clinical_service) label_clinical_service,
                   l_desc_message_ibt(pk_ref_constant.g_sm_ref_grid_t009) label_department,
                   l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t119) label_priority,
                   l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t061) label_home,
                   pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_home, t.flg_home, i_lang) desc_home,
                   l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t035) label_status,
                   l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t040) label_dt_probl_begin,
                   t.decision_urg_level,
                   pk_sysdomain.get_domain(pk_ref_constant.g_decision_urg_level || t.decision_urg_level,
                                           t.decision_urg_level,
                                           i_lang) desc_decision_urg_level,
                   t.id_external_sys,
                   decode(t.id_schedule,
                          NULL,
                          NULL,
                          (SELECT id_schedule_ext
                             FROM sch_api_map_ids
                            WHERE id_schedule_pfh = t.id_schedule
                              AND rownum = 1)) id_schedule_ext,
                   CASE t.flg_status
                       WHEN pk_ref_constant.g_p1_status_a THEN
                        pk_ref_core.get_prof_status(i_lang, i_prof, t.id_external_request, t.flg_status)
                       ELSE
                        t.id_prof_schedule
                   END id_prof_schedule,
                   pk_ref_core.get_referral_obs(i_lang, i_prof, t.id_external_request, t.flg_status, i_view_clin_data) reason_desc,
                   pk_ref_core.get_referral_obs_text(i_lang,
                                                     i_prof,
                                                     t.id_external_request,
                                                     t.flg_status,
                                                     i_view_clin_data) reason_text,
                   l_desc_message_ibt(pk_ref_constant.g_sm_ref_devstatus_notes) title_notes,
                   l_desc_message_ibt(pk_ref_constant.g_sm_ref_devstatus_reason) title_text,
                   pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_clinical_service_code || t.id_clinical_service) sub_spec_name,
                   l_desc_message_ibt(l_sm_sub_speciality) label_sub_spec,
                   l_desc_message_ibt(l_sm_speciality) label_spec,
                   l_wait_days wait_days,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_ref_line, t.flg_ref_line, i_lang)
                      FROM dual) ref_line,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_type_ins, t.flg_type_ins, i_lang)
                      FROM dual) type_ins,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_inside_ref_area, t.flg_inside_ref_area, i_lang)
                      FROM dual) inside_ref_area,
                   l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t012) inst_type_label,
                   l_desc_message_ibt(pk_ref_constant.g_sm_ref_waitingtime_t013) ref_line_label,
                   l_wait_days_label wait_days_label,
                   t.id_dep_clin_serv id_sub_speciality,
                   decode(t.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          pk_ref_core.get_content(i_lang, i_prof, t.id_dep_clin_serv, t.id_prof_schedule),
                          NULL) id_content,
                   pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_code_domain => pk_ref_constant.g_p1_exr_flg_type,
                                                       i_val         => t.flg_type) flg_type_desc,
                   t.inst_dest_location location_dest,
                   pk_date_utils.dt_chr_tsz(i_lang, t.dt_issued, i_prof) dt_issued,
                   l_desc_message_ibt(pk_ref_constant.g_sm_p1_info_t001) label_referral_number,
                   l_flg_create_comment flg_create_comment,
                   t.prof_certificate,
                   t.prof_name,
                   t.prof_surname,
                   t.prof_phone,
                   t.id_fam_rel,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT code_family_relationship
                                                     FROM family_relationship fr
                                                    WHERE fr.id_family_relationship = t.id_fam_rel)) desc_fr,
                   t.name_first_rel,
                   t.name_middle_rel,
                   t.name_last_rel,
                   t.consent,
                   (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.CONSENT', t.consent, i_lang)
                      FROM dual) desc_consent,
                   t.family_relationship_notes
              FROM (SELECT ea.id_external_request,
                           ea.id_workflow,
                           ea.num_req,
                           ea.flg_type,
                           ea.id_episode,
                           ea.flg_status,
                           ea.flg_priority,
                           ea.flg_home,
                           ea.dt_status                 dt_status_tstz,
                           ea.id_prof_requested,
                           ea.id_inst_orig,
                           ea.id_dep_clin_serv,
                           ea.id_speciality,
                           ea.id_inst_dest,
                           ea.dt_last_interaction_tstz,
                           ea.decision_urg_level,
                           ea.id_external_sys,
                           ea.id_schedule,
                           ea.id_prof_redirected,
                           ea.id_prof_orig              id_prof_roda,
                           ea.institution_name_roda,
                           ea.dt_schedule,
                           ea.id_prof_schedule,
                           ea.dt_issued,
                           ea.prof_certificate,
                           ea.prof_name,
                           ea.prof_surname,
                           ea.prof_phone,
                           ea.id_fam_rel,
                           ea.name_first_rel,
                           ea.name_middle_rel,
                           ea.name_last_rel,
                           ea.consent,
                           ist_orig.abbreviation        inst_orig_abbrev,
                           ist_orig.code_institution    inst_orig_code,
                           ist_orig.id_parent           inst_orig_parent,
                           ist.abbreviation             inst_dest_abbrev,
                           ist.code_institution         inst_dest_code,
                           ist.location                 inst_dest_location,
                           dcs.id_clinical_service,
                           dcs.id_department,
                           rdis.flg_ref_line,
                           pdi.flg_type_ins,
                           rdis.flg_inside_ref_area,
                           ea.family_relationship_notes
                      FROM referral_ea ea
                      JOIN institution ist_orig
                        ON (ist_orig.id_institution = ea.id_inst_orig)
                      LEFT JOIN institution ist
                        ON (ist.id_institution = ea.id_inst_dest)
                      LEFT JOIN dep_clin_serv dcs
                        ON (ea.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      LEFT JOIN p1_dest_institution pdi
                        ON (pdi.id_inst_orig = ea.id_inst_orig AND pdi.id_inst_dest = ea.id_inst_dest AND
                           pdi.flg_type = ea.flg_type)
                      LEFT JOIN ref_dest_institution_spec rdis
                        ON (pdi.id_dest_institution = rdis.id_dest_institution AND rdis.id_speciality = ea.id_speciality AND
                           rdis.flg_available = pk_ref_constant.g_yes)
                     WHERE ea.id_external_request = i_ref_row.id_external_request) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_referral_detail;

    /**
    * Gets referral detail short
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Professional data
    * @param   i_ref_row        Referral row data
    * @param   o_ref_data       Referral short detail data   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-01-2013
    */
    FUNCTION get_referral_detail_short
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_param     IN table_varchar DEFAULT table_varchar(),
        o_ref_data  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params               VARCHAR2(1000 CHAR);
        l_sc_other_institution sys_config.desc_sys_config%TYPE;
        l_prev_track_row       p1_tracking%ROWTYPE;
        l_wf_transition_info   table_varchar;
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_ref_row.id_external_request ||
                    ' ID_PAT=' || i_ref_row.id_patient || ' ID_SPEC=' || i_ref_row.id_speciality || ' FLG_STATUS=' ||
                    i_ref_row.flg_status;
        g_error  := 'Init get_referral_detail / ' || l_params;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error                := 'Configs / ' || l_params;
        l_sc_other_institution := pk_sysconfig.get_config(pk_ref_constant.g_sc_other_institution, i_prof);
    
        ----------------------
        -- FUNC
        ---------------------- 
    
        IF i_param IS NULL
           OR i_param.count = 0
        THEN
            g_error              := 'Calling init_param_tab / ' || l_params;
            l_wf_transition_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_ext_req            => i_ref_row.id_external_request,
                                                               i_id_patient         => i_ref_row.id_patient,
                                                               i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                               i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                               i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                                               i_id_speciality      => i_ref_row.id_speciality,
                                                               i_flg_type           => i_ref_row.flg_type,
                                                               i_decision_urg_level => i_ref_row.decision_urg_level,
                                                               i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                               i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                                               i_id_prof_status     => i_ref_row.id_prof_status,
                                                               i_external_sys       => i_ref_row.id_external_sys,
                                                               i_flg_status         => i_ref_row.flg_status);
        
        ELSE
            l_wf_transition_info := i_param;
        END IF;
    
        -- getting previous referral status
        g_error  := 'Call pk_ref_utils.get_prev_status_data / ' || l_params;
        g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => i_ref_row.id_external_request,
                                                      o_data   => l_prev_track_row,
                                                      o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_ref_data FOR / ' || l_params;
        OPEN o_ref_data FOR
            SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang) flg_type_desc,
                   -- professional request
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t.id_prof_requested,
                                                            i_id_prof_roda      => t.id_prof_roda) prof_name_request,
                   t.num_req,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                       t.id_external_request,
                                                                                       t.flg_status,
                                                                                       t.id_workflow),
                                                      i_prof) dt_p1,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_created) prof_created,
                   -- inst_orig_name
                   pk_ref_core.get_inst_orig_name(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_inst_orig   => t.id_inst_orig,
                                                  i_inst_name_roda => t.inst_name_roda) inst_orig_name,
                   -- p1_spec_name
                   decode(t.id_workflow,
                          pk_ref_constant.g_wf_srv_srv,
                          -- if is internal workflow, than shows the desc of clinical service
                          pk_translation.get_translation(i_lang,
                                                         pk_ref_constant.g_clinical_service_code || t.id_clinical_service),
                          -- else  (other than internal workflow)
                          nvl2(t.id_speciality,
                               pk_translation.get_translation(i_lang,
                                                              pk_ref_constant.g_p1_speciality_code || t.id_speciality),
                               pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang))) p1_spec_name,
                   -- clin_srv_name
                   decode(t.id_inst_dest,
                          NULL,
                          NULL,
                          decode(t.id_dep_clin_serv,
                                 NULL,
                                 pk_translation.get_translation(i_lang, t.code_speciality),
                                 pk_translation.get_translation(i_lang, t.code_clinical_service))) clin_srv_name,
                   -- inst_dest
                   decode(t.id_inst_dest, l_sc_other_institution, NULL, t.inst_dest_abbrev) inst_dest_abbrev,
                   pk_ref_core.get_inst_name(i_lang,
                                             i_prof,
                                             t.flg_status,
                                             t.id_inst_dest,
                                             t.inst_dest_code,
                                             t.inst_dest_abbrev) inst_dest_name,
                   pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang) priority_desc, -- ALERT-273753
                   -- ACTUAL STATUS - used in registrar screen, to see the actual referral status
                   pk_workflow.get_status_desc(i_lang,
                                               i_prof,
                                               nvl(t.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                               pk_ref_status.convert_status_n(t.flg_status), -- actual status
                                               i_prof_data.id_category,
                                               i_prof_data.id_profile_template,
                                               i_prof_data.id_functionality,
                                               l_wf_transition_info) desc_status,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_status_tstz, i_prof) dt_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_status) prof_status,
                   -- PREVIOUS STATUS - used in physician screen, to see the referral status before cancelation request
                   pk_workflow.get_status_desc(i_lang,
                                               i_prof,
                                               nvl(t.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                               pk_ref_status.convert_status_n(l_prev_track_row.ext_req_status), -- previous status
                                               i_prof_data.id_category,
                                               i_prof_data.id_profile_template,
                                               i_prof_data.id_functionality,
                                               l_wf_transition_info) desc_prev_status,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_prev_track_row.dt_tracking_tstz, i_prof) dt_prev_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, l_prev_track_row.id_professional) prof_prev_status
              FROM (SELECT exr.flg_type,
                           exr.id_prof_requested,
                           exr.num_req,
                           exr.id_external_request,
                           exr.flg_status,
                           exr.id_workflow,
                           exr.id_speciality,
                           pk_ref_constant.g_p1_speciality_code || exr.id_speciality code_speciality,
                           exr.id_inst_dest,
                           exr.id_inst_orig,
                           exr.flg_priority,
                           exr.dt_status_tstz,
                           exr.id_prof_status,
                           exr.id_prof_created,
                           dcs.id_dep_clin_serv,
                           dcs.id_clinical_service,
                           pk_ref_constant.g_clinical_service_code || dcs.id_clinical_service code_clinical_service,
                           rod.institution_name inst_name_roda,
                           rod.id_professional id_prof_roda,
                           i_dest.abbreviation inst_dest_abbrev,
                           i_dest.code_institution inst_dest_code
                      FROM p1_external_request exr
                      LEFT JOIN ref_orig_data rod
                        ON (exr.id_external_request = rod.id_external_request)
                      LEFT JOIN institution i_dest
                        ON (i_dest.id_institution = exr.id_inst_dest)
                      LEFT JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = exr.id_dep_clin_serv)
                     WHERE exr.id_external_request = i_ref_row.id_external_request) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_ref_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_DETAIL_SHORT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref_data);
            RETURN FALSE;
    END get_referral_detail_short;

    /**
    * Get Referral short detail 
    *
    * @param   i_lang                        Language associated to the professional executing the request
    * @param   i_prof                        Professional, institution and software ids
    * @param   i_id_external_request         Referral identifier 
    * @param   o_detail                      Referral details
    * @param   o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2010 
    */
    FUNCTION get_ref_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN table_number,
        o_detail              OUT pk_ref_core.ref_detail_cur,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ident_id_health_plan health_plan.id_health_plan%TYPE;
        l_market               market.id_market%TYPE;
        l_sc_multi_instit      VARCHAR2(1 CHAR);
        l_sub_speciality       sys_message.desc_message%TYPE;
        l_spec_label           sys_message.desc_message%TYPE;
    BEGIN
        g_error        := 'Init get_ref_detail';
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        l_ident_id_health_plan := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
    
        l_sc_multi_instit := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                         i_id_sys_config => pk_ref_constant.g_sc_multi_institution);
    
        l_sub_speciality := pk_message.get_message(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_code_mess => pk_ref_constant.g_sm_ref_grid_t025); --sub specialty
        l_spec_label     := pk_message.get_message(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_code_mess => pk_ref_constant.g_sm_p1_detail_t011); --specialty
    
        g_error  := 'pk_utils.get_institution_market / ID_INST=' || i_prof.institution;
        l_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'Open o_detail';
        OPEN o_detail FOR
            SELECT t.id_patient,
                   pk_adt.get_patient_name(i_lang,
                                           i_prof,
                                           t.id_patient,
                                           pk_p1_external_request.check_prof_resp(i_lang, i_prof, t.id_external_request)) pat_name,
                   pk_date_utils.dt_chr(i_lang, t.dt_birth, i_prof) dt_birth,
                   decode(l_market, pk_ref_constant.g_market_pt, t.national_health_number, t.num_health_plan) num_health_plan,
                   decode(t.num_health_plan,
                          NULL,
                          pk_translation.get_translation(i_lang,
                                                         pk_ref_constant.g_health_plan_entity_code ||
                                                         t.id_health_plan_entity) || ' - ' ||
                          pk_translation.get_translation(i_lang, t.code_health_plan)) desc_health_plan,
                   pk_ref_core.get_run_curp_number(t.id_patient, l_market) run_number,
                   t.id_external_request,
                   t.num_req,
                   t.flg_type,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang)
                      FROM dual) desc_referral_type,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang)
                      FROM dual) priority,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_decision_urg_level || t.decision_urg_level,
                                                   t.decision_urg_level,
                                                   i_lang)
                      FROM dual) decision_urg_level,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                       t.id_external_request,
                                                                                       t.flg_status,
                                                                                       t.id_workflow),
                                                      i_prof) dt_request,
                   pk_ref_utils.get_ref_detail_date(i_lang, t.id_external_request, t.flg_status, t.id_workflow) dt_requested,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_ref_utils.get_ref_detail_date(i_lang,
                                                                             t.id_external_request,
                                                                             t.flg_status,
                                                                             t.id_workflow),
                                            i_prof) dt_request_date,
                   pk_date_utils.dt_chr_tsz(i_lang, g_sysdate_tstz, i_prof) dt_emited,
                   t.dt_issued dt_emited_tstz,
                   pk_date_utils.dt_chr_hour_tsz(i_lang, g_sysdate_tstz, i_prof) hour_emited,
                   -- professional request
                   pk_p1_external_request.get_prof_req_id(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_prof_requested => t.id_prof_requested,
                                                          i_id_prof_roda      => t.id_prof_roda) id_prof_requested,
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t.id_prof_requested,
                                                            i_id_prof_roda      => t.id_prof_roda) prof_requested_name,
                   -- orig institution
                   t.id_inst_orig,
                   pk_ref_core.get_inst_orig_name(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_inst_orig   => t.id_inst_orig,
                                                  i_inst_name_roda => t.inst_name_roda) inst_orig_name,
                   decode(t.id_workflow, pk_ref_constant.g_wf_x_hosp, '', t.location_io) location_orig,
                   t.id_inst_dest,
                   pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || t.id_inst_dest) inst_dest_name,
                   t.location_id location_dest,
                   t.id_speciality id_speciality,
                   nvl2(t.code_speciality,
                        pk_translation.get_translation(i_lang, t.code_speciality),
                        (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang)
                           FROM dual)) spec_name,
                   t.id_dep_clin_serv,
                   t.id_department,
                   pk_translation.get_translation(i_lang, t.code_department) desc_department,
                   t.id_clinical_service,
                   pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service,
                   decode(t.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          pk_ref_core.get_content(i_lang, i_prof, t.id_dep_clin_serv, t.id_prof_schedule),
                          NULL) id_content,
                   t.dt_schedule dt_sch_tstz,
                   t.id_prof_schedule id_prof_sch,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_schedule) pror_sch_name,
                   pk_translation.get_translation(i_lang, t.code_clinical_service) sub_spec_name, -- clinical service
                   l_sub_speciality label_sub_spec,
                   l_spec_label label_spec
              FROM (SELECT per.id_patient,
                           pat.dt_birth,
                           psa.national_health_number,
                           php.num_health_plan,
                           hep.id_health_plan_entity,
                           hep.code_health_plan,
                           per.id_external_request,
                           per.flg_status,
                           per.num_req,
                           per.flg_type,
                           per.flg_priority,
                           per.decision_urg_level,
                           per.id_workflow,
                           per.dt_requested,
                           per.dt_issued,
                           per.id_prof_orig id_prof_roda,
                           per.institution_name_roda inst_name_roda,
                           per.id_prof_requested,
                           per.id_inst_orig,
                           io.location location_io,
                           id.location location_id,
                           per.id_inst_dest,
                           per.id_speciality,
                           pk_ref_constant.g_p1_speciality_code || per.id_speciality code_speciality,
                           per.id_dep_clin_serv,
                           dcs.id_department,
                           pk_ref_constant.g_department_code || dcs.id_department code_department,
                           dcs.id_clinical_service,
                           pk_ref_constant.g_clinical_service_code || dcs.id_clinical_service code_clinical_service,
                           per.id_prof_schedule,
                           per.dt_schedule
                      FROM referral_ea per
                      JOIN institution io
                        ON (per.id_inst_orig = io.id_institution)
                      JOIN institution id
                        ON (per.id_inst_dest = id.id_institution)
                      LEFT JOIN pat_health_plan php
                        ON (php.id_patient = per.id_patient AND php.id_health_plan = l_ident_id_health_plan AND
                           ((php.id_institution = i_prof.institution AND l_sc_multi_instit = pk_ref_constant.g_no) OR
                           (php.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes)) AND
                           php.flg_status = pk_ref_constant.g_active)
                      LEFT JOIN health_plan hep
                        ON (hep.id_health_plan = php.id_health_plan)
                      LEFT JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = per.id_dep_clin_serv)
                      JOIN patient pat
                        ON (pat.id_patient = per.id_patient)
                      LEFT JOIN pat_soc_attributes psa
                        ON (psa.id_patient = pat.id_patient AND
                           ((psa.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                           (psa.id_institution IN (i_prof.institution, per.id_inst_orig) AND
                           (l_sc_multi_instit = pk_ref_constant.g_no OR l_market = pk_ref_constant.g_market_cl))))
                      JOIN (SELECT column_value
                             FROM TABLE(CAST(i_id_external_request AS table_number))) te
                        ON (te.column_value = per.id_external_request)) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REF_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_ref_detail;

    /**
    * Gets referral mcdt detail
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_ref_type       Referral type
    * @param   o_mcdt           MCDTs information   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2012
    */
    FUNCTION get_referral_mcdt
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_ref_type IN p1_external_request.flg_type%TYPE,
        o_mcdt     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    BEGIN
    
        l_params := 'ID_REF=' || i_id_ref || ' i_ref_type=' || i_ref_type;
        g_error  := 'Init get_referral_mcdt / ' || l_params;
    
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_doctor_cs_t119,
                                        pk_ref_constant.g_sm_doctor_req_t061,
                                        pk_ref_constant.g_ref_mark_req_t030,
                                        pk_ref_constant.g_ref_mark_req_t029);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_ref_type = pk_ref_constant.g_p1_type_a
        THEN
        
            g_error := 'OPEN O_MCDT A / ' || l_params;
            OPEN o_mcdt FOR
                SELECT DISTINCT t.id_analysis id,
                                NULL id_parent,
                                t.id_analysis_req_det id_req,
                                t.id_analysis_req,
                                NULL id_exam_req,
                                pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                          i_prof                      => i_prof,
                                                                          i_flg_type                  => pk_ref_constant.g_p1_type_a,
                                                                          i_analysis_code_translation => t.code_analysis,
                                                                          i_sample_code_translation   => t.code_sample_type,
                                                                          i_dep_clin_serv             => NULL) title,
                                
                                NULL text,
                                NULL dt_insert,
                                NULL prof_name,
                                i_ref_type flg_type,
                                flg_status,
                                t.id_institution,
                                t.abbreviation abbreviation,
                                pk_translation.get_translation(i_lang, t.code_institution) desc_institution,
                                t.flg_priority,
                                t.flg_home,
                                pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang) priority_desc, -- ALERT-273753
                                pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_home, t.flg_home, i_lang) desc_home,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t119) label_priority,
                                pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                        i_prof,
                                                                        pk_ref_constant.g_ref_prio,
                                                                        t.flg_priority) priority_icon,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t061) label_home,
                                t.id_codification,
                                pk_translation.get_translation(i_lang,
                                                               pk_ref_constant.g_codification_code || t.id_codification) desc_codification,
                                t.id_analysis_codification id_mcdt_codification,
                                pk_translation.get_translation(i_lang,
                                                               pk_ref_constant.g_sample_type_code || t.id_sample_type) product_desc,
                                t.id_sample_type,
                                NULL id_rehab_area_interv,
                                NULL desc_rehab_area,
                                NULL flg_laterality,
                                NULL desc_laterality,
                                NULL flg_laterality_mcdt,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t030) label_laterality,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t029) label_amount,
                                t.amount mcdt_amount,
                                NULL id_rehab_session_type,
                                t.reason,
                                t.complementary_information,
                                t.standard_code
                  FROM (SELECT a.id_analysis,
                               pt.id_analysis_req_det,
                               ard.id_analysis_req,
                               a.code_analysis,
                               pk_ref_constant.g_sample_type_code || pt.id_sample_type code_sample_type,
                               pt.id_sample_type,
                               pt.id_institution,
                               ist.abbreviation,
                               ist.code_institution,
                               pt.flg_priority,
                               pt.flg_home,
                               ac.id_codification,
                               ac.id_analysis_codification,
                               ac.standard_code,
                               pt.amount,
                               pt.reason,
                               pt.complementary_information,
                               ard.flg_status
                          FROM p1_external_request exr
                          JOIN p1_exr_temp pt
                            ON (exr.id_external_request = pt.id_external_request)
                          JOIN analysis a
                            ON (pt.id_analysis = a.id_analysis)
                          JOIN analysis_req_det ard
                            ON ard.id_analysis_req_det = pt.id_analysis_req_det
                          LEFT JOIN analysis_codification ac
                            ON (ard.id_analysis_codification = ac.id_analysis_codification) -- ALERT-255928
                          LEFT JOIN institution ist
                            ON (ist.id_institution = pt.id_institution)
                         WHERE exr.id_external_request = i_id_ref
                           AND exr.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_c)
                        UNION ALL
                        SELECT a.id_analysis,
                               pa.id_analysis_req_det,
                               ard.id_analysis_req,
                               a.code_analysis,
                               pk_ref_constant.g_sample_type_code || pa.id_sample_type code_sample_type,
                               pa.id_sample_type,
                               per.id_inst_dest id_institution,
                               ist.abbreviation abbreviation,
                               ist.code_institution code_institution,
                               per.flg_priority,
                               per.flg_home,
                               ac.id_codification,
                               ac.id_analysis_codification,
                               ac.standard_code,
                               pa.amount,
                               pet.reason,
                               pet.complementary_information,
                               ard.flg_status
                          FROM p1_exr_analysis pa
                          JOIN p1_external_request per
                            ON (per.id_external_request = pa.id_external_request)
                          JOIN analysis a
                            ON (pa.id_analysis = a.id_analysis)
                          JOIN analysis_req_det ard
                            ON ard.id_analysis_req_det = pa.id_analysis_req_det
                          LEFT JOIN analysis_codification ac
                            ON (ard.id_analysis_codification = ac.id_analysis_codification) -- ALERT-255928
                          JOIN institution ist
                            ON (ist.id_institution = per.id_inst_dest)
                          LEFT JOIN p1_exr_temp pet
                            ON per.id_external_request = pet.id_external_request
                           AND pet.id_analysis_req_det = pa.id_analysis_req_det
                           AND pet.id_analysis = pa.id_analysis
                         WHERE pa.id_external_request = i_id_ref) t;
        
        ELSIF (i_ref_type = pk_ref_constant.g_p1_type_e OR i_ref_type = pk_ref_constant.g_p1_type_i)
        THEN
        
            g_error := 'OPEN O_MCDT ' || i_ref_type || ' / ' || l_params;
            OPEN o_mcdt FOR
                SELECT DISTINCT t.id_exam id,
                                NULL id_parent,
                                t.id_exam_req_det id_req,
                                NULL id_analysis_req,
                                t.id_exam_req,
                                pk_translation.get_translation(i_lang, t.code_exam) title,
                                NULL text,
                                NULL dt_insert,
                                NULL prof_name,
                                i_ref_type flg_type,
                                flg_status,
                                t.id_institution,
                                t.abbreviation abbreviation,
                                pk_translation.get_translation(i_lang, t.code_institution) desc_institution,
                                t.flg_priority,
                                t.flg_home,
                                pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang) priority_desc, -- ALERT-273753
                                pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_home, t.flg_home, i_lang) desc_home,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t119) label_priority,
                                pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                        i_prof,
                                                                        pk_ref_constant.g_ref_prio,
                                                                        t.flg_priority) priority_icon,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t061) label_home,
                                t.id_codification,
                                pk_translation.get_translation(i_lang,
                                                               pk_ref_constant.g_codification_code || t.id_codification) desc_codification,
                                t.id_exam_codification id_mcdt_codification,
                                NULL product_desc,
                                NULL id_sample_type,
                                NULL id_rehab_area_interv,
                                NULL desc_rehab_area,
                                t.flg_laterality flg_laterality,
                                pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LATERALITY', t.flg_laterality, i_lang) desc_laterality,
                                pk_mcdt.check_mcdt_laterality(i_lang,
                                                              i_prof,
                                                              decode(t.flg_type,
                                                                     pk_ref_constant.g_p1_type_i,
                                                                     'EI',
                                                                     pk_ref_constant.g_p1_type_e,
                                                                     'EO'),
                                                              t.id_exam) flg_laterality_mcdt,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t030) label_laterality,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t029) label_amount,
                                t.amount mcdt_amount,
                                NULL id_rehab_session_type,
                                t.reason,
                                t.complementary_information,
                                t.standard_code
                  FROM (SELECT e.id_exam,
                               pt.id_exam_req_det,
                               erd.id_exam_req,
                               e.code_exam,
                               pt.id_institution,
                               ist.abbreviation,
                               ist.code_institution,
                               pt.flg_priority,
                               pt.flg_home,
                               ec.id_codification,
                               ec.id_exam_codification,
                               ec.standard_code,
                               erd.flg_laterality,
                               exr.flg_type,
                               pt.amount,
                               pt.reason,
                               pt.complementary_information,
                               erd.flg_status
                          FROM p1_external_request exr
                          JOIN p1_exr_temp pt
                            ON (exr.id_external_request = pt.id_external_request)
                          JOIN exam e
                            ON (pt.id_exam = e.id_exam)
                          JOIN exam_req_det erd
                            ON (erd.id_exam_req_det = pt.id_exam_req_det)
                          LEFT JOIN exam_codification ec
                            ON (ec.id_exam_codification = erd.id_exam_codification) -- ALERT-255928
                          LEFT JOIN institution ist
                            ON (ist.id_institution = pt.id_institution)
                         WHERE pt.id_external_request = i_id_ref
                           AND exr.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_c)
                        UNION ALL
                        SELECT e.id_exam,
                               pe.id_exam_req_det,
                               erd.id_exam_req,
                               e.code_exam,
                               per.id_inst_dest              id_institution,
                               ist.abbreviation              abbreviation,
                               ist.code_institution          code_institution,
                               per.flg_priority,
                               per.flg_home,
                               ec.id_codification,
                               ec.id_exam_codification,
                               ec.standard_code,
                               erd.flg_laterality,
                               per.flg_type,
                               pe.amount,
                               pet.reason,
                               pet.complementary_information,
                               erd.flg_status
                          FROM p1_exr_exam pe
                          JOIN p1_external_request per
                            ON (per.id_external_request = pe.id_external_request)
                          JOIN exam e
                            ON (pe.id_exam = e.id_exam)
                          JOIN exam_req_det erd
                            ON (erd.id_exam_req_det = pe.id_exam_req_det)
                          LEFT JOIN exam_codification ec
                            ON (ec.id_exam_codification = erd.id_exam_codification) -- ALERT-255928
                          JOIN institution ist
                            ON (ist.id_institution = per.id_inst_dest)
                          LEFT JOIN p1_exr_temp pet
                            ON per.id_external_request = pet.id_external_request
                           AND pet.id_exam_req_det = pe.id_exam_req_det
                           AND pet.id_exam = pe.id_exam
                         WHERE pe.id_external_request = i_id_ref) t;
        
        ELSIF i_ref_type = pk_ref_constant.g_p1_type_p
        THEN
        
            g_error := 'OPEN O_MCDT ' || i_ref_type || ' / ' || l_params;
            OPEN o_mcdt FOR
                SELECT DISTINCT t.id_intervention id,
                                NULL id_parent,
                                t.id_interv_presc_det id_req,
                                NULL id_analysis_req,
                                NULL id_exam_req,
                                pk_procedures_api_db.get_alias_translation(i_lang, i_prof, t.code_intervention, NULL) title,
                                NULL text,
                                NULL dt_insert,
                                NULL prof_name,
                                i_ref_type flg_type,
                                flg_status,
                                t.id_institution,
                                t.abbreviation abbreviation,
                                pk_translation.get_translation(i_lang, t.code_institution) desc_institution,
                                t.flg_priority,
                                t.flg_home,
                                pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang) priority_desc, -- ALERT-273753
                                pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_home, t.flg_home, i_lang) desc_home,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t119) label_priority,
                                pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                        i_prof,
                                                                        pk_ref_constant.g_ref_prio,
                                                                        t.flg_priority) priority_icon,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t061) label_home,
                                t.id_codification,
                                pk_translation.get_translation(i_lang,
                                                               pk_ref_constant.g_codification_code || t.id_codification) desc_codification,
                                t.id_interv_codification id_mcdt_codification,
                                NULL product_desc,
                                NULL id_sample_type,
                                NULL id_rehab_area_interv,
                                NULL desc_rehab_area,
                                t.flg_laterality flg_laterality,
                                pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', t.flg_laterality, i_lang) desc_laterality,
                                pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', t.id_intervention) flg_laterality_mcdt,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t030) label_laterality,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t029) label_amount,
                                t.amount mcdt_amount,
                                NULL id_rehab_session_type,
                                t.reason,
                                t.complementary_information,
                                t.standard_code
                  FROM (SELECT i.id_intervention,
                               pt.id_interv_presc_det,
                               i.code_intervention,
                               pt.id_institution,
                               ist.abbreviation,
                               ist.code_institution,
                               pt.flg_priority,
                               pt.flg_home,
                               ic.id_codification,
                               ic.id_interv_codification,
                               ic.standard_code,
                               ipd.flg_laterality,
                               pt.amount,
                               pt.reason,
                               pt.complementary_information,
                               ipd.flg_status
                          FROM p1_external_request exr
                          JOIN p1_exr_temp pt
                            ON (exr.id_external_request = pt.id_external_request)
                          JOIN intervention i
                            ON (pt.id_intervention = i.id_intervention)
                          JOIN interv_presc_det ipd
                            ON (ipd.id_interv_presc_det = pt.id_interv_presc_det)
                          LEFT JOIN interv_codification ic
                            ON (ic.id_interv_codification = ipd.id_interv_codification) -- ALERT-255928
                          LEFT JOIN institution ist
                            ON (ist.id_institution = pt.id_institution)
                         WHERE pt.id_external_request = i_id_ref
                           AND exr.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_c)
                        UNION ALL
                        SELECT i.id_intervention,
                               pi.id_interv_presc_det,
                               i.code_intervention,
                               per.id_inst_dest              id_institution,
                               ist.abbreviation              abbreviation,
                               ist.code_institution          code_institution,
                               per.flg_priority,
                               per.flg_home,
                               ic.id_codification,
                               ic.id_interv_codification,
                               ic.standard_code,
                               ipd.flg_laterality,
                               pi.amount,
                               pet.reason,
                               pet.complementary_information,
                               ipd.flg_status
                          FROM p1_exr_intervention pi
                          JOIN p1_external_request per
                            ON (per.id_external_request = pi.id_external_request)
                          JOIN intervention i
                            ON (pi.id_intervention = i.id_intervention)
                          JOIN interv_presc_det ipd
                            ON (ipd.id_interv_presc_det = pi.id_interv_presc_det)
                          LEFT JOIN interv_codification ic
                            ON (ic.id_interv_codification = ipd.id_interv_codification) -- ALERT-255928
                          JOIN institution ist
                            ON (ist.id_institution = per.id_inst_dest)
                          LEFT JOIN p1_exr_temp pet
                            ON per.id_external_request = pet.id_external_request
                           AND pet.id_interv_presc_det = pi.id_interv_presc_det
                           AND pet.id_intervention = pi.id_intervention
                         WHERE pi.id_external_request = i_id_ref) t;
        
        ELSIF i_ref_type = pk_ref_constant.g_p1_type_f
        THEN
        
            -- MFR
            g_error := 'OPEN O_MCDT ' || i_ref_type || ' / ' || l_params;
            OPEN o_mcdt FOR
                SELECT DISTINCT t.id_intervention id,
                                NULL id_parent,
                                t.id_rehab_presc id_req,
                                NULL id_analysis_req,
                                NULL id_exam_req,
                                pk_procedures_api_db.get_alias_translation(i_lang, i_prof, t.code_intervention, NULL) title,
                                NULL text,
                                NULL dt_insert,
                                NULL prof_name,
                                i_ref_type flg_type,
                                flg_status,
                                t.id_institution,
                                t.abbreviation abbreviation,
                                pk_translation.get_translation(i_lang, t.code_institution) desc_institution,
                                t.flg_priority,
                                t.flg_home,
                                pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang) priority_desc, -- ALERT-273753
                                pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_home, t.flg_home, i_lang) desc_home,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t119) label_priority,
                                pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                        i_prof,
                                                                        pk_ref_constant.g_ref_prio,
                                                                        t.flg_priority) priority_icon,
                                l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t061) label_home,
                                t.id_codification,
                                pk_translation.get_translation(i_lang,
                                                               pk_ref_constant.g_codification_code || t.id_codification) desc_codification,
                                t.id_interv_codification id_mcdt_codification,
                                NULL product_desc,
                                NULL id_sample_type,
                                t.id_rehab_area_interv,
                                pk_translation.get_translation(i_lang, 'REHAB_AREA.CODE_REHAB_AREA.' || t.id_rehab_area) desc_rehab_area,
                                t.flg_laterality,
                                pk_sysdomain.get_domain('REHAB_PRESC.FLG_LATERALITY', t.flg_laterality, i_lang) desc_laterality,
                                pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', t.id_intervention) flg_laterality_mcdt,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t030) label_laterality,
                                l_desc_message_ibt(pk_ref_constant.g_ref_mark_req_t029) label_amount,
                                t.amount mcdt_amount,
                                t.id_rehab_session_type,
                                t.reason,
                                t.complementary_information,
                                t.standard_code
                  FROM (SELECT i.id_intervention,
                               pt.id_rehab_presc,
                               i.code_intervention,
                               pt.id_institution,
                               ist.abbreviation,
                               ist.code_institution,
                               pt.flg_priority,
                               pt.flg_home,
                               ic.id_codification,
                               ic.id_interv_codification,
                               ic.standard_code,
                               rp.id_rehab_area_interv,
                               rai.id_rehab_area,
                               pt.amount,
                               rp.flg_laterality,
                               rsn.id_rehab_session_type,
                               pt.reason,
                               pt.complementary_information,
                               rp.flg_status
                          FROM p1_external_request exr
                          JOIN p1_exr_temp pt
                            ON (exr.id_external_request = pt.id_external_request)
                          JOIN rehab_presc rp
                            ON (rp.id_rehab_presc = pt.id_rehab_presc)
                          JOIN rehab_area_interv rai
                            ON (rai.id_rehab_area_interv = rp.id_rehab_area_interv)
                          LEFT JOIN rehab_sch_need rsn
                            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                          JOIN intervention i
                            ON (pt.id_intervention = i.id_intervention)
                          LEFT JOIN interv_codification ic
                            ON (i.id_intervention = ic.id_intervention AND pt.id_codification = ic.id_codification)
                          LEFT JOIN institution ist
                            ON (ist.id_institution = pt.id_institution)
                         WHERE pt.id_external_request = i_id_ref
                           AND exr.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_c)
                        UNION ALL
                        SELECT i.id_intervention,
                               pi.id_rehab_presc,
                               i.code_intervention,
                               per.id_inst_dest              id_institution,
                               ist.abbreviation              abbreviation,
                               ist.code_institution          code_institution,
                               per.flg_priority,
                               per.flg_home,
                               ic.id_codification,
                               ic.id_interv_codification,
                               ic.standard_code,
                               rp.id_rehab_area_interv,
                               rai.id_rehab_area,
                               pi.amount,
                               rp.flg_laterality,
                               rsn.id_rehab_session_type,
                               pet.reason,
                               pet.complementary_information,
                               rp.flg_status
                          FROM p1_exr_intervention pi
                          JOIN rehab_presc rp
                            ON (rp.id_rehab_presc = pi.id_rehab_presc)
                          JOIN rehab_area_interv rai
                            ON (rai.id_rehab_area_interv = rp.id_rehab_area_interv)
                          LEFT JOIN rehab_sch_need rsn
                            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                          JOIN p1_external_request per
                            ON (per.id_external_request = pi.id_external_request)
                          JOIN intervention i
                            ON (pi.id_intervention = i.id_intervention)
                          LEFT JOIN interv_codification ic
                            ON (i.id_intervention = ic.id_intervention AND pi.id_codification = ic.id_codification)
                          JOIN institution ist
                            ON (ist.id_institution = per.id_inst_dest)
                          LEFT JOIN p1_exr_temp pet
                            ON per.id_external_request = pet.id_external_request
                           AND pet.id_rehab_presc = pi.id_rehab_presc
                           AND pet.id_intervention = pi.id_intervention
                         WHERE pi.id_external_request = i_id_ref) t;
        ELSE
            pk_types.open_my_cursor(o_mcdt);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_mcdt);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_MCDT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_mcdt);
            RETURN FALSE;
    END get_referral_mcdt;

    /**
    * Gets referral diagnosis data
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_flg_type       Diagnosis type    
    * @param   o_diagnosis      Referral diagnosis data   
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_flg_type       {*} P- problems {*} D- diagnosis
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_flg_type  IN p1_exr_diagnosis.flg_type%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
        l_cause_enable     sys_config.id_sys_config%TYPE;
        l_label_group      VARCHAR2(1000 CHAR);
        l_label            VARCHAR2(1000 CHAR);
    BEGIN
        l_cause_enable := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                      i_id_sys_config => pk_ref_constant.g_ref_clave_cause_enabled);
    
        l_params := 'ID_REF=' || i_id_ref || ' i_flg_type=' || i_flg_type;
        g_error  := 'Init get_referral_diagnosis / ' || l_params;
    
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_doctor_req_t018,
                                        pk_ref_constant.g_sm_doctor_req_t039,
                                        pk_ref_constant.g_sm_doctor_req_t021,
                                        pk_ref_constant.g_sm_ref_detail_t082);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'labels / ' || l_params;
        IF i_flg_type = pk_ref_constant.g_exr_diag_type_p
        THEN
            l_label_group := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018);
            l_label       := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t039);
        ELSIF i_flg_type = pk_ref_constant.g_exr_diag_type_d
        THEN
            l_label_group := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t021);
            l_label       := NULL;
        END IF;
    
        g_error := 'OPEN o_diagnosis FOR / ' || l_params;
        OPEN o_diagnosis FOR
            SELECT DISTINCT l_label_group label_group,
                            l_label label,
                            t.id_diagnosis id,
                            t.id_diagnosis_parent id_parent,
                            t.id_alert_diagnosis,
                            t.code_icd,
                            t.flg_other,
                            NULL id_req,
                            CASE
                                 WHEN t.id_diagnosis = pk_ref_constant.g_exr_diag_id_other THEN
                                  t.desc_diagnosis
                                 ELSE
                                  nvl(t.desc_diagnosis,
                                      pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                         i_id_institution  => i_prof.institution,
                                                                         i_id_software     => i_prof.software,
                                                                         i_id_concept_term => t.id_alert_diagnosis,
                                                                         i_concept_type    => 'DIAGNOSIS',
                                                                         i_id_task_type    => decode(i_flg_type,
                                                                                                     pk_ref_constant.g_exr_diag_type_p,
                                                                                                     pk_alert_constant.g_task_problems,
                                                                                                     pk_alert_constant.g_task_diagnosis)))
                             
                             END title,
                            NULL text,
                            pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_insert_tstz, i_prof) dt_insert,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name,
                            pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution) prof_spec,
                            i_flg_type flg_type,
                            t.flg_status,
                            NULL id_institution,
                            NULL flg_priority,
                            NULL flg_home,
                            decode(l_cause_enable,
                                   pk_ref_constant.g_yes,
                                   decode(i_flg_type,
                                          pk_ref_constant.g_exr_diag_type_d,
                                          pk_diagnosis.get_diag_cause_code(i_lang, i_prof, t.id_diagnosis),
                                          NULL),
                                   NULL) causes_code,
                            CASE i_flg_type
                                WHEN pk_ref_constant.g_exr_diag_type_d THEN
                                 (20 + sub_rank)
                                WHEN pk_ref_constant.g_exr_diag_type_p THEN
                                 (30 + sub_rank)
                                ELSE
                                 NULL
                            END rank_group_reports, -- ALERT-270965 - field used by reports applicable to AHP client only
                            CASE i_flg_type -- todo: nao da para ordenar entre os mesmos tipos
                                WHEN pk_ref_constant.g_exr_diag_type_d THEN
                                 pk_ref_constant.g_field_diagnosis
                                WHEN pk_ref_constant.g_exr_diag_type_p THEN
                                 pk_ref_constant.g_field_problem
                                ELSE
                                 NULL
                            END field_name,
                            sub_rank sub_rank -- to order all diagnosis/problems
              FROM (SELECT row_number() over(PARTITION BY psd.id_external_request, psd.flg_type, nvl(psd.desc_diagnosis, ed.desc_epis_diagnosis) ORDER BY psd.dt_insert_tstz DESC, psd.id_exr_diagnosis DESC) rn,
                           d.id_diagnosis,
                           d.id_diagnosis_parent,
                           d.code_diagnosis,
                           d.code_icd,
                           d.flg_other,
                           psd.dt_insert_tstz,
                           psd.id_professional,
                           psd.id_institution,
                           psd.flg_status,
                           psd.desc_diagnosis,
                           ed.id_epis_diagnosis,
                           ed.desc_epis_diagnosis,
                           psd.id_alert_diagnosis,
                           row_number() over(PARTITION BY psd.id_external_request, psd.flg_type ORDER BY psd.dt_insert_tstz DESC, psd.id_exr_diagnosis DESC) sub_rank
                      FROM p1_exr_diagnosis psd
                      JOIN p1_external_request per
                        ON (psd.id_external_request = per.id_external_request)
                      LEFT JOIN diagnosis d
                        ON (psd.id_diagnosis = d.id_diagnosis)
                      LEFT JOIN epis_diagnosis ed
                        ON (per.id_episode = ed.id_episode)
                       AND (d.id_diagnosis = ed.id_diagnosis)
                     WHERE psd.id_external_request = i_id_ref
                       AND psd.flg_type = i_flg_type
                       AND psd.flg_status = pk_ref_constant.g_active) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_DIAGNOSIS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_referral_diagnosis;

    /**
    * Gets the answer given by the consultation physician to the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier    
    * @param   o_answer         Referral answer data   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_answer
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_answer OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
        l_prof_data        t_rec_prof_data;
    BEGIN
    
        l_params := 'ID_REF=' || i_id_ref;
        g_error  := 'Init get_referral_answer / ' || l_params;
    
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_p1_answer_t001,
                                        pk_ref_constant.g_sm_p1_answer_t003,
                                        pk_ref_constant.g_sm_p1_answer_t004,
                                        pk_ref_constant.g_sm_p1_answer_t005,
                                        pk_ref_constant.g_sm_p1_answer_t006,
                                        pk_ref_constant.g_sm_p1_answer_t007,
                                        pk_ref_constant.g_sm_p1_answer_t008,
                                        pk_ref_constant.g_sm_p1_answer_t009,
                                        pk_ref_constant.g_sm_p1_answer_t010,
                                        pk_ref_constant.g_sm_p1_answer_t011,
                                        pk_ref_constant.g_sm_p1_answer_t012,
                                        pk_ref_constant.g_sm_common_t001,
                                        pk_ref_constant.g_sm_common_t002);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call pk_ref_core.get_prof_data / i_prof.ID=' || i_prof.id || ' / i_prof.INSTITUTION=' ||
                    i_prof.institution || ' / i_prof.SOFTWARE=' || i_prof.software;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_answer FOR / ' || l_params;
        OPEN o_answer FOR
            SELECT l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t001) label_group,
                   label,
                   TYPE,
                   t.id_diagnosis id,
                   NULL id_parent,
                   NULL id_req,
                   decode(t.desc_diagnosis,
                          NULL,
                          pk_translation.get_translation(i_lang, t.code_diagnosis),
                          t.desc_diagnosis) title,
                   NULL text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_insert_tstz, i_prof) dt_insert,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution) prof_spec,
                   0 flg_type,
                   t.flg_status,
                   NULL id_institution,
                   NULL flg_priority,
                   NULL flg_home,
                   flg_edit,
                   field_name
              FROM (SELECT d.id_diagnosis,
                           psd.desc_diagnosis,
                           d.code_diagnosis,
                           psd.dt_insert_tstz,
                           psd.id_professional,
                           psd.id_institution,
                           psd.flg_status,
                           decode(psd.flg_type,
                                  pk_ref_constant.g_exr_diag_type_a,
                                  l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t003),
                                  pk_ref_constant.g_exr_diag_type_r,
                                  l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t009),
                                  pk_ref_constant.g_exr_diag_type_d,
                                  l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t010)) label,
                           decode(psd.flg_type,
                                  pk_ref_constant.g_exr_diag_type_a,
                                  pk_ref_constant.g_ref_answer_diag,
                                  pk_ref_constant.g_exr_diag_type_r,
                                  pk_ref_constant.g_exr_answer_hp,
                                  pk_ref_constant.g_exr_diag_type_d,
                                  pk_ref_constant.g_exr_answer_diag_in) TYPE,
                           (CASE
                                WHEN psd.id_professional = i_prof.id
                                     AND psd.id_institution = i_prof.institution
                                     AND psd.flg_type IN
                                     (pk_ref_constant.g_exr_diag_type_a, pk_ref_constant.g_exr_diag_type_r) THEN
                                 pk_ref_constant.g_yes
                                ELSE
                                 pk_ref_constant.g_no
                            END) flg_edit,
                           (CASE psd.flg_type
                               WHEN pk_ref_constant.g_exr_diag_type_a THEN
                                pk_ref_constant.g_field_answ_diag
                               WHEN pk_ref_constant.g_exr_diag_type_r THEN
                                pk_ref_constant.g_field_answ_probl
                               WHEN pk_ref_constant.g_exr_diag_type_d THEN
                                pk_ref_constant.g_field_answ_diag_create
                               ELSE
                                NULL
                           END) field_name
                      FROM p1_exr_diagnosis psd
                      JOIN diagnosis d
                        ON (psd.id_diagnosis = d.id_diagnosis)
                     WHERE psd.id_external_request = i_id_ref
                       AND ((psd.flg_type IN (pk_ref_constant.g_exr_diag_type_a, pk_ref_constant.g_exr_diag_type_r)) OR
                           (psd.flg_type = pk_ref_constant.g_exr_diag_type_d AND
                           l_prof_data.id_market = pk_ref_constant.g_market_mx))
                       AND psd.flg_status = pk_ref_constant.g_active) t
            UNION ALL
            SELECT l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t001) label_group,
                   decode(t.flg_type,
                          pk_ref_constant.g_detail_type_a_obs,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t004),
                          pk_ref_constant.g_detail_type_a_ter,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t005),
                          pk_ref_constant.g_detail_type_a_exa,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t006),
                          pk_ref_constant.g_detail_type_a_con,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t007),
                          pk_ref_constant.g_detail_type_answ_evol,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t008),
                          pk_ref_constant.g_detail_type_dt_come_back,
                          l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t012)) label,
                   decode(t.flg_type,
                          pk_ref_constant.g_detail_type_a_obs,
                          pk_ref_constant.g_ref_answer_o,
                          pk_ref_constant.g_detail_type_a_ter,
                          pk_ref_constant.g_ref_answer_t,
                          pk_ref_constant.g_detail_type_a_exa,
                          pk_ref_constant.g_ref_answer_e,
                          pk_ref_constant.g_detail_type_a_con,
                          pk_ref_constant.g_ref_answer_c,
                          pk_ref_constant.g_detail_type_answ_evol,
                          pk_ref_constant.g_ref_answer_ev,
                          pk_ref_constant.g_detail_type_dt_come_back,
                          pk_ref_constant.g_ref_answer_dt_cb) TYPE,
                   t.id_detail id,
                   NULL id_parent,
                   NULL id_req,
                   pk_sysdomain.get_domain(pk_ref_constant.g_p1_detail_type, t.id_detail, i_lang) title,
                   decode(t.flg_type,
                          pk_ref_constant.g_detail_type_dt_come_back,
                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                              i_prof,
                                                                                              t.text,
                                                                                              NULL),
                                                                i_prof.institution,
                                                                i_prof.software),
                          t.text) text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_insert_tstz, i_prof) dt_insert,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution) prof_spec,
                   t.flg_type,
                   t.flg_status,
                   NULL id_institution,
                   NULL flg_priority,
                   NULL flg_home,
                   flg_edit,
                   (CASE t.flg_type
                       WHEN pk_ref_constant.g_detail_type_a_obs THEN
                        pk_ref_constant.g_field_answ_obs_summ
                       WHEN pk_ref_constant.g_detail_type_a_ter THEN
                        pk_ref_constant.g_field_answ_treat_prop
                       WHEN pk_ref_constant.g_detail_type_a_exa THEN
                        pk_ref_constant.g_field_answ_exam_prop
                       WHEN pk_ref_constant.g_detail_type_a_con THEN
                        pk_ref_constant.g_field_answ_concl
                       WHEN pk_ref_constant.g_detail_type_answ_evol THEN
                        pk_ref_constant.g_field_answ_progress
                       WHEN pk_ref_constant.g_detail_type_dt_come_back THEN
                        pk_ref_constant.g_field_answ_dt_comeback
                       ELSE
                        NULL
                   END) field_name
              FROM (SELECT pd.flg_type,
                           pd.id_detail,
                           pd.text,
                           pd.dt_insert_tstz,
                           pd.id_professional,
                           pd.id_institution,
                           pd.flg_status,
                           (CASE
                                WHEN pd.id_professional = i_prof.id
                                     AND pd.id_institution = i_prof.institution THEN
                                 pk_ref_constant.g_yes
                                ELSE
                                 pk_ref_constant.g_no
                            END) flg_edit
                      FROM p1_detail pd
                     WHERE pd.id_external_request = i_id_ref
                       AND pd.flg_type IN (pk_ref_constant.g_detail_type_a_obs,
                                           pk_ref_constant.g_detail_type_a_ter,
                                           pk_ref_constant.g_detail_type_a_exa,
                                           pk_ref_constant.g_detail_type_a_con,
                                           pk_ref_constant.g_detail_type_answ_evol,
                                           pk_ref_constant.g_detail_type_dt_come_back)
                       AND pd.flg_status = pk_ref_constant.g_detail_status_a) t
            -- 
            UNION ALL
            SELECT l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t001) label_group,
                   l_desc_message_ibt(pk_ref_constant.g_sm_p1_answer_t011) label,
                   'MUSTRETURN' TYPE,
                   t.id_detail id,
                   NULL id_parent,
                   NULL id_req,
                   NULL title,
                   CASE
                        WHEN t.text IS NOT NULL THEN
                         l_desc_message_ibt(pk_ref_constant.g_sm_common_t001)
                        ELSE
                         l_desc_message_ibt(pk_ref_constant.g_sm_common_t002)
                    END text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_insert_tstz, i_prof) dt_insert,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution) prof_spec,
                   t.flg_type,
                   t.flg_status,
                   NULL id_institution,
                   NULL flg_priority,
                   NULL flg_home,
                   NULL flg_edit,
                   pk_ref_constant.g_field_answ_label_comeback field_name -- preencher com novo campo
              FROM (SELECT pd.flg_type,
                           pd.id_detail,
                           pd.text,
                           pd.dt_insert_tstz,
                           pd.id_professional,
                           pd.id_institution,
                           pd.flg_status
                      FROM p1_external_request r
                      LEFT JOIN p1_detail pd
                        ON (r.id_external_request = pd.id_external_request AND
                           pd.flg_type = pk_ref_constant.g_detail_type_dt_come_back AND
                           pd.flg_status = pk_ref_constant.g_detail_status_a)
                     WHERE r.flg_status IN (pk_ref_constant.g_p1_status_w, pk_ref_constant.g_p1_status_k)
                       AND r.id_external_request = i_id_ref) t
             ORDER BY flg_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_answer);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_ANSWER',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_answer);
            RETURN FALSE;
    END get_referral_answer;

    /**
    * Gets referral tasks data
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier    
    * @param   i_flg_type       Referral type of task
    * @param   i_flg_status     Tasks status to retrieve
    * @param   o_task_done      Referral tasks data
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_flg_type       {*} S- To schedule {*} C- To Consultation
    * @value   i_flg_status     {*} A- active {*} O- outdated {*} C- canceled
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_taskdone
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_flg_type   IN VARCHAR2,
        i_flg_status IN VARCHAR2 DEFAULT NULL,
        o_task_done  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    
        l_label_group VARCHAR2(1000 CHAR);
        l_label       VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'ID_REF=' || i_id_ref || ' i_flg_type=' || i_flg_type || ' i_flg_status=' || i_flg_status;
        g_error  := 'Init get_referral_taskdone / ' || l_params;
    
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_doctor_req_t057,
                                        pk_ref_constant.g_sm_doctor_cs_t117,
                                        pk_ref_constant.g_sm_doctor_req_t059);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'labels / ' || l_params;
        IF i_flg_type = pk_ref_constant.g_p1_task_done_type_s
        THEN
            l_label_group := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t057);
            l_label       := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t117);
        ELSIF i_flg_type = pk_ref_constant.g_p1_task_done_type_c
        THEN
            l_label_group := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t057);
            l_label       := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t059);
        END IF;
    
        g_error := 'OPEN o_task_done FOR / ' || l_params;
        OPEN o_task_done FOR
            SELECT l_label_group label_group,
                   l_label label,
                   t.id_task,
                   pk_translation.get_translation(i_lang, pk_ref_constant.g_p1_task_code || t.id_task) desc_task,
                   t.flg_task_done,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_inserted_tstz, i_prof) dt_insert,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution) prof_spec,
                   t.flg_status,
                   t.id_group,
                   t.id_task_done,
                   CASE i_flg_type -- todo: nao da para ordenar entre os mesmos tipos
                       WHEN pk_ref_constant.g_p1_task_done_type_s THEN
                        pk_ref_constant.g_field_sent_to_reg
                       WHEN pk_ref_constant.g_p1_task_done_type_c THEN
                        pk_ref_constant.g_field_add_information
                       ELSE
                        NULL
                   END field_name
              FROM (SELECT ptd.id_task,
                           ptd.flg_task_done,
                           ptd.dt_inserted_tstz,
                           ptd.id_professional,
                           ptd.id_institution,
                           ptd.flg_status,
                           ptd.id_group,
                           ptd.id_task_done
                      FROM p1_task_done ptd
                     WHERE ptd.id_external_request = i_id_ref
                       AND ptd.flg_type = i_flg_type
                       AND ptd.flg_status = pk_ref_constant.g_active
                       AND ptd.flg_status = nvl(i_flg_status, ptd.flg_status)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_task_done);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_TASKDONE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_task_done);
            RETURN FALSE;
    END get_referral_taskdone;

    /**
    * Gets referral several details
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier    
    * @param   i_view_clin_data Flag indicating if professional can view clinical data
    * @param   i_flg_status     Tasks status to retrieve
    * @param   o_text           Referral details data
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_text
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_view_clin_data IN VARCHAR2,
        i_flg_status     IN VARCHAR2 DEFAULT NULL,
        o_text           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    BEGIN
    
        l_params := 'ID_REF=' || i_id_ref || ' i_view_clin_data=' || i_view_clin_data || ' i_flg_status=' ||
                    i_flg_status;
        g_error  := 'Init get_referral_text / ' || l_params;
    
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_doctor_req_t038,
                                        pk_ref_constant.g_sm_doctor_req_t018,
                                        pk_ref_constant.g_sm_doctor_req_t019,
                                        pk_ref_constant.g_sm_doctor_req_t055,
                                        pk_ref_constant.g_sm_doctor_req_t020,
                                        pk_ref_constant.g_sm_p1_detail_t016,
                                        pk_ref_constant.g_sm_doctor_req_t050,
                                        pk_ref_constant.g_sm_p1_detail_t063,
                                        pk_ref_constant.g_sm_doctor_req_t041,
                                        pk_ref_constant.g_sm_doctor_req_t042,
                                        pk_ref_constant.g_sm_doctor_req_t045,
                                        pk_ref_constant.g_sm_doctor_req_t046,
                                        pk_ref_constant.g_sm_doctor_req_t058,
                                        pk_ref_constant.g_sm_doctor_req_t082,
                                        pk_ref_constant.g_sm_doctor_req_t081,
                                        pk_ref_constant.g_sm_doctor_req_t083,
                                        pk_ref_constant.g_sm_doctor_req_t080,
                                        pk_ref_constant.g_sm_ref_detail_t046,
                                        pk_ref_constant.g_sm_ref_reg_hs_t001,
                                        pk_ref_constant.g_sm_ref_detail_t076,
                                        pk_ref_constant.g_sm_ref_detail_t083,
                                        pk_ref_constant.g_sm_ref_detail_t088,
                                        pk_ref_constant.g_sm_ref_detail_t089,
                                        pk_ref_constant.g_sm_ref_detail_t090);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_view_clin_data = pk_ref_constant.g_yes
        THEN
            g_error := 'OPEN o_text FOR / ' || l_params;
            OPEN o_text FOR
                SELECT decode(t.flg_type,
                              pk_ref_constant.g_detail_type_note,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t050),
                              pk_ref_constant.g_detail_type_jstf,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t038),
                              pk_ref_constant.g_detail_type_sntm,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018),
                              pk_ref_constant.g_detail_type_evlt,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018),
                              pk_ref_constant.g_detail_type_hstr,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t019),
                              pk_ref_constant.g_detail_type_hstf,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t019),
                              pk_ref_constant.g_detail_type_obje,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t055),
                              pk_ref_constant.g_detail_type_cmpe,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t020),
                              pk_ref_constant.g_detail_type_nadm,
                              l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t016),
                              pk_ref_constant.g_detail_type_rrn,
                              l_desc_message_ibt(pk_ref_constant.g_sm_ref_reg_hs_t001),
                              pk_ref_constant.g_detail_type_begin_sch,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t050),
                              pk_ref_constant.g_detail_type_end_sch,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t050),
                              pk_ref_constant.g_detail_type_prof_sch,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t050),
                              pk_ref_constant.g_detail_type_med,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018), -- ALERT-273876
                              pk_ref_constant.g_detail_type_vs,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018),
                              pk_ref_constant.g_detail_type_auge,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t019),
                              NULL) label_group,
                       decode(t.flg_type,
                              pk_ref_constant.g_detail_type_sntm,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t041),
                              pk_ref_constant.g_detail_type_evlt,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t042),
                              pk_ref_constant.g_detail_type_hstr,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t045),
                              pk_ref_constant.g_detail_type_hstf,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t046),
                              pk_ref_constant.g_detail_type_nadm,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t058),
                              pk_ref_constant.g_detail_type_rrn,
                              l_desc_message_ibt(pk_ref_constant.g_sm_ref_reg_hs_t001),
                              -- ALERT-14479 - GP PORTAL
                              pk_ref_constant.g_detail_type_begin_sch,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t081),
                              pk_ref_constant.g_detail_type_end_sch,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t083),
                              pk_ref_constant.g_detail_type_prof_sch,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t080),
                              pk_ref_constant.g_detail_type_med,
                              l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t063),
                              pk_ref_constant.g_detail_type_vs,
                              l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t083),
                              pk_ref_constant.g_detail_type_auge,
                              l_desc_message_ibt(pk_ref_constant.g_sm_ref_detail_t046),
                              NULL) label,
                       t.id_detail id,
                       NULL id_parent,
                       NULL id_req,
                       pk_sysdomain.get_domain(pk_ref_constant.g_p1_detail_type, t.flg_type, i_lang) title,
                       decode(t.flg_type,
                              pk_ref_constant.g_detail_type_prof_sch, -- gp portal
                              t.text || '|' || pk_prof_utils.get_name_signature(i_lang, i_prof, to_number(t.text)),
                              t.text) text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_insert_tstz, i_prof) dt_insert,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
                          FROM dual) prof_name,
                       (SELECT pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution)
                          FROM dual) prof_spec,
                       t.flg_type,
                       t.flg_status,
                       NULL id_institution,
                       NULL flg_priority,
                       NULL flg_home,
                       t.id_group,
                       CASE t.flg_type
                           WHEN pk_ref_constant.g_detail_type_jstf THEN
                            10
                           WHEN pk_ref_constant.g_detail_type_note THEN
                            15
                       -- diagnosis 20
                       -- problems 30
                           WHEN pk_ref_constant.g_detail_type_sntm THEN
                            40
                           WHEN pk_ref_constant.g_detail_type_evlt THEN
                            50
                           WHEN pk_ref_constant.g_detail_type_med THEN
                            60
                           WHEN pk_ref_constant.g_detail_type_vs THEN
                            70
                           WHEN pk_ref_constant.g_detail_type_hstr THEN
                            80
                           WHEN pk_ref_constant.g_detail_type_hstf THEN
                            90
                           WHEN pk_ref_constant.g_detail_type_obje THEN
                            100
                           WHEN pk_ref_constant.g_detail_type_cmpe THEN
                            110
                           ELSE
                            NULL
                       END rank_group_reports, -- ALERT-270965 - field used by reports applicable to AHP client only
                       CASE t.flg_type -- ALERT-276401
                           WHEN pk_ref_constant.g_detail_type_jstf THEN
                            pk_ref_constant.g_field_reason
                           WHEN pk_ref_constant.g_detail_type_note THEN
                            pk_ref_constant.g_field_notes
                           WHEN pk_ref_constant.g_detail_type_sntm THEN
                            pk_ref_constant.g_field_symptoms
                           WHEN pk_ref_constant.g_detail_type_evlt THEN
                            pk_ref_constant.g_field_progress
                           WHEN pk_ref_constant.g_detail_type_med THEN
                            pk_ref_constant.g_field_med
                           WHEN pk_ref_constant.g_detail_type_vs THEN
                            pk_ref_constant.g_field_vital_signes
                           WHEN pk_ref_constant.g_detail_type_hstr THEN
                            pk_ref_constant.g_field_hist
                           WHEN pk_ref_constant.g_detail_type_hstf THEN
                            pk_ref_constant.g_field_family_hist
                           WHEN pk_ref_constant.g_detail_type_obje THEN
                            pk_ref_constant.g_field_exam_o
                           WHEN pk_ref_constant.g_detail_type_cmpe THEN
                            pk_ref_constant.g_field_exam_c
                           WHEN pk_ref_constant.g_detail_type_nadm THEN
                            pk_ref_constant.g_field_notes_reg
                           WHEN pk_ref_constant.g_detail_type_auge THEN
                            pk_ref_constant.g_field_auge
                           WHEN pk_ref_constant.g_detail_type_rrn THEN
                            pk_ref_constant.g_field_rrn
                           ELSE
                            NULL
                       END field_name
                  FROM (SELECT *
                          FROM (SELECT pd.dt_insert_tstz,
                                       pd.flg_status,
                                       pd.flg_type,
                                       pd.id_detail,
                                       pd.text,
                                       pd.id_professional,
                                       pd.id_institution,
                                       pd.id_group
                                  FROM p1_detail pd
                                 WHERE pd.id_external_request = i_id_ref
                                   AND pd.flg_type IN (pk_ref_constant.g_detail_type_note,
                                                       pk_ref_constant.g_detail_type_jstf,
                                                       pk_ref_constant.g_detail_type_sntm,
                                                       pk_ref_constant.g_detail_type_evlt,
                                                       pk_ref_constant.g_detail_type_hstr,
                                                       pk_ref_constant.g_detail_type_hstf,
                                                       pk_ref_constant.g_detail_type_obje,
                                                       pk_ref_constant.g_detail_type_cmpe,
                                                       pk_ref_constant.g_detail_type_nadm,
                                                       pk_ref_constant.g_detail_type_rrn,
                                                       pk_ref_constant.g_detail_type_item,
                                                       pk_ref_constant.g_detail_type_ubrn,
                                                       pk_ref_constant.g_detail_type_auge,
                                                       pk_ref_constant.g_detail_type_begin_sch,
                                                       pk_ref_constant.g_detail_type_end_sch,
                                                       pk_ref_constant.g_detail_type_prof_sch,
                                                       pk_ref_constant.g_detail_type_med,
                                                       pk_ref_constant.g_detail_type_vs)
                                   AND pd.flg_status = nvl(i_flg_status, pd.flg_status)
                                 ORDER BY pd.dt_insert_tstz DESC, pd.flg_status)
                        /*WHERE rownum = 1*/
                        ) t
                 ORDER BY t.dt_insert_tstz DESC, t.flg_status ASC;
        ELSE
            g_error := 'OPEN o_text FOR / ' || l_params;
            OPEN o_text FOR
                SELECT decode(t.flg_type,
                              pk_ref_constant.g_detail_type_nadm,
                              l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t016),
                              pk_ref_constant.g_detail_type_rrn,
                              l_desc_message_ibt(pk_ref_constant.g_sm_ref_reg_hs_t001),
                              NULL) label_group,
                       decode(t.flg_type,
                              pk_ref_constant.g_detail_type_nadm,
                              l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t058),
                              pk_ref_constant.g_detail_type_rrn,
                              l_desc_message_ibt(pk_ref_constant.g_sm_ref_reg_hs_t001),
                              NULL) label,
                       t.id_detail id,
                       NULL id_parent,
                       NULL id_req,
                       pk_sysdomain.get_domain(pk_ref_constant.g_p1_detail_type, t.flg_type, i_lang) title,
                       t.text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_insert_tstz, i_prof) dt_insert,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
                          FROM dual) prof_name,
                       (SELECT pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_professional, t.id_institution)
                          FROM dual) prof_spec,
                       t.flg_type,
                       t.flg_status,
                       NULL id_institution,
                       NULL flg_priority,
                       NULL flg_home,
                       t.id_group
                  FROM (SELECT *
                          FROM (SELECT pd.dt_insert_tstz,
                                       pd.flg_status,
                                       pd.flg_type,
                                       pd.id_detail,
                                       pd.text,
                                       pd.id_professional,
                                       pd.id_institution,
                                       pd.id_group
                                  FROM p1_detail pd
                                 WHERE pd.id_external_request = i_id_ref
                                   AND pd.flg_type IN
                                       (pk_ref_constant.g_detail_type_rrn, pk_ref_constant.g_detail_type_nadm)
                                   AND pd.flg_status = nvl(i_flg_status, pd.flg_status)
                                 ORDER BY pd.dt_insert_tstz DESC, pd.flg_status DESC)
                        /* WHERE rownum = 1*/
                        ) t
                 ORDER BY t.dt_insert_tstz DESC, t.flg_status ASC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_text);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_TEXT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_text);
            RETURN FALSE;
    END get_referral_text;

    /**
    * Gets referral patient data (to be shown in referral detail)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_patient     Referral patient identifier    
    * @param   i_id_inst_orig   Referral orig institution identifier
    * @param   o_patient        Referral patient data
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-05-2013
    */
    FUNCTION get_referral_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        o_patient      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params    VARCHAR2(1000 CHAR);
        l_id_market institution.id_market%TYPE;
        l_doc_sns   doc_external.id_doc_external%TYPE;
        l_doc_id    doc_external.id_doc_external%TYPE;
        l_cpf       doc_external.id_doc_external%TYPE;
    BEGIN
    
        l_params    := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient;
        g_error     := 'Init get_referral_taskdone / ' || l_params;
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'OPEN o_patient FOR / ' || l_params;
        -- patient data for BR market is different from other markets        
        IF l_id_market = pk_ref_constant.g_market_br
        THEN
            l_doc_sns := pk_sysconfig.get_config(pk_ref_constant.g_sc_sns_doc_type, i_prof); -- cartao nacional de saude
            l_doc_id  := pk_sysconfig.get_config(pk_ref_constant.g_sc_bi_doc_type, i_prof); -- BI            
            l_cpf     := pk_sysconfig.get_config(pk_ref_constant.g_sc_cpf_doc_type, i_prof); -- cadastro pessoa fisica            
        
            g_error := 'OPEN O_PATIENT / ID_PATIENT=' || i_id_patient;
            OPEN o_patient FOR
                SELECT t.id_patient,
                       t.name,
                       pk_sysdomain.get_domain('PATIENT.GENDER', t.gender, i_lang) desc_gender,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_birth, i_prof) dt_birth,
                       pk_ref_core.get_pat_age(i_dt_birth => t.dt_birth, i_age => t.age) age,
                       t.race flg_race,
                       pk_ref_utils.get_domain_cached_desc(i_lang,
                                                           i_prof,
                                                           pk_ref_constant.g_pat_soc_attr_br_code, -- i_code_domain
                                                           t.race -- i_val
                                                           ) desc_race,
                       t.mother_name,
                       t.father_name,
                       t.address_line1 address, -- Endereco
                       t.address_line2 address_add_inf, -- Complemento
                       t.postal_code, -- cep
                       t.door_number, -- numero
                       t.id_districtr_br id_district,
                       pk_translation.get_translation(i_lang, pk_ref_constant.g_district_code || t.id_districtr_br) desc_district, -- Municipio
                       t.id_geo_state,
                       pk_translation.get_translation(i_lang, pk_ref_constant.g_geo_state_code || t.id_geo_state) desc_geo_state, -- Estado
                       t.neighbourhood, -- bairro
                       (SELECT ph_br.phone_number
                          FROM v_contact_phone ph_br
                         WHERE ph_br.id_contact_entity = t.id_person
                           AND ph_br.flg_main_address = pk_ref_constant.g_yes
                           AND ph_br.id_contact_type = pk_ref_constant.g_pat_phone_type_other
                           AND ph_br.id_contact_description = pk_ref_constant.g_pat_preferred_contact) phone_number,
                       (SELECT ph_br.phone_number
                          FROM v_contact_phone ph_br
                         WHERE ph_br.id_contact_entity = t.id_person
                           AND ph_br.flg_main_address = pk_ref_constant.g_yes
                           AND ph_br.id_contact_type = pk_ref_constant.g_pat_phone_type_main
                           AND ph_br.id_contact_description = pk_ref_constant.g_pat_preferred_contact) mobile_number,
                       t.alert_process_number, -- prontuario
                       (SELECT v1.num_doc
                          FROM v_doc_external v1
                         WHERE v1.id_patient = t.id_patient
                           AND v1.id_doc_type = l_doc_sns
                           AND v1.flg_status = pk_ref_constant.g_active) national_health_number, -- Cartao nacional de saude
                       (SELECT v2.num_doc
                          FROM v_doc_external v2
                         WHERE v2.id_patient = t.id_patient
                           AND v2.id_doc_type = l_cpf
                           AND v2.flg_status = pk_ref_constant.g_active) cpf_number, -- Cadastro de pessoa fisica
                       -- patient document identifier
                       v_doc.num_doc doc_id_number,
                       pk_date_utils.dt_chr_tsz(i_lang, v_doc.dt_emited, i_prof) dt_emited,
                       v_doc.organ_shipper
                  FROM (SELECT p.id_patient,
                               p.id_person,
                               p.name,
                               p.gender,
                               p.dt_birth,
                               p.age,
                               (SELECT vpr.id_race
                                  FROM v_pat_race vpr
                                 WHERE vpr.id_patient = p.id_patient
                                   AND rownum = 1) race,
                               psa.mother_name,
                               psa.father_name,
                               add_br.address_line1,
                               add_br.address_line2,
                               add_br.postal_code,
                               add_br.door_number,
                               add_br.id_districtr_br,
                               add_br.id_geo_state,
                               add_br.neighbourhood,
                               pi.alert_process_number
                          FROM v_patient p
                          LEFT JOIN v_pat_soc_attributes psa
                            ON (psa.id_patient = p.id_patient AND psa.id_institution = i_id_inst_orig)
                          LEFT JOIN v_contact_address_br add_br
                            ON (add_br.id_contact_entity = p.id_person)
                          LEFT JOIN v_pat_identifier pi
                            ON (pi.id_patient = p.id_patient AND pi.id_institution = i_id_inst_orig)
                         WHERE p.id_patient = i_id_patient) t
                  LEFT JOIN v_doc_external v_doc
                    ON (v_doc.id_patient = t.id_patient AND v_doc.id_institution = i_id_inst_orig AND
                       v_doc.id_doc_type = l_doc_id);
        
        ELSE
            g_error := 'OPEN O_PATIENT / ID_PATIENT=' || i_id_patient;
            OPEN o_patient FOR
                SELECT p.id_patient,
                       p.name,
                       p.gender,
                       pk_ref_core.get_pat_age(i_dt_birth => p.dt_birth, i_age => p.age) age,
                       NULL dt_birth,
                       NULL flg_race,
                       NULL desc_race,
                       NULL mother_name,
                       NULL father_name,
                       NULL address,
                       NULL address_add_inf,
                       NULL postal_code,
                       NULL door_number,
                       NULL id_districtr,
                       NULL desc_district,
                       NULL id_geo_state,
                       NULL desc_geo_state,
                       NULL neighbourhood,
                       NULL phone_number,
                       NULL alert_process_number
                  FROM patient p
                 WHERE p.id_patient = i_id_patient;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_patient);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_PATIENT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_patient);
            RETURN FALSE;
    END get_referral_patient;

    /**
    * Gets referral orig data (used in 'at hospital entrance' workflow)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   o_error          An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-06-2014
    */
    FUNCTION get_referral_orig_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        o_ref_orig_data OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'ID_REF=' || i_id_ref;
        g_error  := 'Init get_referral_orig_data / ' || l_params;
    
        g_error := 'OPEN O_REF_ORIG_DATA / ' || l_params;
        OPEN o_ref_orig_data FOR
            SELECT t.id_external_request id_ref,
                   pk_p1_external_request.get_prof_req_id(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_prof_requested => t.id_prof_requested,
                                                          i_id_prof_roda      => t.id_prof_roda) id_prof,
                   pk_p1_external_request.get_prof_req_num_order(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_id_prof_requested => t.id_prof_requested,
                                                                 i_id_prof_roda      => t.id_prof_roda) num_order,
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t.id_prof_requested,
                                                            i_id_prof_roda      => t.id_prof_roda) prof_name,
                   pk_ref_core.get_inst_orig_name_detail(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_inst_orig        => t.id_inst_orig,
                                                         i_inst_name_roda      => t.inst_name_roda,
                                                         i_id_inst_orig_parent => t.id_inst_parent) institution_name,
                   pk_ref_constant.g_field_orig_inst field_name_orig_inst,
                   pk_ref_constant.g_field_orig_phy_name field_name_orig_phy_name,
                   pk_ref_constant.g_field_orig_phy_no field_name_orig_phy_no,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_create, i_prof) dt_create,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_requested)
                      FROM dual) prof_name_create
              FROM (SELECT p.id_workflow,
                           p.id_inst_orig,
                           p.id_prof_requested,
                           i.id_parent             id_inst_parent,
                           rod.id_external_request,
                           rod.id_professional     id_prof_roda,
                           rod.institution_name    inst_name_roda,
                           rod.dt_create
                      FROM p1_external_request p
                      JOIN ref_orig_data rod
                        ON (p.id_external_request = rod.id_external_request)
                      JOIN institution i
                        ON (i.id_institution = p.id_inst_orig)
                     WHERE rod.id_external_request = p.id_external_request
                       AND p.id_external_request = i_id_ref) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_ref_orig_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_ORIG_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref_orig_data);
            RETURN FALSE;
    END get_referral_orig_data;

    /**
    * Gets referral comments (to be shown in referral detail)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Profile_template, functionality, category, flg_category and id_market  
    * @param   i_ref_row        Referral row
    * @param   o_ref_comments   Referral comments data
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2013
    */
    FUNCTION get_ref_comments
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_data    IN t_rec_prof_data,
        i_ref_row      IN p1_external_request%ROWTYPE,
        o_ref_comments OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params   VARCHAR2(1000 CHAR);
        l_flg_type ref_comments.flg_type%TYPE;
    
        CURSOR c_ref_comments
        (
            x_id_ref   ref_comments.id_external_request%TYPE,
            x_flg_type ref_comments.flg_type%TYPE
        ) IS
            SELECT rc.id_ref_comment,
                   rc.code_ref_comments,
                   rc.flg_status,
                   rc.id_professional,
                   rc.id_institution,
                   rc.dt_comment,
                   rc.dt_comment_canceled,
                   rc.dt_comment_outdated,
                   i.abbreviation,
                   i.code_institution
              FROM ref_comments rc
              JOIN institution i
                ON (i.id_institution = rc.id_institution)
             WHERE rc.id_external_request = x_id_ref
               AND rc.flg_type = x_flg_type
             ORDER BY dt_comment;
        l_ref_comments_row    c_ref_comments%ROWTYPE;
        l_read                BOOLEAN := FALSE;
        l_id_ref_comment_read ref_comments_read.id_ref_comment_read%TYPE;
        l_comments_available  VARCHAR2(1 CHAR);
    BEGIN
        l_params       := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_prof_data=' ||
                          pk_ref_utils.to_string(i_prof_data => i_prof_data) || ' i_id_ref=' ||
                          i_ref_row.id_external_request;
        g_error        := 'INIT get_ref_comments / ' || l_params;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error              := 'Call pk_ref_core.check_comm_enabled / ' || l_params;
        l_comments_available := pk_ref_core.check_comm_enabled(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_id_inst_orig => i_ref_row.id_inst_orig,
                                                               i_id_inst_dest => i_ref_row.id_inst_dest);
    
        l_params := l_params || ' l_comments_available=' || l_comments_available;
    
        g_error := 'IF i_prof_data.id_category / ' || l_params;
        IF i_prof_data.id_category = pk_ref_constant.g_cat_id_med
        THEN
            l_flg_type := pk_ref_constant.g_clinical_comment;
        ELSE
            l_flg_type := pk_ref_constant.g_administrative_comment;
        END IF;
    
        l_params := l_params || ' l_flg_type' || l_flg_type;
    
        g_error := 'Open c_ref_comments(' || i_ref_row.id_external_request || ',' || l_flg_type || ') / ' || l_params;
        OPEN c_ref_comments(i_ref_row.id_external_request, l_flg_type);
        FETCH c_ref_comments
            INTO l_ref_comments_row;
        g_found := c_ref_comments%FOUND;
    
        IF NOT g_found
        THEN
            CLOSE c_ref_comments;
            pk_types.open_my_cursor(o_ref_comments);
            RETURN TRUE;
        
        ELSE
            g_error := 'Delete tbl_temp / ' || l_params;
            DELETE tbl_temp;
        
            -- regista leituras do comentário mais recente
            -- apenas na primeira vez q acede ao pedido
        
            g_error  := 'Call pk_ref_api.set_ref_comments_read / ' || l_params;
            g_retval := pk_ref_api.set_ref_comments_read(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_ref_comment      => l_ref_comments_row.id_ref_comment,
                                                         i_flg_status          => l_ref_comments_row.flg_status,
                                                         i_flg_type            => l_flg_type,
                                                         i_read                => l_read,
                                                         o_id_ref_comment_read => l_id_ref_comment_read,
                                                         o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
            LOOP
            
                g_error := 'Insert into tbl_temp l_ref_comments_row values / ' || l_params;
                INSERT INTO tbl_temp
                    (num_1, vc_1, vc_2, num_2, num_3, dt_1, dt_2, dt_3, vc_3, vc_4)
                VALUES
                    (l_ref_comments_row.id_ref_comment,
                     l_ref_comments_row.code_ref_comments,
                     l_ref_comments_row.flg_status,
                     l_ref_comments_row.id_professional,
                     l_ref_comments_row.id_institution,
                     l_ref_comments_row.dt_comment,
                     l_ref_comments_row.dt_comment_canceled,
                     l_ref_comments_row.dt_comment_outdated,
                     l_ref_comments_row.abbreviation,
                     l_ref_comments_row.code_institution);
                FETCH c_ref_comments
                    INTO l_ref_comments_row;
                EXIT WHEN c_ref_comments%NOTFOUND;
            
                g_error  := 'Call pk_ref_api.set_ref_comments_read / ' || l_params;
                g_retval := pk_ref_api.set_ref_comments_read(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_ref_comment      => l_ref_comments_row.id_ref_comment,
                                                             i_flg_status          => l_ref_comments_row.flg_status,
                                                             i_flg_type            => l_flg_type,
                                                             i_read                => l_read,
                                                             o_id_ref_comment_read => l_id_ref_comment_read,
                                                             o_error               => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END LOOP;
            CLOSE c_ref_comments;
        END IF;
    
        g_error := 'OPEN o_ref_comments / ' || l_params;
        OPEN o_ref_comments FOR
            SELECT num_1 id,
                   pk_translation.get_translation_trs(vc_1) text,
                   vc_2 flg_status,
                   pk_sysdomain.get_domain(pk_ref_constant.g_ref_cmt_status_code, vc_2, i_lang) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, num_2) prof_name,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, num_2, num_3) prof_spec,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_1, i_prof) dt_insert,
                   num_3 id_institution,
                   nvl(vc_3, pk_translation.get_translation(i_lang, vc_4)) inst_abbreviation,
                   pk_translation.get_translation(i_lang, vc_4) inst_desc,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_2, i_prof) dt_canceled,
                   decode(vc_2,
                          pk_ref_constant.g_active_comment,
                          decode(i_prof.id, num_2, l_comments_available, pk_ref_constant.g_no),
                          pk_ref_constant.g_no) flg_cancel,
                   decode(vc_2,
                          pk_ref_constant.g_active_comment,
                          decode(i_prof.id, num_2, l_comments_available, pk_ref_constant.g_no),
                          pk_ref_constant.g_no) flg_edit,
                   pk_ref_constant.g_field_comments field_name
              FROM tbl_temp rc
             ORDER BY decode(vc_2, pk_ref_constant.g_active_comment, 10, pk_ref_constant.g_outdated_comment, 20, 30),
                      dt_1 DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_ref_comments);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REF_COMMENTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref_comments);
            RETURN FALSE;
    END get_ref_comments;

    /**
    * Gets referral field ranks (to order in flash and reports)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   o_error          An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-06-2014
    */
    FUNCTION get_fields_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_fields_rank OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_fields_rank';
    
        OPEN o_fields_rank FOR
            SELECT t.val field_name, t.rank field_rank
              FROM TABLE(CAST(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                       i_prof,
                                                                       pk_ref_constant.g_referral_fields_code,
                                                                       NULL) AS t_coll_values_domain_mkt)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_fields_rank);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FIELDS_RANK',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_fields_rank);
            RETURN FALSE;
    END get_fields_rank;

    /**
    * Get reason codes list
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_TYPE         Reason list type. {*} C - Cancelation; {*}  D - Medical Decline; {*}  R - Medical Refusal;
                                                {*} B - Administrative Decline; {*} T- transf. Resp.; {*} TR - transf resp decline
                                                {*} X - registrar cancellation/request cancellation.
    * @param   O_REASONS      Reasons data
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION get_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_type    IN p1_reason_code.flg_type%TYPE,
        i_mcdt    IN VARCHAR2 DEFAULT 'N',
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pt     profile_template.id_profile_template%TYPE;
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' TYPE=' || i_type || ' i_mcdt=' || i_mcdt;
        g_error  := 'Init get_reason_list / ' || l_params;
        l_pt     := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        OPEN o_reasons FOR
            SELECT r.id_reason_code,
                   pk_translation.get_translation(i_lang, r.code_reason) desc_reason,
                   r.flg_other,
                   r.flg_default
              FROM p1_reason_code r
              JOIN p1_reason_code_soft_inst rsi
                ON r.id_reason_code = rsi.id_reason_code
             WHERE r.flg_type = i_type
               AND r.flg_mcdt = nvl(i_mcdt, pk_ref_constant.g_no)
               AND r.flg_available = pk_ref_constant.g_yes
               AND r.flg_visible = pk_ref_constant.g_yes
               AND rsi.flg_available = pk_ref_constant.g_yes
               AND rsi.id_profile_template IN (l_pt, 0)
               AND rsi.id_software IN (i_prof.software, 0)
               AND rsi.id_institution IN (i_prof.institution, 0)
             ORDER BY r.rank, desc_reason;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REASON_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END get_reason_list;

    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_mcdt    IN VARCHAR2 DEFAULT 'N',
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pt     profile_template.id_profile_template%TYPE;
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_mcdt=' || i_mcdt;
        g_error  := 'Init get_reason_list / ' || l_params;
        l_pt     := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        OPEN o_reasons FOR
            SELECT r.id_reason_code id_reason,
                   pk_translation.get_translation(i_lang, r.code_reason) reason_desc,
                   r.flg_other notes_mandatory,
                   pk_alert_constant.g_no flg_error
              FROM p1_reason_code r
              JOIN p1_reason_code_soft_inst rsi
                ON r.id_reason_code = rsi.id_reason_code
             WHERE r.flg_type = pk_ref_constant.g_reason_code_c
               AND r.flg_mcdt = nvl(i_mcdt, pk_ref_constant.g_no)
               AND r.flg_available = pk_ref_constant.g_yes
               AND r.flg_visible = pk_ref_constant.g_yes
               AND rsi.flg_available = pk_ref_constant.g_yes
               AND rsi.id_profile_template IN (l_pt, 0)
               AND rsi.id_software IN (i_prof.software, 0)
               AND rsi.id_institution IN (i_prof.institution, 0)
             ORDER BY r.rank, reason_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CANCEL_REASON_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END get_cancel_reason_list;

    /**
    * Returns the options for the professional.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ext_req     Referral id
    * @param   i_dt_modified    Last modified date as provided by get_referral
    * @param   o_status         Options list
    * @param   o_flg_show       Show message
    * @param   o_msg_title      Message title
    * @param   o_msg            Message text
    * @param   o_button         Type of button to show with message
    * @param   o_error          An error message, set when return=false
    *
    * @value   o_flg_show       {*} 'Y' - show message {*} 'N' - do not show message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   25-10-2006
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
        l_exr_row      p1_external_request%ROWTYPE;
        l_prof_data    t_rec_prof_data;
        l_flg_status_n wf_status.id_status%TYPE;
    
        -- wf
        l_wf_transition_info table_varchar;
        l_tab_transitions    t_coll_wf_transition;
        l_params             VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ext_req || ' i_dt_modified=' ||
                    i_dt_modified;
        g_error  := 'Init get_status_options / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_flg_show := pk_ref_constant.g_no;
    
        g_error := 'Dates / ' || l_params || ' DT_LAST_INTERACTION=' ||
                   pk_date_utils.trunc_insttimezone(i_prof, l_exr_row.dt_last_interaction_tstz, 'SS');
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
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ' || l_params || ' DCS=' || l_exr_row.id_dep_clin_serv;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_exr_row.id_dep_clin_serv,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' FLG_STATUS=' || l_exr_row.flg_status || ' WF=' || l_exr_row.id_workflow || ' CAT=' ||
                    l_prof_data.id_category || ' ID_PROF_TEMPL=' || l_prof_data.id_profile_template || ' FUNC=' ||
                    l_prof_data.id_functionality || ' PARAM=' || pk_utils.to_string(l_wf_transition_info);
    
        l_flg_status_n := pk_ref_status.convert_status_n(l_exr_row.flg_status);
    
        g_error              := 'Calling pk_ref_core.init_param_tab / ' || l_params;
        l_wf_transition_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_ext_req            => l_exr_row.id_external_request,
                                                           i_id_patient         => l_exr_row.id_patient,
                                                           i_id_inst_orig       => l_exr_row.id_inst_orig,
                                                           i_id_inst_dest       => l_exr_row.id_inst_dest,
                                                           i_id_dep_clin_serv   => l_exr_row.id_dep_clin_serv,
                                                           i_id_speciality      => l_exr_row.id_speciality,
                                                           i_flg_type           => l_exr_row.flg_type,
                                                           i_decision_urg_level => l_exr_row.decision_urg_level,
                                                           i_id_prof_requested  => l_exr_row.id_prof_requested,
                                                           i_id_prof_redirected => l_exr_row.id_prof_redirected,
                                                           i_id_prof_status     => l_exr_row.id_prof_status,
                                                           i_external_sys       => l_exr_row.id_external_sys,
                                                           i_flg_status         => l_exr_row.flg_status);
    
        -- getting available transitions
        g_error  := 'Calling PK_WORKFLOW.GET_TRANSITIONS / ' || l_params;
        g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => l_exr_row.id_workflow,
                                                i_id_status_begin     => l_flg_status_n,
                                                i_id_category         => l_prof_data.id_category,
                                                i_id_profile_template => l_prof_data.id_profile_template,
                                                i_id_functionality    => l_prof_data.id_functionality,
                                                i_param               => l_wf_transition_info,
                                                i_flg_auto_transition => pk_ref_constant.g_no, -- non-automatic transitions
                                                o_transitions         => l_tab_transitions,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_status / ' || l_params;
        OPEN o_status FOR
            SELECT t.id_workflow,
                   l_exr_row.flg_status status_begin,
                   pk_ref_status.convert_status_v(t.id_status_end) status_end,
                   t.icon,
                   t.desc_transition label,
                   t.rank,
                   pk_ref_constant.get_action_name(t.id_workflow_action) action,
                   t.flg_visible
              FROM TABLE(CAST(l_tab_transitions AS t_coll_wf_transition)) t
             WHERE t.flg_visible = pk_ref_constant.g_yes
             ORDER BY rank;
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_STATUS_OPTIONS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_status_options;

    /**
    * Get Referral list
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_patient       Patient id. Null for all patients
    * @param   i_filter        Filter to apply. Depends on button selected.     
    * @param   i_type          Referral type
    * @param   o_ref_list      Referral data    
    * @param   o_error         An error message, set when return=false
    *
    * @value   i_type          {*} (C)onsultation {*} (A)nalysis {*} (I)mage {*} (E)xam  
    *                          {*} (P)rocedure {*} (M)fr {*} Null for all types
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_filter   IN VARCHAR2,
        i_type     IN p1_external_request.flg_type%TYPE,
        o_ref_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params  VARCHAR2(1000 CHAR);
        l_my_data t_rec_prof_data;
    
        l_var_desc        table_varchar := table_varchar();
        l_var_val         table_varchar := table_varchar();
        l_sql             CLOB;
        l_sql_v           CLOB;
        l_order_by        CLOB;
        l_ref_list_query  CLOB;
        l_doc_can_receive VARCHAR2(1 CHAR);
    
        l_img_receive_ko sys_domain.img_name%TYPE;
        l_img_receive_ok sys_domain.img_name%TYPE;
    
        l_columns_tab table_varchar;
    
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    
        l_coll_dt_last_comment CLOB;
        l_coll_comment_count   CLOB;
        l_coll_prof_comment    CLOB;
        l_coll_inst_comment    CLOB;
    BEGIN
        ----------------------
        -- INIT
        ----------------------     
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_filter=' || i_filter ||
                    ' i_type=' || i_type;
        g_error  := 'Init get_referral_list / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        ----------------------
        -- CONFIG
        ----------------------     
        -- sys_messages    
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_common_m19,
                                        pk_ref_constant.g_sm_common_m20,
                                        pk_ref_constant.g_sm_common_t003,
                                        pk_ref_constant.g_sm_ref_devstatus_notes);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error          := 'Call pk_sysdomain.get_img / ' || l_params;
        l_img_receive_ko := pk_sysdomain.get_img(i_lang, 'DOC_EXTERNAL.FLG_RECEIVED', pk_ref_constant.g_no);
        l_img_receive_ok := pk_sysdomain.get_img(i_lang, 'DOC_EXTERNAL.FLG_RECEIVED', pk_ref_constant.g_yes);
    
        ----------------------
        -- FUNC
        ----------------------
    
        IF i_patient IS NULL
        THEN
            l_var_desc.extend(4);
            l_var_val.extend(4);
        ELSE
            l_var_desc.extend(5);
            l_var_val.extend(5);
        
            l_var_desc(5) := '@PATIENT';
            l_var_val(5) := to_char(i_patient);
        END IF;
    
        l_var_desc(1) := '@LANG';
        l_var_val(1) := to_char(i_lang);
    
        l_var_desc(2) := '@PROFESSIONAL';
        l_var_val(2) := to_char(i_prof.id);
    
        l_var_desc(3) := '@INSTITUTION';
        l_var_val(3) := to_char(i_prof.institution);
    
        l_var_desc(4) := '@SOFTWARE';
        l_var_val(4) := to_char(i_prof.software);
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error           := 'Get DOC_CAN_RECEIVE value / ' || l_params;
        l_doc_can_receive := pk_doc.get_config('DOC_CAN_RECEIVE', i_prof, to_char(l_my_data.id_profile_template), NULL);
    
        -------------------------------------------
        -- query structure
        --   SELECT col1, col2, col3...
        --   FROM (
        --          SELECT d.*, sts_info
        --          FROM (
        --               SELECT * 
        --               FROM v_p1_grid v
        --               WHERE ...
        --               ) d                          
        --        ) v
        --   ORDER BY v.sts_info.id_status
        -------------------------------------------
    
        g_error  := 'Call pk_ref_core_internal.get_grid_sql / ' || l_params;
        g_retval := pk_ref_core_internal.get_grid_sql(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_var_desc => l_var_desc,
                                                      i_var_val  => l_var_val,
                                                      i_filter   => i_filter,
                                                      o_sql      => l_sql_v, -- data from v_p1_grid 
                                                      o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_my_data.id_category = pk_ref_constant.g_cat_id_adm
        THEN
            l_coll_dt_last_comment := 'd.dt_adm_last_comment';
            l_coll_comment_count   := 'd.nr_adm_comments';
            l_coll_prof_comment    := 'd.id_prof_adm_comment';
            l_coll_inst_comment    := 'd.id_inst_adm_comment';
        ELSE
            l_coll_dt_last_comment := 'd.dt_clin_last_comment';
            l_coll_comment_count   := 'd.nr_clin_comments';
            l_coll_prof_comment    := 'd.id_prof_clin_comment';
            l_coll_inst_comment    := 'd.id_inst_clin_comment';
        END IF;
        -- adding possible order_by columns to the query: flg_attach_order_by, sts_info, observations
        -- the no_merge hint avoids merging this select with the outer select, thus preventing functions to be executed more than once
        g_error := 'l_sql / ' || l_params || ' / ID_PRF_TEMPL=' || l_my_data.id_profile_template || ' CAT=' ||
                   l_my_data.flg_category;
        l_sql   := to_clob('SELECT /*+ no_merge*/ d.*,');
    
        -- adding status info
        l_sql := l_sql ||
                 to_clob(' pk_workflow.get_status_info(' || i_lang || ',
                                          profissional(' || i_prof.id || ',' ||
                         i_prof.institution || ',' || i_prof.software ||
                         '),                                           
                                           nvl(d.id_workflow,' || pk_ref_constant.g_wf_pcc_hosp || '),
                                           pk_ref_status.convert_status_n(d.flg_status),
                                           ' || l_my_data.id_category || ',
                                           ' || l_my_data.id_profile_template || ',
                                           (SELECT pk_ref_core.get_prof_func(' || i_lang ||
                         ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                         '), d.id_dep_clin_serv)
                                                    FROM dual),
                                           table_varchar(to_char(d.id_external_request),
                                                         to_char(d.id_patient),
                                                         to_char(d.id_inst_orig),
                                                         to_char(d.id_inst_dest),
                                                         to_char(d.id_dep_clin_serv),
                                                         to_char(d.id_speciality),
                                                         to_char(d.flg_type),
                                                         to_char(d.decision_urg_level),
                                                         to_char(d.id_prof_requested),
                                                         to_char(d.id_prof_redirected),
                                                         to_char(d.id_prof_status),
                                                         to_char(d.id_external_sys),
                                                         ''' || pk_ref_constant.g_location_grid || ''',
                                                         NULL,
                                                         NULL)) sts_info, ' ||
                         
                         'pk_ref_core.get_ref_comments_info(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                         i_prof.institution || ',' || i_prof.software || ') , t_rec_prof_data(' ||
                         l_my_data.id_profile_template || ', ' || l_my_data.id_functionality || ', ' ||
                         l_my_data.id_category || ', ''' || l_my_data.flg_category || ''', ' || l_my_data.id_market ||
                         '), d.id_external_request, d.id_workflow, ' || 'd.id_prof_requested, ' || 'd.id_inst_orig, ' ||
                         'd.id_inst_dest, ' || 'd.id_dep_clin_serv, ' || l_coll_dt_last_comment || ', ' ||
                         l_coll_comment_count || ', ' || l_coll_prof_comment || ', ' || l_coll_inst_comment ||
                         ') rc_info');
    
        l_sql := l_sql || to_clob(' FROM (' || l_sql_v || ') d ');
    
        g_error          := ' l_ref_list_query /' || l_params || ' / id_prf_templ =' || l_my_data.id_profile_template ||
                            ' cat =' || l_my_data.flg_category;
        l_ref_list_query := to_clob('
                    SELECT /*+OPT_ESTIMATE(TABLE, t,SCALE_ROWS=0.0000000001)*/' ||
                                    ' t.id_external_request id_p1,' || -- id_p1
                                    ' t.num_req,' || -- num_req
                                    ' lpad(t.num_req, 15, ''0'') num_req_to_sort, ' || --num_req_to_sort 
                                    -- flg_attach_to_sort
                                    ' pk_ref_list.get_flg_attach_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                                    i_prof.institution || ',' || i_prof.software || '), ''' || l_doc_can_receive ||
                                    ''', t.nr_clinical_doc, t.flg_sent_by, t.flg_received) flg_attach_to_sort,');
        -- add columns 
        l_columns_tab := table_varchar(pk_ref_constant.g_col_dt_p1,
                                       pk_ref_constant.g_col_pat_name,
                                       pk_ref_constant.g_col_pat_ndo,
                                       pk_ref_constant.g_col_pat_nd_icon,
                                       pk_ref_constant.g_col_pat_gender,
                                       pk_ref_constant.g_col_pat_age,
                                       pk_ref_constant.g_col_pat_photo,
                                       pk_ref_constant.g_col_id_prof_req,
                                       pk_ref_constant.g_col_prof_req_name,
                                       --pk_ref_constant.g_col_priority_icon,
                                       pk_ref_constant.g_col_priority_info,
                                       pk_ref_constant.g_col_priority_desc,
                                       pk_ref_constant.g_col_priority_icon,
                                       pk_ref_constant.g_col_priority_sort,
                                       pk_ref_constant.g_col_type_icon,
                                       pk_ref_constant.g_col_inst_orig_name,
                                       pk_ref_constant.g_col_inst_dest_name,
                                       pk_ref_constant.g_col_p1_spec_name,
                                       pk_ref_constant.g_col_clin_srv_name,
                                       pk_ref_constant.g_col_dt_sch_millis,
                                       pk_ref_constant.g_col_id_prof_schedule,
                                       pk_ref_constant.g_col_prof_triage_name,
                                       pk_ref_constant.g_col_observations,
                                       pk_ref_constant.g_col_flg_attach,
                                       pk_ref_constant.g_col_dt_last_interaction,
                                       pk_ref_constant.g_col_status_info,
                                       pk_ref_constant.g_col_can_cancel,
                                       pk_ref_constant.g_col_can_approve,
                                       pk_ref_constant.g_col_desc_dec_urg_level,
                                       pk_ref_constant.g_col_id_schedule_ext,
                                       pk_ref_constant.g_col_id_content,
                                       pk_ref_constant.g_col_reason_desc,
                                       pk_ref_constant.g_col_is_task_complet,
                                       pk_ref_constant.g_col_flg_match_redirect,
                                       pk_ref_constant.g_col_can_sent);
    
        l_ref_list_query := l_ref_list_query ||
                            pk_ref_core_internal.get_column_sql(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_prof_data       => l_my_data,
                                                                i_column_name_tab => l_columns_tab);
    
        -- adding more columns
        l_ref_list_query := l_ref_list_query ||
                            to_clob(', t.id_patient id_patient, ' || -- id_patient
                                    -- pat_name_to_sort
                                    ' pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software ||
                                    '), t.id_patient, NULL) pat_name_to_sort,' || ' t.flg_type,' || -- flg_type
                                    ' t.flg_status,' || -- flg_status
                                    ' t.sts_info.desc_status flg_status_desc,' || -- flg_status_desc
                                    ' t.id_schedule,' || -- id_schedule
                                    ' t.dep_abbreviation dest_department,' || -- dest_department                                    
                                    ' t.id_dep_clin_serv,' || -- id_dep_clin_serv                                    
                                    '''' || l_doc_can_receive || ''' can_receive,' || -- Processa recepcao de documentos?
                                    -- Tem anexos com valor em flg_sent_by?                          
                                    ' decode(' || '''' || l_doc_can_receive || ''', ''' || pk_ref_constant.g_yes ||
                                    ''', decode(t.flg_sent_by, ''' || pk_ref_constant.g_yes || ''', ''' ||
                                    pk_ref_constant.g_yes || ''', ''' || pk_ref_constant.g_no || '''), ''' ||
                                    pk_ref_constant.g_no || ''') flg_sent_by,' ||
                                    -- Tem anexos com valor em flg_sent_by e por receber?       
                                    ' decode(' || '''' || l_doc_can_receive || ''', ''' || pk_ref_constant.g_yes ||
                                    ''', decode(t.flg_received, ''' || pk_ref_constant.g_yes || ''', ''' ||
                                    pk_ref_constant.g_yes || ''', ''' || pk_ref_constant.g_no || '''), ''' ||
                                    pk_ref_constant.g_no || ''') flg_received,' || '''' || l_img_receive_ko ||
                                    ''' img_receive_ko,' || -- img_receive_ko
                                    '''' || l_img_receive_ok || ''' img_receive_ok,' || -- img_receive_ok
                                    ' t.id_match,' || -- id_match 
                                    '''' || l_desc_message_ibt(pk_ref_constant.g_sm_common_m19) || ''' desc_day,' || -- desc_day
                                    '''' || l_desc_message_ibt(pk_ref_constant.g_sm_common_m20) || ''' desc_days,' || -- desc_days
                                    -- date_field
                                    ' pk_date_utils.date_send_tsz(' || i_lang || ', dt_status_tstz, profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                                    ')) date_field,' ||
                                    -- dt_server
                                    ' pk_date_utils.date_send_tsz(' || i_lang || ', current_timestamp, profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                                    ')) dt_server,' || -- 
                                    ' t.id_workflow,' || -- id_workflow
                                    --' decode(t.id_workflow, ' || pk_ref_constant.g_wf_x_hosp ||', NULL, t.id_inst_orig) id_inst_orig,' || -- id_inst_orig
                                    ' t.id_inst_orig,' || -- id_inst_orig
                                    ' t.id_inst_dest,' || -- id_inst_dest
                                    ' t.sts_info.icon status_icon,' || -- status_icon
                                    ' t.sts_info.color status_color,' || -- status_color
                                    ' lpad(t.sts_info.rank, 6, ''0'') status_rank,' || -- status_rank
                                    ' t.sts_info.flg_update flg_editable,' || -- flg_editable
                                    '''' || l_desc_message_ibt(pk_ref_constant.g_sm_ref_devstatus_notes) ||
                                    ''' title_notes, ' || -- title_notes
                                    ' t.rc_info.val rc_val, ' || -- comments number
                                    ' t.rc_info.bg_color rc_bg_color, ' || -- comments bg color
                                    ' t.rc_info.fg_color rc_fg_color, ' || -- comments fg color
                                    ' t.rc_info.shortcut rc_shortcut, ' || -- comments shortcut   
                                    ' t.rc_info.status rc_status, ' || -- comments status                                       
                                    ' pk_ref_core.get_documents_shortcut(' || i_lang || ',profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || ')) DOC_SHORTCUT ' || -- document shortcut                                                                                                                                                
                                    '                                    
                      FROM (' || l_sql || ') t ');
    
        IF i_type IS NOT NULL
        THEN
            l_ref_list_query := l_ref_list_query || to_clob('
                     WHERE t.flg_type = ''' || i_type || '''');
        END IF;
    
        -- adding order by clause
        g_error    := 'l_order_by / ' || l_params || ' / id_prf_templ = ' || l_my_data.id_profile_template || ' cat= ' ||
                      l_my_data.flg_category;
        l_order_by := to_clob('pk_ref_status.get_flash_status_order(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                              i_prof.institution || ', ' || i_prof.software ||
                              '), t.sts_info.color,  t.sts_info.rank, t.dt_status_tstz) ');
    
        l_ref_list_query := l_ref_list_query || to_clob(' ORDER BY ' || l_order_by);
    
        -- print
        pk_alertlog.log_error(l_ref_list_query);
    
        g_error := 'OPEN o_ref_list / ' || l_params || ' / ID_PRF_TEMPL=' || l_my_data.id_profile_template || ' CAT=' ||
                   l_my_data.flg_category;
        OPEN o_ref_list FOR l_ref_list_query;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_ref_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := g_error || '(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ') ';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref_list);
            RETURN FALSE;
    END get_referral_list;

    /**
    * Get referral types: appointment, analysis, exam or intervention
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_TYPE avaible request types on REFERAL
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   2008/02/11
    */
    FUNCTION get_referral_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_list pk_types.cursor_type;
    
        l_desc_tab table_varchar;
        l_val_tab  table_varchar;
        l_img_tab  table_varchar;
        l_rank_tab table_varchar;
    BEGIN
    
        IF NOT pk_sysdomain.get_values_domain(i_code_dom      => pk_ref_constant.g_p1_exr_flg_type,
                                              i_lang          => i_lang,
                                              i_vals_included => NULL,
                                              i_vals_excluded => NULL,
                                              o_error         => o_error,
                                              o_data          => l_list)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_list BULK COLLECT';
        FETCH l_list BULK COLLECT
            INTO l_desc_tab, l_val_tab, l_img_tab, l_rank_tab;
        CLOSE l_list;
    
        OPEN o_type FOR
            SELECT s.desc_val label, s.val data, s.img_name icon
              FROM sys_domain s
             WHERE s.code_domain = pk_ref_constant.g_p1_exr_flg_type
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.flg_available = pk_ref_constant.g_yes
               AND s.id_language = i_lang
                  -- check if there is this kind of referral in the institution
               AND s.val IN (SELECT di.flg_type
                               FROM p1_dest_institution di
                              WHERE di.id_inst_orig = i_prof.institution)
             ORDER BY s.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_TYPE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_type);
            RETURN FALSE;
    END get_referral_type;

    /**
    * Get referal types: Internal or external
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_TYPE_ext avaible external REFERAL
    * @param   O_TYPE_int avaible REFERAL
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.5.0.6
    * @since   2009/08/17
    */
    FUNCTION get_referral_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_type_ext OUT pk_types.cursor_type,
        o_type_int OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_external sys_message.desc_message%TYPE;
        l_internal sys_message.desc_message%TYPE;
    BEGIN
    
        g_error    := 'Init get_referral_type';
        l_external := pk_message.get_message(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_code_mess => pk_ref_constant.g_sm_ref_common_t001);
        l_internal := pk_message.get_message(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_code_mess => pk_ref_constant.g_sm_ref_common_t002);
    
        g_error := 'Open o_type_ext';
        OPEN o_type_ext FOR
            SELECT l_external label,
                   decode((SELECT id_inst_orig
                            FROM p1_dest_institution
                           WHERE id_inst_orig = i_prof.institution
                             AND id_inst_dest <> i_prof.institution
                             AND rownum = 1),
                          i_prof.institution,
                          pk_ref_constant.g_yes,
                          pk_ref_constant.g_no) flg_active
              FROM dual;
    
        g_error := 'Open o_type_int';
        OPEN o_type_int FOR
            SELECT l_internal label,
                   decode((SELECT id_inst_orig
                            FROM p1_dest_institution
                           WHERE id_inst_orig = i_prof.institution
                             AND id_inst_dest = i_prof.institution
                             AND rownum = 1),
                          i_prof.institution,
                          pk_ref_constant.g_yes,
                          pk_ref_constant.g_no) flg_active
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_TYPE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_type_ext);
            pk_types.open_my_cursor(o_type_int);
            RETURN FALSE;
    END get_referral_type;

    /**
    * Get patient social attributes
    * Used by QueryFlashService.
    * @param   i_lang language associated to the professional executing the request
    * @param   i_id_pat Patient id
    * @param   i_prof professional, institution and software ids
    * @param   o_pat patient attributes
    * @param   o_sns "Sistema Nacional de Saude" data
    * @param   o_seq_num external system id for this patient (available if has match)    
    * @param   o_photo url for patient photo    
    * @param   o_id patient id document data (number, expiration date, etc)  
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION get_pat_soc_att
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_pat     OUT pk_types.cursor_type,
        o_sns     OUT pk_types.cursor_type,
        o_seq_num OUT p1_match.sequential_number%TYPE,
        o_photo   OUT VARCHAR2,
        o_id      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_match IS
            SELECT sequential_number
              FROM p1_match
             WHERE id_patient = i_id_pat
               AND id_institution = i_prof.institution
                  -- js, 2007-07-31 - Rematch
               AND flg_status = pk_ref_constant.g_match_status_a;
    
        l_sc_multi_instit   VARCHAR2(1 CHAR);
        l_sns_code_sonho    NUMBER;
        l_health_plan_other VARCHAR2(30 CHAR);
        l_id_health_plan    NUMBER;
        l_id_content_hp     health_plan.id_content%TYPE;
        l_id_bi_doc_type    NUMBER;
    BEGIN
        ----------------------
        -- CONFIG
        ----------------------
        g_error             := 'Calling pk_sysconfig.get_config for ' || pk_ref_constant.g_sc_multi_institution ||
                               ' / i_patient=' || i_id_pat;
        l_sc_multi_instit   := pk_sysconfig.get_config(pk_ref_constant.g_sc_multi_institution, i_prof);
        l_sns_code_sonho    := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                     i_id_sys_config => pk_ref_constant.g_sc_sns_code_sonho));
        l_health_plan_other := pk_ref_utils.get_health_plan_other(i_prof => i_prof);
        l_id_health_plan    := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
        l_id_bi_doc_type    := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                     i_id_sys_config => pk_ref_constant.g_sc_bi_doc_type));
    
        ----------------------
        -- FUNC
        ----------------------
    
        g_error  := 'Call pk_ref_core_internal.get_pat_soc_att / ID_PAT=' || i_id_pat;
        g_retval := pk_ref_core_internal.get_pat_soc_att(i_lang   => i_lang,
                                                         i_id_pat => i_id_pat,
                                                         i_prof   => i_prof,
                                                         o_pat    => o_pat,
                                                         o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'GET C_SNS';
        OPEN o_sns FOR
            SELECT t.id_health_plan,
                   t.num_health_plan num,
                   decode(t.desc_health_plan,
                          NULL,
                          pk_translation.get_translation(i_lang, t.code_health_plan),
                          decode(l_health_plan_other,
                                 t.desc_health_plan,
                                 pk_translation.get_translation(i_lang, t.code_health_plan))) name,
                   l_sns_code_sonho sns_code_sonho
              FROM (SELECT hp.id_health_plan, php.num_health_plan, php.desc_health_plan, hp.code_health_plan
                      FROM pat_health_plan php
                      JOIN health_plan hp
                        ON (php.id_health_plan = hp.id_health_plan)
                     WHERE php.id_patient = i_id_pat
                       AND php.flg_status = pk_ref_constant.g_active
                       AND ((php.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                           (php.id_institution = i_prof.institution AND l_sc_multi_instit = pk_ref_constant.g_no))
                       AND hp.id_health_plan = l_id_health_plan) t;
    
        g_error := 'OPEN C_MATCH';
        OPEN c_match;
        FETCH c_match
            INTO o_seq_num;
        g_found := c_match%FOUND;
        CLOSE c_match;
    
        o_photo := pk_patphoto.get_pat_foto(i_id_pat, i_prof);
    
        g_error := 'OPEN O_ID';
        OPEN o_id FOR
            SELECT t.id_doc_type,
                   pk_translation.get_translation(i_lang, 'DOC_TYPE.CODE_DOC_TYPE.' || t.id_doc_type) desc_doc_type,
                   t.num_doc,
                   t.dt_emited,
                   t.dt_expire
              FROM (SELECT de.id_doc_type, de.num_doc, de.dt_emited, de.dt_expire
                      FROM doc_external de
                     WHERE de.id_patient = i_id_pat
                       AND de.id_doc_type = l_id_bi_doc_type
                       AND de.flg_status = pk_ref_constant.g_active) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_sns);
            pk_types.open_my_cursor(o_id);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_SOC_ATT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_sns);
            pk_types.open_my_cursor(o_id);
            RETURN FALSE;
    END get_pat_soc_att;

    /**
    * Get country attributes
    * Used by QueryFlashService.java
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_country country id
    * @param   o_country cursor
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   12-02-2008
    */
    FUNCTION get_country_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_country IN country.id_country%TYPE,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'open o_country / i_country=' || i_country;
        OPEN o_country FOR
            SELECT t.id_country,
                   pk_translation.get_translation(i_lang, t.code_country) country_name,
                   pk_translation.get_translation(i_lang, t.code_nationality) nationality,
                   t.alpha2_code
              FROM (SELECT c.id_country, c.code_country, c.code_nationality, c.alpha2_code
                      FROM country c
                     WHERE c.id_country = i_country
                       AND c.flg_available = pk_ref_constant.g_yes) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_COUNTRY_DATA',
                                                     o_error    => o_error);
    END get_country_data;

    /**
    * Return available tasks
    *
    * @param   i_lang language
    * @param   i_type task type. For (S)cheduling or (C)onsultation
    * @param   o_tasks returned tasks for type S
    * @param   o_info returned tasks for type C
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S 
    * @version 1.0
    * @since
    */
    FUNCTION get_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_type  IN VARCHAR2,
        o_tasks OUT pk_types.cursor_type,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_TASKS / i_type=' || i_type;
        OPEN o_tasks FOR
            SELECT id_task, pk_translation.get_translation(i_lang, code_task) desc_task
              FROM p1_task
             WHERE flg_type = i_type
               AND flg_purpose = 'S'
             ORDER BY rank, desc_task;
    
        g_error := 'OPEN O_INFO / i_type=' || i_type;
        OPEN o_info FOR
            SELECT id_task, pk_translation.get_translation(i_lang, code_task) desc_task
              FROM p1_task
             WHERE flg_type = i_type
               AND flg_purpose = 'C'
             ORDER BY rank, desc_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TASKS',
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(o_tasks);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_tasks;

    /**
    * Gets the clinical services that have at least one professional associated
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   o_clin_serv       Clinical services data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_clin_serv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        OPEN o_clin_serv FOR
            SELECT DISTINCT t.id_clinical_service,
                            pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service
              FROM (SELECT cs.id_clinical_service, cs.code_clinical_service
                      FROM dep_clin_serv dcs
                      JOIN department d
                        ON d.id_department = dcs.id_department
                      JOIN clinical_service cs
                        ON (cs.id_clinical_service = dcs.id_clinical_service)
                     WHERE dcs.flg_available = pk_ref_constant.g_yes
                       AND cs.flg_available = pk_ref_constant.g_yes
                       AND d.flg_available = pk_ref_constant.g_yes
                       AND d.id_institution = i_prof.institution
                       AND EXISTS
                     (SELECT 1 -- exists at least one professional (of this profile_template) related to this dep_clin_serv
                              FROM prof_dep_clin_serv pdcs
                              JOIN prof_soft_inst psi
                                ON (pdcs.id_professional = psi.id_professional)
                              JOIN prof_profile_template ppt
                                ON (pdcs.id_professional = ppt.id_professional AND
                                   ppt.id_institution = psi.id_institution AND ppt.id_software = psi.id_software)
                             WHERE d.id_institution = psi.id_institution
                               AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                               AND psi.id_software = i_prof.software
                               AND ppt.id_profile_template = l_id_profile_template
                               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, d.id_institution) =
                                   pk_ref_constant.g_yes)) t
             ORDER BY desc_clinical_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_clin_serv);
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_clin_serv);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CLIN_SERV',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clin_serv;

    /**
    * Gets the professionals related to this clinical service
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_clinical_service Clinical service identifier 
    * @param   i_id_prof_except_tab  Array of professional identifiers that must not be returned (exceptions)
    * @param   o_prof                Professional data
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_for_clin_serv
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_prof_except_tab  IN table_number,
        o_prof                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_prof_except_tab  table_number;
    BEGIN
    
        g_error               := ' CALL pk_prof_utils.get_prof_profile_template / i_id_clinical_service = ' ||
                                 i_id_clinical_service;
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        IF i_id_prof_except_tab IS NULL
           OR i_id_prof_except_tab.count = 0
        THEN
            l_id_prof_except_tab := table_number();
        ELSE
            l_id_prof_except_tab := i_id_prof_except_tab;
        END IF;
    
        OPEN o_prof FOR
            SELECT DISTINCT t.id_clinical_service,
                            t.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name,
                            pk_profphoto.get_prof_photo(profissional(t.id_professional, t.id_institution, t.id_software)) photo
              FROM (SELECT dcs.id_clinical_service, psi.id_professional, psi.id_institution, psi.id_software
                      FROM dep_clin_serv dcs
                      JOIN department d
                        ON d.id_department = dcs.id_department
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      JOIN prof_dep_clin_serv pdcs
                        ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN prof_soft_inst psi
                        ON (pdcs.id_professional = psi.id_professional AND d.id_institution = psi.id_institution)
                      JOIN prof_profile_template ppt
                        ON (pdcs.id_professional = ppt.id_professional AND ppt.id_institution = psi.id_institution AND
                           ppt.id_software = psi.id_software)
                     WHERE dcs.flg_available = pk_ref_constant.g_yes
                       AND cs.flg_available = pk_ref_constant.g_yes
                       AND d.flg_available = pk_ref_constant.g_yes
                       AND cs.id_clinical_service = i_id_clinical_service
                       AND d.id_institution = i_prof.institution
                       AND psi.id_software = i_prof.software
                       AND ppt.id_profile_template = l_id_profile_template
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, d.id_institution) =
                           pk_ref_constant.g_yes
                       AND NOT EXISTS (SELECT 1 -- professionals exception
                              FROM TABLE(CAST(l_id_prof_except_tab AS table_number)) tt
                             WHERE tt.column_value = psi.id_professional)) t
             ORDER BY prof_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_prof);
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_FOR_CLIN_SERV',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_for_clin_serv;

    /**
    * Gets field 'Cobertura' 
    * This function will be rebuild or removed in the future.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   o_value    Values to populate multichoice
    * @param   o_error    An error message, set when return=false 
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-10-2010
    */
    FUNCTION get_cover
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_value OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_cover';
        OPEN o_value FOR
            SELECT pk_message.get_message(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_code_mess => pk_ref_constant.g_sm_ref_detail_ges) val
              FROM dual
            UNION ALL
            SELECT pk_message.get_message(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_code_mess => pk_ref_constant.g_sm_ref_detail_no_ges) val
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COVER',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END get_cover;

    /*
    * Return referral depatments (just for internal referrals!!)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids 
    * @param   I_PAT           Patient id
    * @param   i_external_sys   External system identifier
    * @param   O_DEP            Department info    
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009 
    */
    FUNCTION get_internal_dep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_dep          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_gender             patient.gender%TYPE;
        l_age                PLS_INTEGER;
        l_pat_info           pk_types.cursor_type;
        l_int_wf_restriction sys_config.value%TYPE;
        l_params             VARCHAR2(1000 CHAR);
    BEGIN
        l_params             := 'i_pat=' || i_pat || ' i_external_sys=' || i_external_sys;
        g_error              := 'Init get_internal_dep / ' || l_params;
        l_int_wf_restriction := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_internal_restriction,
                                                        i_prof    => i_prof);
    
        g_retval := pk_ref_core.get_pat_info(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => i_pat,
                                             o_info    => l_pat_info,
                                             o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_pat_info / ' || l_params;
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error := 'OPEN o_dep / ' || l_params || ' / GENDER=' || l_gender || ' AGE=' || l_age || ' ID_INSTITUTION=' ||
                   i_prof.institution || ' l_int_wf_restriction=' || l_int_wf_restriction;
        OPEN o_dep FOR
            SELECT DISTINCT t.id_department, -- this distinct is needed because there may be several id_specialities associated to the same id_dep_clin_serv
                            t.dep_abbr,
                            pk_translation.get_translation(i_lang, t.code_department) desc_department
              FROM (SELECT v.id_department, v.dep_abbr, v.code_department
                      FROM v_ref_internal v
                     WHERE v.flg_type = pk_ref_constant.g_p1_type_c
                       AND v.id_institution = i_prof.institution
                       AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND ((l_gender IS NOT NULL AND
                           nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, l_gender)) OR
                           l_gender IS NULL OR l_gender = pk_ref_constant.g_gender_i)
                       AND (nvl(l_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(l_age, 0)) OR
                           nvl(l_age, 0) = 0)
                          -- ALERT-208584 - if professional is associated to this dep_clin_serv, then he cannot create the internal referral (cannot return this dep_clin_serv)
                       AND (l_int_wf_restriction = pk_ref_constant.g_no OR
                           (l_int_wf_restriction = pk_ref_constant.g_yes AND pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                                                                                i_dcs  => v.id_dep_clin_serv,
                                                                                                                i_func => table_number(pk_ref_constant.g_func_d,
                                                                                                                                       pk_ref_constant.g_func_t,
                                                                                                                                       pk_ref_constant.g_func_c)) =
                           pk_ref_constant.g_no))) t
             ORDER BY desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INTERNAL_DEP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
    END get_internal_dep;

    /**
    * Return referral clinical services (just for internal referrals)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface 
    * @param   i_pat            Patient id, to filter by gender and age
    * @param   i_external_sys   External system identifier
    * @param   O_CS             Clinical Service info    
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009 
    */
    FUNCTION get_internal_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_dep          IN department.id_department%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cs           OUT t_cur_ref_dcs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_gender   patient.gender%TYPE;
        l_age      PLS_INTEGER;
        l_pat_info pk_types.cursor_type;
        l_params   VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_dep=' || i_dep ||
                    ' i_external_sys=' || i_external_sys;
        g_error  := 'Init get_internal_spec / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_core.get_pat_info(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => i_pat,
                                             o_info    => l_pat_info,
                                             o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_pat_info / ' || l_params;
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error  := ' CALL get_internal_spec / ' || l_params;
        g_retval := get_internal_spec(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_dep          => i_dep,
                                      i_pat_age      => l_age,
                                      i_pat_gender   => l_gender,
                                      i_external_sys => i_external_sys,
                                      o_cs           => o_cs,
                                      o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => ' get_internal_spec ',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cs);
            RETURN FALSE;
    END get_internal_spec;

    /*
    * Return referral clinical services (just for internal referrals)
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface 
    * @param   i_pat_age           Patient age
    * @param   i_pat_gender        Patient gender
    * @param   i_external_sys      External system identifier
    * @param   o_cs                Clinical Service info    
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-05-2013
    */
    FUNCTION get_internal_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dep          IN department.id_department%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cs           OUT t_cur_ref_dcs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_int_wf_restriction sys_config.value%TYPE;
        l_params             VARCHAR2(1000 CHAR);
    BEGIN
        l_params := ' i_prof = ' || pk_utils.to_string(i_prof) || ' i_pat_age = ' || i_pat_age || ' i_pat_gender = ' ||
                    i_pat_gender || ' i_dep = ' || i_dep || ' i_external_sys = ' || i_external_sys;
        g_error  := ' init get_internal_spec / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_int_wf_restriction := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_internal_restriction,
                                                        i_prof    => i_prof);
    
        g_error := ' OPEN o_cs / gender = ' || i_pat_gender || ' age = ' || i_pat_age || ' l_int_wf_restriction = ' ||
                   l_int_wf_restriction || ' / ' || l_params;
        OPEN o_cs FOR
            SELECT DISTINCT t.id_dep_clin_serv, -- distinct because there may be several id_specialities with the same dep_clin_serv
                            t.id_clinical_service,
                            pk_translation.get_translation(i_lang, t.code_clinical_service) label,
                            NULL flg_default_dcs -- doesn' t matter IN internal workflows
              FROM (SELECT vi.id_dep_clin_serv, vi.id_clinical_service, vi.code_clinical_service
                      FROM v_ref_internal vi
                     WHERE vi.flg_type = pk_ref_constant.g_p1_type_c
                       AND vi.id_institution = i_prof.institution
                       AND vi.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND (vi.id_department = i_dep OR i_dep IS NULL)
                       AND ((i_pat_gender IS NOT NULL AND
                           nvl(vi.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                           i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
                       AND (nvl(i_pat_age, 0) BETWEEN nvl(vi.age_min, 0) AND nvl(vi.age_max, nvl(i_pat_age, 0)) OR
                           nvl(i_pat_age, 0) = 0)
                          -- ALERT-208584 - if professional is associated to this dep_clin_serv, then he cannot create the internal referral (cannot return this dep_clin_serv)
                       AND (l_int_wf_restriction = pk_ref_constant.g_no OR
                           (l_int_wf_restriction = pk_ref_constant.g_yes AND pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                                                                                i_dcs  => vi.id_dep_clin_serv,
                                                                                                                i_func => table_number(pk_ref_constant.g_func_d,
                                                                                                                                       pk_ref_constant.g_func_t,
                                                                                                                                       pk_ref_constant.g_func_c)) =
                           pk_ref_constant.g_no))) t
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INTERNAL_SPEC',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cs);
            RETURN FALSE;
    END get_internal_spec;
    /**
    * Referral network: get available specialities for referring
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   i_pat             Patient identifier, to filter by gender and age   
    * @param   i_ref_type        Referral type   
    * @param   i_external_sys    External system identifier
    * @param   O_SQL             specialities INFO
    * @param   O_ERROR           An error message, set when return=false
    *
    * @value   i_ref_type        {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_net_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_ref_type     IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_sql          OUT t_cur_ref_spec,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_gender   patient.gender%TYPE;
        l_age      PLS_INTEGER;
        l_pat_info pk_types.cursor_type;
        l_params   VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_ref_type=' || i_ref_type ||
                    ' i_external_sys=' || i_external_sys;
        g_error  := 'Init get_net_spec / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        IF i_ref_type NOT IN (pk_ref_constant.g_flg_availability_e, pk_ref_constant.g_flg_availability_p)
        THEN
            g_error := 'i_ref_type not allowed / ' || l_params;
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call pk_ref_core.get_pat_info / ' || l_params;
        g_retval := pk_ref_core.get_pat_info(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => i_pat,
                                             o_info    => l_pat_info,
                                             o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_pat_info / ' || l_params;
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error  := 'Call get_net_spec / l_gender=' || l_gender || ' l_age=' || l_age || ' / ' || l_params;
        g_retval := get_net_spec(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_pat_gender   => l_gender,
                                 i_pat_age      => l_age,
                                 i_ref_type     => i_ref_type,
                                 i_external_sys => i_external_sys,
                                 o_sql          => o_sql,
                                 o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NET_SPEC',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_net_spec;

    /**
    * Referral network: get available specialities for referring
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_pat_gender      Patient gender   
    * @param   i_pat_age         Patient age
    * @param   i_ref_type        Referral type   
    * @param   i_external_sys    External system identifier
    * @param   o_sql             specialities INFO
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_ref_type        {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_net_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_ref_type     IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_sql          OUT t_cur_ref_spec,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' ||
                    i_pat_age || ' i_ref_type=' || i_ref_type || ' i_external_sys=' || i_external_sys;
        g_error  := 'Init get_net_spec / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        IF i_ref_type NOT IN (pk_ref_constant.g_flg_availability_e, pk_ref_constant.g_flg_availability_p)
        THEN
            g_error := 'i_ref_type not allowed / ' || l_params;
            RAISE g_exception;
        END IF;
    
        IF i_external_sys = pk_ref_constant.g_wf_fertis
        THEN
            -- todo: remove this from here, when internal FERTIS workflow become 3 (instead of 8)
        
            g_error := 'OPEN O_SQL 1 / GENDER=' || i_pat_gender || ' AGE=' || i_pat_age || ' / ' || l_params;
            OPEN o_sql FOR
                SELECT DISTINCT data.id_speciality,
                                pk_translation.get_translation(i_lang, data.code_speciality) desc_cls_srv,
                                data.flg_type
                  FROM (SELECT v.id_speciality, v.code_speciality, v.flg_type
                          FROM v_ref_network v
                         WHERE v.flg_type = pk_ref_constant.g_p1_type_c
                           AND v.id_inst_orig = i_prof.institution
                           AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                           AND v.flg_default_dcs = pk_ref_constant.g_yes
                           AND ((i_pat_gender IS NOT NULL AND
                               nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                               i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
                           AND (nvl(i_pat_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(i_pat_age, 0)) OR
                               nvl(i_pat_age, 0) = 0)
                        UNION ALL
                        -- internal fertis referrals
                        SELECT vi.id_speciality, vi.code_speciality, vi.flg_type
                          FROM v_ref_internal_fertis vi
                         WHERE vi.flg_type = pk_ref_constant.g_p1_type_c
                           AND vi.id_inst_orig = i_prof.institution
                           AND vi.id_external_sys IN (nvl(i_external_sys, 0), 0)
                           AND vi.flg_default_dcs = pk_ref_constant.g_yes
                           AND ((i_pat_gender IS NOT NULL AND nvl(vi.gender, pk_ref_constant.g_gender_i) IN
                               (pk_ref_constant.g_gender_i, i_pat_gender)) OR i_pat_gender IS NULL OR
                               i_pat_gender = pk_ref_constant.g_gender_i)
                           AND (nvl(i_pat_age, 0) BETWEEN nvl(vi.age_min, 0) AND nvl(vi.age_max, nvl(i_pat_age, 0)) OR
                               nvl(i_pat_age, 0) = 0)
                        
                        ) data
                 WHERE pk_translation.get_translation(i_lang, data.code_speciality) IS NOT NULL
                 ORDER BY desc_cls_srv;
        ELSE
            g_error := 'OPEN O_SQL 2 / GENDER=' || i_pat_gender || ' AGE=' || i_pat_age || ' / ' || l_params;
            OPEN o_sql FOR
                SELECT DISTINCT data.id_speciality,
                                pk_translation.get_translation(i_lang, data.code_speciality) desc_cls_srv,
                                data.flg_type
                  FROM (
                        
                        -- external referrals
                        SELECT v.id_speciality, v.code_speciality, v.flg_type
                          FROM v_ref_network v
                         WHERE v.flg_type = pk_ref_constant.g_p1_type_c
                           AND v.id_inst_orig = i_prof.institution
                           AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                           AND v.flg_default_dcs = pk_ref_constant.g_yes
                           AND i_ref_type = pk_ref_constant.g_flg_availability_e -- this view is used for external referrals only                              
                           AND ((i_pat_gender IS NOT NULL AND
                               nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                               i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
                           AND (nvl(i_pat_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(i_pat_age, 0)) OR
                               nvl(i_pat_age, 0) = 0)
                        UNION ALL
                        -- at hosp entrance referrals                              
                        SELECT vp.id_speciality, vp.code_speciality, vp.flg_type
                          FROM v_ref_hosp_entrance vp
                         WHERE vp.flg_type = pk_ref_constant.g_p1_type_c
                           AND vp.id_institution = i_prof.institution
                           AND vp.id_external_sys IN (nvl(i_external_sys, 0), 0)
                           AND vp.flg_default_dcs = pk_ref_constant.g_yes
                           AND i_ref_type = pk_ref_constant.g_flg_availability_p -- this view is used for hosp entrance referrals only                              
                           AND ((i_pat_gender IS NOT NULL AND
                               nvl(vp.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                               i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
                           AND (nvl(i_pat_age, 0) BETWEEN nvl(vp.age_min, 0) AND nvl(vp.age_max, nvl(i_pat_age, 0)) OR
                               nvl(i_pat_age, 0) = 0)) data
                 WHERE pk_translation.get_translation(i_lang, data.code_speciality) IS NOT NULL
                 ORDER BY desc_cls_srv;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NET_SPEC',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_net_spec;

    /**
    * Referral network: get available institutions for the selected referral speciality
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_ref_type               Referral type
    * @param   i_external_sys           External system that created the referral   
    * @param   i_id_speciality          Referral speciality identifier
    * @param   i_flg_ref_line           Referral line 1,2,3
    * @param   i_flg_type_ins           Referral network to which it belongs
    * @param   i_flg_inside_ref_area    Flag indicating if is inside referral area or not
    * @param   i_flg_type               Referral type
    * @param   o_sql                    Clinical institutions data
    * @param   o_error                  An error message, set when return=false
    *
    * @value   i_ref_type               {*} 'E' external
    * @value   i_flg_inside_ref_area    {*} 'Y' - inside ref area {*} 'N' - otherwise   
    * @value   i_flg_type               {*} 'C' - Appointments {*} 'A' - Lab tests {*} 'I' - Imaging exams 
    *                                   {*} 'E' - Other exams {*} 'P' - Procedures 
    *                                   {*} 'F' - Physical Medicine and Rehabilitation    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2013
    */
    FUNCTION get_net_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref_type            IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE,
        o_sql                 OUT NOCOPY t_cur_ref_institution,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params                VARCHAR2(1000 CHAR);
        l_ref_adw_column        sys_config.value%TYPE;
        l_ref_network_available sys_config.value%TYPE;
        l_ref_waiting_time      sys_config.value%TYPE;
        l_id_ext_inst           institution.id_institution%TYPE;
        l_icon                  sys_config.value%TYPE;
        l_sm_common_m19         sys_message.desc_message%TYPE;
        l_sm_common_m20         sys_message.desc_message%TYPE;
        l_sysdate               TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_server             VARCHAR2(50 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------            
        l_params  := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ref_type=' || i_ref_type || ' i_external_sys=' ||
                     i_external_sys || ' i_id_speciality=' || i_id_speciality || ' i_flg_ref_line=' || i_flg_ref_line ||
                     ' i_flg_type_ins=' || i_flg_type_ins || ' i_flg_inside_ref_area=' || i_flg_inside_ref_area ||
                     ' i_flg_type=' || i_flg_type;
        g_error   := 'Init get_net_inst / ' || l_params;
        l_sysdate := current_timestamp;
    
        ----------------------
        -- CONFIG
        ----------------------        
        g_error                 := 'Configs / ' || l_params;
        l_ref_network_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_network_available, i_prof),
                                       pk_ref_constant.g_no);
        l_ref_waiting_time      := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_waiting_time, i_prof),
                                       pk_ref_constant.g_no);
        l_ref_adw_column        := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_adw_column, i_prof);
        l_id_ext_inst           := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
        l_icon                  := pk_sysconfig.get_config('REF_WAIT_TIME_ICON', i_prof);
    
        g_error := 'NETWORK AVAILABLE=' || l_ref_network_available || ' WAITING TIME AVAILABLE=' || l_ref_waiting_time ||
                   ' ADW_COLUMN=' || l_ref_adw_column || ' / ' || l_params;
    
        -- sys_messages
        g_error         := 'SYS_MESSAGE / ' || l_params;
        l_sm_common_m19 := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_m19);
        l_sm_common_m20 := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_m20);
    
        g_error     := 'Call pk_date_utils.date_send_tsz / ' || l_params;
        l_dt_server := pk_date_utils.date_send_tsz(i_lang, l_sysdate, i_prof);
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'OPEN o_sql FOR / ' || l_params;
        OPEN o_sql FOR
            SELECT DISTINCT data.id_institution, -- v_ref_network returns several id_dep_clin_servs for the same id_institution
                            nvl(data.abbreviation, pk_translation.get_translation(i_lang, data.code_institution)) abbreviation,
                            pk_translation.get_translation(i_lang, data.code_institution) desc_institution,
                            data.ext_code,
                            data.flg_default_inst flg_default,
                            (SELECT COUNT(sh.id_spec_help)
                               FROM p1_spec_help sh
                              WHERE sh.id_speciality = i_id_speciality
                                AND sh.id_institution = data.id_institution
                                AND sh.flg_available = pk_ref_constant.g_yes) help_count,
                            -- date_field
                            decode(l_ref_waiting_time,
                                   pk_ref_constant.g_no,
                                   NULL,
                                   pk_ref_constant.g_yes,
                                   pk_date_utils.date_send_tsz(i_lang,
                                                               (l_sysdate -
                                                               (pk_ref_waiting_time.get_waiting_time(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ref_adw_column,
                                                                                                      data.id_institution,
                                                                                                      i_id_speciality))),
                                                               i_prof)) date_field,
                            (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_ref_line,
                                                            data.flg_ref_line,
                                                            i_lang)
                               FROM dual) ref_line,
                            (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_type_ins,
                                                            data.flg_type_ins,
                                                            i_lang)
                               FROM dual) type_ins,
                            (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_inside_ref_area,
                                                            data.flg_inside_ref_area,
                                                            i_lang)
                               FROM dual) inside_ref_area,
                            data.flg_ref_line,
                            data.flg_type_ins,
                            data.flg_inside_ref_area,
                            -- icon
                            decode(l_ref_waiting_time, pk_ref_constant.g_no, NULL, pk_ref_constant.g_yes, l_icon) icon,
                            l_sm_common_m19 desc_day,
                            l_sm_common_m20 desc_days,
                            l_dt_server dt_server,
                            -- wait_days
                            decode(l_ref_waiting_time,
                                   pk_ref_constant.g_no,
                                   NULL,
                                   pk_ref_constant.g_yes,
                                   pk_ref_waiting_time.get_waiting_time(i_lang,
                                                                        i_prof,
                                                                        l_ref_adw_column,
                                                                        data.id_institution,
                                                                        i_id_speciality)) wait_days,
                            -- id_speciality
                            data.id_speciality,
                            pk_translation.get_translation(i_lang, data.code_speciality) desc_speciality,
                            -- id_inst_orig
                            data.id_inst_orig,
                            data.orig_ext_code,
                            pk_translation.get_translation(i_lang, data.orig_code_institution) desc_orig_institution
            
              FROM (
                    -- external referrals
                    SELECT v.id_institution,
                            v.ext_code,
                            v.abbreviation,
                            v.code_institution,
                            v.flg_default_inst,
                            v.flg_ref_line,
                            v.flg_type_ins,
                            v.flg_inside_ref_area,
                            v.id_speciality,
                            v.code_speciality,
                            v.id_inst_orig,
                            v.orig_ext_code,
                            v.orig_code_institution
                      FROM v_ref_network v
                     WHERE i_ref_type = pk_ref_constant.g_flg_availability_e -- this view used for external referrals only
                       AND (v.id_speciality = i_id_speciality OR i_id_speciality IS NULL)
                       AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND v.id_inst_orig = i_prof.institution
                       AND (v.flg_inside_ref_area = i_flg_inside_ref_area OR i_flg_inside_ref_area IS NULL)
                       AND (v.flg_ref_line = i_flg_ref_line OR i_flg_ref_line IS NULL)
                       AND (v.flg_type_ins = i_flg_type_ins OR i_flg_type_ins IS NULL)
                       AND (v.flg_type = i_flg_type OR i_flg_type IS NULL)
                       AND v.flg_default_dcs = pk_ref_constant.g_yes
                    -- at hospital entrance referrals: the institution where the professional is
                    UNION ALL
                    SELECT vp.id_institution,
                            vp.ext_code,
                            vp.abbreviation,
                            vp.code_institution,
                            vp.flg_default_inst,
                            vp.flg_ref_line,
                            vp.flg_type_ins,
                            vp.flg_inside_ref_area,
                            vp.id_speciality,
                            vp.code_speciality,
                            NULL                   id_inst_orig,
                            NULL                   orig_ext_code,
                            NULL                   orig_code_institution
                      FROM v_ref_hosp_entrance vp
                     WHERE i_ref_type = pk_ref_constant.g_flg_availability_p -- this view used for at hospital entrance referrals only
                       AND (vp.id_speciality = i_id_speciality OR i_id_speciality IS NULL)
                       AND vp.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND vp.id_institution = i_prof.institution -- at hospital entrance referral
                       AND (vp.flg_ref_line = i_flg_ref_line OR i_flg_ref_line IS NULL)
                       AND (vp.flg_type_ins = i_flg_type_ins OR i_flg_type_ins IS NULL)
                       AND (vp.flg_type = i_flg_type OR i_flg_type IS NULL)
                       AND vp.flg_default_dcs = pk_ref_constant.g_yes) data
            UNION ALL
            SELECT data.id_institution,
                   data.abbreviation,
                   pk_translation.get_translation(i_lang, data.code_institution) desc_institution,
                   data.ext_code,
                   pk_ref_constant.g_no flg_default,
                   (SELECT COUNT(sh.id_spec_help)
                      FROM p1_spec_help sh
                     WHERE sh.id_speciality = i_id_speciality
                       AND sh.id_institution = data.id_institution
                       AND sh.flg_available = pk_ref_constant.g_yes) help_count,
                   NULL date_field,
                   NULL ref_line,
                   NULL type_ins,
                   NULL inside_ref_area,
                   NULL flg_ref_line,
                   NULL flg_type_ins,
                   NULL flg_inside_ref_area,
                   NULL icon,
                   l_sm_common_m19 desc_day,
                   l_sm_common_m20 desc_days,
                   l_dt_server dt_server,
                   NULL wait_days,
                   -- id_speciality
                   NULL id_speciality,
                   NULL desc_speciality,
                   -- id_inst_orig
                   NULL id_inst_orig,
                   NULL orig_ext_code,
                   NULL desc_orig_institution
              FROM institution data
             WHERE id_institution = l_id_ext_inst
               AND l_ref_network_available = pk_ref_constant.g_yes
             ORDER BY flg_default DESC, desc_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NET_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_net_inst;

    /**
    * Referral network: get available institutions for the selected referral speciality
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_ref_type               Referral type
    * @param   i_external_sys           External system that created the referral   
    * @param   i_id_speciality          Referral speciality identifier
    * @param   i_flg_ref_line           Referral line 1,2,3
    * @param   i_flg_type_ins           Referral network to which it belongs
    * @param   i_flg_inside_ref_area    Flag indicating if is inside referral area or not
    * @param   i_flg_type               Referral type
    * @param   o_sql                    Clinical institutions data
    * @param   o_error                  An error message, set when return=false
    *
    * @value   i_ref_type               {*} 'E' external
    * @value   i_flg_inside_ref_area    {*} 'Y' - inside ref area {*} 'N' - otherwise   
    * @value   i_flg_type               {*} 'C' - Appointments {*} 'A' - Lab tests {*} 'I' - Imaging exams 
    *                                   {*} 'E' - Other exams {*} 'P' - Procedures 
    *                                   {*} 'F' - Physical Medicine and Rehabilitation    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-09-2013
    */
    FUNCTION get_net_all_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref_type            IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE,
        o_sql                 OUT NOCOPY t_cur_ref_institution,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params           VARCHAR2(1000 CHAR);
        l_ref_adw_column   sys_config.value%TYPE;
        l_ref_waiting_time sys_config.value%TYPE;
        --l_id_ext_inst      institution.id_institution%TYPE;
        l_icon          sys_config.value%TYPE;
        l_sm_common_m19 sys_message.desc_message%TYPE;
        l_sm_common_m20 sys_message.desc_message%TYPE;
        l_sysdate       TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_server     VARCHAR2(50 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------            
        l_params  := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ref_type=' || i_ref_type || ' i_external_sys=' ||
                     i_external_sys || ' i_id_speciality=' || i_id_speciality || ' i_flg_ref_line=' || i_flg_ref_line ||
                     ' i_flg_type_ins=' || i_flg_type_ins || ' i_flg_inside_ref_area=' || i_flg_inside_ref_area ||
                     ' i_flg_type=' || i_flg_type;
        g_error   := 'Init get_net_inst / ' || l_params;
        l_sysdate := current_timestamp;
    
        ----------------------
        -- CONFIG
        ----------------------        
        g_error            := 'Configs / ' || l_params;
        l_ref_waiting_time := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_waiting_time, i_prof),
                                  pk_ref_constant.g_no);
        l_ref_adw_column   := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_adw_column, i_prof);
        --l_id_ext_inst      := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
        l_icon := pk_sysconfig.get_config('REF_WAIT_TIME_ICON', i_prof);
    
        g_error := ' WAITING TIME AVAILABLE=' || l_ref_waiting_time || ' ADW_COLUMN=' || l_ref_adw_column || ' / ' ||
                   l_params;
    
        -- sys_messages
        g_error         := 'SYS_MESSAGE / ' || l_params;
        l_sm_common_m19 := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_m19);
        l_sm_common_m20 := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_common_m20);
    
        g_error     := 'Call pk_date_utils.date_send_tsz / ' || l_params;
        l_dt_server := pk_date_utils.date_send_tsz(i_lang, l_sysdate, i_prof);
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'OPEN o_sql FOR / ' || l_params;
        OPEN o_sql FOR
            SELECT DISTINCT data.id_institution,
                            nvl(data.abbreviation, pk_translation.get_translation(i_lang, data.code_institution)) abbreviation,
                            pk_translation.get_translation(i_lang, data.code_institution) desc_institution,
                            data.ext_code,
                            data.flg_default_inst flg_default,
                            (SELECT COUNT(sh.id_spec_help)
                               FROM p1_spec_help sh
                              WHERE sh.id_speciality = i_id_speciality
                                AND sh.id_institution = data.id_institution
                                AND sh.flg_available = pk_ref_constant.g_yes) help_count,
                            -- date_field
                            decode(l_ref_waiting_time,
                                   pk_ref_constant.g_no,
                                   NULL,
                                   pk_ref_constant.g_yes,
                                   pk_date_utils.date_send_tsz(i_lang,
                                                               (l_sysdate -
                                                               (pk_ref_waiting_time.get_waiting_time(i_lang,
                                                                                                      i_prof,
                                                                                                      l_ref_adw_column,
                                                                                                      data.id_institution,
                                                                                                      i_id_speciality))),
                                                               i_prof)) date_field,
                            (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_ref_line,
                                                            data.flg_ref_line,
                                                            i_lang)
                               FROM dual) ref_line,
                            (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_type_ins,
                                                            data.flg_type_ins,
                                                            i_lang)
                               FROM dual) type_ins,
                            (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_inside_ref_area,
                                                            data.flg_inside_ref_area,
                                                            i_lang)
                               FROM dual) inside_ref_area,
                            data.flg_ref_line,
                            data.flg_type_ins,
                            data.flg_inside_ref_area,
                            -- icon
                            decode(l_ref_waiting_time, pk_ref_constant.g_no, NULL, pk_ref_constant.g_yes, l_icon) icon,
                            l_sm_common_m19 desc_day,
                            l_sm_common_m20 desc_days,
                            l_dt_server dt_server,
                            -- wait_days
                            decode(l_ref_waiting_time,
                                   pk_ref_constant.g_no,
                                   NULL,
                                   pk_ref_constant.g_yes,
                                   pk_ref_waiting_time.get_waiting_time(i_lang,
                                                                        i_prof,
                                                                        l_ref_adw_column,
                                                                        data.id_institution,
                                                                        i_id_speciality)) wait_days,
                            -- id_speciality
                            data.id_speciality,
                            pk_translation.get_translation(i_lang, data.code_speciality) desc_speciality,
                            -- id_inst_orig
                            data.id_inst_orig,
                            data.orig_ext_code,
                            pk_translation.get_translation(i_lang, data.orig_code_institution) desc_orig_institution
              FROM (
                    -- external referrals
                    SELECT ve.id_institution,
                            ve.ext_code,
                            ve.abbreviation,
                            ve.code_institution,
                            ve.flg_default_inst,
                            ve.flg_ref_line,
                            ve.flg_type_ins,
                            ve.flg_inside_ref_area,
                            ve.id_speciality,
                            ve.code_speciality,
                            ve.id_inst_orig,
                            ve.orig_ext_code,
                            ve.orig_code_institution
                      FROM v_ref_network ve
                     WHERE (ve.id_speciality = i_id_speciality OR i_id_speciality IS NULL)
                       AND ve.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND ve.id_inst_orig = i_prof.institution
                       AND (ve.flg_inside_ref_area = i_flg_inside_ref_area OR i_flg_inside_ref_area IS NULL)
                       AND (ve.flg_ref_line = i_flg_ref_line OR i_flg_ref_line IS NULL)
                       AND (ve.flg_type_ins = i_flg_type_ins OR i_flg_type_ins IS NULL)
                       AND (ve.flg_type = i_flg_type OR i_flg_type IS NULL)
                       AND ve.flg_default_dcs = pk_ref_constant.g_yes
                    UNION ALL
                    -- internal referrals
                    SELECT vi.id_institution,
                            vi.ext_code,
                            vi.abbreviation,
                            vi.code_institution,
                            NULL                flg_default_inst,
                            NULL                flg_ref_line,
                            NULL                flg_type_ins,
                            NULL                flg_inside_ref_area,
                            vi.id_speciality,
                            vi.code_speciality,
                            vi.id_institution   id_inst_orig, -- orig=dest
                            vi.ext_code         orig_ext_code, -- orig=dest
                            vi.code_institution -- orig=dest
                      FROM v_ref_internal vi
                     WHERE (vi.id_speciality = i_id_speciality OR i_id_speciality IS NULL)
                       AND vi.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND vi.id_institution = i_prof.institution
                          -- flg_inside_ref_area, flg_ref_line,flg_type_ins, flg_default_dcs  - meaningless for internal workflows
                       AND (vi.flg_type = i_flg_type OR i_flg_type IS NULL)) data
             ORDER BY flg_default DESC, desc_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NET_ALL_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_net_all_inst;

    /**
    * Referral network: get available clinical services for referring in dest institution
    * Available only for external and at hospital entrance workflows    
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_ref_type        Referring type
    * @param   i_p1_spec         Referral speciality identifier
    * @param   i_id_inst_dest    DEst institution identifier   
    * @param   i_external_sys    External system identifier
    * @param   o_sql             Dest clinical services exposed to the origin institution
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_ref_type        {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-09-2012
    */
    FUNCTION get_net_clin_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ref_type     IN VARCHAR2,
        i_p1_spec      IN p1_speciality.id_speciality%TYPE,
        i_id_inst_dest IN p1_dest_institution.id_inst_dest%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_sql          OUT t_cur_ref_dcs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ref_type=' || i_ref_type || ' i_p1_spec=' ||
                    i_p1_spec || ' i_id_inst_dest=' || i_id_inst_dest || ' i_external_sys=' || i_external_sys;
    
        g_error := 'Init get_net_clin_serv / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        IF i_ref_type NOT IN (pk_ref_constant.g_flg_availability_e, pk_ref_constant.g_flg_availability_p)
        THEN
            g_error := 'i_ref_type not allowed / ' || l_params;
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_sql FOR / ' || l_params;
        OPEN o_sql FOR
            SELECT DISTINCT data.id_dep_clin_serv, -- distinct because we do not filter by orig institution in v_ref_hosp_entrance yet
                            data.id_clinical_service,
                            pk_translation.get_translation(i_lang, data.code_clinical_service) desc_cls_srv,
                            flg_default_dcs
              FROM (
                    -- external referrals
                    SELECT v.id_dep_clin_serv, v.id_clinical_service, v.code_clinical_service, v.flg_default_dcs
                      FROM v_ref_network v
                     WHERE v.flg_type = pk_ref_constant.g_p1_type_c
                       AND v.id_inst_orig = i_prof.institution
                       AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND (v.flg_default_dcs = pk_ref_constant.g_yes OR v.flg_visible_orig = pk_ref_constant.g_yes) -- shows only clin serv that are exposed or the default clin serv
                       AND i_ref_type = pk_ref_constant.g_flg_availability_e -- this view is used for external referrals only
                       AND v.id_speciality = i_p1_spec
                       AND v.id_institution = i_id_inst_dest
                    UNION ALL
                    -- at hosp entrance referrals                              
                    SELECT vp.id_dep_clin_serv, vp.id_clinical_service, vp.code_clinical_service, vp.flg_default_dcs
                      FROM v_ref_hosp_entrance vp
                     WHERE vp.flg_type = pk_ref_constant.g_p1_type_c
                       AND vp.id_institution = i_prof.institution
                       AND vp.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND (vp.flg_default_dcs = pk_ref_constant.g_yes OR vp.flg_visible_orig = pk_ref_constant.g_yes) -- shows only clin serv that are exposed or the default clin serv
                       AND i_ref_type = pk_ref_constant.g_flg_availability_p -- this view is used for hosp entrance referrals only
                       AND vp.id_speciality = i_p1_spec
                       AND vp.id_institution = i_id_inst_dest) data
             ORDER BY flg_default_dcs DESC, desc_cls_srv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NET_CLIN_SERV',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_net_clin_serv;

    /**
    * Referral network: gets available origin institutions that can possibly request the referral
    * Available only for at hospital entrance workflows
    * Any changes to this function must be done in filter_name=ReferralOrigInst
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Professional, institution and software ids    
    * @param   i_p1_spec          Referral speciality identifier
    * @param   i_id_inst_dest     Dest institution identifier   
    * @param   i_external_sys     External system identifier
    * @param   i_id_dep_clin_serv Department/clinical_service identifier
    * @param   i_flg_type_ref     Referral type being requested
    * @param   o_sql              Orig institutions
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   05-12-2013
    */
    FUNCTION get_net_inst_orig
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_p1_spec          IN p1_spec_dep_clin_serv.id_speciality%TYPE,
        i_id_inst_dest     IN p1_dest_institution.id_inst_dest%TYPE,
        i_external_sys     IN p1_spec_dep_clin_serv.id_external_sys%TYPE,
        i_id_dep_clin_serv IN p1_spec_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_type_ref     IN p1_dest_institution.flg_type%TYPE,
        o_sql              OUT t_cur_ref_net_inst_orig,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params            VARCHAR2(1000 CHAR);
        l_id_ext_inst       institution.id_institution%TYPE;
        l_ext_code_ext_inst institution.ext_code%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_p1_spec=' || i_p1_spec || ' i_id_inst_dest=' ||
                    i_id_inst_dest || ' i_external_sys=' || i_external_sys || ' i_id_dep_clin_serv=' ||
                    i_id_dep_clin_serv || ' i_flg_type_ref=' || i_flg_type_ref;
    
        g_error := 'Init get_net_inst_orig / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_id_ext_inst := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
        BEGIN
            SELECT ext_code
              INTO l_ext_code_ext_inst
              FROM institution i
             WHERE i.id_institution = l_id_ext_inst;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'OPEN o_sql FOR / ' || l_params;
        OPEN o_sql FOR
            SELECT DISTINCT data.id_inst_orig, -- distinct because there may be several departments for the same orig institution
                            pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || id_inst_orig) orig_inst_desc,
                            ext_code
              FROM (
                    -- at hosp entrance referrals                              
                    SELECT CASE vp.id_inst_orig
                                WHEN 0 THEN
                                 l_id_ext_inst
                                ELSE
                                 vp.id_inst_orig
                            END id_inst_orig,
                            -- ext_code
                            CASE vp.id_inst_orig
                                WHEN 0 THEN
                                 l_ext_code_ext_inst
                                ELSE
                                 vp.ext_code
                            END ext_code
                      FROM v_ref_hosp_entrance vp
                     WHERE vp.flg_type = i_flg_type_ref
                       AND vp.id_institution = i_prof.institution
                       AND vp.id_institution = i_id_inst_dest
                       AND vp.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND (vp.flg_default_dcs = pk_ref_constant.g_yes OR vp.flg_visible_orig = pk_ref_constant.g_yes) -- shows only clin serv that are exposed or the default clin serv
                       AND vp.id_speciality = i_p1_spec
                       AND vp.id_dep_clin_serv = nvl(i_id_dep_clin_serv, vp.id_dep_clin_serv)) data
             ORDER BY orig_inst_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NET_INST_ORIG',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_net_inst_orig;

    /**
    * Function used to remove patient name criteria, if sns is specified (ACSS performance issues)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   io_crit_id_tab    List of search criteria identifiers
    * @param   io_crit_val_tab   List of values for the criteria in i_crit_id_tab
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-04-2013
    */
    FUNCTION get_search_pat_criterias
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        io_crit_id_tab  IN OUT table_number,
        io_crit_val_tab IN OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_crit_id_tab  table_number;
        l_crit_val_tab table_varchar;
        l_idx          PLS_INTEGER;
    BEGIN
        -- ALERT-255177 - do not search by name if sns is specified
        g_error        := 'io_crit_id_tab.count=' || io_crit_id_tab.count || ' io_crit_val_tab.count=' ||
                          io_crit_val_tab.count;
        l_crit_id_tab  := table_number();
        l_crit_val_tab := table_varchar();
    
        l_idx := pk_utils.search_table_number(i_table => io_crit_id_tab, i_search => pk_ref_constant.g_crit_pat_sns);
    
        g_error := 'SNS idx=' || l_idx;
        IF l_idx != -1
        THEN
        
            -- do not search by the name (ONLY) in this case 
            FOR i IN 1 .. io_crit_id_tab.count
            LOOP
                IF io_crit_id_tab(i) != pk_ref_constant.g_crit_pat_name
                THEN
                    l_crit_id_tab.extend;
                    l_crit_val_tab.extend;
                
                    l_crit_id_tab(l_crit_id_tab.last) := io_crit_id_tab(i);
                    l_crit_val_tab(l_crit_val_tab.last) := io_crit_val_tab(i);
                END IF;
            END LOOP;
        
            io_crit_id_tab  := NULL;
            io_crit_val_tab := NULL;
        
            io_crit_id_tab  := l_crit_id_tab;
            io_crit_val_tab := l_crit_val_tab;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SEARCH_PAT_CRITERIAS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_search_pat_criterias;

    /**
    * Function used to search for patients
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab
    * @param   i_prof_cat_type   Professional category type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_pat             Patient data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_crit_id_tab   IN table_number,
        i_crit_val_tab  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_pat           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count        NUMBER;
        l_limit        sys_config.value%TYPE;
        l_sql          CLOB;
        l_market       market.id_market%TYPE;
        l_crit_id_tab  table_number;
        l_crit_val_tab table_varchar;
    BEGIN
        o_flg_show  := pk_ref_constant.g_no;
        o_msg       := '';
        o_msg_title := '';
        l_limit     := pk_sysconfig.get_config(pk_ref_constant.g_sc_num_record_search, i_prof);
    
        g_error  := 'pk_utils.get_institution_market / ID_INSTITUTION=' || i_prof.institution;
        l_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        l_crit_id_tab  := i_crit_id_tab;
        l_crit_val_tab := i_crit_val_tab;
    
        g_error  := 'Call get_search_pat_criterias / l_crit_id_tab.count=' || l_crit_id_tab.count ||
                    ' l_crit_val_tab.count=' || l_crit_val_tab.count;
        g_retval := get_search_pat_criterias(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             io_crit_id_tab  => l_crit_id_tab,
                                             io_crit_val_tab => l_crit_val_tab,
                                             o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call pk_ref_core_internal.get_search_pat_sql';
        IF NOT pk_ref_core_internal.get_search_pat_sql(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_sys_btn_crit => l_crit_id_tab,
                                                       i_crit_val        => l_crit_val_tab,
                                                       o_sql             => l_sql,
                                                       o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        pk_ref_utils.log_clob(l_sql);
    
        g_error := 'SELECT COUNT(1) INTO l_count';
        SELECT COUNT(1)
          INTO l_count
          FROM TABLE(CAST(pk_ref_core_internal.get_search_pat_data(l_sql) AS t_coll_ref_search)) t;
    
        g_error := 'l_count > l_limit / l_count=' || l_count || ' l_limit=' || l_limit;
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        g_error := 'l_count = 0';
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'OPEN o_pat / l_count=' || l_count;
        OPEN o_pat FOR
            SELECT t.id_patient,
                   (SELECT pk_adt.get_patient_name(i_lang,
                                                   i_prof,
                                                   t.id_patient,
                                                   pk_p1_external_request.check_prof_resp(i_lang,
                                                                                          i_prof,
                                                                                          t.id_external_request)) -- id_external_req will be null in this case
                      FROM dual) name,
                   t.pat_gender gender,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_domain_gender, t.pat_gender, i_lang)
                      FROM dual) desc_gender,
                   pk_date_utils.date_send(i_lang, t.pat_dt_birth, i_prof) dt_birth,
                   pk_patient.get_pat_age(i_lang, t.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_foto(t.id_patient, i_prof) photo,
                   t.pat_address address,
                   t.pat_zip_code zip_code,
                   t.pat_location location,
                   decode(l_market, pk_ref_constant.g_market_pt, t.pat_num_sns, t.run_number) num_health_plan,
                   t.pat_num_clin_record num_clin_record
              FROM TABLE(CAST(pk_ref_core_internal.get_search_pat_data(l_sql) AS t_coll_ref_search)) t
             ORDER BY name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package, 'GET_SEARCH_PAT', o_error);
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package, 'GET_SEARCH_PAT', o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SEARCH_PAT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_search_pat;

    /**
    * Function used to search for referrals
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab
    * @param   i_prof_cat_type   Professional category type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_pat             Referral data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   27-05-2008
    */
    FUNCTION get_search_ref
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_crit_id_tab   IN table_number,
        i_crit_val_tab  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_pat           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_my_data         t_rec_prof_data;
        l_count           NUMBER;
        l_limit           sys_config.value%TYPE;
        l_sql             CLOB;
        l_msg_common_m019 VARCHAR2(1000 CHAR);
        l_msg_common_m020 VARCHAR2(1000 CHAR);
        l_crit_id_tab     table_number;
        l_crit_val_tab    table_varchar;
    BEGIN
        ----------------------
        -- CONFIG
        ---------------------- 
        l_msg_common_m019 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_common_m19);
        l_msg_common_m020 := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_sm_common_m20);
    
        o_flg_show  := pk_ref_constant.g_no;
        o_msg       := '';
        o_msg_title := '';
        l_limit     := pk_sysconfig.get_config(pk_ref_constant.g_sc_num_record_search, i_prof);
    
        ----------------------
        -- FUNC
        ---------------------- 
        g_error  := 'Calling get_prof_data';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
    
        l_crit_id_tab  := i_crit_id_tab;
        l_crit_val_tab := i_crit_val_tab;
    
        g_error  := 'Call get_search_pat_criterias / l_crit_id_tab.count=' || l_crit_id_tab.count ||
                    ' l_crit_val_tab.count=' || l_crit_val_tab.count;
        g_retval := get_search_pat_criterias(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             io_crit_id_tab  => l_crit_id_tab,
                                             io_crit_val_tab => l_crit_val_tab,
                                             o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_core_internal.get_search_ref_sql / i_crit_id_tab=' ||
                    pk_utils.to_string(i_crit_id_tab);
        g_retval := pk_ref_core_internal.get_search_ref_sql(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_crit_id_tab  => l_crit_id_tab,
                                                            i_crit_val_tab => l_crit_val_tab,
                                                            i_pt           => l_my_data.id_profile_template,
                                                            o_sql          => l_sql,
                                                            o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --pk_ref_utils.log_clob(l_sql);
    
        g_error := 'COUNT';
        SELECT COUNT(1)
          INTO l_count
          FROM TABLE(CAST(pk_ref_core_internal.get_search_ref_data(l_sql) AS t_coll_ref_search)) t;
    
        IF l_count > l_limit
        THEN
            g_error := 'l_count[' || l_count || ' > l_limit[' || l_count || ']';
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            g_error := 'l_count = 0';
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'OPEN o_pat';
        OPEN o_pat FOR
            SELECT q.*
              FROM (SELECT t.id_external_request id_p1,
                           t.num_req,
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                     t.id_external_request,
                                                                                     t.flg_status,
                                                                                     t.id_workflow),
                                                    i_prof) dt_p1,
                           t.flg_type,
                           t.id_inst_orig,
                           pk_ref_core.get_inst_orig_name(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_inst_orig   => t.id_inst_orig,
                                                          i_inst_name_roda => t.institution_name_roda) inst_orig_name,
                           t.id_inst_dest,
                           pk_ref_core.get_inst_name(i_lang,
                                                     i_prof,
                                                     t.flg_status,
                                                     t.id_inst_dest,
                                                     t.code_inst_dest,
                                                     t.inst_dest_abbrev) inst_dest_name,
                           pk_translation.get_translation(i_lang, t.code_department) dest_department,
                           decode(t.id_dep_clin_serv,
                                  NULL,
                                  pk_translation.get_translation(i_lang, t.code_speciality),
                                  pk_translation.get_translation(i_lang, t.code_clinical_service)) clin_srv_name,
                           decode(t.id_workflow,
                                  pk_ref_constant.g_wf_srv_srv,
                                  -- if is internal workflow, than shows the value of column clin_srv_name
                                  decode(t.id_dep_clin_serv,
                                         NULL,
                                         pk_translation.get_translation(i_lang, t.code_speciality),
                                         pk_translation.get_translation(i_lang, t.code_clinical_service)),
                                  -- else  (other than internal workflow)
                                  nvl2(t.code_speciality,
                                       pk_translation.get_translation(i_lang, t.code_speciality),
                                       (SELECT desc_val
                                          FROM sys_domain
                                         WHERE id_language = i_lang
                                           AND code_domain = pk_ref_constant.g_p1_exr_flg_type
                                           AND domain_owner = pk_sysdomain.k_default_schema
                                           AND val = t.flg_type))) p1_spec_name,
                           nvl2((SELECT img_name
                                  FROM sys_domain
                                 WHERE id_language = i_lang
                                   AND code_domain = pk_ref_constant.g_p1_exr_flg_type
                                   AND domain_owner = pk_sysdomain.k_default_schema
                                   AND val = t.flg_type),
                                lpad((SELECT rank
                                       FROM sys_domain
                                      WHERE id_language = i_lang
                                        AND code_domain = pk_ref_constant.g_p1_exr_flg_type
                                        AND domain_owner = pk_sysdomain.k_default_schema
                                        AND val = t.flg_type),
                                     6,
                                     '0') || (SELECT img_name
                                                FROM sys_domain
                                               WHERE id_language = i_lang
                                                 AND code_domain = pk_ref_constant.g_p1_exr_flg_type
                                                 AND domain_owner = pk_sysdomain.k_default_schema
                                                 AND val = t.flg_type),
                                NULL) type_icon,
                           t.flg_status,
                           (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', t.flg_status, i_lang)
                              FROM dual) flg_status_desc,
                           nvl2((SELECT pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_PRIORITY', t.flg_priority)
                                  FROM dual),
                                lpad(pk_sysdomain.get_rank(i_lang, 'P1_EXTERNAL_REQUEST.FLG_PRIORITY', t.flg_priority),
                                     6,
                                     '0') ||
                                (SELECT pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_PRIORITY', t.flg_priority)
                                   FROM dual),
                                NULL) priority_icon,
                           pk_date_utils.get_elapsed_tsz(i_lang, t.dt_status_tstz, current_timestamp) dt_elapsed,
                           t.id_patient,
                           (SELECT pk_adt.get_patient_name(i_lang,
                                                           i_prof,
                                                           t.id_patient,
                                                           pk_p1_external_request.check_prof_resp(i_lang,
                                                                                                  i_prof,
                                                                                                  t.id_external_request))
                              FROM dual) pat_name,
                           (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', t.pat_gender, i_lang)
                              FROM dual) pat_gender,
                           pk_patient.get_pat_age(i_lang, t.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_foto(t.id_patient, i_prof) photo,
                           t.id_schedule,
                           pk_date_utils.dt_chr_tsz(i_lang, t.dt_schedule_tstz, i_prof) dt_schedule,
                           pk_date_utils.dt_chr_hour_tsz(i_lang, t.dt_schedule_tstz, i_prof) hour_schedule,
                           l_msg_common_m019 desc_day,
                           l_msg_common_m020 desc_days,
                           pk_date_utils.date_send_tsz(i_lang, dt_status_tstz, i_prof) date_field,
                           pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                           t.sequential_number,
                           t.id_prof_requested,
                           pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_id_prof_requested => t.id_prof_requested,
                                                                    i_id_prof_roda      => t.id_prof_roda) prof_requested_name,
                           t.id_workflow,
                           t.id_match,
                           decode(l_my_data.id_category,
                                   pk_ref_constant.g_cat_id_adm,
                                   decode(l_my_data.id_profile_template,
                                          pk_ref_constant.g_profile_adm_hs_vo,
                                          pk_ref_constant.g_no,
                                          (CASE
                                              WHEN (SELECT pk_ref_core.get_workflow_config(i_prof,
                                                                                           pk_ref_constant.g_adm_required,
                                                                                           t.id_speciality,
                                                                                           t.id_inst_dest,
                                                                                           t.id_inst_orig,
                                                                                           t.id_workflow)
                                                      FROM dual) = pk_ref_constant.g_adm_required_match THEN
                                               pk_ref_constant.g_yes
                                              WHEN t.id_match IS NULL THEN
                                               pk_ref_constant.g_yes
                                              ELSE
                                               pk_ref_constant.g_no
                                          END)),
                                   pk_ref_constant.g_no) flg_match_redirect,
                           --------
                           -- STATUS_INFO
                           pk_ref_status.get_flash_status_info(i_lang,
                                                               i_prof,
                                                               t.id_external_request,
                                                               l_my_data.id_profile_template,
                                                               l_my_data.id_category,
                                                               pk_ref_core.get_prof_func(i_lang,
                                                                                         i_prof,
                                                                                         t.id_dep_clin_serv),
                                                               t.id_workflow,
                                                               t.flg_status,
                                                               t.dt_status_tstz,
                                                               -- workflow data
                                                               pk_ref_constant.g_location_grid,
                                                               t.id_patient,
                                                               t.id_inst_orig,
                                                               t.id_inst_dest,
                                                               t.id_dep_clin_serv,
                                                               t.decision_urg_level,
                                                               t.id_prof_requested,
                                                               t.id_prof_redirected,
                                                               t.id_speciality,
                                                               t.flg_type,
                                                               t.id_prof_status,
                                                               t.id_external_sys) status_info,
                           t.decision_urg_level,
                           (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.' ||
                                                           t.decision_urg_level,
                                                           t.decision_urg_level,
                                                           i_lang)
                              FROM dual) desc_decision_urg_level,
                           t.id_external_sys,
                           pk_ref_core.get_ref_observations(i_lang,
                                                            i_prof,
                                                            l_my_data.id_profile_template,
                                                            t.id_external_request,
                                                            t.flg_status,
                                                            t.id_prof_status,
                                                            t.dt_schedule_tstz,
                                                            (SELECT pk_ref_utils.can_view_clinical_data(i_lang,
                                                                                                        i_prof,
                                                                                                        l_my_data.flg_category,
                                                                                                        l_my_data.id_profile_template,
                                                                                                        t.id_prof_requested,
                                                                                                        t.id_workflow)
                                                               FROM dual),
                                                            t.id_prof_triage,
                                                            t.id_prof_sch_sugg) observations
                      FROM TABLE(CAST(pk_ref_core_internal.get_search_ref_data(l_sql) AS t_coll_ref_search)) t) q;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package, 'GET_SEARCH_REF', o_error);
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package, 'GET_SEARCH_REF', o_error);
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SEARCH_REF',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_search_ref;

    /**
    * Function used to search for my referrals
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab
    * @param   i_prof_cat_type   Professional category type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_pat             Patient data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_my_ref
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_crit_id_tab   IN table_number,
        i_crit_val_tab  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_pat           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_crit_id_tab  table_number;
        l_crit_val_tab table_varchar;
    BEGIN
        g_error := 'Init get_search_my_ref / i_prof_cat_type=' || i_prof_cat_type;
        IF i_crit_id_tab IS NULL
        THEN
            l_crit_id_tab  := table_number();
            l_crit_val_tab := table_varchar();
        ELSE
            l_crit_id_tab  := i_crit_id_tab;
            l_crit_val_tab := i_crit_val_tab;
        END IF;
    
        l_crit_id_tab.extend;
        l_crit_val_tab.extend;
    
        l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_prof_req;
        l_crit_val_tab(l_crit_val_tab.last) := to_char(i_prof.id);
    
        RETURN get_search_ref(i_lang          => i_lang,
                              i_prof          => i_prof,
                              i_crit_id_tab   => l_crit_id_tab,
                              i_crit_val_tab  => l_crit_val_tab,
                              i_prof_cat_type => i_prof_cat_type,
                              o_flg_show      => o_flg_show,
                              o_msg           => o_msg,
                              o_msg_title     => o_msg_title,
                              o_button        => o_button,
                              o_pat           => o_pat,
                              o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SEARCH_MY_REF',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_search_my_ref;

    /**
    * Returns the priority referral list
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   o_list      Priority list   
    * @param   o_error     An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-10-2012
    */
    FUNCTION get_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_dom_ref_prio   sys_domain.code_domain%TYPE;
        l_priority_level      sys_config.value%TYPE;
        l_color_ref_prio      VARCHAR2(4000);
        l_text_color_ref_prio VARCHAR2(4000);
        l_domains             pk_types.cursor_type;
    
        l_val_tab  table_varchar;
        l_desc_tab table_varchar;
        l_rank_tab table_number;
        l_img_tab  table_varchar;
        l_icon_tab table_varchar;
    
    BEGIN
        g_error               := 'Init get_priority_list / i_prof=' || pk_utils.to_string(i_prof);
        l_priority_level      := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                             i_id_sys_config => pk_ref_constant.g_ref_priority_level);
        l_desc_dom_ref_prio   := pk_ref_constant.g_ref_prio || '.' || l_priority_level;
        l_color_ref_prio      := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.COLOR_' || l_priority_level;
        l_text_color_ref_prio := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.TEXT_COLOR_' || l_priority_level;
    
        g_error  := 'Call pk_sysdomain.get_domains / i_code_domain=' || l_desc_dom_ref_prio;
        g_retval := pk_sysdomain.get_domains(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_code_domain => l_desc_dom_ref_prio,
                                             o_domains     => l_domains,
                                             o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_domains BULK COLLECT';
        FETCH l_domains BULK COLLECT
            INTO l_val_tab, l_desc_tab, l_rank_tab, l_img_tab, l_icon_tab;
        CLOSE l_domains;
    
        --DEFAULT_PRIORITY  is the priority with biggest rank
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT val,
                   icon priority_icon,
                   pk_ref_utils.get_domain_cached_desc(i_lang, i_prof, l_color_ref_prio, val) priority_color,
                   pk_ref_utils.get_domain_cached_desc(i_lang, i_prof, l_text_color_ref_prio, val) text_priority_color,
                   priority,
                   decode(priority_desc, priority, NULL, priority_desc) priority_desc,
                   rank,
                   decode(def_val, 1, pk_ref_constant.g_yes, pk_ref_constant.g_no) default_priority
              FROM (SELECT t_img.column_value icon,
                           t_val.column_value val,
                           pk_ref_utils.get_domain_cached_desc(i_lang,
                                                               i_prof,
                                                               pk_ref_constant.g_ref_prio,
                                                               t_val.column_value) priority,
                           t_desc.column_value priority_desc,
                           t_rank.column_value rank,
                           row_number() over(ORDER BY t_rank.column_value DESC) def_val
                      FROM (SELECT rownum rn, column_value
                              FROM TABLE(l_desc_tab)) t_desc -- desc
                      JOIN (SELECT rownum rn, column_value
                             FROM TABLE(l_val_tab)) t_val -- val          
                        ON (t_desc.rn = t_val.rn)
                      JOIN (SELECT rownum rn, column_value
                             FROM TABLE(l_img_tab)) t_img -- icon
                        ON (t_val.rn = t_img.rn)
                      JOIN (SELECT rownum rn, column_value
                             FROM TABLE(l_rank_tab)) t_rank -- rank                
                        ON (t_img.rn = t_rank.rn))
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PRIORITY_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_priority_list;

    FUNCTION get_priority_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
        l_priority_type     sys_domain.code_domain%TYPE;
        l_desc_dom_ref_prio sys_domain.code_domain%TYPE;
        l_priority_level    sys_config.value%TYPE;
        l_domains           pk_types.cursor_type;
    
        l_val_tab  table_varchar;
        l_desc_tab table_varchar;
        l_rank_tab table_number;
        l_img_tab  table_varchar;
        l_icon_tab table_varchar;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    
    BEGIN
        g_error         := 'Init get_priority_list / i_prof=' || pk_utils.to_string(i_prof);
        l_priority_type := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => 'REF_PRIORITY_SHOW');
    
        l_priority_level    := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                           i_id_sys_config => pk_ref_constant.g_ref_priority_level);
        l_desc_dom_ref_prio := pk_ref_constant.g_ref_prio || '.' || l_priority_level;
    
        g_error  := 'Call pk_sysdomain.get_domains / i_code_domain=' || l_desc_dom_ref_prio;
        g_retval := pk_sysdomain.get_domains(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_code_domain => l_desc_dom_ref_prio,
                                             o_domains     => l_domains,
                                             o_error       => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_domains BULK COLLECT';
        FETCH l_domains BULK COLLECT
            INTO l_val_tab, l_desc_tab, l_rank_tab, l_img_tab, l_icon_tab;
        CLOSE l_domains;
    
        --DEFAULT_PRIORITY  is the priority with biggest rank
        g_error := 'OPEN l_ret';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => nvl(priority, priority_desc),
                                         domain_value  => val,
                                         order_rank    => rank,
                                         img_name      => decode(priority_icon,
                                                                 NULL,
                                                                 NULL,
                                                                 'RefUrgentIcon',
                                                                 'icon-UrgentIcon',
                                                                 'icon-' || priority_icon))
                  FROM (SELECT val,
                               icon priority_icon,
                               priority,
                               decode(priority_desc, priority, NULL, priority_desc) priority_desc,
                               rank
                          FROM (SELECT t_img.column_value icon,
                                       t_val.column_value val,
                                       pk_ref_utils.get_domain_cached_desc(i_lang,
                                                                           i_prof,
                                                                           pk_ref_constant.g_ref_prio,
                                                                           t_val.column_value) priority,
                                       t_desc.column_value priority_desc,
                                       t_rank.column_value rank,
                                       row_number() over(ORDER BY t_rank.column_value DESC) def_val
                                  FROM (SELECT rownum rn, column_value
                                          FROM TABLE(l_desc_tab)) t_desc -- desc
                                  JOIN (SELECT rownum rn, column_value
                                         FROM TABLE(l_val_tab)) t_val -- val          
                                    ON (t_desc.rn = t_val.rn)
                                  JOIN (SELECT rownum rn, column_value
                                         FROM TABLE(l_img_tab)) t_img -- icon
                                    ON (t_val.rn = t_img.rn)
                                  JOIN (SELECT rownum rn, column_value
                                         FROM TABLE(l_rank_tab)) t_rank -- rank                
                                    ON (t_img.rn = t_rank.rn))
                         ORDER BY rank)
                 WHERE (l_priority_type = 'C' AND val = 'Y')
                    OR l_priority_type <> 'C');
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PRIORITY_LIST',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
    END get_priority_list;

    /**
    * Returns the list of types of referral handoff
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   i_id_ref_tab     Array of referral identifiers
    * @param   o_list      Types of referral handoff   
    * @param   o_error     An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref_tab IN table_number,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_list_inst      t_cur_ref_handoff_inst;
        l_rec_inst       t_rec_ref_handoff_inst;
        l_params         VARCHAR2(1000 CHAR);
        l_inst_available VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref_tab.count=' || i_id_ref_tab.count;
    
        g_error := 'Init get_handoff_type / ' || l_params;
        pk_alertlog.log_init(g_error);
    
        -- check if there are any origin institutions available to hand off the referral
        l_inst_available := pk_ref_constant.g_no;
        g_retval         := get_handoff_inst(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_inst_parent => NULL,
                                             i_id_ref_tab     => i_id_ref_tab,
                                             o_list_inst      => l_list_inst,
                                             o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_list_inst / ' || l_params;
        FETCH l_list_inst
            INTO l_rec_inst;
        CLOSE l_list_inst;
    
        g_error := 'l_rec_inst.id_institution=' || l_rec_inst.id_institution || ' / ' || l_params;
        IF l_rec_inst.id_institution IS NOT NULL
        THEN
            l_inst_available := pk_ref_constant.g_yes;
        END IF;
    
        g_error := 'OPEN o_list FOR / l_inst_available=' || l_inst_available || ' / ' || l_params;
        OPEN o_list FOR
            SELECT pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => t.code_label) label,
                   t.data,
                   NULL icon,
                   t.flg_default,
                   t.id_workflow,
                   t.flg_active
              FROM (SELECT pk_ref_constant.g_sm_ref_transfresp_t058 code_label,
                           'INST' data,
                           pk_ref_constant.g_no flg_default,
                           pk_ref_constant.g_wf_transfresp_inst id_workflow,
                           l_inst_available flg_active
                      FROM dual
                     WHERE pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_handoff_inst_enabled,
                                                   i_prof    => i_prof) = pk_ref_constant.g_yes
                    UNION ALL
                    SELECT pk_ref_constant.g_sm_ref_transfresp_t059 code_label,
                           'PROF' data,
                           pk_ref_constant.g_yes flg_default,
                           pk_ref_constant.g_wf_transfresp id_workflow,
                           pk_ref_constant.g_yes flg_active -- always active
                      FROM dual) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error || ' / ' || SQLERRM);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HANDOFF_TYPE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_handoff_type;

    /**
    * Returns the list of institutions to transfer the referral
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_id_inst_parent        Institution parent identifier
    * @param   i_id_ref_tab            array of referral identifiers
    * @param   o_list_inst             List of institutions to transfer the referral   
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_inst_parent IN institution.id_institution%TYPE,
        i_id_ref_tab     IN table_number,
        o_list_inst      OUT t_cur_ref_handoff_inst,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sc_value            sys_config.value%TYPE;
        l_cfg_flg_type_tab    table_varchar;
        l_id_inst_parent      institution.id_institution%TYPE;
        l_ref_transfresp_t063 sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_handoff_inst / i_id_inst_parent=' || i_id_inst_parent || ' i_id_ref_tab.count=' ||
                   i_id_ref_tab.count;
    
        l_ref_transfresp_t063 := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => pk_ref_constant.g_sm_ref_transfresp_t063);
    
        -----------
        -- select root institution
        IF i_id_inst_parent IS NULL
        THEN
        
            l_sc_value         := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                              i_id_sys_config => pk_ref_constant.g_ref_tr_inst_par_type);
            l_cfg_flg_type_tab := pk_utils.str_split_l(i_list => l_sc_value, i_delim => ',');
        
            g_error := 'REF_TR_INST_PARENT_TYPE / l_sc_value=' || l_sc_value;
        
            -- getting the id_institution of the "closest" parent that have flg_type=config
            BEGIN
                SELECT id_institution
                  INTO l_id_inst_parent
                  FROM (SELECT i.id_institution
                          FROM institution i
                         WHERE id_institution != i_prof.institution
                           AND i.flg_type IN (SELECT /*+OPT_ESTIMATE (table tc rows=1)*/
                                               tc.column_value
                                                FROM TABLE(CAST(l_cfg_flg_type_tab AS table_varchar)) tc)
                         START WITH id_institution = i_prof.institution
                        CONNECT BY PRIOR id_parent = id_institution
                         ORDER BY LEVEL)
                 WHERE rownum <= 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_inst_parent := NULL; -- show all 
            END;
        
        ELSE
            l_id_inst_parent := i_id_inst_parent;
        END IF;
    
        -----------
        -- getting all possible id_inst_orig (orig institutions that are referring that speciality for that dest institution)
        DELETE FROM tbl_temp;
        INSERT INTO tbl_temp
            (num_1, num_2, vc_1, vc_2)
            WITH tbl_orig AS
             (SELECT v.id_inst_orig
                FROM v_ref_network v
               WHERE v.flg_default_dcs = pk_ref_constant.g_yes
                 AND v.id_inst_orig != i_prof.institution -- do not show the institution itself
                 AND (SELECT pk_sysconfig.get_config(pk_ref_constant.g_ref_handoff_inst_enabled,
                                                     profissional(NULL, v.id_inst_orig, i_prof.software))
                        FROM dual) = pk_ref_constant.g_yes -- show only institutions where this funcionality is available
                 AND EXISTS (SELECT /*+OPT_ESTIMATE (table ti rows=1)*/
                       1
                        FROM p1_external_request p1
                        JOIN TABLE(CAST(i_id_ref_tab AS table_number)) ti
                          ON (ti.column_value = p1.id_external_request)
                       WHERE p1.id_inst_orig = i_prof.institution -- orig institution of all requests is the institution where the prof is
                         AND v.id_institution = p1.id_inst_dest
                         AND v.id_speciality = p1.id_speciality
                         AND nvl(v.id_external_sys, 0) = nvl(p1.id_external_sys, 0)))
            SELECT DISTINCT i1.id_institution, i1.id_parent, i1.flg_type, i1.code_institution
              FROM institution i1
            -- we must select orig institutions that are referring that speciality for that dest institution
             START WITH i1.id_institution IN (SELECT id_inst_orig
                                                FROM tbl_orig)
            CONNECT BY PRIOR i1.id_parent = i1.id_institution;
    
        -----------
        -- select institutions that are parent of those that are 'referable'
        g_error := 'OPEN o_list_inst FOR / i_id_inst_parent=' || i_id_inst_parent || ' l_id_inst_parent=' ||
                   l_id_inst_parent;
        OPEN o_list_inst FOR
            SELECT t.id_institution,
                   pk_translation.get_translation(i_lang, t.code_institution) institution_name,
                   CASE
                        WHEN COUNT(DISTINCT t.flg_type) over() = 1 THEN
                         (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_domain_inst_flg_type, t.flg_type, i_lang)
                            FROM dual)
                        ELSE
                         l_ref_transfresp_t063
                    END inst_type_desc,
                   -- indicates if this institution is selectable or not (if has professionals associated)
                   (SELECT decode(COUNT(1), 0, pk_ref_constant.g_no, pk_ref_constant.g_yes)
                      FROM prof_soft_inst psi
                      JOIN prof_institution pi
                        ON (pi.id_professional = psi.id_professional AND pi.id_institution = psi.id_institution)
                     WHERE psi.id_software = i_prof.software
                       AND psi.id_institution = t.id_institution
                       AND pi.flg_state = pk_ref_constant.g_active
                       AND pi.dt_end_tstz IS NULL
                       AND pi.id_institution != i_prof.institution -- do not select the institution itself
                       AND rownum <= 1) flg_select,
                   -- indicates if this institution has children
                   (SELECT decode(COUNT(1), 0, pk_ref_constant.g_no, pk_ref_constant.g_yes)
                      FROM tbl_temp t2 -- child must be one of possible id_inst_orig (tbl_temp)
                     WHERE t2.num_2 = t.id_institution) flg_has_child
              FROM (SELECT t.num_1 id_institution, t.num_2 id_parent, t.vc_1 flg_type, t.vc_2 code_institution
                      FROM tbl_temp t
                     WHERE ((i_id_inst_parent IS NULL AND l_id_inst_parent IS NOT NULL AND t.num_1 = l_id_inst_parent) -- first level shows self institution
                           OR (i_id_inst_parent IS NULL AND l_id_inst_parent IS NULL AND t.num_2 IS NULL) -- in case of showing all institutions
                           OR (i_id_inst_parent IS NOT NULL AND t.num_2 = l_id_inst_parent) -- not the first level
                           )) t
             ORDER BY institution_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HANDOFF_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list_inst);
            RETURN FALSE;
    END get_handoff_inst;

    /**
    * Returns hand off data of origin institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_tr_tab      Array of hand off identifiers
    * @param   o_tr_orig_det    Origin information of hand off referral   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_detail_orig
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_tr_tab   IN table_number,
        o_tr_orig_det OUT t_cur_handoff_orig,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_tr_tab.count=' || i_id_tr_tab.count;
        g_error  := 'Init get_handoff_detail_orig / ' || l_params;
    
        -- Hand off active detail
        g_error := 'OPEN o_tr_orig_det FOR / ' || l_params;
        OPEN o_tr_orig_det FOR
            SELECT t.id_workflow,
                   pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || t.id_inst_orig_tr) inst_orig_tr_desc, -- hand off orig
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_ref_owner, -- professional responsible for the referral
                   t.id_prof_dest,
                   -- hand_off_to
                   CASE t.id_workflow
                       WHEN pk_ref_constant.g_wf_transfresp THEN
                        pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest) -- dest professional
                       WHEN pk_ref_constant.g_wf_transfresp_inst THEN
                        pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || t.id_inst_dest_tr) -- hand off dest institution
                   END hand_off_to,
                   -- reason_desc
                   nvl(t.reason_code_text,
                       pk_translation.get_translation(i_lang, pk_ref_constant.g_p1_reason_code || t.id_reason_code)) reason_desc,
                   t.notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_tr, i_prof) dt_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_status
              FROM (SELECT row_number() over(PARTITION BY rh.id_external_request, rh.id_workflow, rh.id_status ORDER BY rh.dt_created DESC) AS rn,
                           rh.id_status,
                           rh.id_workflow,
                           rh.id_prof_ref_owner,
                           rh.id_prof_transf_owner,
                           rh.id_prof_dest,
                           rh.id_reason_code,
                           rh.reason_code_text,
                           rh.notes,
                           nvl(rh.dt_update, rh.dt_created) dt_tr,
                           rh.id_professional,
                           rh.id_institution,
                           rh.id_inst_orig_tr,
                           rh.id_inst_dest_tr
                      FROM ref_trans_responsibility r
                      JOIN ref_trans_resp_hist rh
                        ON (r.id_trans_resp = rh.id_trans_resp)
                      JOIN TABLE(CAST(i_id_tr_tab AS table_number)) t
                        ON t.column_value = r.id_trans_resp
                     WHERE r.flg_active = pk_ref_constant.g_yes
                       AND rh.flg_active = pk_ref_constant.g_yes
                       AND rh.id_status = pk_workflow.get_status_begin(rh.id_workflow) -- getting all begin status related to this referral
                    ) t
             WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HANDOFF_DETAIL_ORIG',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_tr_orig_det);
            RETURN FALSE;
    END get_handoff_detail_orig;

    /**
    * Returns hand off data of dest institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Professional data
    * @param   i_id_tr_tab      Array of hand off identifiers
    * @param   o_tr_orig_det    Origin information of hand off referral   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_detail_dest
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_id_tr_tab   IN table_number,
        o_tr_dest_det OUT t_cur_handoff_dest,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' prof_data=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' i_id_tr_tab.count=' || i_id_tr_tab.count;
        g_error  := 'Init get_handoff_detail_dest / ' || l_params;
    
        -- Hand off active detail
        g_error := 'OPEN o_tr_dest_det FOR / ' || l_params;
        OPEN o_tr_dest_det FOR
            SELECT t.id_workflow,
                   pk_workflow.get_status_info(i_lang, i_prof, t.id_workflow, t.id_status, i_prof_data.id_category, i_prof_data.id_profile_template, i_prof_data.id_functionality, pk_ref_tr_status.init_tr_param_tab(i_lang, i_prof, t.id_trans_resp, t.id_external_request, t.id_prof_transf_owner, t.id_prof_dest, t.id_inst_orig_tr, t.id_inst_dest_tr, NULL)).get_desc_status() desc_status,
                   t.id_prof_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_dest) prof_name_dest, -- dest professional
                   t.notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_tr, i_prof) dt_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_status
              FROM (SELECT tr.id_status,
                           tr.id_workflow,
                           tr.id_prof_ref_owner,
                           tr.id_prof_transf_owner,
                           tr.id_prof_dest,
                           tr.id_reason_code,
                           tr.reason_code_text,
                           tr.notes,
                           nvl(tr.dt_update, tr.dt_created) dt_tr,
                           tr.id_professional,
                           tr.id_institution,
                           tr.id_inst_orig_tr,
                           tr.id_inst_dest_tr,
                           tr.id_external_request,
                           tr.id_trans_resp
                      FROM ref_trans_responsibility tr
                      JOIN TABLE(CAST(i_id_tr_tab AS table_number)) t
                        ON t.column_value = tr.id_trans_resp
                     WHERE tr.flg_active = pk_ref_constant.g_yes) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HANDOFF_DETAIL_DEST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_tr_dest_det);
            RETURN FALSE;
    END get_handoff_detail_dest;

    /**
    * Gets field 'Come Back' 
    * 
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   o_value    Values to populate multichoice
    * @param   o_error    An error message, set when return=false 
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Joana Barroso
    * @version 1.0
    * @since   10-10-2010
    */
    FUNCTION get_come_back_vals
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_value OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN
    
     IS
    BEGIN
        g_error := 'Init get_come_back_vals';
        OPEN o_value FOR
            SELECT pk_message.get_message(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_code_mess => pk_ref_constant.g_sm_common_t001) label,
                   pk_ref_constant.g_yes data
              FROM dual
            UNION ALL
            SELECT pk_message.get_message(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_code_mess => pk_ref_constant.g_sm_common_t002) label,
                   pk_ref_constant.g_no data
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COME_BACK_VALS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END get_come_back_vals;

    /**
    * Returns the list of transitions available from the action previously selected
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_prof_data             Professional data
    * @param   i_id_action             Action identifier
    * @param   i_id_workflow           Workflow identifier
    * @param   i_id_status_begin       Begin status identifier
    * @param   i_param                 Action identifier
    * @param   i_value_default         Value to be set as default
    * @param   o_transitions           Transition data available
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-08-2013
    */
    FUNCTION get_trans_from_action
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_data       IN t_rec_prof_data,
        i_id_action       IN wf_action.id_action%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        i_param           IN table_varchar,
        i_value_default   IN VARCHAR2,
        o_transitions     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params            VARCHAR2(1000 CHAR);
        l_flg_enabled       VARCHAR2(1 CHAR);
        l_exists_transition VARCHAR2(1 CHAR);
        l_tab_wf_transition t_coll_wf_transition;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' id_category=' || i_prof_data.id_category ||
                    ' id_profile_template=' || i_prof_data.id_profile_template || ' id_functionality=' ||
                    i_prof_data.id_functionality || ' i_id_action=' || i_id_action || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_status_begin=' || i_id_status_begin || ' i_value_default=' ||
                    i_value_default;
        g_error  := 'Init get_trans_from_action / ' || l_params;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting valid transitions for this action
        g_error  := 'Call pk_ref_core_internal.get_action_trans_valid / ' || l_params;
        g_retval := pk_ref_core_internal.get_action_trans_valid(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_id_action           => i_id_action,
                                                                i_id_workflow         => i_id_workflow,
                                                                i_id_status_begin     => i_id_status_begin,
                                                                i_id_category         => i_prof_data.id_category,
                                                                i_id_profile_template => i_prof_data.id_profile_template,
                                                                i_id_functionality    => i_prof_data.id_functionality,
                                                                i_param               => i_param,
                                                                i_behaviour           => 0, -- gets all valid transitions
                                                                o_exists_transition   => l_exists_transition,
                                                                o_enabled             => l_flg_enabled,
                                                                o_transition_info     => l_tab_wf_transition,
                                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_transitions / ' || l_params;
        OPEN o_transitions FOR
            SELECT decode(t.id_workflow, pk_ref_constant.g_wf_pcc_hosp, NULL, t.id_workflow) id_workflow,
                   pk_ref_status.convert_status_v(t.id_status_begin) id_status_begin,
                   pk_ref_status.convert_status_v(t.id_status_end) id_status_end,
                   t.desc_transition description,
                   decode(rownum, i_value_default, pk_ref_constant.g_yes, pk_ref_constant.g_no) flg_default,
                   pk_ref_constant.get_action_name(t.id_workflow_action) action
              FROM (SELECT *
                      FROM TABLE(CAST(l_tab_wf_transition AS t_coll_wf_transition))
                     ORDER BY rank) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRANS_FROM_ACTION',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_transitions);
            RETURN FALSE;
    END get_trans_from_action;

    /**
    * Returns the professional name that is responsible for the referral 
    * Used by reports
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_ref        Referral identifier
    * @param   o_prof_data     Professional data that is responsible for the referral
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   16-04-2010   
    */
    FUNCTION get_prof_resp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_resp_name VARCHAR2(1000 CHAR);
    BEGIN
        g_error          := 'Init pk_p1_external_request.get_prof_resp / ID_REF=' || i_id_ref;
        l_prof_resp_name := pk_p1_external_request.get_prof_req_name(i_lang   => i_lang,
                                                                     i_prof   => i_prof,
                                                                     i_id_ref => i_id_ref);
    
        g_error := 'OPEN o_prof_data / PROF_NAME=' || l_prof_resp_name;
        OPEN o_prof_data FOR
            SELECT l_prof_resp_name prof_name
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_RESP',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof_data);
            RETURN FALSE;
    END get_prof_resp;

    /**
    * Returns the rank to order by column of documents attached to the referral
    * Used in grids to sort column of documents attached to the referral
    *
    * @param   i_lang            Language associated to the professional 
    * @param   i_prof            Professional, institution and software ids
    * @param   i_doc_can_receive Can register receipt of the document?
    * @param   i_nr_clinical_doc Number of clinical documents attached to the referral
    * @param   i_flg_sent_by     Document sent by (E)mail; (F)ax; (M)ail
    * @param   i_flg_received    Document received: (Y)es; (N)o.    
    *
    * @value   i_doc_can_receive {*} Y-yes {*} N-no
    * @value   i_flg_sent_by {*} E-Email {*} F-Fax {*} M-Mail
    * @value   i_flg_received {*} Y- yes {*} N- no
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   08-10-2013
    */
    FUNCTION get_flg_attach_to_sort
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_can_receive IN VARCHAR2,
        i_nr_clinical_doc IN NUMBER,
        i_flg_sent_by     IN VARCHAR2,
        i_flg_received    IN VARCHAR2
    ) RETURN NUMBER IS
        l_params VARCHAR2(1000 CHAR);
        l_result NUMBER(24);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_doc_can_receive=' || i_doc_can_receive ||
                    ' i_nr_clinical_doc=' || i_nr_clinical_doc || ' i_flg_sent_by=' || i_flg_sent_by ||
                    ' i_flg_received=' || i_flg_received;
        g_error  := 'Init get_flg_attach_to_sort / ' || l_params;
    
        l_result := (2 + nvl(i_nr_clinical_doc, 99998)); -- default rank
    
        IF i_doc_can_receive = pk_ref_constant.g_yes
           AND i_flg_sent_by = pk_ref_constant.g_yes
        THEN
            CASE
                WHEN i_flg_received = pk_ref_constant.g_yes THEN
                    l_result := 0;
                WHEN nvl(i_flg_received, pk_ref_constant.g_no) = pk_ref_constant.g_no THEN
                    l_result := 1;
                ELSE
                    NULL; -- not supposed to....
            END CASE;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_flg_attach_to_sort;

    FUNCTION get_referral_med_dest_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        o_med_dest_data OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title         VARCHAR2(200 CHAR) := pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T131');
        l_title_cert    VARCHAR2(30 CHAR) := pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T132');
        l_title_name    VARCHAR2(200 CHAR) := pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T133');
        l_title_surname VARCHAR2(200 CHAR) := pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T134');
        l_title_phone   VARCHAR2(30 CHAR) := pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T135');
    
    BEGIN
    
        OPEN o_med_dest_data FOR
            SELECT label_group, title, VALUE, rank, dt_insert, prof_name, prof_spec
              FROM (SELECT DISTINCT l_title label_group,
                                    l_title_cert || ':' AS title,
                                    per.prof_certificate AS VALUE,
                                    0 AS rank,
                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, pd.dt_insert_tstz, i_prof) dt_insert,
                                    (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional)
                                       FROM dual) prof_name,
                                    (SELECT pk_ref_utils.get_prof_spec_signature(i_lang,
                                                                                 i_prof,
                                                                                 pd.id_professional,
                                                                                 pd.id_institution)
                                       FROM dual) prof_spec,
                                    pd.id_detail
                      FROM p1_external_request per
                     INNER JOIN p1_detail pd
                        ON pd.id_external_request = per.id_external_request
                     WHERE per.id_external_request = i_id_ref
                     ORDER BY pd.id_detail DESC)
             WHERE rownum = 1
            UNION ALL
            SELECT label_group, title, VALUE, rank, dt_insert, prof_name, prof_spec
              FROM (SELECT DISTINCT l_title label_group,
                                    l_title_name || ':' AS title,
                                    per.prof_name AS VALUE,
                                    5 AS rank,
                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, pd.dt_insert_tstz, i_prof) dt_insert,
                                    (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional)
                                       FROM dual) prof_name,
                                    (SELECT pk_ref_utils.get_prof_spec_signature(i_lang,
                                                                                 i_prof,
                                                                                 pd.id_professional,
                                                                                 pd.id_institution)
                                       FROM dual) prof_spec,
                                    pd.id_detail
                      FROM p1_external_request per
                     INNER JOIN p1_detail pd
                        ON pd.id_external_request = per.id_external_request
                     WHERE per.id_external_request = i_id_ref
                     ORDER BY pd.id_detail DESC)
             WHERE rownum = 1
            UNION ALL
            SELECT label_group, title, VALUE, rank, dt_insert, prof_name, prof_spec
              FROM (SELECT DISTINCT l_title label_group,
                                    l_title_surname || ':' AS title,
                                    per.prof_surname AS VALUE,
                                    10 AS rank,
                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, pd.dt_insert_tstz, i_prof) dt_insert,
                                    (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional)
                                       FROM dual) prof_name,
                                    (SELECT pk_ref_utils.get_prof_spec_signature(i_lang,
                                                                                 i_prof,
                                                                                 pd.id_professional,
                                                                                 pd.id_institution)
                                       FROM dual) prof_spec,
                                    pd.id_detail
                      FROM p1_external_request per
                     INNER JOIN p1_detail pd
                        ON pd.id_external_request = per.id_external_request
                     WHERE per.id_external_request = i_id_ref
                     ORDER BY pd.id_detail DESC)
             WHERE rownum = 1
            UNION ALL
            SELECT label_group, title, VALUE, rank, dt_insert, prof_name, prof_spec
              FROM (SELECT DISTINCT l_title label_group,
                                    l_title_phone || ':' AS title,
                                    per.prof_phone AS VALUE,
                                    15 AS rank,
                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, pd.dt_insert_tstz, i_prof) dt_insert,
                                    (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional)
                                       FROM dual) prof_name,
                                    (SELECT pk_ref_utils.get_prof_spec_signature(i_lang,
                                                                                 i_prof,
                                                                                 pd.id_professional,
                                                                                 pd.id_institution)
                                       FROM dual) prof_spec,
                                    pd.id_detail
                      FROM p1_external_request per
                     INNER JOIN p1_detail pd
                        ON pd.id_external_request = per.id_external_request
                     WHERE per.id_external_request = i_id_ref
                     ORDER BY pd.id_detail DESC)
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_MED_DEST_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med_dest_data);
            RETURN FALSE;
        
    END get_referral_med_dest_data;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_list;
/
