CREATE OR REPLACE PACKAGE BODY pk_p1_ext_sys AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_retval BOOLEAN;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_sysdate_tstz TIMESTAMP(6) WITH TIME ZONE;
    g_error        VARCHAR2(1000 CHAR);
    g_found        BOOLEAN;

    g_p1_pseudo_status_i VARCHAR2(2 CHAR) := 'I1'; -- Pseudo-estado para diferenciar icon do estado emitido entre a institui¿Æo que envia e a que recebe.
    g_p1_pseudo_status_r VARCHAR2(2 CHAR) := 'R1'; -- Pseudo-estado para diferenciar icon de reencaminhado

    /**
    * Private Function. Check if is a validid codification
    *
    * @param i_lang          professional language
    * @param i_prof          professional id, institution and software
    * @param i_mcdt          analisis, exams ou intervention (id, id_institution, id_req
    * @param i_codification  mdct's codifications
    * @param o_error
    *
    * @return                TRUE if sucess, FALSE otherwise
    * @author                Joana Barroso
    * @version               1.0
    * @since                 2009/09/03
    */
    FUNCTION check_codification_count
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mcdt         IN table_number,
        i_codification IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_codification codification.id_codification%TYPE;
    BEGIN
    
        g_error := 'Init check_codification_count';
        IF i_mcdt.exists(1)
        THEN
        
            IF i_codification.exists(1)
            THEN
                IF NOT i_mcdt.count = i_codification.count
                THEN
                    g_error := 'i_mcdt.count = ' || i_mcdt.count || ' and i_codification.count = ' ||
                               i_codification.count;
                    RAISE g_exception;
                END IF;
            END IF;
        
            g_error := 'FOR i IN 1 .. ' || i_codification.count;
            FOR i IN 1 .. i_codification.count
            LOOP
            
                IF i > 1
                THEN
                    l_codification := i_codification(1);
                    IF NOT i_codification(i) = l_codification
                    THEN
                        g_error := 'i_codification(i-1)= ' || i_codification(i - 1) || ' and i_codification(i-1) = ' ||
                                   i_codification(i);
                        RAISE g_exception;
                    END IF;
                
                END IF;
            
            END LOOP;
        
        ELSE
            g_error := 'i_mcdt is null or i_codification is null';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CHECK_CODIFICATION_COUNT',
                                                     o_error    => o_error);
    END check_codification_count;

    /**
    * Gets MCDT codification surrogate key (used as parameter in MCDTs functions)
    *
    * @param   I_LANG                  Language associated to the professional executing the request
    * @param   I_PROF                  Professional, institution and software ids
    * @param   i_mcdt                  MCDT identifier: id_analysis, id_exam, id_intervention
    * @param   i_codification          Codification identifier
    * @param   i_flg_type              MCDT type: {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR
    * @param   o_mcdt_codification     MCDT codification surrogate key
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-09-2009
    */
    FUNCTION get_mcdt_codification
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mcdt              IN table_number,
        i_codification      IN table_number,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        o_mcdt_codification OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error             := 'INIT';
        o_mcdt_codification := table_number();
    
        g_error := 'CASE ' || i_flg_type;
        CASE
            WHEN i_flg_type = pk_ref_constant.g_p1_type_a THEN
            
                g_error := 'SELECT ANALYSIS';
                SELECT id_analysis_codification
                  BULK COLLECT
                  INTO o_mcdt_codification
                  FROM analysis_codification ac
                 WHERE ac.flg_available = pk_ref_constant.g_yes
                   AND ac.id_analysis IN (SELECT column_value
                                            FROM TABLE(CAST(i_mcdt AS table_number)))
                   AND ac.id_codification IN (SELECT column_value
                                                FROM TABLE(CAST(i_codification AS table_number)));
            
            WHEN i_flg_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e) THEN
            
                g_error := 'SELECT EXAM';
                pk_alertlog.log_debug(g_error);
                SELECT id_exam_codification
                  BULK COLLECT
                  INTO o_mcdt_codification
                  FROM exam_codification ec
                 WHERE ec.flg_available = pk_ref_constant.g_yes
                   AND ec.id_exam IN (SELECT column_value
                                        FROM TABLE(CAST(i_mcdt AS table_number)))
                   AND ec.id_codification IN (SELECT column_value
                                                FROM TABLE(CAST(i_codification AS table_number)));
            
            WHEN i_flg_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f) THEN
            
                g_error := 'SELECT INTERV';
                SELECT id_interv_codification
                  BULK COLLECT
                  INTO o_mcdt_codification
                  FROM interv_codification ic
                 WHERE ic.flg_available = pk_ref_constant.g_yes
                   AND ic.id_intervention IN (SELECT column_value
                                                FROM TABLE(CAST(i_mcdt AS table_number)))
                   AND ic.id_codification IN (SELECT column_value
                                                FROM TABLE(CAST(i_codification AS table_number)));
            
            ELSE
                g_error := 'get_mcdt_codification / CASE NOT FOUND ' || i_flg_type;
                RAISE g_exception;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_MCDT_CODIFICATION',
                                                     o_error    => o_error);
        
            RETURN FALSE;
    END get_mcdt_codification;

    FUNCTION get_p1_internal
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_filter   IN VARCHAR2,
        i_type     IN p1_external_request.flg_type%TYPE,
        i_var_desc IN table_varchar,
        i_var_val  IN table_varchar
    ) RETURN t_tbl_p1_grid IS
        l_sql                VARCHAR2(32000);
        l_sd_status_color    VARCHAR2(50 CHAR);
        l_sd_toschedule_icon VARCHAR2(50 CHAR);
        l_msg_common_m019    VARCHAR2(4000);
        l_msg_common_m020    VARCHAR2(4000);
        l_my_pt              profile_template.id_profile_template%TYPE;
        l_id_cat             category.id_category%TYPE;
        l_inst_type          institution.flg_type%TYPE;
    
        l_ret   t_tbl_p1_grid;
        l_error t_error_out;
    
        my_code NUMBER;
        my_errm VARCHAR2(1000 CHAR);
        --l_desc_dom_ref_prio  sys_domain.code_domain%TYPE;
        --l_priority_level     sys_config.value%TYPE;
        --l_color_ref_prio      sys_domain.code_domain%TYPE;
        --l_text_color_ref_prio sys_domain.code_domain%TYPE;
    
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
    
        --g_error := 'Call pk_ref_core.get_referral_list / i_prof=' || pk_utils.to_string(i_prof) || ' i_filter=' ||
        --           i_filter || ' i_type=' || i_type;
        --RETURN pk_ref_core.get_referral_list(i_lang     => i_lang,
        --                                     i_prof     => i_prof,
        --                                     i_patient  => NULL,
        --                                     i_filter   => i_filter,
        --                                     i_type     => i_type,
        --                                     o_ref_list => o_p1,
        --                                     o_error    => o_error);
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init get_p1_internal / FILTER=' || i_filter || ' TYPE=' || i_type;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        l_my_pt  := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        l_id_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        ----------------------
        -- CONF
        ----------------------         
        g_error           := 'Call pk_message.get_message';
        l_msg_common_m019 := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M019');
        l_msg_common_m020 := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M020');
    
        --l_priority_level    := pk_sysconfig.get_config(pk_ref_constant.g_ref_priority_level, i_prof);
        --l_desc_dom_ref_prio := pk_ref_constant.g_ref_prio || '.' || l_priority_level;
        --l_color_ref_prio      := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.COLOR_' || l_priority_level;
        --l_text_color_ref_prio := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.TEXT_COLOR_' || l_priority_level;
    
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'Getting institution type / ID_INSTITUTION=' || i_prof.institution;
        SELECT i.flg_type
          INTO l_inst_type
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        g_error := 'INST_TYPE=' || l_inst_type || ' ID_INSTITUTION=' || i_prof.institution;
        IF l_inst_type = pk_ref_constant.g_hospital
        THEN
            l_sd_status_color    := 'P1_STATUS_COLOR.MED_HS';
            l_sd_toschedule_icon := 'P1_TOSCHEDULE_GRID_ICON.1';
            g_p1_pseudo_status_i := pk_ref_constant.g_p1_pseudo_status_i2;
        ELSE
            l_sd_status_color    := 'P1_STATUS_COLOR.MED_CS';
            l_sd_toschedule_icon := 'P1_TOSCHEDULE_GRID_ICON.1';
            g_p1_pseudo_status_i := pk_ref_constant.g_p1_pseudo_status_i1;
        END IF;
    
        g_error  := 'Call pk_ref_core_internal.get_grid_sql / filter=' || i_filter;
        g_retval := pk_ref_core_internal.get_grid_sql(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_var_desc => i_var_desc,
                                                      i_var_val  => i_var_val,
                                                      i_filter   => i_filter,
                                                      o_sql      => l_sql,
                                                      o_error    => l_error);
    
        g_error := 'OPEN o_p1 FOR';
    
        SELECT t_rec_p1_grid(id_p1               => q.id_p1,
                             num_req             => q.num_req,
                             dt_p1               => q.dt_p1,
                             flg_type            => q.flg_type,
                             prof_requested_name => q.prof_requested_name,
                             id_patient          => q.id_patient,
                             pat_name            => q.pat_name,
                             pat_gender          => q.pat_gender,
                             pat_age             => q.pat_age,
                             photo               => q.photo,
                             inst_dest_name      => q.inst_dest_name,
                             dest_department     => q.dest_department,
                             clin_srv_name       => q.clin_srv_name,
                             p1_spec_name        => q.p1_spec_name,
                             type_icon           => q.type_icon,
                             flg_status          => q.flg_status,
                             flg_status_desc     => q.flg_status_desc,
                             status_icon         => q.status_icon,
                             status_rank         => q.status_rank2,
                             status_colors       => q.status_colors,
                             priority_info       => q.priority_info,
                             priority_desc       => q.priority_desc,
                             priority_icon       => q.priority_icon,
                             dt_schedule         => q.dt_schedule,
                             hour_schedule       => q.hour_schedule,
                             dt_sch_millis       => q.dt_sch_millis,
                             dt_elapsed          => q.dt_elapsed,
                             id_schedule         => q.id_schedule,
                             inst_orig_name      => q.inst_orig_name,
                             flg_editable        => q.flg_editable,
                             flg_task_editable   => q.flg_task_editable,
                             desc_day            => q.desc_day,
                             desc_days           => q.desc_days,
                             date_field          => q.date_field,
                             dt_server           => q.dt_server,
                             can_cancel          => q.can_cancel,
                             can_sent            => q.can_sent,
                             observations        => q.observations,
                             id_rep_duplicata    => q.id_rep_duplicata,
                             id_rep_reprint      => q.id_rep_reprint,
                             id_task_type        => q.id_task_type,
                             id_codification     => q.id_codification,
                             dt_order            => q.dt_order,
                             flg_migrated        => q.flg_migrated)
        
          BULK COLLECT
          INTO l_ret
          FROM (SELECT v.id_external_request id_p1,
                       v.num_req,
                       pk_date_utils.date_chr_short_read(i_lang,
                                                         pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                          v.id_external_request,
                                                                                          v.flg_status,
                                                                                          v.id_workflow),
                                                         i_prof) dt_p1,
                       v.flg_type,
                       pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_id_prof_requested => v.id_prof_requested,
                                                                i_id_prof_roda      => v.id_prof_orig) prof_requested_name,
                       v.id_patient,
                       v.pat_name,
                       v.pat_gender,
                       pk_patient.get_pat_age(i_lang, v.id_patient, i_prof) pat_age,
                       pk_patphoto.get_pat_foto(v.id_patient, i_prof) photo,
                       pk_ref_core.get_inst_name(i_lang,
                                                 i_prof,
                                                 v.flg_status,
                                                 v.id_inst_dest,
                                                 v.code_inst_dest,
                                                 v.inst_dest_abbrev) inst_dest_name,
                       v.dep_abbreviation dest_department,
                       decode(v.id_inst_dest,
                              NULL,
                              NULL,
                              decode(v.id_dep_clin_serv,
                                     NULL,
                                     pk_translation.get_translation(i_lang, v.code_speciality),
                                     pk_translation.get_translation(i_lang, v.code_clinical_service))) clin_srv_name,
                       decode(v.id_workflow,
                              pk_ref_constant.g_wf_srv_srv,
                              pk_translation.get_translation(i_lang, v.code_clinical_service),
                              nvl2(v.code_speciality,
                                   pk_translation.get_translation(i_lang, v.code_speciality),
                                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, v.flg_type, i_lang)
                                      FROM dual))) p1_spec_name,
                       /*nvl2((pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                i_prof,
                                                                pk_ref_constant.g_p1_exr_flg_type,
                                                                v.flg_type)),
                       lpad((pk_ref_utils.get_domain_cached_rank(i_lang,
                                                                 i_prof,
                                                                 pk_ref_constant.g_p1_exr_flg_type,
                                                                 v.flg_type)),
                            6,
                            '0') || (pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                             i_prof,
                                                                             pk_ref_constant.g_p1_exr_flg_type,
                                                                             v.flg_type)),
                       NULL)*/
                       pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                               i_prof,
                                                               pk_ref_constant.g_p1_exr_flg_type,
                                                               v.flg_type) type_icon,
                       v.flg_status,
                       (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', v.flg_status, i_lang)
                          FROM dual) flg_status_desc,
                       -- STATUS_ICON
                       decode(v.flg_status,
                              pk_ref_constant.g_p1_status_a,
                              
                              pk_sysdomain.get_img(i_lang,
                                                   l_sd_toschedule_icon,
                                                   to_char(nvl(v.decision_urg_level,
                                                               pk_ref_constant.g_decision_urg_level_normal))),
                              
                              pk_sysdomain.get_img(i_lang,
                                                   'P1_EXTERNAL_REQUEST.FLG_STATUS',
                                                   decode(v.flg_status,
                                                          pk_ref_constant.g_p1_status_i,
                                                          g_p1_pseudo_status_i,
                                                          pk_ref_constant.g_p1_status_r,
                                                          g_p1_pseudo_status_r,
                                                          v.flg_status))) status_icon,
                       decode(v.flg_status,
                              pk_ref_constant.g_p1_status_a,
                              lpad(pk_sysdomain.get_rank(i_lang, 'P1_STATUS_RANK.MED_CS', v.flg_status) +
                                   (SELECT rank
                                      FROM sys_domain
                                     WHERE id_language = i_lang
                                       AND code_domain = l_sd_toschedule_icon
                                       AND domain_owner = pk_sysdomain.k_default_schema
                                       AND img_name =
                                           pk_sysdomain.get_img(i_lang,
                                                                l_sd_toschedule_icon,
                                                                to_char(nvl(v.decision_urg_level,
                                                                            pk_ref_constant.g_decision_urg_level_normal)))),
                                   6,
                                   '0'),
                              lpad(pk_sysdomain.get_rank(i_lang, 'P1_STATUS_RANK.MED_CS', v.flg_status), 6, '0')) status_rank2,
                       pk_ref_utils.get_domain_cached_desc(i_lang,
                                                           i_prof,
                                                           l_sd_status_color,
                                                           decode(v.flg_status,
                                                                  pk_ref_constant.g_p1_status_r,
                                                                  g_p1_pseudo_status_r,
                                                                  v.flg_status)) status_colors,
                       v.flg_priority priority_info,
                       --pk_ref_core.get_ref_priority_info(i_lang, i_prof, v.flg_priority) priority_info,
                       --pk_ref_core.get_ref_priority_desc(i_lang, i_prof, v.flg_priority) priority_desc, -- ALERT-273753
                       pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_code_domain => 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.COLOR',
                                                           i_val         => v.flg_priority) priority_desc,
                       pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                               i_prof,
                                                               pk_ref_constant.g_ref_prio,
                                                               v.flg_priority) priority_icon,
                       pk_date_utils.dt_chr_tsz(i_lang, v.dt_schedule_tstz, i_prof) dt_schedule,
                       pk_date_utils.dt_chr_hour_tsz(i_lang, v.dt_schedule_tstz, i_prof) hour_schedule,
                       pk_date_utils.date_send_tsz(i_lang, v.dt_schedule_tstz, i_prof) dt_sch_millis,
                       pk_date_utils.get_elapsed_tsz(i_lang, v.dt_status_tstz, g_sysdate_tstz) dt_elapsed,
                       v.id_schedule,
                       pk_translation.get_translation(i_lang, v.code_inst_orig) inst_orig_name,
                       decode(v.flg_status,
                              pk_ref_constant.g_p1_status_o,
                              decode(v.id_prof_requested, i_prof.id, pk_ref_constant.g_yes, pk_ref_constant.g_no),
                              pk_ref_constant.g_no) flg_editable,
                       pk_ref_constant.g_no flg_task_editable,
                       l_msg_common_m019 desc_day,
                       l_msg_common_m020 desc_days,
                       pk_date_utils.to_char_insttimezone(i_prof,
                                                          dt_status_tstz,
                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) date_field,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) dt_server,
                       /*(SELECT pk_ref_core.can_cancel(i_lang,
                                                   i_prof,
                                                   v.id_external_request,
                                                   v.flg_status,
                                                   nvl(v.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                                   l_my_pt,
                                                   (SELECT pk_ref_core.get_prof_func(i_lang, i_prof, v.id_dep_clin_serv)
                                                      FROM dual),
                                                   l_id_cat,
                                                   v.id_patient,
                                                   v.id_inst_orig,
                                                   v.id_inst_dest,
                                                   v.id_dep_clin_serv,
                                                   v.id_speciality,
                                                   v.flg_type,
                                                   v.id_prof_requested,
                                                   v.id_prof_redirected,
                                                   v.id_prof_status,
                                                   v.id_external_sys,
                                                   v.decision_urg_level)
                       FROM dual)*/
                       decode(v.flg_status,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               CASE
                                   WHEN (pk_ref_utils.get_ref_detail_date(i_lang,
                                                                          v.id_external_request,
                                                                          v.flg_status,
                                                                          v.id_workflow) + numtodsinterval(180, 'DAY')) >
                                        current_timestamp THEN
                                    pk_alert_constant.g_yes
                                   ELSE
                                    pk_alert_constant.g_no
                               END) can_cancel,
                       pk_ref_core.can_sent(i_lang,
                                            i_prof,
                                            v.id_external_request,
                                            v.flg_status,
                                            v.flg_migrated,
                                            l_bdnp_available) can_sent,
                       pk_ref_core.get_ref_observations(i_lang,
                                                        i_prof,
                                                        l_my_pt,
                                                        v.id_external_request,
                                                        v.flg_status,
                                                        v.id_prof_status,
                                                        v.dt_schedule_tstz,
                                                        pk_ref_constant.g_yes,
                                                        v.id_prof_triage,
                                                        NULL) observations,
                       CASE v.flg_status
                           WHEN pk_ref_constant.g_p1_status_p THEN
                            pk_ref_ext_sys.get_ref_report(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_referral  => v.id_external_request,
                                                          i_flg_rep_type => pk_ref_constant.g_rep_type_duplicata)
                           ELSE
                            NULL
                       END id_rep_duplicata, -- if this column name is changed/deleted, change PK_REF_EXT_SYS.get_available_id_reports parameter o_column_name accordingly
                       pk_ref_ext_sys.get_ref_report(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_referral  => v.id_external_request,
                                                     i_flg_rep_type => pk_ref_constant.g_rep_type_reprint) AS id_rep_reprint, -- if this column name is changed/deleted, change PK_REF_EXT_SYS.get_available_id_reports parameter o_column_name accordingly
                       pk_ref_constant.g_task_type_referral id_task_type,
                       (SELECT id_codification
                          FROM p1_exr_temp pet
                         WHERE pet.id_external_request = v.id_external_request
                           AND rownum = 1) id_codification,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                    v.id_external_request,
                                                                                    v.flg_status,
                                                                                    v.id_workflow),
                                                   i_prof) dt_order,
                       v.flg_migrated
                  FROM TABLE(CAST(pk_ref_core_internal.get_grid_data(l_sql) AS t_coll_p1_request)) v
                 WHERE v.flg_type = nvl(i_type, v.flg_type)) q
         ORDER BY q.status_colors, q.status_rank2;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            my_code := SQLCODE;
            my_errm := SQLERRM;
            RETURN NULL;
        
    END get_p1_internal;

    FUNCTION get_p1_internal
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_filter   IN VARCHAR2,
        i_type     IN p1_external_request.flg_type%TYPE,
        i_var_desc IN table_varchar,
        i_var_val  IN table_varchar,
        o_p1       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql                VARCHAR2(32000);
        l_sd_status_color    VARCHAR2(50 CHAR);
        l_sd_toschedule_icon VARCHAR2(50 CHAR);
        l_msg_common_m019    VARCHAR2(4000);
        l_msg_common_m020    VARCHAR2(4000);
        l_my_pt              profile_template.id_profile_template%TYPE;
        l_id_cat             category.id_category%TYPE;
        l_inst_type          institution.flg_type%TYPE;
        --l_desc_dom_ref_prio  sys_domain.code_domain%TYPE;
        --l_priority_level     sys_config.value%TYPE;
        --l_color_ref_prio      sys_domain.code_domain%TYPE;
        --l_text_color_ref_prio sys_domain.code_domain%TYPE;
    
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
    
        --g_error := 'Call pk_ref_core.get_referral_list / i_prof=' || pk_utils.to_string(i_prof) || ' i_filter=' ||
        --           i_filter || ' i_type=' || i_type;
        --RETURN pk_ref_core.get_referral_list(i_lang     => i_lang,
        --                                     i_prof     => i_prof,
        --                                     i_patient  => NULL,
        --                                     i_filter   => i_filter,
        --                                     i_type     => i_type,
        --                                     o_ref_list => o_p1,
        --                                     o_error    => o_error);
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init get_p1_internal / FILTER=' || i_filter || ' TYPE=' || i_type;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        l_my_pt  := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        l_id_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        ----------------------
        -- CONF
        ----------------------         
        g_error           := 'Call pk_message.get_message';
        l_msg_common_m019 := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M019');
        l_msg_common_m020 := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M020');
    
        --l_priority_level    := pk_sysconfig.get_config(pk_ref_constant.g_ref_priority_level, i_prof);
        --l_desc_dom_ref_prio := pk_ref_constant.g_ref_prio || '.' || l_priority_level;
        --l_color_ref_prio      := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.COLOR_' || l_priority_level;
        --l_text_color_ref_prio := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.TEXT_COLOR_' || l_priority_level;
    
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'Getting institution type / ID_INSTITUTION=' || i_prof.institution;
        SELECT i.flg_type
          INTO l_inst_type
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        g_error := 'INST_TYPE=' || l_inst_type || ' ID_INSTITUTION=' || i_prof.institution;
        IF l_inst_type = pk_ref_constant.g_hospital
        THEN
            l_sd_status_color    := 'P1_STATUS_COLOR.MED_HS';
            l_sd_toschedule_icon := 'P1_TOSCHEDULE_GRID_ICON.1';
            g_p1_pseudo_status_i := pk_ref_constant.g_p1_pseudo_status_i2;
        ELSE
            l_sd_status_color    := 'P1_STATUS_COLOR.MED_CS';
            l_sd_toschedule_icon := 'P1_TOSCHEDULE_GRID_ICON.1';
            g_p1_pseudo_status_i := pk_ref_constant.g_p1_pseudo_status_i1;
        END IF;
    
        g_error  := 'Call pk_ref_core_internal.get_grid_sql / filter=' || i_filter;
        g_retval := pk_ref_core_internal.get_grid_sql(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_var_desc => i_var_desc,
                                                      i_var_val  => i_var_val,
                                                      i_filter   => i_filter,
                                                      o_sql      => l_sql,
                                                      o_error    => o_error);
    
        g_error := 'OPEN o_p1 FOR';
        OPEN o_p1 FOR
            SELECT q.*, status_rank2 || date_field status_rank
              FROM (SELECT v.id_external_request id_p1,
                           v.num_req,
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                     v.id_external_request,
                                                                                     v.flg_status,
                                                                                     v.id_workflow),
                                                    i_prof) dt_p1,
                           v.flg_type,
                           pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_id_prof_requested => v.id_prof_requested,
                                                                    i_id_prof_roda      => v.id_prof_orig) prof_requested_name,
                           v.id_patient,
                           v.pat_name,
                           v.pat_gender,
                           pk_patient.get_pat_age(i_lang, v.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_foto(v.id_patient, i_prof) photo,
                           pk_ref_core.get_inst_name(i_lang,
                                                     i_prof,
                                                     v.flg_status,
                                                     v.id_inst_dest,
                                                     v.code_inst_dest,
                                                     v.inst_dest_abbrev) inst_dest_name,
                           v.dep_abbreviation dest_department,
                           decode(v.id_inst_dest,
                                  NULL,
                                  NULL,
                                  decode(v.id_dep_clin_serv,
                                         NULL,
                                         pk_translation.get_translation(i_lang, v.code_speciality),
                                         pk_translation.get_translation(i_lang, v.code_clinical_service))) clin_srv_name,
                           decode(v.id_workflow,
                                  pk_ref_constant.g_wf_srv_srv,
                                  pk_translation.get_translation(i_lang, v.code_clinical_service),
                                  nvl2(v.code_speciality,
                                       pk_translation.get_translation(i_lang, v.code_speciality),
                                       (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type,
                                                                       v.flg_type,
                                                                       i_lang)
                                          FROM dual))) p1_spec_name,
                           pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                   i_prof,
                                                                   pk_ref_constant.g_p1_exr_flg_type,
                                                                   v.flg_type) type_icon,
                           v.flg_status,
                           (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', v.flg_status, i_lang)
                              FROM dual) flg_status_desc,
                           -- STATUS_ICON
                           decode(v.flg_status,
                                  pk_ref_constant.g_p1_status_a,
                                  
                                  pk_sysdomain.get_img(i_lang,
                                                       l_sd_toschedule_icon,
                                                       to_char(nvl(v.decision_urg_level,
                                                                   pk_ref_constant.g_decision_urg_level_normal))),
                                  
                                  pk_sysdomain.get_img(i_lang,
                                                       'P1_EXTERNAL_REQUEST.FLG_STATUS',
                                                       decode(v.flg_status,
                                                              pk_ref_constant.g_p1_status_i,
                                                              g_p1_pseudo_status_i,
                                                              pk_ref_constant.g_p1_status_r,
                                                              g_p1_pseudo_status_r,
                                                              v.flg_status))) status_icon,
                           decode(v.flg_status,
                                  pk_ref_constant.g_p1_status_a,
                                  lpad(pk_sysdomain.get_rank(i_lang, 'P1_STATUS_RANK.MED_CS', v.flg_status) +
                                       (SELECT rank
                                          FROM sys_domain
                                         WHERE id_language = i_lang
                                           AND code_domain = l_sd_toschedule_icon
                                           AND domain_owner = pk_sysdomain.k_default_schema
                                           AND img_name =
                                               pk_sysdomain.get_img(i_lang,
                                                                    l_sd_toschedule_icon,
                                                                    to_char(nvl(v.decision_urg_level,
                                                                                pk_ref_constant.g_decision_urg_level_normal)))),
                                       6,
                                       '0'),
                                  lpad(pk_sysdomain.get_rank(i_lang, 'P1_STATUS_RANK.MED_CS', v.flg_status), 6, '0')) status_rank2,
                           pk_ref_utils.get_domain_cached_desc(i_lang,
                                                               i_prof,
                                                               l_sd_status_color,
                                                               decode(v.flg_status,
                                                                      pk_ref_constant.g_p1_status_r,
                                                                      g_p1_pseudo_status_r,
                                                                      v.flg_status)) status_colors,
                           pk_ref_core.get_ref_priority_info(i_lang, i_prof, v.flg_priority) priority_info,
                           pk_ref_core.get_ref_priority_desc(i_lang, i_prof, v.flg_priority) priority_desc, -- ALERT-273753
                           pk_ref_utils.get_domain_cached_img_name(i_lang,
                                                                   i_prof,
                                                                   pk_ref_constant.g_ref_prio,
                                                                   v.flg_priority) priority_icon,
                           pk_date_utils.dt_chr_tsz(i_lang, v.dt_schedule_tstz, i_prof) dt_schedule,
                           pk_date_utils.dt_chr_hour_tsz(i_lang, v.dt_schedule_tstz, i_prof) hour_schedule,
                           pk_date_utils.date_send_tsz(i_lang, v.dt_schedule_tstz, i_prof) dt_sch_millis,
                           pk_date_utils.get_elapsed_tsz(i_lang, v.dt_status_tstz, g_sysdate_tstz) dt_elapsed,
                           v.id_schedule,
                           pk_translation.get_translation(i_lang, v.code_inst_orig) inst_orig_name,
                           decode(v.flg_status,
                                  pk_ref_constant.g_p1_status_o,
                                  decode(v.id_prof_requested, i_prof.id, pk_ref_constant.g_yes, pk_ref_constant.g_no),
                                  pk_ref_constant.g_no) flg_editable,
                           pk_ref_constant.g_no flg_task_editable,
                           l_msg_common_m019 desc_day,
                           l_msg_common_m020 desc_days,
                           pk_date_utils.date_send_tsz(i_lang, dt_status_tstz, i_prof) date_field,
                           pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) dt_server,
                           (SELECT pk_ref_core.can_cancel(i_lang,
                                                          i_prof,
                                                          v.id_external_request,
                                                          v.flg_status,
                                                          nvl(v.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                                          l_my_pt,
                                                          (SELECT pk_ref_core.get_prof_func(i_lang,
                                                                                            i_prof,
                                                                                            v.id_dep_clin_serv)
                                                             FROM dual),
                                                          l_id_cat,
                                                          v.id_patient,
                                                          v.id_inst_orig,
                                                          v.id_inst_dest,
                                                          v.id_dep_clin_serv,
                                                          v.id_speciality,
                                                          v.flg_type,
                                                          v.id_prof_requested,
                                                          v.id_prof_redirected,
                                                          v.id_prof_status,
                                                          v.id_external_sys,
                                                          v.decision_urg_level)
                              FROM dual) can_cancel,
                           pk_ref_core.can_sent(i_lang,
                                                i_prof,
                                                v.id_external_request,
                                                v.flg_status,
                                                v.flg_migrated,
                                                l_bdnp_available) can_sent,
                           pk_ref_core.get_ref_observations(i_lang,
                                                            i_prof,
                                                            l_my_pt,
                                                            v.id_external_request,
                                                            v.flg_status,
                                                            v.id_prof_status,
                                                            v.dt_schedule_tstz,
                                                            pk_ref_constant.g_yes,
                                                            v.id_prof_triage,
                                                            NULL) observations,
                           CASE v.flg_status
                               WHEN pk_ref_constant.g_p1_status_p THEN
                                pk_ref_ext_sys.get_ref_report(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_id_referral  => v.id_external_request,
                                                              i_flg_rep_type => pk_ref_constant.g_rep_type_duplicata)
                               ELSE
                                NULL
                           END id_rep_duplicata, -- if this column name is changed/deleted, change PK_REF_EXT_SYS.get_available_id_reports parameter o_column_name accordingly
                           pk_ref_ext_sys.get_ref_report(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_referral  => v.id_external_request,
                                                         i_flg_rep_type => pk_ref_constant.g_rep_type_reprint) AS id_rep_reprint, -- if this column name is changed/deleted, change PK_REF_EXT_SYS.get_available_id_reports parameter o_column_name accordingly
                           pk_ref_constant.g_task_type_referral id_task_type,
                           (SELECT id_codification
                              FROM p1_exr_temp pet
                             WHERE pet.id_external_request = v.id_external_request
                               AND rownum = 1) id_codification,
                           (CAST(MULTISET
                                 (SELECT pt.id_analysis_req_det id_req
                                    FROM p1_exr_temp pt
                                   WHERE pt.id_external_request = v.id_external_request
                                     AND v.flg_type = pk_ref_constant.g_p1_type_a
                                  UNION
                                  SELECT pa.id_analysis_req_det id_req
                                    FROM p1_exr_analysis pa
                                   WHERE pa.id_external_request = v.id_external_request
                                     AND v.flg_type = pk_ref_constant.g_p1_type_a
                                  UNION
                                  SELECT pt.id_interv_presc_det id_req
                                    FROM p1_exr_temp pt
                                   WHERE pt.id_external_request = v.id_external_request
                                     AND v.flg_type = pk_ref_constant.g_p1_type_p
                                  UNION
                                  SELECT pi.id_interv_presc_det id_req
                                    FROM p1_exr_intervention pi
                                   WHERE pi.id_external_request = v.id_external_request
                                     AND v.flg_type = pk_ref_constant.g_p1_type_p
                                  UNION
                                  SELECT pt.id_exam_req_det id_req
                                    FROM p1_exr_temp pt
                                   WHERE pt.id_external_request = v.id_external_request
                                     AND v.flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i)
                                  UNION
                                  SELECT pe.id_exam_req_det id_req
                                    FROM p1_exr_exam pe
                                   WHERE pe.id_external_request = v.id_external_request
                                     AND v.flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i)
                                  UNION
                                  SELECT pt.id_rehab_presc id_req
                                    FROM p1_exr_temp pt
                                   WHERE pt.id_external_request = v.id_external_request
                                     AND v.flg_type = pk_ref_constant.g_p1_type_f
                                  UNION
                                  SELECT pi.id_rehab_presc id_req
                                    FROM p1_exr_intervention pi
                                   WHERE pi.id_external_request = v.id_external_request
                                     AND v.flg_type = pk_ref_constant.g_p1_type_f
                                  UNION
                                  SELECT v.id_external_request
                                    FROM dual
                                   WHERE v.flg_type = pk_ref_constant.g_p1_type_c) AS table_number)) tbl_id_records
                      FROM TABLE(CAST(pk_ref_core_internal.get_grid_data(l_sql) AS t_coll_p1_request)) v
                     WHERE v.flg_type = nvl(i_type, v.flg_type)) q
             ORDER BY q.status_colors, q.status_rank2, status_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_p1);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_p1);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_P1_INTERNAL',
                                                     o_error    => o_error);
    END get_p1_internal;

    /**
    * Gets list of patient referrals
    *
    * @param   i_lang  language
    * @param   i_prof  profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   o_p1 returned referral list
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   29-08-2007
    */

    FUNCTION get_pat_p1
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN p1_external_request.flg_type%TYPE
    ) RETURN t_tbl_p1_grid IS
        l_filter VARCHAR2(15 CHAR);
    
        l_var_desc table_varchar := table_varchar();
        l_var_val  table_varchar := table_varchar();
        l_ret      t_tbl_p1_grid;
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_var_desc.extend(5);
        l_var_val.extend(5);
    
        l_var_desc(1) := '@LANG';
        l_var_val(1) := to_char(i_lang);
    
        l_var_desc(2) := '@PROFESSIONAL';
        l_var_val(2) := to_char(i_prof.id);
    
        l_var_desc(3) := '@INSTITUTION';
        l_var_val(3) := to_char(i_prof.institution);
    
        l_var_desc(4) := '@SOFTWARE';
        l_var_val(4) := to_char(i_prof.software);
    
        l_var_desc(5) := '@PATIENT';
        l_var_val(5) := to_char(i_id_patient);
    
        l_filter := 'PATIENT';
    
        --g_sysdate_tstz := current_timestamp;
        --g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error := 'Call get_p1_internal';
        l_ret   := get_p1_internal(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_filter   => l_filter,
                                   i_type     => i_type,
                                   i_var_desc => l_var_desc,
                                   i_var_val  => l_var_val);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
        
    END get_pat_p1;

    FUNCTION get_pat_p1_to_edit
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_p1_external_request IN p1_external_request.id_external_request%TYPE,
        o_p1                     OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        OPEN o_p1 FOR
            SELECT pt.id_analysis_req_det id_req,
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type,
                                                            NULL) desc_req,
                   ard.id_analysis id_mcdt
              FROM p1_exr_temp pt
              JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = pt.id_analysis_req_det
             WHERE pt.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pa.id_analysis_req_det id_req,
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type,
                                                            NULL) desc_req,
                   ard.id_analysis id_mcdt
            
              FROM p1_exr_analysis pa
              JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = pa.id_analysis_req_det
             WHERE pa.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pt.id_interv_presc_det id_req,
                   pk_translation.get_translation(i_lang, i.code_intervention) desc_req,
                   ipd.id_intervention id_mcdt
              FROM p1_exr_temp pt
              JOIN interv_presc_det ipd
                ON ipd.id_interv_presc_det = pt.id_interv_presc_det
              JOIN intervention i
                ON i.id_intervention = ipd.id_intervention
             WHERE pt.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pi.id_interv_presc_det id_req,
                   pk_translation.get_translation(i_lang, i.code_intervention) desc_req,
                   ipd.id_intervention id_mcdt
              FROM p1_exr_intervention pi
              JOIN interv_presc_det ipd
                ON ipd.id_interv_presc_det = pi.id_interv_presc_det
              JOIN intervention i
                ON i.id_intervention = ipd.id_intervention
             WHERE pi.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pt.id_exam_req_det id_req,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || erd.id_exam, NULL) desc_req,
                   erd.id_exam id_mcdt
              FROM p1_exr_temp pt
              JOIN exam_req_det erd
                ON erd.id_exam_req_det = pt.id_exam_req_det
             WHERE pt.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pe.id_exam_req_det id_req,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || erd.id_exam, NULL) desc_req,
                   erd.id_exam id_mcdt
              FROM p1_exr_exam pe
              JOIN exam_req_det erd
                ON erd.id_exam_req_det = pe.id_exam_req_det
             WHERE pe.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pt.id_rehab_presc id_req,
                   pk_translation.get_translation(i_lang, i.code_intervention) desc_req,
                   i.id_intervention id_mcdt
              FROM p1_exr_temp pt
              JOIN rehab_presc rp
                ON rp.id_rehab_presc = pt.id_rehab_presc
              JOIN rehab_area_interv rai
                ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
              JOIN intervention i
                ON i.id_intervention = rai.id_intervention
             WHERE pt.id_external_request = i_id_p1_external_request
            
            UNION ALL
            SELECT pi.id_rehab_presc id_req,
                   pk_translation.get_translation(i_lang, i.code_intervention) desc_req,
                   i.id_intervention id_mcdt
              FROM p1_exr_intervention pi
              JOIN rehab_presc rp
                ON rp.id_rehab_presc = pi.id_rehab_presc
              JOIN rehab_area_interv rai
                ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
              JOIN intervention i
                ON i.id_intervention = rai.id_intervention
             WHERE pi.id_external_request = i_id_p1_external_request;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_p1);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_P1_TO_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_p1_to_edit;

    FUNCTION get_pat_p1
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN p1_external_request.flg_type%TYPE,
        o_p1         OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_filter VARCHAR2(15 CHAR);
    
        l_var_desc table_varchar := table_varchar();
        l_var_val  table_varchar := table_varchar();
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_var_desc.extend(5);
        l_var_val.extend(5);
    
        l_var_desc(1) := '@LANG';
        l_var_val(1) := to_char(i_lang);
    
        l_var_desc(2) := '@PROFESSIONAL';
        l_var_val(2) := to_char(i_prof.id);
    
        l_var_desc(3) := '@INSTITUTION';
        l_var_val(3) := to_char(i_prof.institution);
    
        l_var_desc(4) := '@SOFTWARE';
        l_var_val(4) := to_char(i_prof.software);
    
        l_var_desc(5) := '@PATIENT';
        l_var_val(5) := to_char(i_id_patient);
    
        l_filter := 'PATIENT';
    
        --g_sysdate_tstz := current_timestamp;
        --g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error  := 'Call get_p1_internal';
        g_retval := get_p1_internal(i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    i_filter   => l_filter,
                                    i_type     => i_type,
                                    i_var_desc => l_var_desc,
                                    i_var_val  => l_var_val,
                                    o_p1       => o_p1,
                                    o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_cursor_if_closed(o_p1);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_p1);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_P1',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_p1;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    *
    * @param   i_lang  language
    * @param   i_prof  profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   o_p1 returned referral list
    * @param   i_schedule current schedule id
    * @param   o_message message to return
    * @param   o_title  message type
    * @param   o_button button message
    * @param   o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   29-08-2007
    */
    FUNCTION get_pat_p1_to_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN table_varchar, --p1_external_request.flg_type%TYPE,
        i_schedule   IN schedule.id_schedule%TYPE,
        o_p1         OUT pk_types.cursor_type,
        o_message    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_buttons    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql      VARCHAR2(32000);
        l_filter   VARCHAR2(15 CHAR);
        l_var_desc table_varchar := table_varchar();
        l_var_val  table_varchar := table_varchar();
        g_ok_button_code CONSTANT VARCHAR2(7) := 'C829664';
        l_type table_varchar;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init get_pat_p1_to_schedule';
        --g_sysdate_tstz := current_timestamp;
        --g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        ----------------------
        -- CONFIG
        ----------------------          
        o_message := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_DOCTOR_REQ_T064');
        o_title   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_DOCTOR_REQ_T065');
        o_buttons := g_ok_button_code ||
                     pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_DOCTOR_REQ_T066') || '|';
    
        ----------------------
        -- FUNC
        ----------------------    
        l_var_desc.extend(5);
        l_var_val.extend(5);
    
        l_var_desc(1) := '@LANG';
        l_var_val(1) := to_char(i_lang);
    
        l_var_desc(2) := '@PROFESSIONAL';
        l_var_val(2) := to_char(i_prof.id);
    
        l_var_desc(3) := '@INSTITUTION';
        l_var_val(3) := to_char(i_prof.institution);
    
        l_var_desc(4) := '@SOFTWARE';
        l_var_val(4) := to_char(i_prof.software);
    
        l_var_desc(5) := '@PATIENT';
        l_var_val(5) := to_char(i_id_patient);
    
        l_filter := 'TO_SCHEDULE_PAT';
    
        IF i_type IS NULL
           OR i_type.count = 0
           OR (i_type.exists(1) AND i_type(1) IS NULL)
        THEN
        
            -- getting all referral types
            g_error := 'SELECT sys_domain';
            SELECT val
              BULK COLLECT
              INTO l_type
              FROM sys_domain s
             WHERE s.code_domain = 'P1_EXTERNAL_REQUEST.FLG_TYPE'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND s.flg_available = pk_ref_constant.g_yes;
        ELSE
            l_type := i_type;
        END IF;
    
        g_error  := 'Call pk_ref_core_internal.get_grid_sql / filter=' || l_filter;
        g_retval := pk_ref_core_internal.get_grid_sql(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_var_desc => l_var_desc,
                                                      i_var_val  => l_var_val,
                                                      i_filter   => l_filter,
                                                      o_sql      => l_sql,
                                                      o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_p1 FOR';
        OPEN o_p1 FOR
            SELECT v.id_external_request,
                   v.num_req num_req,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_ref_utils.get_ref_detail_date(i_lang,
                                                                             v.id_external_request,
                                                                             v.flg_status,
                                                                             v.id_workflow),
                                            i_prof) dt_p1,
                   v.flg_type,
                   nvl2(pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_TYPE', v.flg_type),
                        lpad(pk_sysdomain.get_rank(i_lang, 'P1_EXTERNAL_REQUEST.FLG_TYPE', v.flg_type), 6, '0') ||
                        pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_TYPE', v.flg_type),
                        NULL) type_icon,
                   v.id_dep_clin_serv,
                   nvl2(v.code_department,
                        pk_translation.get_translation(i_lang, v.code_department) || '/' ||
                        pk_translation.get_translation(i_lang, v.code_clinical_service),
                        (SELECT desc_val
                           FROM sys_domain
                          WHERE id_language = i_lang
                            AND code_domain = 'P1_EXTERNAL_REQUEST.FLG_TYPE'
                            AND domain_owner = pk_sysdomain.k_default_schema
                            AND val = v.flg_type)) serv_spec_desc,
                   (SELECT text
                      FROM p1_detail d
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_item
                       AND d.flg_status = pk_ref_constant.g_active
                       AND d.id_external_request = v.id_external_request
                       AND rownum = 1) desc_activity,
                   pk_ref_core.get_inst_name(i_lang,
                                             i_prof,
                                             v.flg_status,
                                             v.id_inst_dest,
                                             v.code_inst_dest,
                                             v.inst_dest_abbrev) inst_dest,
                   pk_translation.get_translation(i_lang, v.code_inst_orig) inst_orig,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, v.id_prof_triage)
                      FROM dual) prof_triage,
                   v.flg_status,
                   (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', v.flg_status, i_lang)
                      FROM dual) flg_status_desc,
                   nvl2(decode(v.flg_status,
                               pk_ref_constant.g_p1_status_a,
                               pk_sysdomain.get_img(i_lang,
                                                    'P1_TOSCHEDULE_GRID_ICON.1',
                                                    to_char(nvl(v.decision_urg_level,
                                                                pk_ref_constant.g_decision_urg_level_normal))),
                               pk_sysdomain.get_img(i_lang,
                                                    'P1_EXTERNAL_REQUEST.FLG_STATUS',
                                                    decode(v.flg_status,
                                                           pk_ref_constant.g_p1_status_i,
                                                           g_p1_pseudo_status_i,
                                                           pk_ref_constant.g_p1_status_r,
                                                           g_p1_pseudo_status_r,
                                                           v.flg_status))),
                        lpad(pk_sysdomain.get_rank(i_lang, 'P1_STATUS_RANK.MED_CS', v.flg_status), 6, '0') ||
                        decode(v.flg_status,
                               pk_ref_constant.g_p1_status_a,
                               pk_sysdomain.get_img(i_lang,
                                                    'P1_TOSCHEDULE_GRID_ICON.1',
                                                    to_char(nvl(v.decision_urg_level,
                                                                pk_ref_constant.g_decision_urg_level_normal))),
                               pk_sysdomain.get_img(i_lang,
                                                    'P1_EXTERNAL_REQUEST.FLG_STATUS',
                                                    decode(v.flg_status,
                                                           pk_ref_constant.g_p1_status_i,
                                                           g_p1_pseudo_status_i,
                                                           pk_ref_constant.g_p1_status_r,
                                                           g_p1_pseudo_status_r,
                                                           v.flg_status))),
                        NULL) status_icon,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_p1_utils.get_status_date(i_lang,
                                                                        v.id_external_request,
                                                                        pk_ref_constant.g_p1_status_e),
                                            i_prof) dt_execution,
                   -- js, 2008-08-05: so esta agendado se tiver id_schedule E dt_schedule_tstz
                   decode(v.dt_schedule_tstz, NULL, NULL, v.id_schedule) id_schedule
              FROM TABLE(CAST(pk_ref_core_internal.get_grid_data(l_sql) AS t_coll_p1_request)) v
              JOIN(TABLE(CAST(l_type AS table_varchar))) tt
                ON (tt.column_value = v.flg_type)
             ORDER BY v.id_schedule, v.dt_requested, status_icon DESC;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_p1);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_PAT_P1_TO_SCHEDULE',
                                                     o_error    => o_error);
    END get_pat_p1_to_schedule;

    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        id_prof             IN professional.id_professional%TYPE,
        id_inst             IN institution.id_institution%TYPE,
        id_soft             IN software.id_software%TYPE,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_institution       OUT pk_types.cursor_type,
        o_patient           OUT pk_types.cursor_type,
        o_ref_health_plan   OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
    
        l_id_ext_local_presc_syscfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'ID_EXTERNAL_SYS_LOCAL_PRESCRICAO',
                                                                                     i_prof_inst => id_inst,
                                                                                     i_prof_soft => id_soft);
    
        l_prescriptions_ars_syscfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'PRESCRIPTION_ARS',
                                                                                    i_prof    => profissional(id_prof,
                                                                                                              id_inst,
                                                                                                              id_soft));
    
        l_sns                   pat_health_plan.num_health_plan%TYPE; --Numero SNS
        l_num_health_plan       pat_health_plan.num_health_plan%TYPE; --Numero sns/seguro saude/etc
        l_id_health_plan        pat_health_plan.id_health_plan%TYPE;
        l_pat_name              patient.name%TYPE; --Nome paciente
        l_pat_dt_birth          VARCHAR2(200); --Data de nascimento
        l_pat_gender            patient.gender%TYPE; --Género
        l_pat_gender_desc       VARCHAR2(200);
        l_pat_birth_place       country.alpha2_code%TYPE; --Nacionalidade
        l_hp_entity             VARCHAR2(4000);
        l_flg_migrator          pat_soc_attributes.flg_migrator%TYPE;
        l_flg_occ_disease       VARCHAR2(1);
        l_flg_independent       VARCHAR2(1);
        l_dt_deceased           VARCHAR2(4000);
        l_hp_alpha2_code        VARCHAR2(4000);
        l_hp_national_ident_nbr VARCHAR2(4000);
        l_hp_dt_effective       VARCHAR2(200);
        l_valid_sns             VARCHAR2(1);
        l_flg_recm              VARCHAR2(2);
        l_main_phone            VARCHAR2(200);
        l_hp_country_desc       VARCHAR2(200);
        l_num_order             professional.num_order%TYPE;
        l_valid_hp              VARCHAR2(1);
        l_flg_type_hp           health_plan.flg_type%TYPE;
        l_hp_id_content         health_plan.id_content%TYPE;
        l_hp_inst_ident_nbr     pat_health_plan.inst_identifier_number%TYPE;
        l_hp_inst_ident_desc    pat_health_plan.inst_identifier_desc%TYPE;
        l_hp_dt_valid           VARCHAR(200);
    
    BEGIN
    
        SELECT p.id_patient, p.id_episode
          INTO l_patient, l_episode
          FROM p1_external_request p
         WHERE p.id_external_request = i_exr;
    
        OPEN o_institution FOR
            SELECT ies.id_institution,
                   pk_utils.get_institution_name(i_lang => i_lang, i_id_institution => ies.id_institution) inst,
                   ies.value,
                   i.ine_location user_local,
                   l_prescriptions_ars_syscfg ars_code
              FROM instit_ext_sys ies
              JOIN institution i
                ON i.id_institution = ies.id_institution
             WHERE ies.id_external_sys = l_id_ext_local_presc_syscfg
               AND ies.id_institution = id_inst
               AND rownum = 1;
    
        IF NOT pk_adt.get_pat_info(i_lang                    => i_lang,
                                   i_id_patient              => l_patient,
                                   i_prof                    => profissional(id_prof, id_inst, id_soft),
                                   i_id_episode              => l_episode,
                                   i_id_presc                => NULL,
                                   i_flg_info_for_medication => pk_alert_constant.g_no,
                                   o_name                    => l_pat_name,
                                   o_gender                  => l_pat_gender,
                                   o_desc_gender             => l_pat_gender_desc,
                                   o_dt_birth                => l_pat_dt_birth,
                                   o_dt_deceased             => l_dt_deceased,
                                   o_flg_migrator            => l_flg_migrator,
                                   o_id_country_nation       => l_pat_birth_place,
                                   o_sns                     => l_sns,
                                   o_valid_sns               => l_valid_sns,
                                   o_flg_occ_disease         => l_flg_occ_disease,
                                   o_flg_independent         => l_flg_independent,
                                   o_num_health_plan         => l_num_health_plan,
                                   o_hp_entity               => l_hp_entity,
                                   o_id_health_plan          => l_id_health_plan,
                                   o_flg_recm                => l_flg_recm,
                                   o_main_phone              => l_main_phone,
                                   o_hp_alpha2_code          => l_hp_alpha2_code,
                                   o_hp_country_desc         => l_hp_country_desc,
                                   o_hp_national_ident_nbr   => l_hp_national_ident_nbr,
                                   o_hp_dt_effective         => l_hp_dt_effective,
                                   o_valid_hp                => l_valid_hp,
                                   o_flg_type_hp             => l_flg_type_hp,
                                   o_hp_id_content           => l_hp_id_content,
                                   o_hp_inst_ident_nbr       => l_hp_inst_ident_nbr,
                                   o_hp_inst_ident_desc      => l_hp_inst_ident_desc,
                                   o_hp_dt_valid             => l_hp_dt_valid,
                                   o_error                   => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF NOT pk_prof_utils.get_num_order(i_lang      => i_lang,
                                           i_prof      => profissional(id_prof, id_inst, id_soft),
                                           i_prof_id   => id_prof,
                                           o_num_order => l_num_order,
                                           o_error     => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        OPEN o_patient FOR
            SELECT id_prof                 id_professional,
                   l_num_order             num_order,
                   l_pat_name              name,
                   l_pat_gender            gender,
                   l_pat_gender_desc       gender_desc,
                   l_pat_dt_birth          dt_bith,
                   l_dt_deceased           dt_deceased,
                   l_flg_migrator          flg_migrator,
                   l_pat_birth_place       id_country_nation,
                   l_sns                   sns,
                   l_valid_sns             valid_sns,
                   l_flg_occ_disease       flg_occ_disease,
                   l_flg_independent       flg_independent,
                   l_num_health_plan       num_health_plan,
                   l_hp_entity             hp_entity,
                   l_id_health_plan        id_health_plan,
                   l_flg_recm              flg_recm,
                   l_main_phone            main_phone,
                   l_hp_alpha2_code        hp_alpha2_code,
                   l_hp_country_desc       hp_country_desc,
                   l_hp_national_ident_nbr hp_national_ident_nbr,
                   l_hp_dt_effective       hp_dt_effective,
                   l_valid_hp              valid_hp,
                   l_flg_type_hp           flg_type_hp,
                   l_hp_id_content         hp_id_content,
                   l_hp_inst_ident_nbr     hp_inst_ident_nbr,
                   l_hp_inst_ident_desc    hp_inst_ident_desc,
                   l_hp_dt_valid           hp_dt_valid
              FROM dual;
    
        g_error := 'Open o_ref_health_plan';
        OPEN o_ref_health_plan FOR
            SELECT php.id_pat_health_plan,
                   php.id_health_plan,
                   php.num_health_plan,
                   php.inst_identifier_number,
                   pk_translation.get_translation(i_lang,
                                                  'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                  hp.id_health_plan_entity) hp_entity,
                   (SELECT c.alpha2_code
                      FROM country c
                     WHERE c.id_country = nvl(php.id_country, hp.id_country)) hp_alpha2_code,
                   (SELECT pk_translation.get_translation(i_lang, c.code_country)
                      FROM country c
                     WHERE c.id_country = nvl(php.id_country, hp.id_country)) hp_country_desc,
                   nvl(php.national_identifier_number, hp.national_identifier_number) hp_national_ident_nbr,
                   pk_date_utils.date_send(i_lang, php.dt_effective, profissional(id_prof, id_inst, id_soft)) hp_dt_effective,
                   CASE
                    --has comparticipation
                        WHEN hp.flg_type IN ('S', 'P', 'A', 'B', 'E') THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END valid_hp,
                   hp.flg_type flg_hp_type,
                   hp.id_content hp_id_content,
                   pk_date_utils.date_send(i_lang, php.dt_health_plan, profissional(id_prof, id_inst, id_soft)) hp_dt_valid,
                   pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan
              FROM p1_external_request per
              JOIN pat_health_plan php
                ON php.id_pat_health_plan = per.id_pat_health_plan
              JOIN health_plan hp
                ON hp.id_health_plan = php.id_health_plan
             WHERE per.id_external_request = i_exr
               AND hp.flg_available = pk_alert_constant.get_available
               AND php.flg_status = pk_alert_constant.g_active
               AND rownum = 1;
    
        g_error := 'Init get_exr_group';
        RETURN pk_p1_med_cs.get_exr_group(i_lang              => i_lang,
                                          i_prof              => profissional(id_prof, id_inst, id_soft),
                                          i_exr               => i_exr,
                                          i_type              => i_type,
                                          i_id_report         => i_id_report,
                                          i_id_ref_completion => i_id_ref_completion,
                                          i_flg_isencao       => i_flg_isencao,
                                          o_ref               => o_ref,
                                          o_error             => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ref);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_EXR_GROUP',
                                                     o_error    => o_error);
    END get_exr_group;

    /**
    * Returns the list of referral MCDTs grouped as required the specified report
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   id_prof             Professional identifier
    * @param   id_inst             Professional institution identifier
    * @param   id_soft             Professional software identifier   
    * @param   i_exr               Referral identifier
    * @param   i_type              Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application  
    * @param   i_id_report         Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion Referral completion option id. Needed to get the maximum number of MCDTs in each referral report   
    * @param   o_ref               MCDTs list
    * @param   O_ERROR             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    * @modify  Ana Monteiro, 2009-10-23: ALERT-48308 - added parameters i_id_report and i_id_ref_completion   
    */
    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        id_prof             IN professional.id_professional%TYPE,
        id_inst             IN institution.id_institution%TYPE,
        id_soft             IN software.id_software%TYPE,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init get_exr_group';
        RETURN pk_p1_med_cs.get_exr_group(i_lang              => i_lang,
                                          i_prof              => profissional(id_prof, id_inst, id_soft),
                                          i_exr               => i_exr,
                                          i_type              => i_type,
                                          i_id_report         => i_id_report,
                                          i_id_ref_completion => i_id_ref_completion,
                                          i_flg_isencao       => i_flg_isencao,
                                          o_ref               => o_ref,
                                          o_error             => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ref);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_EXR_GROUP',
                                                     o_error    => o_error);
    END get_exr_group;

    /**
    * Splits referral MCDTs into groups, as required the specified report
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   id_prof                Professional identifier
    * @param   id_inst                Professional institution identifier
    * @param   id_soft                Professional software identifier   
    * @param   i_exr                  Referral identifier
    * @param   i_id_patient           Patient identifier
    * @param   i_id_episode           Episode identifier    
    * @param   i_type                 Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application  
    * @param   i_num_req              Referrals number    
    * @param   i_id_report            Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion    Referral completion option id. Needed to get the maximum number of MCDTs in each referral report   
    * @param   o_id_external_request  Created referral ids
    * @param   O_ERROR                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    * @modify  Ana Monteiro, 2009-10-23: ALERT-48308 - added parameters i_id_report and i_id_ref_completion
    */
    FUNCTION split_mcdt_request_by_group
    (
        i_lang                IN language.id_language%TYPE,
        id_prof               IN professional.id_professional%TYPE,
        id_inst               IN institution.id_institution%TYPE,
        id_soft               IN software.id_software%TYPE,
        i_exr                 IN p1_external_request.id_external_request%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_type                IN VARCHAR2,
        i_num_req             IN table_varchar,
        i_id_report           IN reports.id_reports%TYPE,
        i_id_ref_completion   IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao         IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'split_mcdt_request_by_group / ID_EXT_REQ=' || i_exr || ' ID_PATIENT=' || i_id_patient ||
                   ' ID_EPISODE=' || i_id_episode || ' TYPE=' || i_type || ' ID_REPORT=' || i_id_report ||
                   ' ID_REF_COMPLETION=' || i_id_ref_completion;
        pk_alertlog.log_debug(g_error);
    
        g_retval := pk_p1_med_cs.split_mcdt_request_by_group(i_lang                => i_lang,
                                                             i_prof                => profissional(id_prof,
                                                                                                   id_inst,
                                                                                                   id_soft),
                                                             i_exr                 => i_exr,
                                                             i_id_patient          => i_id_patient,
                                                             i_id_episode          => i_id_episode,
                                                             i_type                => i_type,
                                                             i_num_req             => i_num_req,
                                                             i_id_report           => i_id_report,
                                                             i_id_ref_completion   => i_id_ref_completion,
                                                             i_flg_isencao         => i_flg_isencao,
                                                             o_id_external_request => o_id_external_request,
                                                             o_error               => o_error);
    
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
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SPLIT_MCDT_REQUEST_BY_GROUP',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END split_mcdt_request_by_group;

    /**
    * Service to create or update a request
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_ext_req request id
    * @param   i_dt_modified data da última alteração tal como devolvida por pk_p1_core.get_p1_detail
    * @param   i_id_patient patient id
    * @param   i_speciality request speciality (P1_SPECIALITY)
    * @param   i_id_dep_clin_serv id department/clinical_service (can be null)
    * @param   i_req_type (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type (A)nalisys; (C)onsultation (E)xam, (I)ntervention,
    * @param   i_flg_priority urgent/not urgent
    * @param   i_flg_home home consultation?
    * @param   i_inst_dest destination institution
    * @param   i_prof  professional, institution and software ids
    * @param   i_id_sched   @deprecated
    * @param   i_problems request data - problem identifiers to solve
    * @param   i_problems request data - problem descriptions to solve
    * @param   i_dt_problem_begin request data - date of problem begining
    * @param   i_detail P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis request data - diagnosis
    * @param   i_completed request completeded (Y/N)
    * @param   i_id_tasks           Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP]
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP]
    * @param   o_id_external_request request id
    * @param   o_flg_show show message (Y/N)
    * @param   o_msg message text
    * @param   o_msg_title message title
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    * @modify  Ana Monteiro 2009/01/08 ALERT-11632
    */
    FUNCTION insert_external_request_new
    (
        i_lang             IN language.id_language%TYPE,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2, -- JS: 2007-04-18, Validar se pedido é modificado enquanto é editado pelo médico do CS
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE, -- I_ID_INST_ORIG IN PROFISSIONAL,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_prof             IN profissional,
        --i_id_sched            IN schedule.id_schedule%TYPE, --- Não usado
        i_problems            IN CLOB,
        i_dt_problem_begin    IN VARCHAR2,
        i_detail              IN table_table_varchar,
        i_diagnosis           IN CLOB,
        i_completed           IN VARCHAR2,
        i_id_tasks            IN table_table_number,
        i_id_info             IN table_table_number,
        i_epis                IN episode.id_episode%TYPE,
        i_ref_completion      IN ref_completion.id_ref_completion%TYPE,
        i_prof_cert           IN VARCHAR2,
        i_prof_first_name     IN VARCHAR2,
        i_prof_surname        IN VARCHAR2,
        i_prof_phone          IN VARCHAR2,
        i_id_fam_rel          IN family_relationship.id_family_relationship%TYPE,
        i_name_first_rel      IN VARCHAR2,
        i_name_middle_rel     IN VARCHAR2,
        i_name_last_rel       IN VARCHAR2,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_wf PLS_INTEGER;
    BEGIN
    
        IF i_ref_completion != pk_ref_constant.g_ref_compl_ge
           OR i_ref_completion IS NULL
        THEN
            l_id_wf := NULL;
        ELSE
            l_id_wf := to_number(nvl(pk_sysconfig.get_config(pk_ref_constant.g_referral_button_wf, i_prof), 0));
        
            IF l_id_wf = 0
            THEN
                l_id_wf := NULL;
            END IF;
        
        END IF;
        g_error  := 'Call pk_ref_service.insert_referral i_workflow=' || l_id_wf || ' i_ref_completion =' ||
                    i_ref_completion;
        g_retval := pk_ref_service.insert_referral(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_ext_req          => i_ext_req,
                                                   i_dt_modified      => i_dt_modified,
                                                   i_id_patient       => i_id_patient,
                                                   i_speciality       => i_speciality,
                                                   i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                   i_req_type         => i_req_type,
                                                   i_flg_type         => i_flg_type,
                                                   i_flg_priority     => i_flg_priority,
                                                   i_flg_home         => i_flg_home,
                                                   i_inst_orig        => i_prof.id,
                                                   i_inst_dest        => i_inst_dest,
                                                   i_problems         => i_problems,
                                                   i_dt_problem_begin => i_dt_problem_begin,
                                                   i_detail           => i_detail,
                                                   i_diagnosis        => i_diagnosis,
                                                   i_completed        => i_completed,
                                                   i_id_tasks         => i_id_tasks,
                                                   i_id_info          => i_id_info,
                                                   i_epis             => i_epis,
                                                   i_workflow         => l_id_wf,
                                                   i_num_order        => NULL,
                                                   i_prof_name        => NULL,
                                                   i_prof_id          => NULL,
                                                   i_institution_name => NULL,
                                                   i_external_sys     => NULL,
                                                   i_comments         => NULL,
                                                   i_prof_cert        => i_prof_cert,
                                                   i_prof_first_name  => i_prof_first_name,
                                                   i_prof_surname     => i_prof_surname,
                                                   i_prof_phone       => i_prof_phone,
                                                   i_id_fam_rel       => i_id_fam_rel,
                                                   i_fam_rel_spec     => NULL,
                                                   i_name_first_rel   => i_name_first_rel,
                                                   i_name_middle_rel  => i_name_middle_rel,
                                                   i_name_last_rel    => i_name_last_rel,
                                                   
                                                   o_id_external_request => o_id_external_request,
                                                   o_flg_show            => o_flg_show,
                                                   o_msg                 => o_msg,
                                                   o_msg_title           => o_msg_title,
                                                   o_button              => o_button,
                                                   o_error               => o_error);
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_EXTERNAL_REQUEST_NEW',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END insert_external_request_new;

    /**
    * Insert mdct external request
    *
    * @param i_lang language associated to the professional executing the request
    * @param i_ext_req external request id
    * @param i_dt_modified
    * @param i_id_patient patient id
    * @param i_id_episode episode id
    * @param i_req_type
    * @param i_flg_type {*} 'A' analysis {*} 'I' Image {*} 'E' Other Exams {*} 'P' Intervention/Procedures {*} 'F' MFR
    * @param i_flg_priority_home priority and home flags home for each mcdt
    * @param i_mcdt selected mcdt, requisitions and institutions
    * @param i_prof  professional, institution and software ids
    * @param i_id_sched
    * @param i_problems Referral problems identifiers
    * @param i_problems_desc Referral problems descriptions
    * @param i_dt_problem_begin P1 detail
    * @param i_detail P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_diagnosis P1 diagnosis
    * @param i_completed
    * @param   i_id_tasks           Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP]
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP]
    * @param o_id_external_request
    * @param o_flg_show
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION insert_external_request_mcdt
    (
        i_lang              IN language.id_language%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_prof              IN profissional,
        --i_id_sched            IN schedule.id_schedule%TYPE, --- Not used
        i_problems            IN CLOB,
        i_dt_problem_begin    IN VARCHAR2,
        i_detail              IN table_table_varchar,
        i_diagnosis           IN CLOB,
        i_completed           IN VARCHAR2,
        i_id_tasks            IN table_table_number,
        i_id_info             IN table_table_number,
        i_codification        IN codification.id_codification%TYPE,
        i_flg_laterality      IN table_varchar DEFAULT NULL,
        i_ref_completion      IN ref_completion.id_ref_completion%TYPE,
        i_consent             IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_wf PLS_INTEGER;
    BEGIN
    
        g_error := 'Call pk_p1_med_cs.insert_referral_mcdt_internal';
        IF i_ref_completion != pk_ref_constant.g_ref_compl_ge
        THEN
            l_id_wf := NULL;
        ELSE
            l_id_wf := to_number(nvl(pk_sysconfig.get_config(pk_ref_constant.g_referral_button_wf, i_prof), 0));
            IF l_id_wf = 0
            THEN
                l_id_wf := NULL;
            END IF;
        END IF;
    
        g_error  := 'Call pk_ref_service.insert_mcdt_referral';
        g_retval := pk_ref_service.insert_mcdt_referral(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_ext_req                   => i_ext_req,
                                                        i_workflow                  => l_id_wf,
                                                        i_flg_priority_home         => i_flg_priority_home,
                                                        i_mcdt                      => i_mcdt,
                                                        i_id_patient                => i_id_patient,
                                                        i_req_type                  => i_req_type,
                                                        i_flg_type                  => i_flg_type,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => i_detail,
                                                        i_diagnosis                 => i_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => i_id_tasks,
                                                        i_id_info                   => i_id_info,
                                                        i_epis                      => i_id_episode,
                                                        i_date                      => NULL,
                                                        i_codification              => i_codification,
                                                        i_flg_laterality            => i_flg_laterality,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_consent                   => i_consent,
                                                        i_reason                    => NULL,
                                                        i_complementary_information => NULL,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg                       => o_msg,
                                                        o_msg_title                 => o_msg_title,
                                                        o_button                    => o_button,
                                                        o_ext_req                   => o_id_external_request,
                                                        o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- O COMMIT é feito no pk_ref_service
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_EXTERNAL_REQUEST_MCDT_N',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END insert_external_request_mcdt;

    /**
    * Gets request detail
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   i_id_ext_req       External request id
    * @param   i_status_detail    Detail status returned: {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @param   i_flg_labels       Indicates if labels are returned: {*} 'Y' Returns lables {*} 'N' otherwise
    * @param   o_patient          Referral patient general data
    * @param   O_DETAIL           Request general data
    * @param   O_TEXT             P1 information detail: Reason, Symptomology, Progress, History, Family history, Objective exam
    *                                  Diagnostic exams and Notes (mcdts)
    * @param   O_PROBLEM
    * @param   O_DIAGNOSIS
    * @param   O_MCDT
    * @param   O_NEEDS
    * @param   O_INFO
    * @param   O_NOTES_STATUS
    * @param   O_NOTES_STATUS_DET
    * @param   o_answer
    * @param   O_TITLE_STATUS
    * @param   O_EDITABLE
    * @param   O_CAN_CANCEL 'Y' if the request can be canceled, 'N' otherwise
    * @param   o_fields_rank       Cursor with field names and ranks
    *
    * @param   O_ERROR
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   03-11-2006
    */
    FUNCTION get_p1_detail_new
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          profissional,
        i_id_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_status_detail IN p1_detail.flg_status%TYPE,
        i_flg_labels    IN VARCHAR2 DEFAULT pk_ref_constant.g_no,
        --o_patient          OUT pk_types.cursor_type,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_title_status     OUT VARCHAR2,
        o_editable         OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_comments     OUT pk_types.cursor_type,
        o_fields_rank      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_orig_data pk_types.cursor_type;
        l_patient       pk_types.cursor_type;
        l_id_workflow   p1_external_request.id_workflow%TYPE;
    BEGIN
    
        g_error  := 'Init get_p1_detail_new / ID_REF=' || i_id_ext_req;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_ref      => i_id_ext_req,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT pk_ref_service.get_referral(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_ext_req       => i_id_ext_req,
                                           i_status_detail    => i_status_detail,
                                           o_patient          => l_patient,
                                           o_detail           => o_detail,
                                           o_text             => o_text,
                                           o_problem          => o_problem,
                                           o_diagnosis        => o_diagnosis,
                                           o_mcdt             => o_mcdt,
                                           o_needs            => o_needs,
                                           o_info             => o_info,
                                           o_notes_status     => o_notes_status,
                                           o_notes_status_det => o_notes_status_det,
                                           o_answer           => o_answer,
                                           o_title_status     => o_title_status,
                                           o_can_cancel       => o_can_cancel,
                                           o_ref_orig_data    => l_ref_orig_data,
                                           o_ref_comments     => o_ref_comments,
                                           o_fields_rank      => o_fields_rank,
                                           o_error            => o_error)
        THEN
            NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_P1_DETAIL_NEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_comments);
        
            --pk_types.open_cursor_if_closed(o_patient);
            RETURN FALSE;
    END get_p1_detail_new;

    FUNCTION get_p1_healthcare_insurance
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_ext_req            IN p1_external_request.id_external_request%TYPE,
        i_root_name             IN VARCHAR2,
        i_req_det               IN exam_req_det.id_exam_req_det%TYPE DEFAULT NULL,
        o_id_pat_health_plan    OUT exam_req_det.id_pat_health_plan%TYPE,
        o_id_pat_exemption      OUT exam_req_det.id_pat_exemption%TYPE,
        o_id_health_plan_entity OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_num_health_plan       OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat_health_plan    exam_req_det.id_pat_health_plan%TYPE;
        l_id_pat_exemption      exam_req_det.id_pat_exemption%TYPE;
        l_id_health_plan_entity health_plan_entity.id_health_plan_entity%TYPE;
        l_num_health_plan       VARCHAR2(1000);
    BEGIN
        IF i_root_name = pk_orders_utils.g_p1_appointment
        THEN
            SELECT per.id_pat_health_plan, per.id_pat_exemption
              INTO l_id_pat_health_plan, l_id_pat_exemption
              FROM p1_external_request per
             WHERE per.id_external_request = i_id_ext_req;
        ELSIF i_root_name = pk_orders_utils.g_p1_lab_test
        THEN
            SELECT ard.id_pat_health_plan, ard.id_pat_exemption
              INTO l_id_pat_health_plan, l_id_pat_exemption
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = i_req_det;
        ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
        THEN
            SELECT erd.id_pat_health_plan, erd.id_pat_exemption
              INTO l_id_pat_health_plan, l_id_pat_exemption
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = i_req_det;
        ELSIF i_root_name = pk_orders_utils.g_p1_intervention
        THEN
            SELECT ipd.id_pat_health_plan, ipd.id_pat_exemption
              INTO l_id_pat_health_plan, l_id_pat_exemption
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = i_req_det;
        ELSIF i_root_name = pk_orders_utils.g_p1_rehab
        THEN
            SELECT rp.id_pat_health_plan, rp.id_pat_exemption
              INTO l_id_pat_health_plan, l_id_pat_exemption
              FROM rehab_presc rp
             WHERE rp.id_rehab_presc = i_req_det;
        END IF;
    
        IF l_id_pat_health_plan IS NOT NULL
        THEN
            SELECT hpe.id_health_plan_entity
              INTO l_id_health_plan_entity
              FROM pat_health_plan php
              JOIN health_plan hp
                ON php.id_health_plan = hp.id_health_plan
              LEFT JOIN health_plan_entity hpe
                ON hp.id_health_plan_entity = hpe.id_health_plan_entity
             WHERE php.id_pat_health_plan = l_id_pat_health_plan;
        
            l_num_health_plan := pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'N');
        END IF;
    
        o_id_pat_health_plan    := l_id_pat_health_plan;
        o_id_pat_exemption      := l_id_pat_exemption;
        o_id_health_plan_entity := l_id_health_plan_entity;
        o_num_health_plan       := l_num_health_plan;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_P1_HEALTHCARE_INSURANCE',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_p1_healthcare_insurance;

    FUNCTION get_diagnosis_concat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_diagnosis IN tbl_p1_diagnosis
    ) RETURN VARCHAR2 IS
    
        l_count PLS_INTEGER;
        l_ret   VARCHAR2(4000);
    BEGIN
    
        l_count := i_tbl_diagnosis.count;
    
        FOR i IN i_tbl_diagnosis.first .. i_tbl_diagnosis.last
        LOOP
        
            l_ret := l_ret || i_tbl_diagnosis(i).title;
        
            IF l_count = 1
               OR i = i_tbl_diagnosis.last
            THEN
                l_ret := l_ret || '.';
            ELSIF i < i_tbl_diagnosis.last
            THEN
                l_ret := l_ret || '; ';
            END IF;
        
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diagnosis_concat;

    FUNCTION get_mcdt_concat
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_tbl_mcdt             IN tbl_mcdt_type,
        i_flg_show_cancel_info IN VARCHAR2
    ) RETURN CLOB IS
        l_count PLS_INTEGER;
        l_ret   CLOB;
        l_ident VARCHAR2(50) := '    ';
    
        l_id_prof_cancel   exam_req_det.id_prof_cancel%TYPE;
        l_notes_cancel     exam_req_det.notes_cancel%TYPE;
        l_id_cancel_reason exam_req_det.id_cancel_reason%TYPE;
        l_dt_cancel        exam_req_det.dt_cancel_tstz%TYPE;
    
        l_error t_error_out;
    BEGIN
        l_count := i_tbl_mcdt.count;
    
        FOR i IN i_tbl_mcdt.first .. i_tbl_mcdt.last
        LOOP
            l_ret := l_ret || chr(10) || l_ident || '<b>' || i_tbl_mcdt(i).p1_title || '</b>';
        
            IF i_tbl_mcdt(i).p1_mcdt_amount IS NOT NULL
            THEN
                l_ret := l_ret || chr(10) || l_ident || '<b>' || i_tbl_mcdt(i).p1_label_amount || ': </b>' || i_tbl_mcdt(i).p1_mcdt_amount;
            END IF;
        
            IF i_tbl_mcdt(i).p1_complementary_information IS NOT NULL
            THEN
                l_ret := l_ret || chr(10) || l_ident || '<b>' ||
                         pk_message.get_message(i_lang, 'REP_REQ_MCDTS_DEMATERIALIZED_028') || ' </b>' || i_tbl_mcdt(i).p1_complementary_information;
            END IF;
        
            IF i_tbl_mcdt(i).p1_desc_laterality IS NOT NULL
            THEN
                l_ret := l_ret || chr(10) || l_ident || '<b>' || i_tbl_mcdt(i).p1_label_laterality || ': </b>' || i_tbl_mcdt(i).p1_desc_laterality;
            END IF;
        
            IF i_tbl_mcdt(i).p1_priority_desc IS NOT NULL
            THEN
                l_ret := l_ret || chr(10) || l_ident || '<b>' || i_tbl_mcdt(i).p1_label_priority || ': </b>' || i_tbl_mcdt(i).p1_priority_desc;
            END IF;
        
            IF i_tbl_mcdt(i).p1_desc_home IS NOT NULL
            THEN
                l_ret := l_ret || chr(10) || l_ident || '<b>' || i_tbl_mcdt(i).p1_label_home || ': </b>' || i_tbl_mcdt(i).p1_desc_home;
            END IF;
        
            IF i_tbl_mcdt(i).p1_reason IS NOT NULL
            THEN
                l_ret := l_ret || chr(10) || l_ident || '<b>' || pk_message.get_message(i_lang, 'P1_DETAIL_T013') ||
                         ': </b>' || i_tbl_mcdt(i).p1_reason;
            END IF;
        
            --Cancellation info
            IF i_tbl_mcdt(i).p1_flg_status = pk_alert_constant.g_cancelled
                AND i_flg_show_cancel_info = pk_alert_constant.g_yes
            THEN
                BEGIN
                    SELECT *
                      INTO l_id_cancel_reason, l_notes_cancel, l_id_prof_cancel, l_dt_cancel
                      FROM (SELECT ard.id_cancel_reason, ard.notes_cancel, ard.id_prof_cancel, ard.dt_cancel_tstz
                              FROM analysis_req_det ard
                             WHERE ard.id_analysis_req_det = i_tbl_mcdt(i).p1_id_req
                               AND i_tbl_mcdt(i).p1_flg_type = pk_ref_constant.g_p1_type_a
                            UNION
                            SELECT erd.id_cancel_reason, erd.notes_cancel, erd.id_prof_cancel, erd.dt_cancel_tstz
                              FROM exam_req_det erd
                             WHERE erd.id_exam_req_det = i_tbl_mcdt(i).p1_id_req
                               AND i_tbl_mcdt(i)
                                  .p1_flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i)
                            UNION
                            SELECT ipd.id_cancel_reason, ipd.notes_cancel, ipd.id_prof_cancel, ipd.dt_cancel_tstz
                              FROM interv_presc_det ipd
                             WHERE ipd.id_interv_presc_det = i_tbl_mcdt(i).p1_id_req
                               AND i_tbl_mcdt(i).p1_flg_type = pk_ref_constant.g_p1_type_p
                            UNION
                            SELECT rp.id_cancel_reason, rp.notes_cancel, rp.id_cancel_professional, rp.dt_cancel
                              FROM rehab_presc rp
                             WHERE rp.id_rehab_presc = i_tbl_mcdt(i).p1_id_req
                               AND i_tbl_mcdt(i).p1_flg_type = pk_ref_constant.g_p1_type_f);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_cancel_reason := NULL;
                        l_notes_cancel     := NULL;
                        l_id_prof_cancel   := NULL;
                        l_dt_cancel        := NULL;
                END;
            
                l_ret := l_ret || chr(10) || l_ident || '<b>' || pk_message.get_message(i_lang, 'PROCEDURES_T011') ||
                         ' </b>' || pk_message.get_message(i_lang, 'CANCELLED');
            
                IF l_id_cancel_reason IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) || l_ident || '<b>' || pk_message.get_message(i_lang, 'ANALYSIS_T077') ||
                             ' </b>' || pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, l_id_cancel_reason);
                END IF;
            
                IF l_notes_cancel IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) || l_ident || '<b>' || pk_message.get_message(i_lang, 'ANALYSIS_T072') ||
                             ' </b>' || l_notes_cancel;
                END IF;
            
                IF l_id_prof_cancel IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) || l_ident || '<b>' || pk_message.get_message(i_lang, 'EXAMS_T127') ||
                             ' </b>' || pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_prof_cancel);
                END IF;
            
                IF l_dt_cancel IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) || l_ident || '<b>' || pk_message.get_message(i_lang, 'SUPPLIES_T111') ||
                             ' </b>' ||
                             pk_date_utils.date_char_tsz(i_lang, l_dt_cancel, i_prof.institution, i_prof.software);
                END IF;
            END IF;
        
            IF i < i_tbl_mcdt.last
            THEN
                l_ret := l_ret || chr(10);
            END IF;
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_mcdt_concat;

    FUNCTION get_p1_detail_html
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_status_detail IN p1_detail.flg_status%TYPE,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tab_dd_block_referral t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
        l_request_type p1_external_request.flg_type%TYPE;
    
        l_diagnosis_desc        VARCHAR2(4000);
        l_problems_desc         VARCHAR2(4000);
        l_reason                VARCHAR2(4000);
        l_notes                 VARCHAR2(4000);
        l_mcdt_desc             CLOB;
        l_symptoms_desc         VARCHAR2(4000);
        l_course_desc           VARCHAR2(4000);
        l_medication_desc       VARCHAR2(4000);
        l_vital_signs_desc      VARCHAR2(4000);
        l_past_history_desc     VARCHAR2(4000);
        l_family_history_desc   VARCHAR2(4000);
        l_obective_exam_desc    VARCHAR2(4000);
        l_diagnostic_tests_desc VARCHAR2(4000);
    
        l_has_present_history       VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_past_history          VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_objective_examination VARCHAR2(1) := pk_alert_constant.g_no;
        l_has_diagnostic_tests      VARCHAR2(1) := pk_alert_constant.g_no;
    
        c_detail           pk_types.cursor_type;
        c_text             pk_types.cursor_type;
        c_problem          pk_types.cursor_type;
        c_diagnosis        pk_types.cursor_type;
        c_mcdt             pk_types.cursor_type;
        l_needs            pk_types.cursor_type;
        l_info             pk_types.cursor_type;
        l_notes_status     pk_types.cursor_type;
        l_notes_status_det pk_types.cursor_type;
        l_answer           pk_types.cursor_type;
        l_title_status     VARCHAR2(1000);
        l_editable         VARCHAR2(10);
        l_can_cancel       VARCHAR2(10);
        l_ref_comments     pk_types.cursor_type;
        l_fields_rank      pk_types.cursor_type;
    
        l_tbl_p1_detail    tbl_p1_detail_type;
        l_tbl_p1_diagnosis tbl_p1_diagnosis;
        l_tbl_p1_text      tbl_p1_text;
        l_tbl_p1_mcdt      tbl_mcdt_type;
    
        --Variables for health insurance and exemption
        l_id_pat_health_plan    exam_req_det.id_pat_health_plan%TYPE;
        l_id_pat_exemption      exam_req_det.id_pat_exemption%TYPE;
        l_id_health_plan_entity health_plan_entity.id_health_plan_entity%TYPE;
        l_num_health_plan       VARCHAR2(1000);
    
        --CANCEL
        l_id_cancel_reason      cancel_reason.id_cancel_reason%TYPE;
        l_cancel_reason_desc    translation.desc_lang_1%TYPE;
        l_notes_cancel_reason   VARCHAR2(1000 CHAR);
        l_count_distinct_cancel PLS_INTEGER := 0;
    
        l_id_patient patient.id_patient%TYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT p.flg_type, p.id_patient
          INTO l_request_type, l_id_patient
          FROM p1_external_request p
         WHERE p.id_external_request = i_id_ext_req;
    
        IF NOT get_p1_detail_new(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_ext_req       => i_id_ext_req,
                                 i_status_detail    => i_status_detail,
                                 i_flg_labels       => pk_ref_constant.g_no,
                                 o_detail           => c_detail,
                                 o_text             => c_text,
                                 o_problem          => c_problem,
                                 o_diagnosis        => c_diagnosis,
                                 o_mcdt             => c_mcdt,
                                 o_needs            => l_needs,
                                 o_info             => l_info,
                                 o_notes_status     => l_notes_status,
                                 o_notes_status_det => l_notes_status_det,
                                 o_answer           => l_answer,
                                 o_title_status     => l_title_status,
                                 o_editable         => l_editable,
                                 o_can_cancel       => l_can_cancel,
                                 o_ref_comments     => l_ref_comments,
                                 o_fields_rank      => l_fields_rank,
                                 o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH c_detail BULK COLLECT
            INTO l_tbl_p1_detail;
    
        FOR i IN l_tbl_p1_detail.first .. l_tbl_p1_detail.last
        LOOP
            IF l_tbl_p1_detail(i).dt_probl_begin IS NOT NULL
            THEN
                l_has_present_history := pk_alert_constant.g_yes;
                EXIT;
            END IF;
        END LOOP;
    
        BEGIN
            FETCH c_diagnosis BULK COLLECT
                INTO l_tbl_p1_diagnosis;
        
            l_diagnosis_desc := pk_p1_ext_sys.get_diagnosis_concat(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_tbl_diagnosis => l_tbl_p1_diagnosis);
        EXCEPTION
            WHEN OTHERS THEN
                l_diagnosis_desc := NULL;
        END;
    
        BEGIN
            FETCH c_problem BULK COLLECT
                INTO l_tbl_p1_diagnosis;
        
            l_problems_desc := pk_p1_ext_sys.get_diagnosis_concat(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_tbl_diagnosis => l_tbl_p1_diagnosis);
        
            IF l_problems_desc IS NOT NULL
            THEN
                l_has_present_history := pk_alert_constant.g_yes;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_problems_desc := NULL;
        END;
    
        BEGIN
            FETCH c_text BULK COLLECT
                INTO l_tbl_p1_text;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        IF l_tbl_p1_text.count > 0
        THEN
            FOR i IN l_tbl_p1_text.first .. l_tbl_p1_text.last
            LOOP
                IF l_tbl_p1_text(i).field_name = 'REASON'
                THEN
                    l_reason := l_tbl_p1_text(i).text;
                ELSIF l_tbl_p1_text(i).field_name = 'NOTES'
                THEN
                    l_notes := l_tbl_p1_text(i).text;
                ELSIF l_tbl_p1_text(i).field_name = 'SYMPTOMS'
                THEN
                    l_symptoms_desc       := l_tbl_p1_text(i).text;
                    l_has_present_history := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'PROGRESS'
                THEN
                    l_course_desc         := l_tbl_p1_text(i).text;
                    l_has_present_history := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'MEDICATION'
                THEN
                    l_medication_desc     := l_tbl_p1_text(i).text;
                    l_has_present_history := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'VITAL_SIGNES'
                THEN
                    l_vital_signs_desc    := l_tbl_p1_text(i).text;
                    l_has_present_history := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'HISTORY'
                THEN
                    l_past_history_desc := l_tbl_p1_text(i).text;
                    l_has_past_history  := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'FAMILY_HISTORY'
                THEN
                    l_family_history_desc := l_tbl_p1_text(i).text;
                    l_has_past_history    := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'OBJECTIVE_EXAM'
                THEN
                    l_obective_exam_desc        := l_tbl_p1_text(i).text;
                    l_has_objective_examination := pk_alert_constant.g_yes;
                ELSIF l_tbl_p1_text(i).field_name = 'DIAGNOSTIC_TESTS'
                THEN
                    l_diagnostic_tests_desc := l_tbl_p1_text(i).text;
                    l_has_diagnostic_tests  := pk_alert_constant.g_yes;
                END IF;
            END LOOP;
        END IF;
    
        --check if record is canceled
        IF l_tbl_p1_detail(1).flg_status = pk_alert_constant.g_cancelled
        THEN
            BEGIN
                SELECT pt.id_reason_code
                  INTO l_id_cancel_reason
                  FROM p1_tracking pt
                 WHERE pt.id_external_request = l_tbl_p1_detail(1).id_external_request
                   AND pt.flg_type = 'S'
                   AND pt.id_reason_code IS NOT NULL;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_cancel_reason := NULL;
            END;
        
            IF l_id_cancel_reason IS NOT NULL
            THEN
                SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                  INTO l_cancel_reason_desc
                  FROM cancel_reason cr
                 WHERE cr.id_cancel_reason = l_id_cancel_reason;
            
                BEGIN
                    SELECT pd.text
                      INTO l_notes_cancel_reason
                      FROM p1_detail pd
                     WHERE pd.id_external_request = l_tbl_p1_detail(1).id_external_request
                       AND pd.flg_type = 10;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_notes_cancel_reason := NULL;
                END;
            END IF;
        
            --CONTINUAR COM A VERIFICAÇÃO DA DATA PARA PERCEBER SE FORAM TODOS CANCELADOS AO MESMO TEMPO
            -- SELECT DISTINCT DT_CANCEL -- COUNT = 1
            SELECT COUNT(1)
              INTO l_count_distinct_cancel
              FROM (SELECT DISTINCT ard.dt_cancel_tstz
                      FROM analysis_req_det ard
                      JOIN p1_exr_temp pet
                        ON ard.id_analysis_req_det = pet.id_analysis_req_det
                      JOIN p1_external_request per
                        ON per.id_external_request = pet.id_external_request
                     WHERE pet.id_external_request = i_id_ext_req
                       AND per.flg_type = pk_ref_constant.g_p1_type_a
                    UNION
                    SELECT DISTINCT erd.dt_cancel_tstz
                      FROM exam_req_det erd
                      JOIN p1_exr_temp pet
                        ON erd.id_exam_req_det = pet.id_exam_req_det
                      JOIN p1_external_request per
                        ON per.id_external_request = pet.id_external_request
                     WHERE pet.id_external_request = i_id_ext_req
                       AND per.flg_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e)
                    UNION
                    SELECT DISTINCT ipd.dt_cancel_tstz
                      FROM interv_presc_det ipd
                      JOIN p1_exr_temp pet
                        ON ipd.id_interv_presc_det = pet.id_interv_presc_det
                      JOIN p1_external_request per
                        ON per.id_external_request = pet.id_external_request
                     WHERE pet.id_external_request = i_id_ext_req
                       AND per.flg_type = pk_ref_constant.g_p1_type_p
                    UNION
                    SELECT DISTINCT rp.dt_cancel
                      FROM rehab_presc rp
                      JOIN p1_exr_temp pet
                        ON rp.id_rehab_presc = pet.id_rehab_presc
                      JOIN p1_external_request per
                        ON per.id_external_request = pet.id_external_request
                     WHERE pet.id_external_request = i_id_ext_req
                       AND per.flg_type = pk_ref_constant.g_p1_type_f);
        END IF;
    
        BEGIN
            FETCH c_mcdt BULK COLLECT
                INTO l_tbl_p1_mcdt;
        
            l_mcdt_desc := pk_p1_ext_sys.get_mcdt_concat(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_tbl_mcdt             => l_tbl_p1_mcdt,
                                                         i_flg_show_cancel_info => CASE l_count_distinct_cancel
                                                                                       WHEN 1 THEN
                                                                                        pk_alert_constant.g_no
                                                                                       ELSE
                                                                                        pk_alert_constant.g_yes
                                                                                   END);
        EXCEPTION
            WHEN OTHERS THEN
                l_mcdt_desc := NULL;
        END;
    
        IF NOT pk_p1_ext_sys.get_p1_healthcare_insurance(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_id_ext_req            => i_id_ext_req,
                                                         i_root_name             => pk_orders_utils.g_p1_appointment,
                                                         o_id_pat_health_plan    => l_id_pat_health_plan,
                                                         o_id_pat_exemption      => l_id_pat_exemption,
                                                         o_id_health_plan_entity => l_id_health_plan_entity,
                                                         o_num_health_plan       => l_num_health_plan,
                                                         o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
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
          INTO l_tab_dd_block_referral
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT NULL AS referral,
                                       ' ' AS referral_details,
                                       to_char(t.id_external_request) id_external_request,
                                       t.spec_name clinical_service,
                                       t.inst_orig_name,
                                       t.inst_name,
                                       CASE
                                            WHEN l_request_type = 'C' THEN
                                             t.desc_home
                                            ELSE
                                             NULL
                                        END desc_home,
                                       CASE
                                            WHEN l_request_type = 'C' THEN
                                             t.priority_desc
                                            ELSE
                                             NULL
                                        END priority_desc,
                                       t.desc_consent,
                                       l_reason AS reason,
                                       l_notes AS notes,
                                       l_diagnosis_desc AS diagnosis,
                                       t.desc_status,
                                       CASE
                                            WHEN l_has_present_history = pk_alert_constant.g_yes THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END present_history,
                                       l_problems_desc AS problems,
                                       t.dt_probl_begin AS onset,
                                       l_symptoms_desc AS symptoms,
                                       l_course_desc AS course,
                                       l_medication_desc AS medication,
                                       l_vital_signs_desc AS vital_signs,
                                       CASE
                                            WHEN l_has_past_history = pk_alert_constant.g_yes THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END past_history,
                                       l_past_history_desc AS history,
                                       l_family_history_desc AS family_history,
                                       l_obective_exam_desc AS objective_exam,
                                       decode(l_obective_exam_desc, NULL, NULL, ' ') objective_exam_wl,
                                       l_diagnostic_tests_desc AS diagnostic_tests,
                                       decode(l_diagnostic_tests_desc, NULL, NULL, ' ') diagnostic_tests_wl,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_requested) ||
                                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               t.id_prof_requested,
                                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             t.dt_last_interaction,
                                                                                                             NULL),
                                                                               t.id_episode),
                                              NULL,
                                              '; ',
                                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                       i_prof,
                                                                                       t.id_prof_requested,
                                                                                       pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     t.dt_last_interaction,
                                                                                                                     NULL),
                                                                                       t.id_episode) || '); ') ||
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   pk_date_utils.get_string_tstz(i_lang,
                                                                                                 i_prof,
                                                                                                 t.dt_last_interaction,
                                                                                                 NULL),
                                                                   i_prof.institution,
                                                                   i_prof.software) registry,
                                       CASE
                                            WHEN l_has_present_history = pk_alert_constant.g_yes THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END present_history_wl,
                                       CASE
                                            WHEN l_has_past_history = pk_alert_constant.g_yes THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END past_history_wl,
                                       CASE
                                            WHEN (l_id_pat_health_plan IS NOT NULL OR l_id_pat_exemption IS NOT NULL) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END healthcare_insurance,
                                       CASE
                                            WHEN l_id_pat_health_plan IS NOT NULL THEN
                                             pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'F')
                                            ELSE
                                             NULL
                                        END healthplan_entity,
                                       CASE
                                            WHEN l_id_pat_health_plan IS NOT NULL THEN
                                             pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'H')
                                            ELSE
                                             NULL
                                        END health_coverage_plan,
                                       CASE
                                            WHEN l_id_pat_health_plan IS NOT NULL THEN
                                             l_num_health_plan
                                            ELSE
                                             NULL
                                        END beneficiary_number,
                                       CASE
                                            WHEN l_id_pat_exemption IS NOT NULL THEN
                                             pk_adt.get_pat_exemption_detail(i_lang, i_prof, l_id_pat_exemption)
                                            ELSE
                                             NULL
                                        END exemption,
                                       CASE
                                            WHEN (l_id_pat_health_plan IS NOT NULL OR l_id_pat_exemption IS NOT NULL) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END healthcare_wl,
                                       t.type_ins,
                                       t.ref_line,
                                       CASE
                                            WHEN (t.desc_fr IS NOT NULL OR t.name_first_rel IS NOT NULL OR
                                                 t.name_middle_rel IS NOT NULL OR t.name_last_rel IS NOT NULL) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END patient_responsible_wl,
                                       CASE
                                            WHEN (t.desc_fr IS NOT NULL OR t.name_first_rel IS NOT NULL OR
                                                 t.name_middle_rel IS NOT NULL OR t.name_last_rel IS NOT NULL) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END patient_responsible,
                                       CASE
                                            WHEN t.id_fam_rel = 44
                                                 AND t.family_relationship_notes IS NOT NULL THEN
                                             t.desc_fr || ' - ' || t.family_relationship_notes
                                            ELSE
                                             t.desc_fr
                                        END desc_fr,
                                       t.name_first_rel,
                                       t.name_middle_rel,
                                       t.name_last_rel,
                                       CASE
                                            WHEN (t.prof_certificate IS NOT NULL OR t.prof_name IS NOT NULL OR
                                                 t.prof_surname IS NOT NULL OR t.prof_phone IS NOT NULL) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END destination_physician_wl,
                                       CASE
                                            WHEN (t.prof_certificate IS NOT NULL OR t.prof_name IS NOT NULL OR
                                                 t.prof_surname IS NOT NULL OR t.prof_phone IS NOT NULL) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END destination_physician,
                                       t.prof_certificate,
                                       t.prof_name,
                                       t.prof_surname,
                                       t.prof_phone,
                                       CASE
                                            WHEN ((l_id_cancel_reason IS NOT NULL OR l_notes_cancel_reason IS NOT NULL) AND
                                                 l_count_distinct_cancel = 1) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END cancel_wl,
                                       CASE
                                            WHEN ((l_id_cancel_reason IS NOT NULL OR l_notes_cancel_reason IS NOT NULL) AND
                                                 l_count_distinct_cancel = 1) THEN
                                             ' '
                                            ELSE
                                             NULL
                                        END cancel,
                                       CASE
                                            WHEN l_count_distinct_cancel = 1 THEN
                                             l_cancel_reason_desc
                                        END cancel_reason,
                                       CASE
                                            WHEN l_count_distinct_cancel = 1 THEN
                                             l_notes_cancel_reason
                                        END cancel_notes
                                  FROM TABLE(l_tbl_p1_detail) t) unpivot include NULLS(data_source_val FOR data_source IN(referral,
                                                                                                                          referral_details,
                                                                                                                          id_external_request,
                                                                                                                          clinical_service,
                                                                                                                          inst_orig_name,
                                                                                                                          inst_name,
                                                                                                                          desc_home,
                                                                                                                          priority_desc,
                                                                                                                          desc_consent,
                                                                                                                          reason,
                                                                                                                          notes,
                                                                                                                          diagnosis,
                                                                                                                          desc_status,
                                                                                                                          present_history,
                                                                                                                          problems,
                                                                                                                          onset,
                                                                                                                          symptoms,
                                                                                                                          course,
                                                                                                                          medication,
                                                                                                                          vital_signs,
                                                                                                                          past_history,
                                                                                                                          history,
                                                                                                                          family_history,
                                                                                                                          objective_exam,
                                                                                                                          objective_exam_wl,
                                                                                                                          diagnostic_tests,
                                                                                                                          diagnostic_tests_wl,
                                                                                                                          registry,
                                                                                                                          present_history_wl,
                                                                                                                          past_history_wl,
                                                                                                                          healthcare_insurance,
                                                                                                                          healthplan_entity,
                                                                                                                          health_coverage_plan,
                                                                                                                          beneficiary_number,
                                                                                                                          exemption,
                                                                                                                          healthcare_wl,
                                                                                                                          type_ins,
                                                                                                                          ref_line,
                                                                                                                          desc_fr,
                                                                                                                          patient_responsible_wl,
                                                                                                                          patient_responsible,
                                                                                                                          name_first_rel,
                                                                                                                          name_middle_rel,
                                                                                                                          name_last_rel,
                                                                                                                          destination_physician_wl,
                                                                                                                          destination_physician,
                                                                                                                          prof_certificate,
                                                                                                                          prof_name,
                                                                                                                          prof_surname,
                                                                                                                          prof_phone,
                                                                                                                          cancel_wl,
                                                                                                                          cancel,
                                                                                                                          cancel_reason,
                                                                                                                          cancel_notes)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'EXTERNALREFERRAL'
           AND ddb.internal_name = 'REFERRAL'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              flg_type, -- TYPE
                              flg_html,
                              CASE
                                  WHEN flg_clob = pk_alert_constant.g_yes THEN
                                   l_mcdt_desc
                                  ELSE
                                   NULL
                              END,
                              flg_clob),
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_referral) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'EXTERNALREFERRAL'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1'))
                UNION
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       NULL                  rnk,
                       ddc.rank,
                       ddc.id_dd_block,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM dd_content ddc
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'EXTERNALREFERRAL'
                   AND ((ddc.data_source = 'PROCEDURES' AND
                       l_request_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f)) OR
                       (ddc.data_source = 'LAB_TESTS' AND l_request_type = pk_ref_constant.g_p1_type_a) OR
                       (ddc.data_source = 'EXAMS' AND
                       l_request_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e))))
         ORDER BY rank;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ' '
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
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_p1_detail_html',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_p1_detail_html;

    FUNCTION get_p1_mcdts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_request_type p1_external_request.flg_type%TYPE;
    
        c_detail           pk_types.cursor_type;
        c_text             pk_types.cursor_type;
        c_problem          pk_types.cursor_type;
        c_diagnosis        pk_types.cursor_type;
        c_mcdt             pk_types.cursor_type;
        l_needs            pk_types.cursor_type;
        l_info             pk_types.cursor_type;
        l_notes_status     pk_types.cursor_type;
        l_notes_status_det pk_types.cursor_type;
        l_answer           pk_types.cursor_type;
        l_title_status     VARCHAR2(1000);
        l_editable         VARCHAR2(10);
        l_can_cancel       VARCHAR2(10);
        l_ref_comments     pk_types.cursor_type;
        l_fields_rank      pk_types.cursor_type;
    
        l_tbl_p1_mcdt tbl_mcdt_type;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT p.flg_type
          INTO l_request_type
          FROM p1_external_request p
         WHERE p.id_external_request = i_id_ext_req;
    
        IF l_request_type <> 'C'
        THEN
            IF NOT get_p1_detail_new(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_id_ext_req       => i_id_ext_req,
                                     i_status_detail    => 'A',
                                     i_flg_labels       => pk_ref_constant.g_no,
                                     o_detail           => c_detail,
                                     o_text             => c_text,
                                     o_problem          => c_problem,
                                     o_diagnosis        => c_diagnosis,
                                     o_mcdt             => c_mcdt,
                                     o_needs            => l_needs,
                                     o_info             => l_info,
                                     o_notes_status     => l_notes_status,
                                     o_notes_status_det => l_notes_status_det,
                                     o_answer           => l_answer,
                                     o_title_status     => l_title_status,
                                     o_editable         => l_editable,
                                     o_can_cancel       => l_can_cancel,
                                     o_ref_comments     => l_ref_comments,
                                     o_fields_rank      => l_fields_rank,
                                     o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            FETCH c_mcdt BULK COLLECT
                INTO l_tbl_p1_mcdt;
        
            OPEN o_list FOR
                SELECT pet.id_exr_temp,
                       coalesce(t.p1_id_analysis_req, t.p1_id_exam_req) id_req,
                       t.p1_id_req id_req_det,
                       t.p1_id id_mcdt,
                       t.p1_id_sample_type id_analysis_sample_type,
                       t.p1_flg_type flg_type,
                       t.standard_code,
                       t.p1_flg_status flg_status,
                       t.p1_title mcdt_desc,
                       pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T039') || ': ' || t.p1_desc_institution || '; ' ||
                        t.p1_label_amount || ': ' || t.p1_mcdt_amount || '; ' || CASE
                            WHEN t.p1_complementary_information IS NOT NULL THEN
                             pk_message.get_message(i_lang, 'DS_COMPONENT.CODE_DS_COMPONENT.1815') || ': ' ||
                             t.p1_complementary_information || '; '
                        END || CASE
                            WHEN t.p1_desc_laterality IS NOT NULL THEN
                             t.p1_label_laterality || ': ' || t.p1_desc_laterality || '; '
                        END || t.p1_label_priority || ': ' || t.p1_priority_desc || '; ' || t.p1_label_home || ': ' ||
                        t.p1_desc_home || '; ' || CASE
                            WHEN t.p1_reason IS NOT NULL THEN
                             pk_message.get_message(i_lang, 'P1_DOCTOR_CS_T010') || ': ' || t.p1_reason || '; '
                        END AS mcdt_info
                  FROM TABLE(l_tbl_p1_mcdt) t
                  LEFT JOIN p1_exr_temp pet
                    ON pet.id_external_request = i_id_ext_req
                   AND ((t.p1_flg_type = pk_ref_constant.g_p1_type_a AND pet.id_analysis_req_det = t.p1_id_req) OR
                       (t.p1_flg_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e) AND
                       pet.id_exam_req_det = t.p1_id_req) OR
                       (t.p1_flg_type = pk_ref_constant.g_p1_type_p AND pet.id_interv_presc_det = t.p1_id_req) OR
                       ((t.p1_flg_type = pk_ref_constant.g_p1_type_f AND pet.id_rehab_presc = t.p1_id_req)));
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
                                              'GET_P1_MCDTS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_p1_mcdts;

    /**
    * Get cancel reason codes list
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF id professional, institution and software
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Ss
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION get_cancel_reasons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
    
        g_error  := 'Call pk_ref_list.get_reason_list I_TYPE=' || pk_ref_constant.g_reason_code_c || ' i_mcdt=' ||
                    l_bdnp_available;
        g_retval := pk_ref_list.get_reason_list(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_type    => pk_ref_constant.g_reason_code_c,
                                                i_mcdt    => l_bdnp_available,
                                                o_reasons => o_reasons,
                                                o_error   => o_error);
    
        /*    g_error  := 'Call pk_ref_list.get_cancel_reason_list ' || ' i_mcdt=' || l_bdnp_available;
        g_retval := pk_ref_list.get_cancel_reason_list(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_mcdt    => l_bdnp_available,
                                                       o_reasons => o_reasons,
                                                       o_error   => o_error);*/
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CANCEL_REASONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_cancel_reasons;

    FUNCTION get_cancel_reasons
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_p1_flg_type VARCHAR,
        o_reasons     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
        IF i_p1_flg_type = 'C'
        THEN
            l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                    pk_ref_constant.g_no);
        END IF;
    
        g_error  := 'Call pk_ref_list.get_cancel_reason_list ' || ' i_mcdt=' || l_bdnp_available;
        g_retval := pk_ref_list.get_cancel_reason_list(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_mcdt    => CASE i_p1_flg_type
                                                                        WHEN 'C' THEN
                                                                         l_bdnp_available
                                                                        ELSE
                                                                         pk_alert_constant.g_yes
                                                                    END,
                                                       o_reasons => o_reasons,
                                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CANCEL_REASONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_cancel_reasons;

    /**
    * Cancel referral
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof id professional, institution and software
    * @param   i_ext_req referral id
    * @param   i_id_patient patient id
    * @param   i_id_episode episode id
    * @param   i_notes cancelation notes episode id
    * @param   i_reason cancelation reason code
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Ss
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_external_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_mcdts      IN table_number,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes      IN VARCHAR2,
        i_reason     IN p1_reason_code.id_reason_code%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_track_tab      table_number;
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'Call pk_p1_med_cs.cancel_external_request_int / ID_REF=' || i_ext_req || ' ID_PATIENT=' ||
                   i_id_patient || ' ID_EPISODE=' || i_id_episode || ' ID_REASON_CODE=' || i_reason;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_med_cs.cancel_external_request_int(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_ext_req        => i_ext_req,
                                                             i_mcdts          => i_mcdts,
                                                             i_id_patient     => i_id_patient,
                                                             i_id_episode     => i_id_episode,
                                                             i_notes          => i_notes,
                                                             i_reason         => i_reason,
                                                             i_transaction_id => l_transaction_id,
                                                             o_track          => l_track_tab,
                                                             o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_EXTERNAL_REQUEST',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_external_request;

    /**
    * Changes request status after scheduling
    *
    * @param   i_lang idioma
    * @param   i_prof professional id, institution and software for the professional that schedules
    * @param   i_ext_req external request id
    * @param   i_schedule schedule id
    * @param   i_reschedule Y - it is a reschedule, N - Otherwise
    * @param   i_date         Date of status change
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-07-2008
    */
    FUNCTION set_status_scheduled
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_schedule   IN schedule.id_schedule%TYPE,
        i_reschedule IN VARCHAR,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exr IS
            SELECT id_external_request
              FROM p1_external_request exr
             WHERE exr.id_schedule = i_schedule
               AND exr.flg_status IN (pk_ref_constant.g_p1_status_s, pk_ref_constant.g_p1_status_m);
    
        l_exr_status_row p1_external_request%ROWTYPE;
        l_track_row      p1_tracking%ROWTYPE;
        l_date_tstz      schedule.dt_begin_tstz%TYPE;
        l_dcs            schedule.id_dcs_requested%TYPE;
        l_prof_sch       sch_prof_outp.id_professional%TYPE;
    
        l_rowids         table_varchar;
        l_p1_skip_triage sys_config.value%TYPE;
        l_sysdate_tstz   p1_tracking.dt_tracking_tstz%TYPE;
        o_track          table_number;
        l_track_tab      table_number;
    BEGIN
    
        g_error := '->Init set_status_scheduled / ID_REF=' || i_ext_req || ' ID_SCHEDULE=' || i_schedule ||
                   ' RESCHEDULE=' || i_reschedule;
        pk_alertlog.log_debug(g_error);
        l_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        l_p1_skip_triage := pk_sysconfig.get_config('P1_SKIP_TRIAGE', i_prof);
    
        -- Se houver P1 associados a este agendamento devem ser desmarcados
        g_error := 'Call cancel_schedule';
        FOR w IN c_exr
        LOOP
        
            g_error := 'Call cancel_schedule / ID_REF=' || w.id_external_request;
            IF NOT cancel_schedule(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_ext_req => w.id_external_request,
                                   i_notes   => NULL,
                                   i_date    => l_sysdate_tstz,
                                   o_error   => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        END LOOP;
    
        g_error := 'Get schedule data';
        SELECT s.dt_begin_tstz, s.id_dcs_requested, spo.id_professional
          INTO l_date_tstz, l_dcs, l_prof_sch
          FROM schedule s
          JOIN schedule_outp so
            ON (s.id_schedule = so.id_schedule)
          LEFT JOIN sch_prof_outp spo
            ON (spo.id_schedule_outp = so.id_schedule_outp)
         WHERE s.id_schedule = i_schedule;
    
        g_error := 'Call ts_p1_external_request.upd';
        ts_p1_external_request.upd(id_external_request_in => i_ext_req,
                                   id_dep_clin_serv_in    => l_dcs,
                                   id_schedule_in         => i_schedule,
                                   rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_status_row,
                                                       o_error  => o_error);
    
        -- Se está em estado Emitido é porque foi agendado directamente sem passa por "Triagem"
        -- ACM 2009-06-29, ALERT-32888: nao faz triagem se a conf deixar
        IF l_p1_skip_triage = pk_ref_constant.g_yes
        THEN
            IF l_exr_status_row.flg_status = pk_ref_constant.g_p1_status_i
            THEN
                g_error                         := 'UPDATE STATUS T';
                l_track_row.id_external_request := i_ext_req;
                l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_t;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.dt_tracking_tstz    := l_sysdate_tstz - INTERVAL '2' SECOND;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_t);
            
                IF i_reschedule = pk_ref_constant.g_yes
                THEN
                    l_track_row.flg_reschedule := i_reschedule;
                END IF;
            
                g_error  := 'Call pk_p1_core.update_status / ID_EXT_REQ=' || l_track_row.id_external_request ||
                            ' FLG_STATUS=' || l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
                g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_track_row   => l_track_row,
                                                     i_old_status  => pk_ref_constant.g_p1_status_i,
                                                     i_flg_isencao => NULL,
                                                     i_mcdt_nature => NULL,
                                                     o_track       => l_track_tab,
                                                     o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_exr_status_row.flg_status := pk_ref_constant.g_p1_status_t;
                o_track                     := o_track MULTISET UNION l_track_tab;
            
            END IF;
        
            -- Se está em estado de Triagem é porque foi agendado directamente sem passa por "para Agendar"
            IF l_exr_status_row.flg_status = pk_ref_constant.g_p1_status_t
               OR l_exr_status_row.flg_status = pk_ref_constant.g_p1_status_r
            THEN
                g_error := 'UPDATE STATUS A';
            
                l_track_row.id_external_request := i_ext_req;
                l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_a;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.id_dep_clin_serv    := l_dcs;
                l_track_row.dt_tracking_tstz    := l_sysdate_tstz - INTERVAL '1' SECOND;
                l_track_row.decision_urg_level  := pk_ref_constant.g_decision_urg_level_normal;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_a);
            
                IF i_reschedule = pk_ref_constant.g_yes
                THEN
                    l_track_row.flg_reschedule := i_reschedule;
                END IF;
            
                g_error  := 'Call pk_p1_core.update_status / ID_EXT_REQ=' || l_track_row.id_external_request ||
                            ' FLG_STATUS=' || l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type ||
                            ' DEP_CLIN_SERV=' || l_track_row.id_dep_clin_serv || ' DECISION_URG_LEVEL=' ||
                            l_track_row.decision_urg_level;
                g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_track_row   => l_track_row,
                                                     i_old_status  => pk_ref_constant.g_p1_status_t ||
                                                                      pk_ref_constant.g_p1_status_r,
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
    
        g_error                         := 'UPDATE STATUS S';
        l_track_row.id_external_request := i_ext_req;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_s;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_dep_clin_serv    := l_dcs;
        l_track_row.dt_tracking_tstz    := l_sysdate_tstz;
        l_track_row.decision_urg_level  := NULL;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_s);
    
        IF i_reschedule = pk_ref_constant.g_yes
        THEN
            l_track_row.flg_reschedule := i_reschedule;
        END IF;
        -- JS, 2007-12-13: Guardar historico de agendamentos.
        l_track_row.id_schedule := i_schedule;
    
        g_error  := 'Call pk_p1_core.update_status / ID_EXT_REQ=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                    l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type || ' DEP_CLIN_SERV=' ||
                    l_track_row.id_dep_clin_serv || ' DECISION_URG_LEVEL=' || l_track_row.decision_urg_level ||
                    ' FLG_RESCHEDULE=' || l_track_row.flg_reschedule;
        g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_track_row   => l_track_row,
                                             i_old_status  => pk_ref_constant.g_p1_status_a ||
                                                              pk_ref_constant.g_p1_status_s ||
                                                              pk_ref_constant.g_p1_status_m,
                                             i_flg_isencao => NULL,
                                             i_mcdt_nature => NULL,
                                             o_track       => l_track_tab,
                                             o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_track := o_track MULTISET UNION l_track_tab;
    
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
                                              i_function => 'SET_STATUS_SCHEDULED',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_status_scheduled;

    /**
    * Changes request status after schedule cancelation
    *
    * @param   i_lang idioma
    * @param   i_prof professional id, institution and software for the professional that schedules
    * @param   i_ext_req external request id
    * @param   i_notes cancelation notes
    * @param   i_date         Date of status change
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-08-2007
    */
    FUNCTION cancel_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_req     IN p1_external_request.id_external_request%TYPE,
        i_notes       IN VARCHAR2,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_last IS
            SELECT t.id_prof_dest,
                   t.id_dep_clin_serv,
                   t.decision_urg_level,
                   p.id_inst_dest,
                   p.id_inst_orig,
                   p.id_workflow
              FROM p1_tracking t
              JOIN p1_external_request p
                ON (t.id_external_request = p.id_external_request)
             WHERE t.id_external_request = i_ext_req
               AND t.flg_type = pk_ref_constant.g_tracking_type_s
               AND t.ext_req_status = pk_ref_constant.g_p1_status_a
             ORDER BY dt_tracking_tstz DESC;
    
        l_last             c_last%ROWTYPE;
        l_track_row        p1_tracking%ROWTYPE;
        l_sysdate_tstz     p1_tracking.dt_tracking_tstz%TYPE;
        l_id_inst_dcs      institution.id_institution%TYPE;
        l_rowids           table_varchar;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
        o_track            table_number;
    BEGIN
        g_error := '->Init cancel_schedule / ID_REF=' || i_ext_req;
        pk_alertlog.log_debug(g_error);
        l_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        -- Cleans dt_schedule from p1_external_request but keeps reference to cancelled scheduling.    
        g_error := 'Open c_last';
        OPEN c_last;
        FETCH c_last
            INTO l_last;
        CLOSE c_last;
    
        -- check if dep_clin_serv belongs to referral dest institution
        g_error  := 'Call pk_ref_utils.get_institution / ID_REF=' || i_ext_req || ' ID_DEP_CLIN_SERV=' ||
                    l_last.id_dep_clin_serv;
        g_retval := pk_ref_utils.get_institution(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_dcs            => l_last.id_dep_clin_serv,
                                                 o_id_institution => l_id_inst_dcs,
                                                 o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_inst_dcs != l_last.id_inst_dest
        THEN
            -- change referral dest institution 
        
            g_error            := 'Call pk_api_ref_ws.get_flg_availability / ID_WF=' || l_last.id_workflow ||
                                  ' ID_INST_ORIG=' || l_last.id_inst_orig || ' ID_INST_DEST=' || l_last.id_inst_dest;
            l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_last.id_workflow,
                                                                     i_id_inst_orig => l_last.id_inst_orig,
                                                                     i_id_inst_dest => l_last.id_inst_dest);
        
            -- cannot change referral institution for internal and at hospital entrance referrals
            IF l_flg_availability IN (pk_ref_constant.g_flg_availability_i, pk_ref_constant.g_flg_availability_p)
            THEN
                g_error := 'Cannot change dep_clin_serv for this kind of referrals / ID_WF=' || l_last.id_workflow ||
                           ' ID_REF=' || i_ext_req || ' ID_INST_ORIG=' || l_last.id_inst_orig || ' ID_INST_DEST=' ||
                           l_last.id_inst_dest || ' ID_DEP_CLIN_SERV_NEW=' || l_last.id_dep_clin_serv ||
                           ' ID_INST_DEST_NEW=' || l_id_inst_dcs;
                RAISE g_exception;
            END IF;
        
            g_error := 'Call ts_p1_external_request.upd / ID_EXT_REQ=' || i_ext_req || ' ID_INST_DEST_OLD=' ||
                       l_last.id_inst_dest || ' ID_INST_DEST_NEW=' || l_id_inst_dcs || ' DEP_CLIN_SERV=' ||
                       l_last.id_dep_clin_serv;
            ts_p1_external_request.upd(id_external_request_in => i_ext_req,
                                       id_inst_dest_in        => l_id_inst_dcs,
                                       rows_out               => l_rowids);
        
            g_error := 'Process_update P1_EXTERNAL_REQUEST / ID_EXT_REQ=' || i_ext_req || ' ID_INST_DEST_OLD=' ||
                       l_last.id_inst_dest || ' ID_INST_DEST_NEW=' || l_id_inst_dcs || ' DEP_CLIN_SERV=' ||
                       l_last.id_dep_clin_serv;
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'P1_EXTERNAL_REQUEST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error                         := 'UPDATE STATUS A';
        l_track_row.id_external_request := i_ext_req;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_a;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_prof_dest        := l_last.id_prof_dest;
        l_track_row.id_dep_clin_serv    := l_last.id_dep_clin_serv;
        l_track_row.dt_tracking_tstz    := l_sysdate_tstz;
        l_track_row.decision_urg_level  := l_last.decision_urg_level;
        l_track_row.flg_subtype         := pk_ref_constant.g_tracking_subtype_c;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_csh);
        l_track_row.id_reason_code      := i_reason_code;
    
        g_error  := 'Call pk_p1_core.update_status / ID_EXT_REQ=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                    l_track_row.ext_req_status || ' ID_PROF_DEST=' || l_track_row.id_prof_dest || ' DEP_CLIN_SERV=' ||
                    l_track_row.id_dep_clin_serv || ' DECISION_URG_LEVEL=' || l_track_row.decision_urg_level ||
                    ' FLG_SUBTYPE=' || l_track_row.flg_subtype;
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
    
        IF i_notes IS NOT NULL
        THEN
        
            g_error := 'INSERT P1_DETAIL / ID_REF=' || i_ext_req || ' FLG_TYPE=' || pk_ref_constant.g_detail_type_ndec ||
                       ' ID_PROFESSIONAL=' || i_prof.id || ' ID_INSTITUTION=' || i_prof.institution || ' ID_TRACKING=' ||
                       o_track(1);
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
                 l_sysdate_tstz,
                 pk_ref_constant.g_detail_type_ndec,
                 i_prof.id,
                 i_prof.institution,
                 o_track(1), -- first iteration
                 pk_ref_constant.g_active);
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
                                              i_function => 'CANCEL_SCHEDULE',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_schedule;

    /**
    * Updates referral status
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof id professional, institution and software
    * @param   i_ext_req           Referral identifier
    * @param   i_id_sch            Schedule identifier
    * @param   i_status            Referral new status. {*} S - schedule {*} E - efectivation {*} M - mailed 
                                   {*} C - appointment canceled {*} F - failed appointment
    * @param   i_notes             Notes related to this transition
    * @param   i_reschedule        {*} Y if reschedule {*} N Otherwise
    * @param   i_id_reason_code
    * @param   i_date         Date of status change
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-07-2008
    */
    FUNCTION update_referral_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN NUMBER,
        i_id_sch         IN schedule.id_schedule%TYPE,
        i_status         IN VARCHAR2,
        i_notes          IN VARCHAR2,
        i_reschedule     IN VARCHAR2,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row    p1_tracking%ROWTYPE;
        l_workflow     wf_workflow.id_workflow%TYPE;
        l_sysdate_tstz p1_tracking.dt_tracking_tstz%TYPE;
        o_track        table_number;
    BEGIN
    
        g_error := 'Init update_referral_status / ID_REF=' || i_ext_req || ' ID_SCHEDULE=' || i_id_sch ||
                   ' FLG_STATUS=' || i_status || ' RESCHEDULE=' || i_reschedule || ' OP_DATE=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, i_date, pk_ref_constant.g_format_date_2);
        pk_alertlog.log_debug(g_error);
        l_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_ref      => i_ext_req,
                                                           o_id_workflow => l_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_workflow IS NOT NULL
        THEN
        
            g_error := 'Call pk_ref_ext_sys.update_referral_status / ID_REF=' || i_ext_req || ' STATUS=' || i_status ||
                       ' ID_SCHEDULE=' || i_id_sch || ' ID_EPISODE=NULL DATE=' ||
                       pk_date_utils.to_char_insttimezone(i_prof, l_sysdate_tstz, pk_date_utils.g_dateformat);
            RETURN pk_ref_ext_sys.update_referral_status(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_ext_req        => i_ext_req,
                                                         i_status         => i_status,
                                                         i_notes          => i_notes,
                                                         i_schedule       => i_id_sch,
                                                         i_episode        => NULL,
                                                         i_date           => l_sysdate_tstz,
                                                         i_id_reason_code => i_id_reason_code,
                                                         o_error          => o_error);
        ELSE
            CASE i_status
                WHEN pk_ref_constant.g_p1_status_s THEN
                    -- S - Scheduled (Agendado);
                    g_error := 'Call set_status_scheduled / ID_REF=' || i_ext_req || ' ID_SCHEDULE=' || i_id_sch ||
                               ' FLG_RESCHEDULE=' || i_reschedule || ' DATE=' ||
                               pk_date_utils.to_char_insttimezone(i_prof, l_sysdate_tstz, pk_date_utils.g_dateformat);
                    RETURN set_status_scheduled(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_ext_req    => i_ext_req,
                                                i_schedule   => i_id_sch,
                                                i_reschedule => i_reschedule,
                                                i_date       => l_sysdate_tstz,
                                                o_error      => o_error);
                
                WHEN pk_ref_constant.g_p1_status_m THEN
                    -- M - Mailed (Enviada notificacao);
                    g_error                         := 'UPDATE STATUS M';
                    l_track_row.id_external_request := i_ext_req;
                    l_track_row.ext_req_status      := i_status;
                    l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                    l_track_row.dt_tracking_tstz    := l_sysdate_tstz;
                    l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_m);
                
                    -- JS: Nao valida retorno da funcao delineradamente. Na agenda pode ser chamada varias vezes.                    
                    g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request ||
                                ' FLG_STATUS=' || l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type ||
                                ' DATE=' || pk_date_utils.to_char_insttimezone(i_prof,
                                                                               l_track_row.dt_tracking_tstz,
                                                                               pk_date_utils.g_dateformat);
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
                
                WHEN pk_ref_constant.g_p1_status_e THEN
                    -- E - Executed (Consulta efectivada)
                    g_error                         := 'UPDATE STATUS';
                    l_track_row.id_external_request := i_ext_req;
                    l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_e;
                    l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                    -- js, 2008-04-02: Corrigir dt_tracking de S e E iguais
                    l_track_row.dt_tracking_tstz   := l_sysdate_tstz + INTERVAL '1' SECOND;
                    l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_e);
                
                    g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request ||
                                ' FLG_STATUS=' || l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type ||
                                ' DATE=' || pk_date_utils.to_char_insttimezone(i_prof,
                                                                               l_track_row.dt_tracking_tstz,
                                                                               pk_date_utils.g_dateformat);
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
                
                WHEN pk_ref_constant.g_p1_status_a THEN
                    --- Schedule canceled (Agendamento cancelado, E NAO P1 CANCELADO)                    
                    g_error := 'Call cancel_schedule / ID_REF=' || i_ext_req || ' DATE=' ||
                               pk_date_utils.to_char_insttimezone(i_prof, l_sysdate_tstz, pk_date_utils.g_dateformat);
                    RETURN cancel_schedule(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_ext_req     => i_ext_req,
                                           i_notes       => i_notes,
                                           i_date        => l_sysdate_tstz,
                                           i_reason_code => i_id_reason_code,
                                           o_error       => o_error);
                
                WHEN pk_ref_constant.g_p1_status_f THEN
                    -- F - Failed Appointment
                
                    -- change referral status
                    l_track_row.id_external_request := i_ext_req;
                    l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_f;
                    l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                    l_track_row.dt_tracking_tstz    := l_sysdate_tstz;
                    l_track_row.id_reason_code      := i_id_reason_code;
                    l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_f);
                
                    g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request ||
                                ' FLG_STATUS=' || l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type ||
                                ' DATE=' || pk_date_utils.to_char_insttimezone(i_prof,
                                                                               l_track_row.dt_tracking_tstz,
                                                                               pk_date_utils.g_dateformat);
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
                
                    -- add notes
                    IF i_notes IS NOT NULL
                    THEN
                    
                        g_error := 'INSERT P1_DETAIL / ID_REF=' || i_ext_req || ' FLG_TYPE=' ||
                                   pk_ref_constant.g_detail_type_miss || ' ID_PROFESSIONAL=' || i_prof.id ||
                                   ' ID_INSTITUTION=' || i_prof.institution || ' ID_TRACKING=' || o_track(1);
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
                             l_sysdate_tstz,
                             pk_ref_constant.g_detail_type_miss,
                             i_prof.id,
                             i_prof.institution,
                             o_track(1), -- first iteration
                             pk_ref_constant.g_active);
                    END IF;
                
                ELSE
                    RAISE g_exception;
            END CASE;
        
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
                                              i_function => 'UPDATE_REFERRAL_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_referral_status;

    /** 
    * Getting flg_time value
    * Used for Imaging exams, Other exams and Procedures
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   i_flg_type           Referral type
    * @param   o_flg_time           Scope of order's execution (this episode, between episodes, next episode)
    * @param   o_error              Error information
    *
    * @value   i_flg_type           {*} I-Imaging exams {*} E-Other exams {*} P-Procedures
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   26-08-2014
    */
    FUNCTION get_flg_time
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_time   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params          VARCHAR2(1000 CHAR);
        l_id_epis_type    episode.id_epis_type%TYPE;
        l_cur_time        pk_types.cursor_type;
        l_tab_val         table_varchar;
        l_tab_rank        table_number;
        l_tab_desc_val    table_varchar;
        l_tab_flg_default table_varchar;
    BEGIN
        -- getting flg_time value
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_flg_type=' || i_flg_type || ' i_id_episode=' ||
                    i_id_episode;
        g_error  := 'Init get_flg_time / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        IF i_flg_type = pk_ref_constant.g_p1_type_a
        THEN
            g_error  := 'Call pk_lab_tests_api_db.get_lab_test_time_list / ' || l_params;
            g_retval := pk_lab_tests_api_db.get_lab_test_time_list(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_epis_type => l_id_epis_type,
                                                                   o_list      => l_cur_time,
                                                                   o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSIF i_flg_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e)
        THEN
        
            g_error  := 'Call pk_episode.get_epis_type_new / ' || l_params;
            g_retval := pk_episode.get_epis_type_new(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_id_epis   => i_id_episode,
                                                     o_epis_type => l_id_epis_type,
                                                     o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'Call pk_exams_api_db.get_exam_time_list / ' || l_params;
            g_retval := pk_exams_api_db.get_exam_time_list(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_epis_type => l_id_epis_type,
                                                           i_exam_type => i_flg_type,
                                                           o_list      => l_cur_time,
                                                           o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSIF i_flg_type = pk_ref_constant.g_p1_type_p
        THEN
        
            g_error  := 'Call pk_procedures_api_db.get_procedure_time_list / FLG_TYPE=' || i_flg_type;
            g_retval := pk_procedures_api_db.get_procedure_time_list(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_epis_type => l_id_epis_type,
                                                                     o_list      => l_cur_time,
                                                                     o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error := 'FETCH l_cur_time BULK COLLECT INTO / FLG_TYPE=' || i_flg_type;
        FETCH l_cur_time BULK COLLECT
            INTO l_tab_val, l_tab_rank, l_tab_desc_val, l_tab_flg_default;
        CLOSE l_cur_time;
    
        -- if there is only one option, return that option
        -- otherwise return the option B- Before next episode
        IF l_tab_val.count = 1
        THEN
            o_flg_time := l_tab_val(1);
        ELSE
            o_flg_time := pk_alert_constant.g_flg_time_b;
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
                                              i_function => 'GET_FLG_TIME',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_flg_time;

    /** 
    * Getting workflow identifier of external referrals
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   i_ref_completion     Referral completion option identifier
    * @param   i_flg_type           Referral type
    * @param   o_flg_time           Scope of order's execution (this episode, between episodes, next episode)
    * @param   o_error              Error information
    *
    * @value   i_flg_type           {*} I-Imaging exams {*} E-Other exams {*} P-Procedures
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   02-09-2014
    */
    FUNCTION get_workflow_external
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_completion IN ref_completion.id_ref_completion%TYPE,
        o_id_workflow    OUT wf_workflow.id_workflow%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        -- getting flg_time value
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ref_completion=' || i_ref_completion;
        g_error  := 'Init get_workflow_external / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'i_ref_completion=' || i_ref_completion || ' / ' || l_params;
        IF i_ref_completion != pk_ref_constant.g_ref_compl_ge
        THEN
            o_id_workflow := NULL;
        ELSE
            o_id_workflow := to_number(pk_sysconfig.get_config(pk_ref_constant.g_referral_button_wf, i_prof));
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WORKFLOW_EXTERNAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_workflow_external;

    FUNCTION get_p1_cross_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_subject             IN action.subject%TYPE,
        i_p1_external_request IN p1_external_request.id_external_request%TYPE,
        i_p1_exr_temp         IN table_number,
        i_from_state          IN table_varchar,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --REF_PAT_GRID
        g_error := 'GET CURSOR o_actions';
    
        OPEN o_actions FOR
            SELECT t.id_action,
                   t.id_parent,
                   t.l AS "LEVEL",
                   t.to_state,
                   t.desc_action,
                   t.icon,
                   t.flg_default,
                   decode(per.id_prof_requested, i_prof.id, t.flg_active, 'I') flg_active,
                   t.action,
                   t.rank
              FROM (SELECT MIN(id_action) id_action,
                           id_parent,
                           l,
                           to_state,
                           desc_action,
                           icon,
                           flg_default,
                           MAX(flg_active) flg_active,
                           action,
                           MIN(rank) rank
                      FROM (SELECT id_action,
                                   id_parent,
                                   LEVEL AS l, --used to manage the shown' items by Flash
                                     to_state, --destination state flag
                                     pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                                   icon, --action's icon
                                     decode(flg_default, 'D', 'Y', 'N') flg_default, --default action
                                     nvl(pk_action.get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) AS flg_active, --action's state
                                   internal_name action,
                                   a.from_state,
                                   rank
                              FROM action a
                             WHERE subject = i_subject
                               AND from_state IN (SELECT *
                                                    FROM TABLE(i_from_state))
                            CONNECT BY PRIOR id_action = id_parent
                             START WITH id_parent IS NULL)
                     GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
                    HAVING COUNT(from_state) = (SELECT COUNT(*)
                                                 FROM TABLE(table_varchar() MULTISET UNION DISTINCT i_from_state))
                     ORDER BY l, rank, desc_action) t
              JOIN p1_external_request per
                ON per.id_external_request = i_p1_external_request;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_P1_EXT_SYS',
                                              'GET_P1_CROSS_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_p1_cross_actions;

    /**
    * Creates lab tests order and creates/updates a referral request
    *
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @param i_analysis_req           Array of lab test order identifiers
    * @param i_analysis_req_det       Array of lab test order detail identifiers
    * @param i_dt_begin               Array of dates for the lab test to be performed
    * @param i_analysis               Array of lab test identifiers
    * @param i_analysis_group         Array of lab test identifiers in a panel (always empty array)
    * @param i_flg_type               Array of types of the lab test: A - Lab test; G - group of lab tests
    * @param i_prof_order             Array of professionals that ordered the lab test (co-sign)
    * @param i_codification           Array of lab test codification identifiers
    * @param i_clinical_decision_rule Array of lab test clinical decision rule id    
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount|id_sample_type]
    * @param i_problems               Referral problems identifiers info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not.
    * @param i_id_task                Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg_req                Message to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_external_request    Array of referral identifiers created
    * @param o_error                  Error message
    *
    * @value i_flg_type               {*} 'A' - Lab test {*} 'G' - group of lab tests
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'A' Lab test
    * @value i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/04/20
    */
    FUNCTION create_lab_test_order
    (
        i_lang                   IN language.id_language%TYPE, --1
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_analysis_req           IN table_number, -- 5
        i_analysis_req_det       IN table_number,
        i_dt_begin               IN table_varchar,
        i_analysis               IN table_number,
        i_analysis_group         IN table_table_varchar,
        i_flg_type               IN table_varchar, --10
        i_prof_order             IN table_number,
        i_codification           IN table_number,
        i_clinical_decision_rule IN table_number,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'A'
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB, -- 25
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2, --30
        -- End of referral parameters
        o_flg_show  OUT VARCHAR2,
        o_msg_req   OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL CREATE_LAB_TEST_ORDER';
        IF NOT pk_p1_ext_sys.create_lab_test_order_internal(i_lang                      => i_lang,
                                                            i_prof                      => i_prof,
                                                            i_patient                   => i_patient,
                                                            i_episode                   => i_episode,
                                                            i_analysis_req              => i_analysis_req,
                                                            i_analysis_req_det          => i_analysis_req_det,
                                                            i_dt_begin                  => i_dt_begin,
                                                            i_analysis                  => i_analysis,
                                                            i_analysis_group            => i_analysis_group,
                                                            i_flg_type                  => i_flg_type,
                                                            i_prof_order                => i_prof_order,
                                                            i_codification              => i_codification,
                                                            i_clinical_decision_rule    => i_clinical_decision_rule,
                                                            i_reason                    => NULL,
                                                            i_complementary_information => NULL,
                                                            i_ext_req                   => i_ext_req,
                                                            i_dt_modified               => i_dt_modified,
                                                            i_req_type                  => i_req_type,
                                                            i_req_flg_type              => i_req_flg_type,
                                                            i_flg_priority_home         => i_flg_priority_home,
                                                            i_mcdt                      => i_mcdt,
                                                            i_problems                  => i_problems,
                                                            i_dt_problem_begin          => i_dt_problem_begin,
                                                            i_detail                    => i_detail,
                                                            i_req_diagnosis             => i_req_diagnosis,
                                                            i_completed                 => i_completed,
                                                            i_id_tasks                  => i_id_tasks,
                                                            i_id_info                   => i_id_info,
                                                            i_ref_completion            => i_ref_completion,
                                                            i_consent                   => i_consent,
                                                            i_health_plan               => NULL,
                                                            i_exemption                 => NULL,
                                                            o_flg_show                  => o_flg_show,
                                                            o_msg_req                   => o_msg_req,
                                                            o_msg                       => o_msg,
                                                            o_msg_title                 => o_msg_title,
                                                            o_button                    => o_button,
                                                            o_id_external_request       => o_id_external_request,
                                                            o_error                     => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_LAB_TEST_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_lab_test_order;

    FUNCTION create_lab_test_order_internal
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_analysis_req              IN table_number, -- 5
        i_analysis_req_det          IN table_number,
        i_dt_begin                  IN table_varchar,
        i_analysis                  IN table_number,
        i_analysis_group            IN table_table_varchar,
        i_flg_type                  IN table_varchar, --10
        i_prof_order                IN table_number,
        i_codification              IN table_number,
        i_clinical_decision_rule    IN table_number,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'A'
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB, -- 25
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2, --30
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL,
        i_exemption       IN table_number DEFAULT NULL,
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show  OUT VARCHAR2,
        o_msg_req   OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- lab test vars
        l_flg_time_value VARCHAR2(5 CHAR);
        -- create new orders vars
        l_new_analysis_req            table_number := table_number();
        l_new_analysis_req_det        table_number := table_number();
        l_new_dt_begin                table_varchar := table_varchar();
        l_new_analysis                table_number := table_number();
        l_new_analysis_group          table_table_varchar := table_table_varchar();
        l_new_flg_type                table_varchar := table_varchar();
        l_new_prof_order              table_number := table_number();
        l_new_codification            table_number := table_number();
        l_new_clinical_decision_rule  table_number := table_number();
        l_new_dt_req                  table_varchar := table_varchar();
        l_new_episode_destination     table_number := table_number();
        l_new_flg_prn                 table_varchar := table_varchar();
        l_new_notes_prn               table_varchar := table_varchar();
        l_new_body_location           table_table_number := table_table_number();
        l_new_laterality              table_table_varchar := table_table_varchar();
        l_new_order_recurrence        table_number := table_number();
        l_new_collection_room         table_number := table_number();
        l_new_notes_patient           table_varchar := table_varchar();
        l_new_diagnosis_notes         table_varchar := table_varchar();
        l_new_clinical_purpose        table_number := table_number();
        l_new_clinical_purpose_notes  table_varchar := table_varchar();
        l_new_health_plan             table_number := table_number();
        l_new_exemption               table_number := table_number();
        l_new_notes                   table_varchar := table_varchar();
        l_new_notes_scheduler         table_varchar := table_varchar();
        l_new_notes_technician        table_varchar := table_varchar();
        l_new_prof_cc                 table_table_varchar := table_table_varchar();
        l_new_prof_bcc                table_table_varchar := table_table_varchar();
        l_new_clinical_question       table_table_number := table_table_number();
        l_new_response                table_table_varchar := table_table_varchar();
        l_new_clinical_question_notes table_table_varchar := table_table_varchar();
        l_new_task_dependency         table_number := table_number();
        l_new_flg_task_depending      table_varchar := table_varchar();
        l_new_episode_followup_app    table_number := table_number();
        l_new_schedule_followup_app   table_number := table_number();
        l_new_event_followup_app      table_number := table_number();
        l_new_dt_order                table_varchar := table_varchar();
        l_new_order_type              table_number := table_number();
        l_new_flg_col_inst            table_varchar := table_varchar();
        l_new_priority                table_varchar := table_varchar();
        l_new_flg_fasting             table_varchar := table_varchar();
        l_new_lab_req                 table_number := table_number();
        l_new_flg_time                table_varchar := table_varchar();
        l_new_dt_begin_limit          table_varchar := table_varchar();
        l_new_exec_institution        table_number := table_number();
        l_new_specimen                table_number := table_number();
        -- output
        l_analysis_req_array     table_number;
        l_analysis_req_par_array table_number;
        l_analysis_req_det_array table_number;
        -- referral vars
        l_mcdt               table_table_number := table_table_number(table_number(NULL, NULL, NULL, NULL, NULL));
        l_id_wf              PLS_INTEGER;
        l_id_pat_health_plan p1_external_request.id_pat_health_plan%TYPE;
        l_id_pat_exemption   p1_external_request.id_pat_exemption%TYPE;
        l_rows_out           table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' pat=' || i_patient || ' epis=' || i_episode ||
                    ' a_req=' || i_analysis_req.count || ' a_req_d=' || i_analysis_req_det.count || ' a=' ||
                    i_analysis.count || ' i_ext_req=' || i_ext_req || 'i_mcdt=' || i_mcdt.count || ' i_dt_modified=' ||
                    i_dt_modified || ' i_req_type=' || i_req_type || ' i_req_flg_type=' || i_req_flg_type ||
                    ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed ||
                    ' i_ref_completion=' || i_ref_completion;
        g_error  := 'Init create_lab_test_order / ' || l_params;
    
        -- validation of input parameters
        IF i_analysis.count != i_analysis_req.count
           OR i_analysis.count != i_analysis_req_det.count
           OR i_analysis.count != i_dt_begin.count
           OR i_analysis.count != i_flg_type.count
           OR i_analysis.count != i_prof_order.count
           OR i_analysis.count != i_codification.count
           OR i_analysis.count != i_mcdt.count
        THEN
            g_error := 'Invalid input parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- check if i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) = i_analysis(i): must be the same
        g_error := 'FOR i IN 1 .. i_mcdt.count / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt) != i_analysis(i)
            THEN
                g_error := 'Invalid analysis identifier / i_mcdt(' || i || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' ||
                           i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt) || ' i_analysis(' || i || ')=' || i_analysis(i) ||
                           ' / ' || l_params;
                RAISE g_exception;
            END IF;
        END LOOP;
    
        -- getting workflow identifier
        g_error  := 'i_ref_completion=' || i_ref_completion || ' / ' || l_params;
        g_retval := get_workflow_external(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ref_completion => i_ref_completion,
                                          o_id_workflow    => l_id_wf,
                                          o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' l_id_wf=' || l_id_wf;
    
        -- check if is a valid codification
        g_error  := 'Calling check_codification_count / ' || l_params;
        g_retval := check_codification_count(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_mcdt         => i_analysis,
                                             i_codification => i_codification,
                                             o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting flg_time value
        g_error  := 'Call get_flg_time / ' || l_params;
        g_retval := get_flg_time(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_flg_type   => i_req_flg_type,
                                 i_id_episode => i_episode,
                                 o_flg_time   => l_flg_time_value,
                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'l_mcdt := i_mcdt / ' || l_params;
        l_mcdt  := i_mcdt;
    
        -- Important note:        
        -- for all orders that are new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) = NULL):
        --   -create the order (pk_lab_tests_api_db.create_lab_test_order)
        --   -associate it to the referral (pk_ref_service.insert_mcdt_referral)
        -- for all orders that are NOT new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) IS NOT NULL):
        --   -associate/dissociate it from the referral (pk_ref_service.insert_mcdt_referral)
    
        g_error := 'FOR i IN 1 .. ' || i_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NULL
            THEN
                -- create new lab test order
            
                -- extend vars
                g_error := 'Extend vars / i_analysis=' || i_analysis(i) || ' / ' || l_params;
                l_new_analysis_req.extend;
                l_new_analysis_req_det.extend;
                l_new_dt_begin.extend;
                l_new_analysis.extend;
                l_new_analysis_group.extend;
                l_new_flg_type.extend;
                l_new_prof_order.extend;
                l_new_codification.extend;
                l_new_clinical_decision_rule.extend;
                l_new_dt_req.extend;
                l_new_episode_destination.extend;
                l_new_flg_prn.extend;
                l_new_notes_prn.extend;
                l_new_body_location.extend;
                l_new_laterality.extend;
                l_new_order_recurrence.extend;
                l_new_collection_room.extend;
                l_new_notes_patient.extend;
                l_new_diagnosis_notes.extend;
                l_new_clinical_purpose.extend;
                l_new_clinical_purpose_notes.extend;
                l_new_health_plan.extend;
                l_new_exemption.extend;
                l_new_notes.extend;
                l_new_notes_scheduler.extend;
                l_new_notes_technician.extend;
                l_new_prof_cc.extend;
                l_new_prof_bcc.extend;
                l_new_clinical_question.extend;
                l_new_response.extend;
                l_new_clinical_question_notes.extend;
                l_new_task_dependency.extend;
                l_new_flg_task_depending.extend;
                l_new_episode_followup_app.extend;
                l_new_schedule_followup_app.extend;
                l_new_event_followup_app.extend;
                l_new_dt_order.extend;
                l_new_order_type.extend;
                l_new_flg_col_inst.extend;
                l_new_priority.extend;
                l_new_flg_fasting.extend;
                l_new_lab_req.extend;
                l_new_flg_time.extend;
                l_new_dt_begin_limit.extend;
                l_new_exec_institution.extend;
                l_new_specimen.extend;
            
                -- set vars
                g_error := 'Set vars / i_analysis=' || i_analysis(i) || ' / ' || l_params;
                l_new_analysis_req(l_new_analysis_req.last) := i_analysis_req(i);
                l_new_analysis_req_det(l_new_analysis_req_det.last) := i_analysis_req_det(i);
                l_new_analysis(l_new_analysis.last) := i_analysis(i);
                l_new_analysis_group(l_new_analysis_group.last) := i_analysis_group(i);
                l_new_flg_type(l_new_flg_type.last) := i_flg_type(i);
                l_new_dt_req(l_new_dt_req.last) := NULL;
                l_new_flg_time(l_new_flg_time.last) := l_flg_time_value;
                l_new_dt_begin(l_new_dt_begin.last) := i_dt_begin(i);
                l_new_dt_begin_limit(l_new_dt_begin_limit.last) := NULL;
                l_new_episode_destination(l_new_episode_destination.last) := NULL;
                l_new_order_recurrence(l_new_order_recurrence.last) := NULL;
                l_new_priority(l_new_priority.last) := NULL;
                l_new_flg_prn(l_new_flg_prn.last) := pk_ref_constant.g_no;
                l_new_notes_prn(l_new_notes_prn.last) := NULL;
                l_new_specimen(l_new_specimen.last) := i_mcdt(i) (pk_ref_constant.g_idx_id_sample_type);
                l_new_body_location(l_new_body_location.last) := table_number(NULL);
                l_new_laterality(l_new_laterality.last) := table_varchar(NULL);
                l_new_collection_room(l_new_collection_room.last) := NULL;
                l_new_notes(l_new_notes.last) := NULL;
                l_new_notes_scheduler(l_new_notes_scheduler.last) := NULL;
                l_new_notes_technician(l_new_notes_technician.last) := NULL;
                l_new_notes_patient(l_new_notes_patient.last) := NULL;
                l_new_diagnosis_notes(l_new_diagnosis_notes.last) := NULL;
                l_new_exec_institution(l_new_exec_institution.last) := i_mcdt(i)
                                                                       (pk_ref_constant.g_idx_id_inst_dest_mcdt);
                l_new_clinical_purpose(l_new_clinical_purpose.last) := NULL;
                l_new_clinical_purpose_notes(l_new_clinical_purpose_notes.last) := NULL;
                l_new_flg_col_inst(l_new_flg_col_inst.last) := pk_ref_constant.g_no;
                l_new_flg_fasting(l_new_flg_fasting.last) := NULL;
                l_new_lab_req(l_new_lab_req.last) := NULL;
                l_new_prof_cc(l_new_prof_cc.last) := table_varchar(NULL);
                l_new_prof_bcc(l_new_prof_bcc.last) := table_varchar(NULL);
                l_new_codification(l_new_codification.last) := i_codification(i);
                IF i_health_plan.exists(i)
                THEN
                    l_new_health_plan(l_new_health_plan.last) := i_health_plan(i);
                ELSE
                    l_new_health_plan(l_new_health_plan.last) := NULL;
                END IF;
                IF i_exemption.exists(i)
                THEN
                    l_new_exemption(l_new_exemption.last) := i_exemption(i);
                ELSE
                    l_new_exemption(l_new_exemption.last) := NULL;
                END IF;
                l_new_prof_order(l_new_prof_order.last) := i_prof_order(i);
                l_new_dt_order(l_new_dt_order.last) := NULL;
                l_new_order_type(l_new_order_type.last) := NULL;
                l_new_clinical_question(l_new_clinical_question.last) := table_number(NULL);
                l_new_response(l_new_response.last) := table_varchar(NULL);
                l_new_clinical_question_notes(l_new_clinical_question_notes.last) := table_varchar(NULL);
                l_new_clinical_decision_rule(l_new_clinical_decision_rule.last) := i_clinical_decision_rule(i);
                l_new_task_dependency(l_new_task_dependency.last) := NULL;
                l_new_flg_task_depending(l_new_flg_task_depending.last) := pk_ref_constant.g_no;
                l_new_episode_followup_app(l_new_episode_followup_app.last) := NULL;
                l_new_schedule_followup_app(l_new_schedule_followup_app.last) := NULL;
                l_new_event_followup_app(l_new_event_followup_app.last) := NULL;
            END IF;
        END LOOP;
    
        ------------------------------------------
        -- create new lab tests
        IF l_new_analysis.count > 0
        THEN
            -- Creating analysis prescriptions
            g_error  := 'Call pk_lab_tests_api_db.create_lab_test_order / ' || l_params;
            g_retval := pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang, --1
                                                                  i_prof                    => i_prof,
                                                                  i_patient                 => i_patient,
                                                                  i_episode                 => i_episode,
                                                                  i_analysis_req            => NULL, --5 -- new order id
                                                                  i_analysis_req_det        => l_new_analysis_req_det,
                                                                  i_analysis_req_det_parent => NULL,
                                                                  i_harvest                 => NULL,
                                                                  i_analysis                => l_new_analysis,
                                                                  i_analysis_group          => l_new_analysis_group, --10
                                                                  i_flg_type                => l_new_flg_type,
                                                                  i_dt_req                  => l_new_dt_req,
                                                                  i_flg_time                => l_new_flg_time,
                                                                  i_dt_begin                => l_new_dt_begin,
                                                                  i_dt_begin_limit          => l_new_dt_begin_limit, -- 15
                                                                  i_episode_destination     => l_new_episode_destination,
                                                                  i_order_recurrence        => l_new_order_recurrence,
                                                                  i_priority                => l_new_priority,
                                                                  i_flg_prn                 => l_new_flg_prn,
                                                                  i_notes_prn               => l_new_notes_prn, -- 20
                                                                  i_specimen                => l_new_specimen,
                                                                  i_body_location           => l_new_body_location,
                                                                  i_laterality              => l_new_laterality,
                                                                  i_collection_room         => l_new_collection_room,
                                                                  i_notes                   => l_new_notes, -- 25
                                                                  i_notes_scheduler         => l_new_notes_scheduler,
                                                                  i_notes_technician        => l_new_notes_technician,
                                                                  i_notes_patient           => l_new_notes_patient,
                                                                  i_diagnosis_notes         => l_new_diagnosis_notes,
                                                                  i_diagnosis               => NULL,
                                                                  i_exec_institution        => l_new_exec_institution, -- 30
                                                                  i_clinical_purpose        => l_new_clinical_purpose,
                                                                  i_clinical_purpose_notes  => l_new_clinical_purpose_notes,
                                                                  i_flg_col_inst            => l_new_flg_col_inst,
                                                                  i_flg_fasting             => l_new_flg_fasting,
                                                                  i_lab_req                 => l_new_lab_req, --35
                                                                  i_prof_cc                 => l_new_prof_cc,
                                                                  i_prof_bcc                => l_new_prof_bcc,
                                                                  i_codification            => l_new_codification,
                                                                  i_health_plan             => l_new_health_plan,
                                                                  i_exemption               => l_new_exemption, -- 40
                                                                  i_prof_order              => l_new_prof_order,
                                                                  i_dt_order                => l_new_dt_order,
                                                                  i_order_type              => l_new_order_type,
                                                                  i_clinical_question       => l_new_clinical_question,
                                                                  i_response                => l_new_response, -- 45
                                                                  i_clinical_question_notes => l_new_clinical_question_notes,
                                                                  i_clinical_decision_rule  => l_new_clinical_decision_rule,
                                                                  i_flg_origin_req          => 'R',
                                                                  i_task_dependency         => l_new_task_dependency,
                                                                  i_flg_task_depending      => l_new_flg_task_depending, -- 50
                                                                  i_episode_followup_app    => l_new_episode_followup_app,
                                                                  i_schedule_followup_app   => l_new_schedule_followup_app,
                                                                  i_event_followup_app      => l_new_event_followup_app,
                                                                  i_test                    => pk_ref_constant.g_no,
                                                                  o_flg_show                => o_flg_show,
                                                                  o_msg_title               => o_msg_title,
                                                                  o_msg_req                 => o_msg_req,
                                                                  o_button                  => o_button,
                                                                  o_analysis_req_array      => l_analysis_req_array,
                                                                  o_analysis_req_det_array  => l_analysis_req_det_array,
                                                                  o_analysis_req_par_array  => l_analysis_req_par_array,
                                                                  o_error                   => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- fill in the analysis_req_det in l_mcdt(i)(pk_ref_constant.g_idx_id_req_det) position
            g_error := 'FOR h IN 1 .. ' || l_mcdt.count || ' / ' || l_params;
            <<mcdt_loop>>
            FOR h IN 1 .. l_mcdt.count
            LOOP
            
                g_error := '[BEG]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_amount) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_sample_type || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_sample_type);
                pk_alertlog.log_debug(g_error);
            
                /*JFA : if the requisition detail id is null on  the l_mcdt var, 
                        the i_analysis var should be checked on the relevant position (i_analysis(c) = l_mcdt(h) (1))
                        and on the l_analysis_req_det_array the requistion detail id for the 
                        exam we are checking should be assigned to the missing entry of
                        l_mcdt                
                */
                IF l_mcdt(h) (pk_ref_constant.g_idx_id_req_det) IS NULL
                THEN
                    <<analysis_loop>>
                    FOR c IN 1 .. l_new_analysis.count
                    LOOP
                    
                        g_error := 'LOOP l_new_analysis(' || c || ')=' || l_new_analysis(c) || ' l_specimen(' || c || ')=' ||
                                   l_new_specimen(c) || ' l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_req_det || ')=' ||
                                   l_mcdt(h) (pk_ref_constant.g_idx_id_req_det) || ' / ' || l_params;
                        IF l_new_analysis(c) = l_mcdt(h) (pk_ref_constant.g_idx_id_mcdt)
                           AND l_new_specimen(c) = l_mcdt(h) (pk_ref_constant.g_idx_id_sample_type)
                        THEN
                            l_mcdt(h)(pk_ref_constant.g_idx_id_req_det) := l_analysis_req_det_array(c);
                        END IF;
                    END LOOP analysis_loop;
                END IF;
            
                g_error := '[END]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_amount) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_sample_type || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_sample_type);
                pk_alertlog.log_debug(g_error);
            
            END LOOP mcdt_loop;
        ELSIF i_ext_req IS NULL
              AND i_analysis_req_det.count > 0
        THEN
            FOR i IN i_analysis_req_det.first .. i_analysis_req_det.last
            LOOP
                SELECT ard.id_pat_health_plan, ard.id_pat_exemption
                  INTO l_id_pat_health_plan, l_id_pat_exemption
                  FROM analysis_req_det ard
                 WHERE ard.id_analysis_req_det = i_analysis_req_det(i);
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_analysis_req_det.upd(id_analysis_req_det_in => i_analysis_req_det(i),
                                                id_pat_health_plan_in  => i_health_plan(i),
                                                id_pat_health_plan_nin => FALSE,
                                                id_pat_exemption_in    => i_exemption(i),
                                                id_pat_exemption_nin   => FALSE,
                                                handle_error_in        => TRUE,
                                                rows_out               => l_rows_out);
                    END IF;
                END IF;
            END LOOP;
        
        END IF;
    
        -- Create referral request
        g_error  := 'Call pk_ref_service.insert_mcdt_referral / ' || l_params;
        g_retval := pk_ref_service.insert_mcdt_referral(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_ext_req                   => i_ext_req,
                                                        i_workflow                  => l_id_wf,
                                                        i_flg_priority_home         => i_flg_priority_home,
                                                        i_mcdt                      => l_mcdt,
                                                        i_id_patient                => i_patient,
                                                        i_req_type                  => i_req_type,
                                                        i_flg_type                  => pk_ref_constant.g_p1_type_a,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => i_detail,
                                                        i_diagnosis                 => i_req_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => i_id_tasks,
                                                        i_id_info                   => i_id_info,
                                                        i_epis                      => i_episode,
                                                        i_date                      => NULL,
                                                        i_codification              => i_codification(1),
                                                        i_flg_laterality            => NULL,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_consent                   => i_consent,
                                                        i_health_plan               => i_health_plan,
                                                        i_exemption                 => i_exemption,
                                                        i_reason                    => i_reason,
                                                        i_complementary_information => i_complementary_information,
                                                        i_id_fam_rel                => i_id_fam_rel,
                                                        i_fam_rel_spec              => i_fam_rel_spec,
                                                        i_name_first_rel            => i_name_first_rel,
                                                        i_name_middle_rel           => i_name_middle_rel,
                                                        i_name_last_rel             => i_name_last_rel,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg                       => o_msg,
                                                        o_msg_title                 => o_msg_title,
                                                        o_button                    => o_button,
                                                        o_ext_req                   => o_id_external_request,
                                                        o_error                     => o_error);
    
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_LAB_TEST_ORDER_INTERNAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_lab_test_order_internal;

    /**
    * Creates exams order and creates/updates referral request
    *
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @param i_dt_begin               Array of dates of the exam to be performed
    * @param i_exam                   Array of exam identifiers
    * @param i_exam_req               Array of exam order identifiers
    * @param i_exam_req_det           Array of exam order details identifiers
    * @param i_flg_type               Array of types of the exam
    * @param i_dt_order               Array of dates of the exam order (co-sign)
    * @param i_codification           Array of exam codification identifiers
    * @param i_clinical_decision_rule Array of exam clinical decision rule id    
    * @param i_flg_laterality         Array of exam lateralities
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount]
    * @param i_problems               Referral problems identifier info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not
    * @param i_id_task                Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg_req                Message to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title    
    * @param o_exam_req_array         Array of exam orders identifiers related to the referral
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_external_request    Array of referral identifiers created/updated
    * @param o_error                  Error message
    *
    * @value i_flg_type               {*} 'E' - exam {*} 'G' - group of exams
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'I' Image {*} 'E' Exam
    * @value i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *    
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/04/20
    */
    FUNCTION create_exam_order
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN exam_req.id_episode%TYPE,
        i_dt_begin               IN table_varchar, --5
        i_exam                   IN table_number,
        i_exam_req               IN table_number, --exam_req.id_exam_req%TYPE,
        i_exam_req_det           IN table_number,
        i_flg_type               IN table_varchar,
        i_dt_order               IN table_varchar, --10
        i_codification           IN table_number,
        i_clinical_decision_rule IN table_number,
        i_flg_laterality         IN table_varchar DEFAULT NULL,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number, --25
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg_req        OUT VARCHAR2,
        o_msg            OUT VARCHAR2, --30
        o_msg_title      OUT VARCHAR2,
        o_exam_req_array OUT table_number,
        o_button         OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out --35
    ) RETURN BOOLEAN IS
    
        l_exam_id table_varchar := table_varchar();
    
        l_dt_begin               table_varchar := table_varchar();
        l_exam                   table_number := table_number();
        l_exam_req               table_number := table_number();
        l_exam_req_det           table_number := table_number();
        l_flg_type               table_varchar := table_varchar();
        l_dt_order               table_varchar := table_varchar();
        l_codification           table_number := table_number();
        l_clinical_decision_rule table_number := table_number();
        l_flg_laterality         table_varchar := table_varchar();
    
        l_flg_priority_home table_table_varchar := table_table_varchar();
        l_mcdt              table_table_number := table_table_number();
    
        l_detail   table_table_varchar := table_table_varchar();
        l_id_tasks table_table_number := table_table_number();
        l_id_info  table_table_number := table_table_number();
    
        l_exists VARCHAR2(1 CHAR);
    
    BEGIN
    
        FOR i IN 1 .. i_flg_type.count
        LOOP
            IF i_flg_type(i) = 'G'
            THEN
                SELECT e.id_exam
                  BULK COLLECT
                  INTO l_exam_id
                  FROM exam e,
                       exam_egp ee,
                       (SELECT *
                          FROM exam_dep_clin_serv
                         WHERE flg_type = pk_exam_constant.g_exam_can_req
                           AND id_software = i_prof.software
                           AND id_institution = i_prof.institution) edcs
                 WHERE ee.id_exam_group = i_exam(i)
                   AND ee.id_exam = e.id_exam
                   AND e.flg_available = pk_exam_constant.g_available
                   AND e.id_exam = edcs.id_exam;
            END IF;
        END LOOP;
    
        FOR i IN 1 .. i_flg_type.count
        LOOP
            IF i_flg_type(i) = 'G'
            THEN
                l_dt_begin.extend;
                l_dt_begin(l_dt_begin.count) := i_dt_begin(i);
            
                l_exam.extend;
                l_exam(l_exam.count) := i_exam(i);
            
                l_exam_req.extend;
                l_exam_req(l_exam_req.count) := i_exam_req(i);
            
                l_exam_req_det.extend;
                l_exam_req_det(l_exam_req_det.count) := i_exam_req_det(i);
            
                l_flg_type.extend;
                l_flg_type(l_flg_type.count) := i_flg_type(i);
            
                l_dt_order.extend;
                l_dt_order(l_dt_order.count) := i_dt_order(i);
                l_codification.extend;
                l_codification(l_codification.count) := i_codification(i);
                l_clinical_decision_rule.extend;
                l_clinical_decision_rule(l_clinical_decision_rule.count) := i_clinical_decision_rule(i);
                l_flg_laterality.extend;
                l_flg_laterality(l_flg_laterality.count) := i_flg_laterality(i);
            
                l_flg_priority_home.extend;
                l_flg_priority_home(l_flg_priority_home.count) := i_flg_priority_home(i);
            
                l_mcdt.extend;
                l_mcdt(l_mcdt.count) := i_mcdt(i);
            
                IF i_detail IS NOT NULL
                   AND i_detail.count >= i
                THEN
                    l_detail.extend;
                    l_detail(l_detail.count) := i_detail(i);
                END IF;
            
                IF i_id_tasks IS NOT NULL
                   AND i_id_tasks.count >= i
                THEN
                    l_id_tasks.extend;
                    l_id_tasks(l_id_tasks.count) := i_id_tasks(i);
                END IF;
            
                IF i_id_info IS NOT NULL
                   AND i_id_info.count >= i
                THEN
                    l_id_info.extend;
                    l_id_info(l_id_info.count) := i_id_info(i);
                END IF;
            ELSE
                l_exists := pk_alert_constant.g_no;
                FOR j IN 1 .. l_exam_id.count
                LOOP
                    IF l_exam_id(j) = i_exam(i)
                    THEN
                        l_exists := pk_alert_constant.g_yes;
                    END IF;
                END LOOP;
            
                IF l_exists = pk_alert_constant.g_no
                THEN
                    l_dt_begin.extend;
                    l_dt_begin(l_dt_begin.count) := i_dt_begin(i);
                
                    l_exam.extend;
                    l_exam(l_exam.count) := i_exam(i);
                
                    l_exam_req.extend;
                    l_exam_req(l_exam_req.count) := i_exam_req(i);
                
                    l_exam_req_det.extend;
                    l_exam_req_det(l_exam_req_det.count) := i_exam_req_det(i);
                
                    l_flg_type.extend;
                    l_flg_type(l_flg_type.count) := i_flg_type(i);
                
                    l_dt_order.extend;
                    l_dt_order(l_dt_order.count) := i_dt_order(i);
                    l_codification.extend;
                    l_codification(l_codification.count) := i_codification(i);
                    l_clinical_decision_rule.extend;
                    l_clinical_decision_rule(l_clinical_decision_rule.count) := i_clinical_decision_rule(i);
                    l_flg_laterality.extend;
                    l_flg_laterality(l_flg_laterality.count) := i_flg_laterality(i);
                
                    l_flg_priority_home.extend;
                    l_flg_priority_home(l_flg_priority_home.count) := i_flg_priority_home(i);
                
                    l_mcdt.extend;
                    l_mcdt(l_mcdt.count) := i_mcdt(i);
                
                    IF i_detail IS NOT NULL
                       AND i_detail.count >= i
                    THEN
                        l_detail.extend;
                        l_detail(l_detail.count) := i_detail(i);
                    END IF;
                
                    IF i_id_tasks IS NOT NULL
                       AND i_id_tasks.count >= i
                    THEN
                        l_id_tasks.extend;
                        l_id_tasks(l_id_tasks.count) := i_id_tasks(i);
                    END IF;
                
                    IF i_id_info IS NOT NULL
                       AND i_id_info.count >= i
                    THEN
                        l_id_info.extend;
                        l_id_info(l_id_info.count) := i_id_info(i);
                    END IF;
                END IF;
            
            END IF;
        END LOOP;
    
        g_error := 'CALL CREATE_LAB_TEST_ORDER';
        IF NOT pk_p1_ext_sys.create_exam_order_internal(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_patient                   => i_patient,
                                                        i_episode                   => i_episode,
                                                        i_dt_begin                  => l_dt_begin,
                                                        i_exam                      => l_exam,
                                                        i_exam_req                  => l_exam_req,
                                                        i_exam_req_det              => l_exam_req_det,
                                                        i_flg_type                  => l_flg_type,
                                                        i_dt_order                  => l_dt_order,
                                                        i_codification              => l_codification,
                                                        i_clinical_decision_rule    => l_clinical_decision_rule,
                                                        i_flg_laterality            => l_flg_laterality,
                                                        i_reason                    => NULL,
                                                        i_complementary_information => NULL,
                                                        i_ext_req                   => i_ext_req,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_req_type                  => i_req_type,
                                                        i_req_flg_type              => i_req_flg_type,
                                                        i_flg_priority_home         => l_flg_priority_home,
                                                        i_mcdt                      => l_mcdt,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => l_detail,
                                                        i_req_diagnosis             => i_req_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => l_id_tasks,
                                                        i_id_info                   => l_id_info,
                                                        i_ref_completion            => i_ref_completion,
                                                        i_consent                   => i_consent,
                                                        i_health_plan               => NULL,
                                                        i_exemption                 => NULL,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg_req                   => o_msg_req,
                                                        o_msg                       => o_msg,
                                                        o_msg_title                 => o_msg_title,
                                                        o_exam_req_array            => o_exam_req_array,
                                                        o_button                    => o_button,
                                                        o_id_external_request       => o_id_external_request,
                                                        o_error                     => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_EXAM_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_exam_order;

    FUNCTION create_exam_order_internal
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN exam_req.id_episode%TYPE,
        i_dt_begin                  IN table_varchar, --5
        i_exam                      IN table_number,
        i_exam_req                  IN table_number, --exam_req.id_exam_req%TYPE,
        i_exam_req_det              IN table_number,
        i_flg_type                  IN table_varchar,
        i_dt_order                  IN table_varchar, --10
        i_codification              IN table_number,
        i_clinical_decision_rule    IN table_number,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number, --25
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL,
        i_exemption       IN table_number DEFAULT NULL, --30   
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg_req        OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_exam_req_array OUT table_number,
        o_button         OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out --35
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- exam vars
        l_flg_time_value VARCHAR2(5 CHAR);
        -- create new exam vars
        l_new_exam_req_det            table_number := table_number();
        l_new_exam                    table_number := table_number();
        l_new_flg_type                table_varchar := table_varchar();
        l_new_dt_req                  table_varchar := table_varchar();
        l_new_flg_time                table_varchar := table_varchar();
        l_new_dt_begin                table_varchar := table_varchar();
        l_new_dt_begin_limit          table_varchar := table_varchar();
        l_new_episode_destination     table_number := table_number();
        l_new_order_recurrence        table_number := table_number();
        l_new_priority                table_varchar := table_varchar();
        l_new_flg_prn                 table_varchar := table_varchar();
        l_new_notes_prn               table_varchar := table_varchar();
        l_new_flg_fasting             table_varchar := table_varchar();
        l_new_notes                   table_varchar := table_varchar();
        l_new_notes_scheduler         table_varchar := table_varchar();
        l_new_notes_technician        table_varchar := table_varchar();
        l_new_notes_patient           table_varchar := table_varchar();
        l_new_diagnosis_notes         table_varchar := table_varchar();
        l_new_laterality              table_varchar := table_varchar();
        l_new_exec_room               table_number := table_number();
        l_new_exec_institution        table_number := table_number();
        l_new_clinical_purpose        table_number := table_number();
        l_new_codification            table_number := table_number();
        l_new_health_plan             table_number := table_number();
        l_new_exemption               table_number := table_number();
        l_new_prof_order              table_number := table_number();
        l_new_dt_order                table_varchar := table_varchar();
        l_new_order_type              table_number := table_number();
        l_new_clinical_question       table_table_number := table_table_number();
        l_new_response                table_table_varchar := table_table_varchar();
        l_new_clinical_question_notes table_table_varchar := table_table_varchar();
        l_new_clinical_decision_rule  table_number := table_number();
        l_new_task_dependency         table_number := table_number();
        l_new_flg_task_depending      table_varchar := table_varchar();
        l_new_episode_followup_app    table_number := table_number();
        l_new_schedule_followup_app   table_number := table_number();
        l_new_event_followup_app      table_number := table_number();
        -- output
        l_exam_req_det_array table_number := table_number();
        l_exam_req_array     table_number := table_number();
        ------------------
        -- referral vars
        ------------------
        l_mcdt  table_table_number := table_table_number(table_number(NULL, NULL, NULL, NULL, NULL));
        l_id_wf PLS_INTEGER;
    
        l_tbl_id_exam table_number;
        l_tbl_id_erd  table_number;
    
        l_mcdt_aux table_table_number := table_table_number();
    
        l_flg_priority_home table_table_varchar := table_table_varchar();
        l_id_tasks          table_table_number := table_table_number();
        l_id_info           table_table_number := table_table_number();
        l_flg_laterality    table_varchar := table_varchar();
    
        l_id_pat_health_plan p1_external_request.id_pat_health_plan%TYPE;
        l_id_pat_exemption   p1_external_request.id_pat_exemption%TYPE;
        l_rows_out           table_varchar;
    
    BEGIN
        l_params         := 'i_prof=' || pk_utils.to_string(i_prof) || ' pat=' || i_patient || ' epis=' || i_episode ||
                            ' exam=' || i_exam.count || ' e_req=' || i_exam_req.count || ' e_req_det=' ||
                            i_exam_req_det.count || ' cod=' || i_codification.count || ' i_ext_req=' || i_ext_req ||
                            'i_mcdt=' || i_mcdt.count || ' i_dt_modified=' || i_dt_modified || ' i_req_type=' ||
                            i_req_type || ' i_req_flg_type=' || i_req_flg_type || ' i_dt_problem_begin=' ||
                            i_dt_problem_begin || ' i_completed=' || i_completed || ' i_ref_completion=' ||
                            i_ref_completion;
        g_error          := 'Init create_exam_order / ' || l_params;
        o_exam_req_array := table_number();
    
        -- validation of input parameters
        IF i_exam.count != i_exam_req.count
           OR i_exam.count != i_exam_req_det.count
           OR i_exam.count != i_dt_begin.count
           OR i_exam.count != i_flg_type.count
           OR i_exam.count != i_dt_order.count
           OR i_exam.count != i_codification.count
           OR i_exam.count != i_mcdt.count
        THEN
            g_error := 'Invalid input parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- check if i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) = i_exam(i): must be the same
        g_error := 'FOR i IN 1 .. i_mcdt.count / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt) != i_exam(i)
            THEN
                g_error := 'Invalid exam identifier / i_mcdt(' || i || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' ||
                           i_mcdt(i)
                           (pk_ref_constant.g_idx_id_mcdt) || ' i_exam(' || i || ')=' || i_exam(i) || ' / ' || l_params;
                RAISE g_exception;
            END IF;
        END LOOP;
    
        -- getting workflow identifier
        g_error  := 'i_ref_completion=' || i_ref_completion || ' / ' || l_params;
        g_retval := get_workflow_external(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ref_completion => i_ref_completion,
                                          o_id_workflow    => l_id_wf,
                                          o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' l_id_wf=' || l_id_wf;
    
        -- check if is a valid codification
        g_error  := 'Calling check_codification_count / ' || l_params;
        g_retval := check_codification_count(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_mcdt         => i_exam,
                                             i_codification => i_codification,
                                             o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting flg_time value
        g_error  := 'Call get_flg_time / ' || l_params;
        g_retval := get_flg_time(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_flg_type   => i_req_flg_type,
                                 i_id_episode => i_episode,
                                 o_flg_time   => l_flg_time_value,
                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'l_mcdt := i_mcdt / ' || l_params;
        l_mcdt  := i_mcdt;
    
        -- Important note:        
        -- for all orders that are new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) = NULL):
        --   -create the exam orders (pk_exams_api_db.create_exam_order)
        --   -associate it to the referral (pk_ref_service.insert_mcdt_referral)
        -- for all exam orders that are NOT new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) IS NOT NULL):
        --   -associate/dissociate it from the referral (pk_ref_service.insert_mcdt_referral)
    
        g_error := 'FOR i IN 1 .. ' || i_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
        
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NULL
            THEN
                -- create new prescription order
            
                -- extend vars
                g_error := 'Extend vars / ID_EXAM=' || i_exam(i) || ' / ' || l_params;
                l_new_exam_req_det.extend;
                l_new_exam.extend;
                l_new_flg_type.extend;
                l_new_dt_req.extend;
                l_new_flg_time.extend;
                l_new_dt_begin.extend;
                l_new_dt_begin_limit.extend;
                l_new_episode_destination.extend;
                l_new_order_recurrence.extend;
                l_new_priority.extend;
                l_new_flg_prn.extend;
                l_new_notes_prn.extend;
                l_new_flg_fasting.extend;
                l_new_notes.extend;
                l_new_notes_scheduler.extend;
                l_new_notes_technician.extend;
                l_new_notes_patient.extend;
                l_new_diagnosis_notes.extend;
                l_new_laterality.extend;
                l_new_exec_room.extend;
                l_new_exec_institution.extend;
                l_new_clinical_purpose.extend;
                l_new_codification.extend;
                l_new_health_plan.extend;
                l_new_exemption.extend;
                l_new_prof_order.extend;
                l_new_dt_order.extend;
                l_new_order_type.extend;
                l_new_clinical_question.extend;
                l_new_response.extend;
                l_new_clinical_question_notes.extend;
                l_new_clinical_decision_rule.extend;
                l_new_task_dependency.extend;
                l_new_flg_task_depending.extend;
                l_new_episode_followup_app.extend;
                l_new_schedule_followup_app.extend;
                l_new_event_followup_app.extend;
            
                -- set vars
                g_error := 'Set vars / ID_EXAM=' || i_exam(i) || ' / ' || l_params;
                l_new_exam_req_det(l_new_exam_req_det.last) := i_exam_req_det(i);
                l_new_exam(l_new_exam.last) := i_exam(i);
                l_new_flg_type(l_new_flg_type.last) := i_flg_type(i);
                l_new_dt_req(l_new_dt_req.last) := NULL;
                l_new_flg_time(l_new_flg_time.last) := l_flg_time_value;
                l_new_dt_begin(l_new_dt_begin.last) := i_dt_begin(i);
                l_new_dt_begin_limit(l_new_dt_begin_limit.last) := NULL;
                l_new_episode_destination(l_new_episode_destination.last) := NULL;
                l_new_order_recurrence(l_new_order_recurrence.last) := NULL;
                l_new_priority(l_new_priority.last) := NULL;
                l_new_flg_prn(l_new_flg_prn.last) := NULL;
                l_new_notes_prn(l_new_notes_prn.last) := NULL;
                l_new_flg_fasting(l_new_flg_fasting.last) := NULL;
                l_new_notes(l_new_notes.last) := NULL;
                l_new_notes_scheduler(l_new_notes_scheduler.last) := NULL;
                l_new_notes_technician(l_new_notes_technician.last) := NULL;
                l_new_notes_patient(l_new_notes_patient.last) := NULL;
                l_new_diagnosis_notes(l_new_diagnosis_notes.last) := NULL;
                l_new_laterality(l_new_laterality.last) := i_flg_laterality(i);
                l_new_exec_room(l_new_exec_room.last) := NULL;
                l_new_exec_institution(l_new_exec_institution.last) := i_mcdt(i)
                                                                       (pk_ref_constant.g_idx_id_inst_dest_mcdt);
                l_new_clinical_purpose(l_new_clinical_purpose.last) := NULL;
                l_new_codification(l_new_codification.last) := i_codification(i);
                IF i_health_plan.exists(i)
                THEN
                    l_new_health_plan(l_new_health_plan.last) := i_health_plan(i);
                ELSE
                    l_new_health_plan(l_new_health_plan.last) := NULL;
                END IF;
                IF i_exemption.exists(i)
                THEN
                    l_new_exemption(l_new_exemption.last) := i_exemption(i);
                ELSE
                    l_new_exemption(l_new_exemption.last) := NULL;
                END IF;
                l_new_prof_order(l_new_prof_order.last) := i_prof.id;
                l_new_dt_order(l_new_dt_order.last) := i_dt_order(i);
                l_new_order_type(l_new_order_type.last) := NULL;
                l_new_clinical_question(l_new_clinical_question.last) := table_number();
                l_new_response(l_new_response.last) := table_varchar();
                l_new_clinical_question_notes(l_new_clinical_question_notes.last) := table_varchar();
                l_new_clinical_decision_rule(l_new_clinical_decision_rule.last) := i_clinical_decision_rule(i);
                l_new_task_dependency(l_new_task_dependency.last) := NULL;
                l_new_flg_task_depending(l_new_flg_task_depending.last) := NULL;
                l_new_episode_followup_app(l_new_episode_followup_app.last) := NULL;
                l_new_schedule_followup_app(l_new_schedule_followup_app.last) := NULL;
                l_new_event_followup_app(l_new_event_followup_app.last) := NULL;
            END IF;
        END LOOP;
    
        ------------------------------------------
        -- create new exams
        IF l_new_exam.count > 0
        THEN
        
            -- Creating exams prescriptions
            g_error  := 'Call pk_exams_api_db.create_exam_order / ' || l_params;
            g_retval := pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_patient                 => i_patient,
                                                          i_episode                 => i_episode,
                                                          i_exam_req                => NULL, -- new order id
                                                          i_exam_req_det            => l_new_exam_req_det,
                                                          i_exam                    => l_new_exam,
                                                          i_flg_type                => l_new_flg_type,
                                                          i_dt_req                  => l_new_dt_req,
                                                          i_flg_time                => l_new_flg_time,
                                                          i_dt_begin                => l_new_dt_begin,
                                                          i_dt_begin_limit          => l_new_dt_begin_limit,
                                                          i_episode_destination     => l_new_episode_destination,
                                                          i_order_recurrence        => l_new_order_recurrence,
                                                          i_priority                => l_new_priority,
                                                          i_flg_prn                 => l_new_flg_prn,
                                                          i_notes_prn               => l_new_notes_prn,
                                                          i_flg_fasting             => l_new_flg_fasting,
                                                          i_notes                   => l_new_notes,
                                                          i_notes_scheduler         => l_new_notes_scheduler,
                                                          i_notes_technician        => l_new_notes_technician,
                                                          i_notes_patient           => l_new_notes_patient,
                                                          i_diagnosis_notes         => l_new_diagnosis_notes,
                                                          i_diagnosis               => NULL,
                                                          i_laterality              => l_new_laterality,
                                                          i_exec_room               => l_new_exec_room,
                                                          i_exec_institution        => l_new_exec_institution,
                                                          i_clinical_purpose        => l_new_clinical_purpose,
                                                          i_codification            => l_new_codification,
                                                          i_health_plan             => l_new_health_plan,
                                                          i_exemption               => l_new_exemption,
                                                          i_prof_order              => l_new_prof_order,
                                                          i_dt_order                => l_new_dt_order,
                                                          i_order_type              => l_new_order_type,
                                                          i_clinical_question       => l_new_clinical_question,
                                                          i_response                => l_new_response,
                                                          i_clinical_question_notes => l_new_clinical_question_notes,
                                                          i_clinical_decision_rule  => l_new_clinical_decision_rule,
                                                          i_flg_origin_req          => 'R',
                                                          i_task_dependency         => l_new_task_dependency,
                                                          i_flg_task_depending      => l_new_flg_task_depending,
                                                          i_episode_followup_app    => l_new_episode_followup_app,
                                                          i_schedule_followup_app   => l_new_schedule_followup_app,
                                                          i_event_followup_app      => l_new_event_followup_app,
                                                          i_test                    => pk_ref_constant.g_no,
                                                          o_flg_show                => o_flg_show,
                                                          o_msg_title               => o_msg_title,
                                                          o_msg_req                 => o_msg_req,
                                                          o_button                  => o_button,
                                                          o_exam_req_array          => l_exam_req_array,
                                                          o_exam_req_det_array      => l_exam_req_det_array,
                                                          o_error                   => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            FOR z IN 1 .. i_flg_type.count
            LOOP
            
                IF i_flg_type(z) = 'E'
                THEN
                    l_mcdt_aux.extend;
                
                    SELECT erd.id_exam_req_det
                      BULK COLLECT
                      INTO l_tbl_id_erd
                      FROM exam_req_det erd
                     INNER JOIN exam_req er
                        ON er.id_exam_req = erd.id_exam_req
                     WHERE erd.id_exam_req_det IN (SELECT t.column_value
                                                     FROM TABLE(l_exam_req_det_array) t)
                       AND er.id_exam_group IS NULL
                       AND erd.id_exam = i_mcdt(z) (1);
                
                    l_mcdt_aux(l_mcdt_aux.count) := table_number(i_mcdt(z) (1),
                                                                 l_tbl_id_erd(1),
                                                                 i_mcdt(z) (3),
                                                                 i_mcdt(z) (4));
                
                    IF i_flg_priority_home IS NOT NULL
                       AND i_flg_priority_home.count >= z
                    THEN
                        l_flg_priority_home.extend;
                        l_flg_priority_home(l_flg_priority_home.count) := i_flg_priority_home(z);
                    END IF;
                
                    IF i_id_tasks IS NOT NULL
                       AND i_id_tasks.count >= z
                    THEN
                    
                        l_id_tasks.extend;
                        l_id_tasks(l_id_tasks.count) := i_id_tasks(z);
                    END IF;
                    IF i_id_info IS NOT NULL
                       AND i_id_info.count >= z
                    THEN
                    
                        l_id_info.extend;
                        l_id_info(l_id_info.count) := i_id_info(z);
                    END IF;
                    IF i_flg_laterality IS NOT NULL
                       AND i_flg_laterality.count >= z
                    THEN
                    
                        l_flg_laterality.extend;
                        l_flg_laterality(l_flg_laterality.count) := i_flg_laterality(z);
                    END IF;
                
                ELSE
                
                    SELECT erd.id_exam, erd.id_exam_req_det
                      BULK COLLECT
                      INTO l_tbl_id_exam, l_tbl_id_erd
                      FROM exam_req_det erd
                     INNER JOIN exam_req er
                        ON er.id_exam_req = erd.id_exam_req
                     WHERE erd.id_exam_req_det IN (SELECT t.column_value
                                                     FROM TABLE(l_exam_req_det_array) t)
                       AND er.id_exam_group = i_mcdt(z) (1);
                
                    FOR j IN 1 .. l_tbl_id_exam.count
                    LOOP
                    
                        l_mcdt_aux.extend;
                        l_mcdt_aux(l_mcdt_aux.count) := table_number(l_tbl_id_exam(j),
                                                                     l_tbl_id_erd(j),
                                                                     i_mcdt(z) (3),
                                                                     i_mcdt(z) (4),
                                                                     NULL);
                    
                        IF i_flg_priority_home IS NOT NULL
                           AND i_flg_priority_home.count >= z
                        THEN
                            l_flg_priority_home.extend;
                            l_flg_priority_home(l_flg_priority_home.count) := i_flg_priority_home(z);
                        END IF;
                    
                        IF i_id_tasks IS NOT NULL
                           AND i_id_tasks.count >= z
                        THEN
                        
                            l_id_tasks.extend;
                            l_id_tasks(l_id_tasks.count) := i_id_tasks(z);
                        END IF;
                        IF i_id_info IS NOT NULL
                           AND i_id_info.count >= z
                        THEN
                        
                            l_id_info.extend;
                            l_id_info(l_id_info.count) := i_id_info(z);
                        END IF;
                        IF i_flg_laterality IS NOT NULL
                           AND i_flg_laterality.count >= z
                        THEN
                        
                            l_flg_laterality.extend;
                            l_flg_laterality(l_flg_laterality.count) := i_flg_laterality(z);
                        END IF;
                    
                    END LOOP;
                
                END IF;
            
            END LOOP;
        
            l_mcdt := l_mcdt_aux;
        
            -- fill in the exam_req_det in l_mcdt(i)(pk_ref_constant.g_idx_id_req_det) position
            <<mcdt_loop>>
            FOR h IN 1 .. l_mcdt.count
            LOOP
            
                g_error := '[BEG]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h) (pk_ref_constant.g_idx_amount);
                pk_alertlog.log_debug(g_error);
            
                IF l_mcdt(h) (pk_ref_constant.g_idx_id_req_det) IS NULL
                THEN
                
                    <<exam_loop>>
                    FOR c IN 1 .. l_new_exam.count
                    LOOP
                        IF l_new_exam(c) = l_mcdt(h) (pk_ref_constant.g_idx_id_mcdt)
                        THEN
                            l_mcdt(h)(pk_ref_constant.g_idx_id_req_det) := l_exam_req_det_array(c);
                        END IF;
                    END LOOP exam_loop;
                END IF;
            
                g_error := '[END]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h) (pk_ref_constant.g_idx_amount);
                pk_alertlog.log_debug(g_error);
            
            END LOOP mcdt_loop;
        ELSIF i_ext_req IS NULL
              AND i_exam_req_det.count > 0
        THEN
            FOR i IN i_exam_req_det.first .. i_exam_req_det.last
            LOOP
                SELECT erd.id_pat_health_plan, erd.id_pat_exemption
                  INTO l_id_pat_health_plan, l_id_pat_exemption
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req_det = i_exam_req_det(i);
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_exam_req_det.upd(id_exam_req_det_in     => i_exam_req_det(i),
                                            id_pat_health_plan_in  => i_health_plan(i),
                                            id_pat_health_plan_nin => FALSE,
                                            id_pat_exemption_in    => i_exemption(i),
                                            id_pat_exemption_nin   => FALSE,
                                            handle_error_in        => TRUE,
                                            rows_out               => l_rows_out);
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        -- Create referral request    
        g_error  := 'Call pk_ref_service.insert_mcdt_referral / ' || l_params;
        g_retval := pk_ref_service.insert_mcdt_referral(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_ext_req                   => i_ext_req,
                                                        i_workflow                  => l_id_wf,
                                                        i_flg_priority_home         => CASE
                                                                                           WHEN l_flg_priority_home.count = 0 THEN
                                                                                            i_flg_priority_home
                                                                                           ELSE
                                                                                            l_flg_priority_home
                                                                                       END,
                                                        i_mcdt                      => l_mcdt,
                                                        i_id_patient                => i_patient,
                                                        i_req_type                  => i_req_type,
                                                        i_flg_type                  => i_req_flg_type,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => i_detail,
                                                        i_diagnosis                 => i_req_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => CASE
                                                                                           WHEN l_id_tasks.count = 0 THEN
                                                                                            i_id_tasks
                                                                                           ELSE
                                                                                            l_id_tasks
                                                                                       END,
                                                        i_id_info                   => CASE
                                                                                           WHEN l_id_info.count = 0 THEN
                                                                                            i_id_info
                                                                                           ELSE
                                                                                            l_id_info
                                                                                       END,
                                                        i_epis                      => i_episode,
                                                        i_date                      => NULL,
                                                        i_codification              => i_codification(1),
                                                        i_flg_laterality            => CASE
                                                                                           WHEN l_flg_laterality.count = 0 THEN
                                                                                            i_flg_laterality
                                                                                           ELSE
                                                                                            l_flg_laterality
                                                                                       END,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_consent                   => i_consent,
                                                        i_health_plan               => i_health_plan,
                                                        i_exemption                 => i_exemption,
                                                        i_reason                    => i_reason,
                                                        i_complementary_information => i_complementary_information,
                                                        i_id_fam_rel                => i_id_fam_rel,
                                                        i_fam_rel_spec              => i_fam_rel_spec,
                                                        i_name_first_rel            => i_name_first_rel,
                                                        i_name_middle_rel           => i_name_middle_rel,
                                                        i_name_last_rel             => i_name_last_rel,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg                       => o_msg,
                                                        o_msg_title                 => o_msg_title,
                                                        o_button                    => o_button,
                                                        o_ext_req                   => o_id_external_request,
                                                        o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- update o_exam_req_array with the identifiers
        o_exam_req_array.extend(l_mcdt.count);
        g_error := 'FOR i IN 1 .. ' || l_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. l_mcdt.count
        LOOP
            o_exam_req_array(i) := l_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_EXAM_ORDER_INTERNAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_exam_order_internal;

    /**
    * Creates a new prescription for one or more procedures and creates/updates the referral request
    *    
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_episode                Episode identifier
    * @param i_patient                Patient identifier    
    * @param i_intervention           Array of procedures identifiers (ID_INTERVENTION)
    * @param i_interv_type            Array of procedure type    
    * @param i_interval               Array of interval between executions
    * @param i_num_take               Array of number of executions
    * @param i_dt_begin               Array of start dates
    * @param i_dt_end                 Array of end dates
    * @param i_notes                  Array of prescription notes
    * @param i_diagnosis              Array of array of diagnoses
    * @param i_prof_order             Array of professionals who ordered the procedures
    * @param i_dt_order               Array of order dates
    * @param i_test                   Test for recent prescriptions of the same procedure(s)
    * @param i_codification           Array of prescription codification identifiers
    * @param i_flg_laterality         Array of prescription lateralities
    * @param i_id_cdr_call            Rule event identifier
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount]
    * @param i_problems               Referral problems identifier info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not
    * @param i_id_task                Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_interv_presc_det    Array of prescription identifiers
    * @param o_id_external_request    Array of referral identifiers created/updated
    * @param o_error                  Error message
    *
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'P' Procedure
    * @value i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *    
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Tércio Soares - JTS
    * @version                        0.1
    * @since                          2008/08/20
    */
    FUNCTION create_interv_presc
    (
        i_lang                   IN language.id_language%TYPE, --1 
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_intervention           IN table_number, --5
        i_dt_begin               IN table_varchar,
        i_dt_order               IN table_varchar,
        i_codification           IN table_number,
        i_flg_laterality         IN table_varchar DEFAULT NULL,
        i_clinical_decision_rule IN table_number, --10
        -- Referral parameters    
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'P'
        i_flg_priority_home IN table_table_varchar, --15
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar, --20
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number, --25
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        -- End of referral parameters
        o_flg_show            OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_id_interv_presc_det OUT table_number, --30
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL CREATE_LAB_TEST_ORDER';
        IF NOT pk_p1_ext_sys.create_interv_presc_internal(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_id_episode                => i_id_episode,
                                                          i_id_patient                => i_id_patient,
                                                          i_intervention              => i_intervention,
                                                          i_dt_begin                  => i_dt_begin,
                                                          i_dt_order                  => i_dt_order,
                                                          i_codification              => i_codification,
                                                          i_flg_laterality            => i_flg_laterality,
                                                          i_clinical_decision_rule    => i_clinical_decision_rule,
                                                          i_reason                    => NULL,
                                                          i_ext_req                   => i_ext_req,
                                                          i_dt_modified               => i_dt_modified,
                                                          i_req_type                  => i_req_type,
                                                          i_req_flg_type              => i_req_flg_type,
                                                          i_flg_priority_home         => i_flg_priority_home,
                                                          i_mcdt                      => i_mcdt,
                                                          i_problems                  => i_problems,
                                                          i_dt_problem_begin          => i_dt_problem_begin,
                                                          i_detail                    => i_detail,
                                                          i_req_diagnosis             => i_req_diagnosis,
                                                          i_completed                 => i_completed,
                                                          i_id_tasks                  => i_id_tasks,
                                                          i_id_info                   => i_id_info,
                                                          i_ref_completion            => i_ref_completion,
                                                          i_consent                   => i_consent,
                                                          i_health_plan               => NULL,
                                                          i_exemption                 => NULL,
                                                          i_complementary_information => NULL,
                                                          o_flg_show                  => o_flg_show,
                                                          o_msg_req                   => o_msg_req,
                                                          o_msg_title                 => o_msg_title,
                                                          o_id_interv_presc_det       => o_id_interv_presc_det,
                                                          o_id_external_request       => o_id_external_request,
                                                          o_error                     => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_INTERV_PRESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_interv_presc;

    FUNCTION create_interv_presc_internal
    (
        i_lang                      IN language.id_language%TYPE, --1 
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_patient                IN patient.id_patient%TYPE,
        i_intervention              IN table_number, --5
        i_dt_begin                  IN table_varchar,
        i_dt_order                  IN table_varchar,
        i_codification              IN table_number,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_clinical_decision_rule    IN table_number, --10
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters    
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'P'
        i_flg_priority_home IN table_table_varchar, --15
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar, --20
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number, --25
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL,
        i_exemption       IN table_number DEFAULT NULL,
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show            OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_id_interv_presc_det OUT table_number, --30
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- procedure vars
        l_flg_time_value VARCHAR2(5 CHAR);
        -- create new procedure vars
        l_new_intervention            table_number := table_number();
        l_new_flg_time                table_varchar := table_varchar();
        l_new_dt_begin                table_varchar := table_varchar();
        l_new_episode_destination     table_number := table_number();
        l_new_order_recurrence        table_number := table_number();
        l_new_priority                table_varchar := table_varchar();
        l_new_flg_prn                 table_varchar := table_varchar();
        l_new_notes_prn               table_varchar := table_varchar();
        l_new_notes                   table_varchar := table_varchar();
        l_new_laterality              table_varchar := table_varchar();
        l_new_exec_institution        table_number := table_number();
        l_new_supply                  table_table_number := table_table_number();
        l_new_supply_set              table_table_number := table_table_number();
        l_new_supply_qty              table_table_number := table_table_number();
        l_new_dt_return               table_table_varchar := table_table_varchar();
        l_new_not_order_reason        table_number := table_number();
        l_new_clinical_purpose        table_number := table_number();
        l_new_clinical_purpose_notes  table_varchar := table_varchar();
        l_new_codification            table_number := table_number();
        l_new_health_plan             table_number := table_number();
        l_new_exemption               table_number := table_number();
        l_new_prof_order              table_number := table_number();
        l_new_dt_order                table_varchar := table_varchar();
        l_new_order_type              table_number := table_number();
        l_new_clinical_question       table_table_number := table_table_number();
        l_new_response                table_table_varchar := table_table_varchar();
        l_new_clinical_question_notes table_table_varchar := table_table_varchar();
        l_new_clinical_decision_rule  table_number := table_number();
        -- output
        l_interv_presc_det_array table_number := table_number();
        l_interv_presc_array     table_number := table_number();
        -- referral vars
        l_mcdt  table_table_number := table_table_number(table_number(NULL, NULL, NULL, NULL, NULL));
        l_id_wf PLS_INTEGER;
    
        l_button VARCHAR2(1000 CHAR);
    
        l_id_pat_health_plan p1_external_request.id_pat_health_plan%TYPE;
        l_id_pat_exemption   p1_external_request.id_pat_exemption%TYPE;
        l_rows_out           table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' pat=' || i_id_patient || ' epis=' || i_id_episode ||
                    ' interv=' || i_intervention.count || ' cod=' || i_codification.count || ' i_flg_lat=' ||
                    i_flg_laterality.count || ' i_ext_req=' || i_ext_req || 'i_mcdt=' || i_mcdt.count ||
                    ' i_dt_modified=' || i_dt_modified || ' i_req_type=' || i_req_type || ' i_req_flg_type=' ||
                    i_req_flg_type || ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed ||
                    ' i_ref_completion=' || i_ref_completion;
        g_error  := 'Init create_interv_presc_internal / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_id_interv_presc_det := table_number();
        o_id_interv_presc_det.extend(i_intervention.count);
    
        -- validation of input parameters
        IF i_intervention.count != i_codification.count
           OR i_intervention.count != i_flg_laterality.count
           OR i_intervention.count != i_mcdt.count
        THEN
            g_error := 'Invalid input parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- check if i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) = i_intervention(i): must be the same
        g_error := 'FOR i IN 1 .. i_mcdt.count / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt) != i_intervention(i)
            THEN
                g_error := 'Invalid intervention identifier / i_mcdt(' || i || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' ||
                           i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt) || ' i_intervention(' || i || ')=' ||
                           i_intervention(i) || ' / ' || l_params;
                RAISE g_exception;
            END IF;
        END LOOP;
    
        -- getting workflow identifier
        g_error  := 'i_ref_completion=' || i_ref_completion || ' / ' || l_params;
        g_retval := get_workflow_external(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ref_completion => i_ref_completion,
                                          o_id_workflow    => l_id_wf,
                                          o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' l_id_wf=' || l_id_wf;
    
        -- check if is a valid codification
        g_error  := 'Calling check_codification_count / ' || l_params;
        g_retval := check_codification_count(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_mcdt         => i_intervention,
                                             i_codification => i_codification,
                                             o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting flg_time value - ALERT-263095
        g_error  := 'Call get_flg_time / ' || l_params;
        g_retval := get_flg_time(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_flg_type   => pk_ref_constant.g_p1_type_p,
                                 i_id_episode => i_id_episode,
                                 o_flg_time   => l_flg_time_value,
                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'l_mcdt := i_mcdt / ' || l_params;
        l_mcdt  := i_mcdt;
    
        -- Important note:        
        -- for all prescriptions that are new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) = NULL):
        --   -create the prescription (pk_procedures_core.create_procedure_order)
        --   -associate it to the referral (pk_ref_service.insert_mcdt_referral)
        -- for all prescriptions that are NOT new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) IS NOT NULL):
        --   -associate/dissociate it from the referral (pk_ref_service.insert_mcdt_referral)
    
        g_error := 'FOR i IN 1 .. ' || i_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NULL
            THEN
                -- create new prescription order
            
                -- extend vars
                g_error := 'Extend vars / ID_INTERVENTION=' || i_intervention(i) || ' / ' || l_params;
                l_new_intervention.extend;
                l_new_flg_time.extend;
                l_new_dt_begin.extend;
                l_new_episode_destination.extend;
                l_new_order_recurrence.extend;
                l_new_priority.extend;
                l_new_flg_prn.extend;
                l_new_notes_prn.extend;
                l_new_notes.extend;
                l_new_laterality.extend;
                l_new_exec_institution.extend;
                l_new_supply.extend;
                l_new_supply_set.extend;
                l_new_supply_qty.extend;
                l_new_dt_return.extend;
                l_new_not_order_reason.extend;
                l_new_clinical_purpose.extend;
                l_new_clinical_purpose_notes.extend;
                l_new_codification.extend;
                l_new_health_plan.extend;
                l_new_exemption.extend;
                l_new_prof_order.extend;
                l_new_dt_order.extend;
                l_new_order_type.extend;
                l_new_clinical_question.extend;
                l_new_response.extend;
                l_new_clinical_question_notes.extend;
                l_new_clinical_decision_rule.extend;
            
                -- set vars
                g_error := 'Set vars / ID_INTERVENTION=' || i_intervention(i) || ' / ' || l_params;
                l_new_intervention(l_new_intervention.last) := i_intervention(i);
                l_new_flg_time(l_new_flg_time.last) := l_flg_time_value;
                l_new_dt_begin(l_new_dt_begin.last) := i_dt_begin(i);
                l_new_episode_destination(l_new_episode_destination.last) := NULL;
                l_new_order_recurrence(l_new_order_recurrence.last) := NULL;
                l_new_priority(l_new_priority.last) := NULL;
                l_new_flg_prn(l_new_flg_prn.last) := NULL;
                l_new_notes_prn(l_new_notes_prn.last) := NULL;
                l_new_notes(l_new_notes.last) := NULL;
                l_new_laterality(l_new_laterality.last) := i_flg_laterality(i);
                l_new_exec_institution(l_new_exec_institution.last) := i_mcdt(i)
                                                                       (pk_ref_constant.g_idx_id_inst_dest_mcdt);
                l_new_supply(l_new_supply.last) := table_number();
                l_new_supply_set(l_new_supply_set.last) := table_number();
                l_new_supply_qty(l_new_supply_qty.last) := table_number();
                l_new_dt_return(l_new_dt_return.last) := table_varchar();
                l_new_not_order_reason(l_new_not_order_reason.last) := NULL;
                l_new_clinical_purpose(l_new_clinical_purpose.last) := NULL;
                l_new_clinical_purpose_notes(l_new_clinical_purpose_notes.last) := NULL;
                l_new_codification(l_new_codification.last) := i_codification(i);
                IF i_health_plan.exists(i)
                THEN
                    l_new_health_plan(l_new_health_plan.last) := i_health_plan(i);
                ELSE
                    l_new_health_plan(l_new_health_plan.last) := NULL;
                END IF;
                IF i_exemption.exists(i)
                THEN
                    l_new_exemption(l_new_exemption.last) := i_exemption(i);
                ELSE
                    l_new_exemption(l_new_exemption.last) := NULL;
                END IF;
                l_new_prof_order(l_new_prof_order.last) := i_prof.id;
                l_new_dt_order(l_new_dt_order.last) := i_dt_order(i);
                l_new_order_type(l_new_order_type.last) := NULL;
                l_new_clinical_question(l_new_clinical_question.last) := table_number();
                l_new_response(l_new_response.last) := table_varchar();
                l_new_clinical_question_notes(l_new_clinical_question_notes.last) := table_varchar();
                --l_new_clinical_decision_rule(l_new_clinical_decision_rule.last) := i_clinical_decision_rule(i);
            END IF;
        END LOOP;
    
        ------------------------------------------
        -- create new prescription orders
        IF l_new_intervention.count > 0
        THEN
            -- Creating procedures prescriptions
            g_error  := 'Calling pk_procedures_api_db.create_procedure_order / ' || l_params;
            g_retval := pk_procedures_api_db.create_procedure_order(i_lang                    => i_lang,
                                                                    i_prof                    => i_prof,
                                                                    i_patient                 => i_id_patient,
                                                                    i_episode                 => i_id_episode,
                                                                    i_intervention            => l_new_intervention,
                                                                    i_flg_time                => l_new_flg_time,
                                                                    i_dt_begin                => l_new_dt_begin,
                                                                    i_episode_destination     => l_new_episode_destination,
                                                                    i_order_recurrence        => l_new_order_recurrence,
                                                                    i_diagnosis               => NULL,
                                                                    i_clinical_purpose        => l_new_clinical_purpose,
                                                                    i_clinical_purpose_notes  => l_new_clinical_purpose_notes,
                                                                    i_laterality              => l_new_laterality,
                                                                    i_priority                => l_new_priority,
                                                                    i_flg_prn                 => l_new_flg_prn,
                                                                    i_notes_prn               => l_new_notes_prn,
                                                                    i_exec_institution        => l_new_exec_institution,
                                                                    i_supply                  => l_new_supply,
                                                                    i_supply_set              => l_new_supply_set,
                                                                    i_supply_qty              => l_new_supply_qty,
                                                                    i_dt_return               => l_new_dt_return,
                                                                    i_not_order_reason        => l_new_not_order_reason,
                                                                    i_notes                   => l_new_notes,
                                                                    i_prof_order              => l_new_prof_order,
                                                                    i_dt_order                => l_new_dt_order,
                                                                    i_order_type              => l_new_order_type,
                                                                    i_codification            => l_new_codification,
                                                                    i_health_plan             => l_new_health_plan,
                                                                    i_exemption               => l_new_exemption,
                                                                    i_clinical_question       => l_new_clinical_question,
                                                                    i_response                => l_new_response,
                                                                    i_clinical_question_notes => l_new_clinical_question_notes,
                                                                    i_clinical_decision_rule  => l_new_clinical_decision_rule,
                                                                    i_flg_origin_req          => 'R',
                                                                    i_test                    => pk_ref_constant.g_no,
                                                                    o_flg_show                => o_flg_show,
                                                                    o_msg_title               => o_msg_title,
                                                                    o_msg_req                 => o_msg_req,
                                                                    o_interv_presc_array      => l_interv_presc_array,
                                                                    o_interv_presc_det_array  => l_interv_presc_det_array,
                                                                    o_error                   => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- fill in the l_id_interv_presc_det in l_mcdt(i)(pk_ref_constant.g_idx_id_req_det) position
            <<mcdt_loop>>
            FOR h IN 1 .. l_mcdt.count
            LOOP
                g_error := '[BEG]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h) (pk_ref_constant.g_idx_amount);
                pk_alertlog.log_debug(g_error);
            
                /*JFA : if the requisition detail id is null on the l_mcdt var, 
                        the i_intervention var should be checked on the relevant position 
                        (i_intervention(c) = l_mcdt(h) (1))
                        and on the l_id_interv_presc_det the requistion detail id for the 
                        exam we are checking should be assigned to the missing entry of
                        l_mcdt                
                */
                IF l_mcdt(h) (pk_ref_constant.g_idx_id_req_det) IS NULL
                THEN
                    <<interv_loop>>
                    FOR c IN 1 .. l_new_intervention.count
                    LOOP
                        IF l_new_intervention(c) = l_mcdt(h) (pk_ref_constant.g_idx_id_mcdt)
                        THEN
                            l_mcdt(h)(pk_ref_constant.g_idx_id_req_det) := l_interv_presc_det_array(c);
                        END IF;
                    END LOOP interv_loop;
                END IF;
            
                g_error := '[END]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h) (pk_ref_constant.g_idx_amount);
                pk_alertlog.log_debug(g_error);
            
            END LOOP mcdt_loop;
        ELSIF i_ext_req IS NULL
              AND l_mcdt.count > 0
        THEN
            FOR i IN l_mcdt.first .. l_mcdt.last
            LOOP
                SELECT ipd.id_pat_health_plan, ipd.id_pat_exemption
                  INTO l_id_pat_health_plan, l_id_pat_exemption
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det = l_mcdt(i) (2);
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_interv_presc_det.upd(id_interv_presc_det_in => l_mcdt(i) (2),
                                                id_pat_health_plan_in  => i_health_plan(i),
                                                id_pat_health_plan_nin => FALSE,
                                                id_pat_exemption_in    => i_exemption(i),
                                                id_pat_exemption_nin   => FALSE,
                                                handle_error_in        => TRUE,
                                                rows_out               => l_rows_out);
                    END IF;
                END IF;
            END LOOP;
        END IF;
        -- Create referral request    
        g_error  := 'Call pk_ref_service.insert_mcdt_referral / ' || l_params;
        g_retval := pk_ref_service.insert_mcdt_referral(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_ext_req                   => i_ext_req,
                                                        i_workflow                  => l_id_wf,
                                                        i_flg_priority_home         => i_flg_priority_home,
                                                        i_mcdt                      => l_mcdt,
                                                        i_id_patient                => i_id_patient,
                                                        i_req_type                  => i_req_type,
                                                        i_flg_type                  => pk_ref_constant.g_p1_type_p,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => i_detail,
                                                        i_diagnosis                 => i_req_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => i_id_tasks,
                                                        i_id_info                   => i_id_info,
                                                        i_epis                      => i_id_episode,
                                                        i_date                      => NULL,
                                                        i_codification              => i_codification(1),
                                                        i_flg_laterality            => i_flg_laterality,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_consent                   => i_consent,
                                                        i_health_plan               => i_health_plan,
                                                        i_exemption                 => i_exemption,
                                                        i_reason                    => i_reason,
                                                        i_complementary_information => i_complementary_information,
                                                        i_id_fam_rel                => i_id_fam_rel,
                                                        i_fam_rel_spec              => i_fam_rel_spec,
                                                        i_name_first_rel            => i_name_first_rel,
                                                        i_name_middle_rel           => i_name_middle_rel,
                                                        i_name_last_rel             => i_name_last_rel,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg                       => o_msg_req,
                                                        o_msg_title                 => o_msg_title,
                                                        o_button                    => l_button,
                                                        o_ext_req                   => o_id_external_request,
                                                        o_error                     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- update o_id_interv_presc_det with the identifiers
        g_error := 'FOR i IN 1 .. ' || l_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. l_mcdt.count
        LOOP
            o_id_interv_presc_det(i) := l_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_INTERV_PRESC_INTERNAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_interv_presc_internal;

    /**
    * Creates a new prescription for one or more procedures and creates/updates tge referral request
    *    
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_rehab_area_interv   Array of intervention identifiers
    * @param i_id_rehab_sch_need      Array of intervention schedule needs
    * @param i_exec_per_session       Array of number of executions per treeatment
    * @param i_presc_notes            Array of treatment notes
    * @param i_sessions               Array of sessions
    * @param i_frequency              Array of frequencies
    * @param i_flg_frequency          Array of frequency units
    * @param i_flg_priority           Array of priorities
    * @param i_date_begin             Array of begin date
    * @param i_session_notes          Array of session notes
    * @param i_session_type           Array of session types
    * @param i_codification           Array of intervention codification identifiers
    * @param i_flg_laterality         Array of intervention lateralities        
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount]
    * @param i_problems               Referral problems identifier info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not
    * @param i_id_tasks               Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_rehab_presc         Array of rehab orders identifiers related to the referral
    * @param o_id_external_request    Array of referral identifiers created/updated
    * @param o_error                  Error message
    *
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'F' MFR
    * @param i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2008/10/08
    */
    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_rehab_area_interv IN table_number, -- 5
        i_id_rehab_sch_need    IN table_number,
        i_exec_per_session     IN table_number,
        i_presc_notes          IN table_varchar,
        i_sessions             IN table_number,
        i_frequency            IN table_number, -- 10
        i_flg_frequency        IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_date_begin           IN table_varchar,
        i_session_notes        IN table_varchar,
        i_session_type         IN table_varchar, -- 15
        i_codification         IN table_number,
        i_flg_laterality       IN table_varchar DEFAULT NULL,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE, -- 20
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, -- 25
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2, -- 30
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2, --35
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_id_rehab_presc OUT table_number,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL CREATE_REHAB_PRESC_INTERNAL';
        IF NOT pk_p1_ext_sys.create_rehab_presc_internal(i_lang                      => i_lang,
                                                         i_prof                      => i_prof,
                                                         i_id_patient                => i_id_patient,
                                                         i_id_episode                => i_id_episode,
                                                         i_id_rehab_area_interv      => i_id_rehab_area_interv,
                                                         i_id_rehab_sch_need         => i_id_rehab_sch_need,
                                                         i_exec_per_session          => i_exec_per_session,
                                                         i_presc_notes               => i_presc_notes,
                                                         i_sessions                  => i_sessions,
                                                         i_frequency                 => i_frequency,
                                                         i_flg_frequency             => i_flg_frequency,
                                                         i_flg_priority              => i_flg_priority,
                                                         i_reason                    => NULL,
                                                         i_complementary_information => NULL,
                                                         i_date_begin                => i_date_begin,
                                                         i_session_notes             => i_session_notes,
                                                         i_session_type              => i_session_type,
                                                         i_codification              => i_codification,
                                                         i_flg_laterality            => i_flg_laterality,
                                                         i_ext_req                   => i_ext_req,
                                                         i_dt_modified               => i_dt_modified,
                                                         i_req_type                  => i_req_type,
                                                         i_req_flg_type              => i_req_flg_type,
                                                         i_flg_priority_home         => i_flg_priority_home,
                                                         i_mcdt                      => i_mcdt,
                                                         i_problems                  => i_problems,
                                                         i_dt_problem_begin          => i_dt_problem_begin,
                                                         i_detail                    => i_detail,
                                                         i_req_diagnosis             => i_req_diagnosis,
                                                         i_completed                 => i_completed,
                                                         i_id_tasks                  => i_id_tasks,
                                                         i_id_info                   => i_id_info,
                                                         i_ref_completion            => i_ref_completion,
                                                         i_consent                   => i_consent,
                                                         o_flg_show                  => o_flg_show,
                                                         o_msg                       => o_msg,
                                                         o_msg_title                 => o_msg_title,
                                                         o_button                    => o_button,
                                                         o_id_rehab_presc            => o_id_rehab_presc,
                                                         o_id_external_request       => o_id_external_request,
                                                         o_error                     => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_REHAB_PRESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_rehab_presc;

    FUNCTION create_rehab_presc_internal
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_patient                IN patient.id_patient%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_rehab_area_interv      IN table_number, -- 5
        i_id_rehab_sch_need         IN table_number,
        i_exec_per_session          IN table_number,
        i_presc_notes               IN table_varchar,
        i_sessions                  IN table_number,
        i_frequency                 IN table_number, -- 10
        i_flg_frequency             IN table_varchar,
        i_flg_priority              IN table_varchar,
        i_date_begin                IN table_varchar,
        i_session_notes             IN table_varchar,
        i_session_type              IN table_varchar, -- 15
        i_codification              IN table_number,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE, -- 20
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, -- 25
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2, -- 30
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL, --35
        i_exemption       IN table_number DEFAULT NULL,
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2, --40
        o_button         OUT VARCHAR2,
        o_id_rehab_presc OUT table_number,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        -- rehab vars
        l_sessions         table_number := table_number();
        l_exec_institution table_number := table_number();
        l_id_intervention  table_number := table_number();
        l_id_rehab_presc   table_number := table_number();
        -- create new rehab vars
        l_new_id_rehab_area_interv table_number := table_number();
        l_new_id_rehab_sch_need    table_number := table_number();
        l_new_exec_per_session     table_number := table_number();
        l_new_presc_notes          table_varchar := table_varchar();
        l_new_sessions             table_number := table_number();
        l_new_frequency            table_number := table_number();
        l_new_flg_frequency        table_varchar := table_varchar();
        l_new_flg_priority         table_varchar := table_varchar();
        l_new_date_begin           table_varchar := table_varchar();
        l_new_session_notes        table_varchar := table_varchar();
        l_new_session_type         table_varchar := table_varchar();
        l_new_codification         table_number := table_number();
        l_new_flg_laterality       table_varchar := table_varchar();
        l_new_mcdt_codification    table_number := table_number();
        l_new_id_intervention      table_number := table_number();
        l_new_exec_institution     table_number := table_number();
        l_new_id_health_plan       table_number := table_number();
        l_new_id_exemption         table_number := table_number();
        -- referral vars
        l_mcdt table_table_number := table_table_number(table_number(NULL, NULL, NULL, NULL, NULL));
    
        l_idx   PLS_INTEGER := 0;
        l_id_wf PLS_INTEGER;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' pat=' || i_id_patient || ' epis=' || i_id_episode ||
                    ' rehab_area_i=' || i_id_rehab_area_interv.count || ' rehab_sch_need=' || i_id_rehab_sch_need.count ||
                    ' i_session_type=' || i_session_type.count || ' cod=' || i_codification.count || ' i_flg_lat=' ||
                    i_flg_laterality.count || ' i_ext_req=' || i_ext_req || 'i_mcdt=' || i_mcdt.count ||
                    ' i_dt_modified=' || i_dt_modified || ' i_req_type=' || i_req_type || ' i_req_flg_type=' ||
                    i_req_flg_type || ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed ||
                    ' i_ref_completion=' || i_ref_completion;
        g_error  := 'Init create_rehab_presc_internal / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_id_rehab_presc := table_number();
        o_id_rehab_presc.extend(i_id_rehab_area_interv.count);
    
        -- validation of input parameters
        IF i_id_rehab_area_interv.count != i_id_rehab_sch_need.count
           OR i_id_rehab_area_interv.count != i_exec_per_session.count
           OR i_id_rehab_area_interv.count != i_presc_notes.count
           OR i_id_rehab_area_interv.count != i_session_type.count
           OR i_id_rehab_area_interv.count != i_codification.count
           OR i_id_rehab_area_interv.count != i_mcdt.count
        THEN
            g_error := 'Invalid input parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- getting workflow identifier
        g_error  := 'i_ref_completion=' || i_ref_completion || ' / ' || l_params;
        g_retval := get_workflow_external(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ref_completion => i_ref_completion,
                                          o_id_workflow    => l_id_wf,
                                          o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' l_id_wf=' || l_id_wf;
    
        -- i_mcdt(1) = id_mcdt = id_intervention
        -- i_mcdt(2) = id_mcdt_req_det = id_rehab_presc
        -- i_mcdt(3) = id_institution_dest
        -- i_mcdt(4) = amount        
    
        g_error := 'Getting id_intervention from i_mcdt / ' || l_params;
        l_id_intervention.extend(i_mcdt.count);
        l_exec_institution.extend(i_mcdt.count);
        l_sessions.extend(i_mcdt.count);
    
        FOR i IN 1 .. i_mcdt.count
        LOOP
            l_idx := l_idx + 1;
            l_id_intervention(l_idx) := i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt); -- id_intervention
            l_exec_institution(i) := i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt); -- id_inst_dest           
            l_sessions(i) := i_mcdt(i) (pk_ref_constant.g_idx_amount); -- amount/ NUM SESSIONS            
        END LOOP;
    
        -- check if is a valid codification
        g_error  := 'Call check_codification_count / l_id_intervention.count=' || l_id_intervention.count || ' / ' ||
                    l_params;
        g_retval := check_codification_count(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_mcdt         => l_id_intervention,
                                             i_codification => i_codification,
                                             o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'l_mcdt := i_mcdt / ' || l_params;
        l_mcdt  := i_mcdt;
    
        -- Important note:        
        -- for all prescriptions that are new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) = NULL):
        --   -create the prescription (pk_rehab.create_rehab_presc)
        --   -associate it to the referral (pk_ref_service.insert_mcdt_referral)
        -- for all prescriptions that are NOT new (i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) IS NOT NULL):
        --   -associate/dissociate it from the referral (pk_ref_service.insert_mcdt_referral)
    
        g_error := 'FOR i IN 1 .. ' || i_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NULL
            THEN
                -- create new prescription order
            
                -- extend vars
                g_error := 'Extend vars / ID_INTERVENTION=' || l_id_intervention(i) || ' / ' || l_params;
                l_new_id_intervention.extend;
                l_new_id_rehab_area_interv.extend;
                l_new_id_rehab_sch_need.extend;
                l_new_exec_per_session.extend;
                l_new_presc_notes.extend;
                l_new_sessions.extend;
                l_new_frequency.extend;
                l_new_flg_frequency.extend;
                l_new_flg_priority.extend;
                l_new_date_begin.extend;
                l_new_session_notes.extend;
                l_new_session_type.extend;
                l_new_codification.extend;
                l_new_flg_laterality.extend;
                l_new_mcdt_codification.extend;
                l_new_exec_institution.extend;
                l_new_id_health_plan.extend();
                l_new_id_exemption.extend();
            
                -- set vars    
                g_error := 'Set vars / ID_INTERVENTION=' || l_id_intervention(i) || ' / ' || l_params;
                l_new_id_intervention(l_new_id_intervention.last) := l_id_intervention(i);
                l_new_id_rehab_area_interv(l_new_id_rehab_area_interv.last) := i_id_rehab_area_interv(i);
                l_new_id_rehab_sch_need(l_new_id_rehab_sch_need.last) := i_id_rehab_sch_need(i);
                l_new_exec_per_session(l_new_exec_per_session.last) := i_exec_per_session(i);
                l_new_presc_notes(l_new_presc_notes.last) := i_presc_notes(i);
                l_new_sessions(l_new_sessions.last) := l_sessions(i);
                l_new_frequency(l_new_frequency.last) := i_frequency(i);
                l_new_flg_frequency(l_new_flg_frequency.last) := i_flg_frequency(i);
                l_new_flg_priority(l_new_flg_priority.last) := i_flg_priority(i);
                l_new_date_begin(l_new_date_begin.last) := i_date_begin(i);
                l_new_session_notes(l_new_session_notes.last) := i_session_notes(i);
                l_new_session_type(l_new_session_type.last) := i_session_type(i);
                l_new_codification(l_new_codification.last) := i_codification(i);
                l_new_flg_laterality(l_new_flg_laterality.last) := i_flg_laterality(i);
                l_new_exec_institution(l_new_exec_institution.last) := l_exec_institution(i);
                IF i_health_plan.exists(i)
                THEN
                    l_new_id_health_plan(l_new_id_health_plan.count) := i_health_plan(i);
                ELSE
                    l_new_id_health_plan(l_new_id_health_plan.count) := NULL;
                END IF;
                IF i_exemption.exists(i)
                THEN
                    l_new_id_exemption(l_new_id_exemption.count) := i_exemption(i);
                ELSE
                    l_new_id_exemption(l_new_id_exemption.count) := NULL;
                END IF;
            
            END IF;
        END LOOP;
    
        ------------------------------------------
        -- create new prescription orders
        IF l_new_id_rehab_area_interv.count > 0
        THEN
        
            -- converting i_codification into l_new_mcdt_codification
            g_error  := 'Calling get_mcdt_codification / ' || l_params;
            g_retval := get_mcdt_codification(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_mcdt              => l_new_id_intervention,
                                              i_codification      => l_new_codification,
                                              i_flg_type          => pk_ref_constant.g_p1_type_f, -- MFR
                                              o_mcdt_codification => l_new_mcdt_codification,
                                              o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'l_new_mcdt_codification.count=' || l_new_mcdt_codification.count;
            IF l_new_mcdt_codification.count = pk_ref_constant.g_zero
            THEN
                l_new_mcdt_codification.extend(l_new_id_intervention.count);
            END IF;
        
            -- create new rehab prescription
            g_error  := 'Call pk_rehab.create_rehab_presc_internal / ' || l_params;
            g_retval := pk_rehab.create_rehab_presc_internal(i_lang                 => i_lang,
                                                             i_prof                 => i_prof,
                                                             i_id_patient           => i_id_patient,
                                                             i_id_episode           => i_id_episode,
                                                             i_id_rehab_area_interv => l_new_id_rehab_area_interv,
                                                             i_id_rehab_sch_need    => l_new_id_rehab_sch_need,
                                                             i_id_exec_institution  => l_new_exec_institution,
                                                             i_exec_per_session     => l_new_exec_per_session,
                                                             i_presc_notes          => l_new_presc_notes,
                                                             i_sessions             => l_new_sessions,
                                                             i_frequency            => l_new_frequency,
                                                             i_flg_frequency        => l_new_flg_frequency,
                                                             i_flg_priority         => l_new_flg_priority,
                                                             i_flg_laterality       => l_new_flg_laterality,
                                                             i_date_begin           => l_new_date_begin,
                                                             i_session_notes        => l_new_session_notes,
                                                             i_session_type         => l_new_session_type,
                                                             i_id_codification      => l_new_mcdt_codification,
                                                             i_id_pat_health_plan   => l_new_id_health_plan,
                                                             i_id_pat_exemption     => l_new_id_exemption,
                                                             o_id_rehab_presc       => l_id_rehab_presc,
                                                             o_error                => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- fill in the l_id_rehab_presc in l_mcdt(i)(pk_ref_constant.g_idx_id_req_det) position
            <<mcdt_loop>>
            FOR h IN 1 .. l_mcdt.count
            LOOP
                g_error := '[BEG]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h) (pk_ref_constant.g_idx_amount);
                pk_alertlog.log_debug(g_error);
            
                IF l_mcdt(h) (pk_ref_constant.g_idx_id_req_det) IS NULL
                THEN
                    <<rehab_loop>>
                    FOR c IN 1 .. l_new_id_intervention.count
                    LOOP
                        IF l_new_id_intervention(c) = l_mcdt(h) (pk_ref_constant.g_idx_id_mcdt)
                        THEN
                            l_mcdt(h)(pk_ref_constant.g_idx_id_req_det) := l_id_rehab_presc(c);
                        END IF;
                    END LOOP rehab_loop;
                
                END IF;
                g_error := '[END]: l_mcdt(' || h || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_req_det || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_req_det) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_id_inst_dest_mcdt || ')=' || l_mcdt(h)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || '|l_mcdt(' || h || ')(' ||
                           pk_ref_constant.g_idx_amount || ')=' || l_mcdt(h) (pk_ref_constant.g_idx_amount);
                pk_alertlog.log_debug(g_error);
            
            END LOOP mcdt_loop;
        
        END IF;
    
        -- Create referral request
        g_error  := 'Call pk_ref_service.insert_mcdt_referral i_workflow=' || l_id_wf;
        g_retval := pk_ref_service.insert_mcdt_referral(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_ext_req                   => i_ext_req,
                                                        i_workflow                  => l_id_wf,
                                                        i_flg_priority_home         => i_flg_priority_home,
                                                        i_mcdt                      => l_mcdt,
                                                        i_id_patient                => i_id_patient,
                                                        i_req_type                  => i_req_type,
                                                        i_flg_type                  => pk_ref_constant.g_p1_type_f,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => i_detail,
                                                        i_diagnosis                 => i_req_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => i_id_tasks,
                                                        i_id_info                   => i_id_info,
                                                        i_epis                      => i_id_episode,
                                                        i_date                      => NULL,
                                                        i_codification              => i_codification(1),
                                                        i_flg_laterality            => i_flg_laterality,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_consent                   => i_consent,
                                                        i_health_plan               => i_health_plan,
                                                        i_exemption                 => i_exemption,
                                                        i_reason                    => i_reason,
                                                        i_complementary_information => i_complementary_information,
                                                        i_id_fam_rel                => i_id_fam_rel,
                                                        i_fam_rel_spec              => i_fam_rel_spec,
                                                        i_name_first_rel            => i_name_first_rel,
                                                        i_name_middle_rel           => i_name_middle_rel,
                                                        i_name_last_rel             => i_name_last_rel,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg                       => o_msg,
                                                        o_msg_title                 => o_msg_title,
                                                        o_button                    => o_button,
                                                        o_ext_req                   => o_id_external_request,
                                                        o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- update o_id_rehab_presc with the identifiers
        g_error := 'FOR i IN 1 .. ' || l_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. l_mcdt.count
        LOOP
            o_id_rehab_presc(i) := l_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REHAB_PRESC_INTERNAL',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_rehab_presc_internal;

    /** @headcom
    * Public Function. Returns type of form to be used for printing the referral.
    * If the health plan in use is "SNS" then return the SYS_CONFIG value for id REFERRAL_FULL_FORM.
    * Otherwise returns (B)lank form.
    *
    * @param      i_lang         professional language
    * @param      i_prof         professional id, institution and software
    * @param      i_pat          patient id
    * @param      o_format       B - "Blank page"; Y - Generate complete referral form; N - Print on top of referral form
    * @param      o_error        error message
    *
    * @return     boolean
    * @author     Joao Sa
    * @version    1.0
    * @since      2008/09/17
    * @modified
    */
    FUNCTION get_referral_form_format
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_pat    IN patient.id_patient%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        o_format OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_blank IS
            SELECT 1
              FROM pat_health_plan php
              JOIN health_plan hp
                ON (php.id_health_plan = hp.id_health_plan)
             WHERE php.id_patient = i_pat
               AND php.id_institution = i_prof.institution
               AND hp.flg_type = 'S' -- SNS
               AND php.flg_default = pk_ref_constant.g_yes;
    
    BEGIN
        -- If the default health plan is SNS then return SYS_CONFIG (REFERRAL_FULL_FORM)
        OPEN c_blank;
        FETCH c_blank
            INTO o_format;
        g_found := c_blank%FOUND;
        CLOSE c_blank;
    
        IF g_found
        THEN
            SELECT pk_sysconfig.get_config('REFERRAL_FULL_FORM', i_prof)
              INTO o_format
              FROM dual;
        ELSE
            o_format := 'B'; -- Blank Form
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := 'Configuration error: SYS_CONFIG Parameter REFERRAL_FULL_FORM not found';
            BEGIN
                l_error_in.set_all(i_lang,
                                   'REFERRAL_FULL_FORM not found',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_REFERRAL_FORM_FORMAT',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_FORM_FORMAT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_form_format;

    FUNCTION get_mcdts_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_desc_type IN VARCHAR2
    ) RETURN CLOB
    
     IS
        l_ret               CLOB;
        l_ref_type          p1_external_request.flg_type%TYPE;
        l_title             sys_message.desc_message%TYPE;
        l_just              p1_detail.text%TYPE;
        l_nutrition_content VARCHAR2(200 CHAR) := 'TMP166.2654';
        l_spec              p1_speciality.id_content%TYPE;
    BEGIN
    
        SELECT flg_type,
               (SELECT id_content
                  FROM p1_speciality s
                 WHERE s.id_speciality = p.id_speciality)
          INTO l_ref_type, l_spec
          FROM p1_external_request p
         WHERE p.id_external_request = i_ext_req;
    
        IF l_ref_type = pk_ref_constant.g_p1_type_c
        THEN
        
            SELECT decode(p.id_inst_dest,
                          NULL,
                          NULL,
                          decode(p.id_dep_clin_serv,
                                 NULL,
                                 pk_translation.get_translation(i_lang,
                                                                pk_ref_constant.g_p1_speciality_code || p.id_speciality),
                                 pk_translation.get_translation(i_lang,
                                                                pk_ref_constant.g_clinical_service_code ||
                                                                dcs.id_clinical_service))) clin_srv_name
              INTO l_ret
              FROM p1_external_request p
              LEFT JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = p.id_dep_clin_serv
             WHERE p.id_external_request = i_ext_req;
        ELSIF l_ref_type = pk_ref_constant.g_p1_type_a
        THEN
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_analysis) AS table_varchar), ' <br> ')
              INTO l_ret
              FROM (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                     i_prof                      => i_prof,
                                                                     i_flg_type                  => pk_ref_constant.g_p1_type_a,
                                                                     i_analysis_code_translation => a.code_analysis,
                                                                     i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                    pa.id_sample_type,
                                                                     i_dep_clin_serv             => NULL) desc_analysis
                    
                      FROM p1_external_request p
                      JOIN p1_exr_temp pa
                        ON p.id_external_request = pa.id_external_request
                      JOIN analysis a
                        ON pa.id_analysis = a.id_analysis
                     WHERE p.id_external_request = i_ext_req) t;
        
        ELSIF l_ref_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i)
        THEN
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_exam) AS table_varchar), ' <br> ')
              INTO l_ret
              FROM (SELECT pk_translation.get_translation(i_lang, e.code_exam) desc_exam
                      FROM p1_exr_temp pe
                      JOIN p1_external_request p
                        ON (p.id_external_request = pe.id_external_request)
                      JOIN exam e
                        ON pe.id_exam = e.id_exam
                     WHERE p.id_external_request = i_ext_req) t;
        ELSIF l_ref_type = pk_ref_constant.g_p1_type_p
        THEN
        
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_interv) AS table_varchar), ' <br> ')
              INTO l_ret
              FROM (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_interv
                      FROM p1_exr_temp pi
                      JOIN p1_external_request p
                        ON p.id_external_request = pi.id_external_request
                      JOIN intervention i
                        ON pi.id_intervention = i.id_intervention
                     WHERE p.id_external_request = i_ext_req) t;
        ELSIF l_ref_type = pk_ref_constant.g_p1_type_f
        THEN
        
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_rehab) AS table_varchar), ' <br> ')
              INTO l_ret
              FROM (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_rehab
                      FROM p1_exr_temp pi
                      JOIN p1_external_request p
                        ON p.id_external_request = pi.id_external_request
                      JOIN intervention i
                        ON pi.id_intervention = i.id_intervention
                     WHERE p.id_external_request = i_ext_req) t;
        END IF;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_mcdts_description;

    FUNCTION get_sp_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_desc_type IN VARCHAR2
    ) RETURN CLOB
    
     IS
        l_ret               CLOB;
        l_ref_type          p1_external_request.flg_type%TYPE;
        l_title             sys_message.desc_message%TYPE;
        l_just              p1_detail.text%TYPE;
        l_nutrition_content VARCHAR2(200 CHAR) := 'TMP166.2654';
        l_spec              p1_speciality.id_content%TYPE;
    BEGIN
    
        SELECT flg_type,
               (SELECT id_content
                  FROM p1_speciality s
                 WHERE s.id_speciality = p.id_speciality)
          INTO l_ref_type, l_spec
          FROM p1_external_request p
         WHERE p.id_external_request = i_ext_req;
    
        BEGIN
            SELECT text
              INTO l_just
              FROM p1_detail pd
             WHERE pd.id_external_request = i_ext_req
               AND pd.flg_type = pk_ref_constant.g_detail_type_jstf
               AND pd.flg_status = pk_ref_constant.g_detail_status_a;
        EXCEPTION
            WHEN OTHERS THEN
                l_just := NULL;
        END;
    
        IF l_ref_type = pk_ref_constant.g_p1_type_c
        THEN
            IF l_spec = l_nutrition_content
            THEN
                l_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_prog_notes_constants.g_sm_referal_nutrition);
            
            ELSE
                l_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_prog_notes_constants.g_sm_referal_consult);
            END IF;
            SELECT l_title ||
                   decode(p.id_inst_dest,
                          NULL,
                          NULL,
                          decode(p.id_dep_clin_serv,
                                 NULL,
                                 pk_translation.get_translation(i_lang,
                                                                pk_ref_constant.g_p1_speciality_code || p.id_speciality),
                                 pk_translation.get_translation(i_lang,
                                                                pk_ref_constant.g_clinical_service_code ||
                                                                dcs.id_clinical_service))) ||
                   nvl2(l_just, ', ' || l_just, '') clin_srv_name
              INTO l_ret
              FROM p1_external_request p
              LEFT JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = p.id_dep_clin_serv
             WHERE p.id_external_request = i_ext_req;
        ELSIF l_ref_type = pk_ref_constant.g_p1_type_a
        THEN
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_analysis) AS table_varchar), chr(10)) ||
                   nvl2(l_just, ', ' || l_just, '')
              INTO l_ret
              FROM (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                     i_prof                      => i_prof,
                                                                     i_flg_type                  => pk_ref_constant.g_p1_type_a,
                                                                     i_analysis_code_translation => a.code_analysis,
                                                                     i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                    pa.id_sample_type,
                                                                     i_dep_clin_serv             => NULL) desc_analysis
                    
                      FROM p1_external_request p
                      JOIN p1_exr_analysis pa
                        ON p.id_external_request = pa.id_external_request
                      JOIN analysis a
                        ON pa.id_analysis = a.id_analysis
                     WHERE p.id_external_request = i_ext_req) t;
        
        ELSIF l_ref_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i)
        THEN
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_exam) AS table_varchar), chr(10)) ||
                   nvl2(l_just, ', ' || l_just, '')
              INTO l_ret
              FROM (SELECT pk_translation.get_translation(i_lang, e.code_exam) desc_exam
                      FROM p1_exr_temp pe
                      JOIN p1_external_request p
                        ON (p.id_external_request = pe.id_external_request)
                      JOIN exam e
                        ON pe.id_exam = e.id_exam
                     WHERE p.id_external_request = i_ext_req) t;
        ELSIF l_ref_type = pk_ref_constant.g_p1_type_p
        THEN
            l_title := pk_message.get_message(i_lang      => i_lang,
                                              i_code_mess => pk_prog_notes_constants.g_sm_referal_interv);
        
            SELECT l_title || pk_utils.concat_table_l(CAST(COLLECT(t.desc_interv) AS table_varchar), chr(10)) ||
                   nvl2(l_just, ', ' || l_just, '')
              INTO l_ret
              FROM (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_interv
                      FROM p1_exr_intervention pi
                      JOIN p1_external_request p
                        ON p.id_external_request = pi.id_external_request
                      JOIN intervention i
                        ON pi.id_intervention = i.id_intervention
                     WHERE p.id_external_request = i_ext_req) t;
        ELSIF l_ref_type = pk_ref_constant.g_p1_type_f
        THEN
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_prog_notes_constants.g_sm_referal_mfr);
        
            SELECT l_title || pk_utils.concat_table_l(CAST(COLLECT(t.desc_rehab) AS table_varchar), chr(10)) ||
                   nvl2(l_just, ', ' || l_just, '')
              INTO l_ret
              FROM (SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) desc_rehab
                      FROM p1_exr_intervention pi
                      JOIN p1_external_request p
                        ON p.id_external_request = pi.id_external_request
                      JOIN intervention i
                        ON pi.id_intervention = i.id_intervention
                     WHERE p.id_external_request = i_ext_req) t;
        END IF;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sp_description;

    FUNCTION create_p1_request
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_root_name            IN VARCHAR2,
        i_tbl_records          IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_ref_completion       IN ref_completion.id_ref_completion%TYPE,
        i_codification         IN codification.id_codification%TYPE,
        o_id_external_request  OUT table_number,
        o_id_requisition       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin table_varchar := table_varchar();
        l_dt_order table_varchar := table_varchar();
    
        l_tbl_id_prob       table_number := table_number();
        l_tbl_id_alert_prob table_number := table_number();
        l_problems          CLOB;
    
        l_tbl_id_diagnosis       table_number := table_number();
        l_tbl_id_alert_diagnosis table_number := table_number();
        l_diagnosis              CLOB;
    
        l_dt_problem_begin VARCHAR2(100);
    
        l_tbl_detail                    table_table_varchar := table_table_varchar();
        l_tbl_reason                    table_varchar := table_varchar();
        l_tbl_reason_mcdt               table_varchar := table_varchar(); --MCDTS will store the reason info in p1_exr_temp
        l_tbl_notes                     table_varchar := table_varchar();
        l_tbl_symptoms                  table_varchar := table_varchar();
        l_tbl_course                    table_varchar := table_varchar();
        l_tbl_medication                table_varchar := table_varchar();
        l_tbl_vs                        table_varchar := table_varchar();
        l_tbl_personal_history          table_varchar := table_varchar();
        l_tbl_family_history            table_varchar := table_varchar();
        l_tbl_objective_examination     table_varchar := table_varchar();
        l_tbl_mcdt                      table_varchar := table_varchar();
        l_tbl_complementary_information table_varchar := table_varchar();
    
        l_tbl_analysis         table_number;
        l_tbl_sample_type      table_number;
        l_tbl_type             table_varchar := table_varchar(); ----
        l_tbl_analysis_req     table_number := table_number();
        l_tbl_analysis_req_det table_number := table_number();
        l_tbl_analysis_group   table_table_varchar := table_table_varchar();
    
        l_tbl_exam_req     table_number := table_number();
        l_tbl_exam_req_det table_number := table_number();
    
        --This table will hold the ids of the mcdts (id_exam, id_interventions, etc.)
        --when dealing with editions the i_tbl_records will hold transactional ids
        l_tbl_records table_number := table_number();
    
        --Variables used for edition
        l_id_ext_req  NUMBER(24) := NULL;
        l_dt_modified VARCHAR2(100) := NULL;
        l_tbl_req_det table_number := table_number(NULL);
        l_id_detail   p1_detail.id_detail%TYPE;
    
        --Variables for rehab
        l_tbl_session_type       table_varchar := table_varchar();
        l_tbl_rehab_sch_need     table_number := table_number();
        l_tbl_exec_per_session   table_number := table_number();
        l_tbl_presc_notes        table_varchar := table_varchar();
        l_tbl_sessions           table_number := table_number();
        l_tbl_frequency          table_number := table_number();
        l_tbl_flg_frequency      table_varchar := table_varchar();
        l_tbl_flg_priority_rehab table_varchar := table_varchar();
        l_tbl_session_notes      table_varchar := table_varchar();
    
        l_consent VARCHAR2(1);
    
        l_table_mcdt                 table_table_number := table_table_number();
        l_tbl_quantity               table_number := table_number();
        l_tbl_dest_facility          table_number := table_number();
        l_tbl_prof_order             table_number := table_number();
        l_tbl_codification           table_number := table_number();
        l_tbl_clinical_decision_rule table_number := table_number();
    
        l_tbl_flg_laterality    table_varchar := table_varchar();
        l_tbl_flg_priority      table_varchar := table_varchar();
        l_tbl_flg_home          table_varchar := table_varchar();
        l_tbl_flg_priority_home table_table_varchar := table_table_varchar();
    
        l_flg_show             VARCHAR2(1);
        l_msg_req              VARCHAR2(1000);
        l_msg_title            VARCHAR2(1000);
        l_msg                  VARCHAR2(1000);
        l_button               VARCHAR2(1000);
        l_tbl_interv_presc_det table_number;
        l_id_external_request  p1_external_request.id_external_request%TYPE;
    
        l_id_clinical_service p1_speciality.id_speciality%TYPE;
    
        --Health insurance
        l_tbl_health_plan  table_number := table_number();
        l_tbl_exemption    table_number := table_number();
        l_id_pat_exemption pat_isencao.id_pat_isencao%TYPE;
    
        l_id_wf PLS_INTEGER;
    
        l_id_fam_rel   p1_external_request.id_fam_rel%TYPE;
        l_fam_rel_spec VARCHAR2(200);
        l_first_name   VARCHAR2(4000);
        l_middle_name  VARCHAR2(4000);
        l_last_name    VARCHAR2(4000);
    
        l_physician_name    VARCHAR2(4000);
        l_physician_surname VARCHAR2(4000);
        l_physician_phone   VARCHAR2(100);
        l_physician_license VARCHAR2(100);
    
        l_count PLS_INTEGER;
    
        l_flg_origin              VARCHAR2(1);
        l_flg_type                p1_external_request.flg_type%TYPE;
        l_req_type                p1_external_request.req_type%TYPE;
        l_tbl_id_external_request table_number;
    
        l_id_metadata    table_number;
        l_id_req_det     table_number;
        l_id_sample_type table_number;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_tbl_records.count > 0
        THEN
            FOR i IN i_tbl_records.first .. i_tbl_records.last
            LOOP
                l_dt_begin.extend();
                l_dt_order.extend();
            
                l_dt_begin(i) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                             i_date => g_sysdate_tstz,
                                                             i_prof => i_prof);
                l_dt_order(i) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                             i_date => g_sysdate_tstz,
                                                             i_prof => i_prof);
            END LOOP;
        ELSE
            l_dt_begin.extend();
            l_dt_order.extend();
        
            l_dt_begin(1) := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => g_sysdate_tstz, i_prof => i_prof);
            l_dt_order(1) := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => g_sysdate_tstz, i_prof => i_prof);
        END IF;
    
        --Obtain the External id request (it will be null for a new prescription)
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_dummy_number
            THEN
                IF i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_id_ext_req  := to_number(i_tbl_real_val(i) (1));
                    l_dt_modified := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                 i_date => g_sysdate_tstz,
                                                                 i_prof => i_prof);
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_p1_origin_info
            THEN
                l_flg_origin := nvl(i_tbl_real_val(i) (1), pk_p1_ext_sys.g_p1_referrals_origin);
            END IF;
        END LOOP;
    
        --Obtain the id req det if this is an edition
        IF l_id_ext_req IS NOT NULL
        THEN
            SELECT *
              BULK COLLECT
              INTO l_tbl_req_det
              FROM (SELECT pt.id_analysis_req_det id_req
                      FROM p1_exr_temp pt
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pt.id_analysis_req_det
                     WHERE pt.id_external_request = l_id_ext_req
                       AND i_root_name = pk_orders_utils.g_p1_lab_test
                    UNION
                    SELECT pa.id_analysis_req_det id_req
                      FROM p1_exr_analysis pa
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pa.id_analysis_req_det
                     WHERE pa.id_external_request = l_id_ext_req
                       AND i_root_name = pk_orders_utils.g_p1_lab_test
                    UNION
                    SELECT pt.id_interv_presc_det id_req
                      FROM p1_exr_temp pt
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pt.id_interv_presc_det
                     WHERE pt.id_external_request = l_id_ext_req
                       AND i_root_name = pk_orders_utils.g_p1_intervention
                    UNION
                    SELECT pi.id_interv_presc_det id_req
                      FROM p1_exr_intervention pi
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pi.id_interv_presc_det
                     WHERE pi.id_external_request = l_id_ext_req
                       AND i_root_name = pk_orders_utils.g_p1_intervention
                    UNION
                    SELECT pt.id_exam_req_det id_req
                      FROM p1_exr_temp pt
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pt.id_exam_req_det
                     WHERE pt.id_external_request = l_id_ext_req
                       AND i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                    UNION
                    SELECT pe.id_exam_req_det id_req
                      FROM p1_exr_exam pe
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pe.id_exam_req_det
                     WHERE pe.id_external_request = l_id_ext_req
                       AND i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                    UNION
                    SELECT pt.id_rehab_presc id_req
                      FROM p1_exr_temp pt
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pt.id_rehab_presc
                     WHERE pt.id_external_request = l_id_ext_req
                       AND i_root_name = pk_orders_utils.g_p1_rehab
                    UNION
                    SELECT pi.id_rehab_presc id_req
                      FROM p1_exr_intervention pi
                      JOIN TABLE(i_tbl_records) t
                        ON t.column_value = pi.id_rehab_presc
                     WHERE pi.id_external_request = l_id_ext_req
                       AND i_root_name = pk_orders_utils.g_p1_rehab);
        
            IF i_root_name = pk_orders_utils.g_p1_lab_test
            THEN
                SELECT ard.id_analysis, ard.id_sample_type
                  BULK COLLECT
                  INTO l_tbl_analysis, l_tbl_sample_type
                  FROM analysis_req_det ard
                 WHERE ard.id_analysis_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                     FROM TABLE(i_tbl_records) t);
            ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
            THEN
                SELECT erd.id_exam
                  BULK COLLECT
                  INTO l_tbl_records
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                 FROM TABLE(i_tbl_records) t);
            ELSIF i_root_name = pk_orders_utils.g_p1_intervention
            THEN
                SELECT ipd.id_intervention
                  BULK COLLECT
                  INTO l_tbl_records
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                     FROM TABLE(i_tbl_records) t);
            ELSIF i_root_name = pk_orders_utils.g_p1_rehab
            THEN
                SELECT rp.id_rehab_area_interv
                  BULK COLLECT
                  INTO l_tbl_records
                  FROM rehab_presc rp
                 WHERE rp.id_rehab_presc IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                               FROM TABLE(i_tbl_records) t);
            END IF;
        
        ELSIF i_root_name <> pk_orders_utils.g_p1_appointment
        THEN
            IF l_flg_origin = pk_p1_ext_sys.g_p1_orders_origin
            THEN
                l_tbl_req_det := i_tbl_records;
            
                IF i_root_name = pk_orders_utils.g_p1_lab_test
                THEN
                    SELECT ard.id_analysis, ard.id_sample_type
                      BULK COLLECT
                      INTO l_tbl_analysis, l_tbl_sample_type
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                         FROM TABLE(i_tbl_records) t);
                ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                THEN
                    SELECT erd.id_exam, erd.id_exam_req, erd.id_exam_req_det
                      BULK COLLECT
                      INTO l_tbl_records, l_tbl_exam_req, l_tbl_exam_req_det
                      FROM exam_req_det erd
                     WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                     FROM TABLE(i_tbl_records) t);
                ELSIF i_root_name = pk_orders_utils.g_p1_intervention
                THEN
                    SELECT ipd.id_intervention
                      BULK COLLECT
                      INTO l_tbl_records
                      FROM interv_presc_det ipd
                     WHERE ipd.id_interv_presc_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                         FROM TABLE(i_tbl_records) t);
                ELSIF i_root_name = pk_orders_utils.g_p1_rehab
                THEN
                    SELECT rp.id_rehab_area_interv
                      BULK COLLECT
                      INTO l_tbl_records
                      FROM rehab_presc rp
                     WHERE rp.id_rehab_presc IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                   FROM TABLE(i_tbl_records) t);
                END IF;
            ELSE
                --For new requests, l_tbl_req_det must be initialized as null
                FOR i IN i_tbl_records.first .. i_tbl_records.last
                LOOP
                    l_tbl_req_det.extend();
                    l_tbl_req_det(l_tbl_req_det.count) := NULL;
                END LOOP;
            
                IF i_root_name = pk_orders_utils.g_p1_lab_test
                THEN
                    WITH aux AS
                     (SELECT tt.column_value, rownum AS rn
                        FROM TABLE(i_tbl_records) tt)
                    SELECT ais.id_analysis, ais.id_sample_type
                      BULK COLLECT
                      INTO l_tbl_analysis, l_tbl_sample_type
                      FROM analysis_instit_soft ais
                      JOIN aux t
                        ON t.column_value = ais.id_analysis_instit_soft
                     ORDER BY t.rn;ELSE
                    l_tbl_records := i_tbl_records;
                END IF;
            END IF;
        END IF;
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_problems_addressed
            THEN
                l_tbl_id_prob       := table_number();
                l_tbl_id_alert_prob := table_number();
            
                SELECT ad.id_diagnosis, ad.id_alert_diagnosis
                  BULK COLLECT
                  INTO l_tbl_id_prob, l_tbl_id_alert_prob
                  FROM alert_diagnosis ad
                 WHERE ad.id_alert_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  t.*
                                                   FROM TABLE(i_tbl_real_val(i)) t);
            
                IF l_tbl_id_prob.count > 0
                THEN
                    l_problems := '<EPIS_DIAGNOSES ID_PATIENT="' || i_id_patient || '" ID_EPISODE="' || i_id_episode ||
                                  '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
                
                    FOR k IN l_tbl_id_prob.first .. l_tbl_id_prob.last
                    LOOP
                        l_problems := l_problems || ' <DIAGNOSIS ID_DIAGNOSIS="' || l_tbl_id_prob(k) ||
                                      '" ID_ALERT_DIAG="' || l_tbl_id_alert_prob(k) || '">
                                <DESC_DIAGNOSIS>' ||
                                      pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                         i_id_institution  => i_prof.institution,
                                                                         i_id_software     => i_prof.software,
                                                                         i_id_concept_term => l_tbl_id_alert_prob(k),
                                                                         i_concept_type    => 'DIAGNOSIS',
                                                                         i_id_task_type    => pk_alert_constant.g_task_problems) ||
                                      '</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                    END LOOP;
                
                    l_problems := l_problems || ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
                ELSE
                    l_tbl_id_prob.extend();
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_diagnosis
            THEN
                l_tbl_id_diagnosis       := table_number();
                l_tbl_id_alert_diagnosis := table_number();
            
                SELECT ad.id_diagnosis, ad.id_alert_diagnosis
                  BULK COLLECT
                  INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
                  FROM alert_diagnosis ad
                 WHERE ad.id_alert_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  t.*
                                                   FROM TABLE(i_tbl_real_val(i)) t);
            
                IF l_tbl_id_diagnosis.count > 0
                THEN
                    l_diagnosis := '<EPIS_DIAGNOSES ID_PATIENT="' || i_id_patient || '" ID_EPISODE="' || i_id_episode ||
                                   '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
                
                    FOR k IN l_tbl_id_diagnosis.first .. l_tbl_id_diagnosis.last
                    LOOP
                        l_diagnosis := l_diagnosis || ' <DIAGNOSIS ID_DIAGNOSIS="' || l_tbl_id_diagnosis(k) ||
                                       '" ID_ALERT_DIAG="' || l_tbl_id_alert_diagnosis(k) || '">
                                <DESC_DIAGNOSIS>' ||
                                       pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                          i_id_institution  => i_prof.institution,
                                                                          i_id_software     => i_prof.software,
                                                                          i_id_concept_term => l_tbl_id_alert_diagnosis(k),
                                                                          i_concept_type    => 'DIAGNOSIS',
                                                                          i_id_task_type    => pk_alert_constant.g_task_diagnosis) ||
                                       '</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                    END LOOP;
                
                    l_diagnosis := l_diagnosis || ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
                ELSE
                    l_tbl_id_diagnosis.extend();
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_onset
            THEN
                l_dt_problem_begin := substr(i_tbl_real_val(i) (1), 1, 8);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_laterality
            THEN
                l_tbl_flg_laterality := i_tbl_real_val(i);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_p1_home
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_flg_home.extend;
                    l_tbl_flg_home(l_tbl_flg_home.count) := nvl(i_tbl_real_val(i) (j), pk_alert_constant.g_no);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_priority
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_flg_priority.extend;
                    l_tbl_flg_priority(l_tbl_flg_priority.count) := nvl(i_tbl_real_val(i) (j), pk_alert_constant.g_no);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_quantity
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_quantity.extend();
                    l_tbl_quantity(l_tbl_quantity.count) := to_number(i_tbl_real_val(i) (j));
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_destination_facility
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_dest_facility.extend();
                    l_tbl_dest_facility(l_tbl_dest_facility.count) := to_number(i_tbl_real_val(i) (j));
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_clinical_service
            THEN
                l_id_clinical_service := to_number(i_tbl_real_val(i) (1));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_referral_reason
                  AND i_tbl_real_val(i) (1) IS NOT NULL
                  AND i_root_name = pk_orders_utils.g_p1_appointment
            THEN
                l_tbl_reason.extend(5);
            
                l_tbl_reason(1) := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_episode             => i_id_episode,
                                                                    i_id_external_request => l_id_ext_req,
                                                                    i_flg_type            => 0);
                l_tbl_reason(2) := '0';
                l_tbl_reason(3) := i_tbl_real_val(i) (1);
                l_tbl_reason(4) := CASE
                                       WHEN l_id_ext_req IS NULL THEN
                                        'I'
                                       ELSE
                                        'U'
                                   END;
                l_tbl_reason(5) := '1';
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_referral_reason
                  AND i_tbl_real_val(i).exists(1)
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_reason_mcdt.extend();
                    l_tbl_reason_mcdt(l_tbl_reason_mcdt.count) := i_tbl_real_val(i) (j);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_complementary_information
                  AND i_tbl_real_val(i).exists(1)
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_complementary_information.extend();
                    l_tbl_complementary_information(l_tbl_complementary_information.count) := i_tbl_real_val(i) (j);
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_notes
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 17);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_notes.extend(5);
                
                    l_tbl_notes(1) := l_id_detail;
                    l_tbl_notes(2) := '17';
                    l_tbl_notes(3) := i_tbl_real_val(i) (1);
                    l_tbl_notes(4) := CASE
                                          WHEN l_id_detail IS NULL THEN
                                           'I'
                                          WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                           'D'
                                          ELSE
                                           'U'
                                      END;
                    l_tbl_notes(5) := '3';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_symptoms
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 1);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_symptoms.extend(5);
                
                    l_tbl_symptoms(1) := l_id_detail;
                    l_tbl_symptoms(2) := '1';
                    l_tbl_symptoms(3) := i_tbl_real_val(i) (1);
                    l_tbl_symptoms(4) := CASE
                                             WHEN l_id_detail IS NULL THEN
                                              'I'
                                             WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                              'D'
                                             ELSE
                                              'U'
                                         END;
                    l_tbl_symptoms(5) := '3';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_course
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 2);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_course.extend(5);
                
                    l_tbl_course(1) := l_id_detail;
                    l_tbl_course(2) := '2';
                    l_tbl_course(3) := i_tbl_real_val(i) (1);
                    l_tbl_course(4) := CASE
                                           WHEN l_id_detail IS NULL THEN
                                            'I'
                                           WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                            'D'
                                           ELSE
                                            'U'
                                       END;
                    l_tbl_course(5) := '3';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_medication
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 22);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_medication.extend(5);
                
                    l_tbl_medication(1) := l_id_detail;
                    l_tbl_medication(2) := '22';
                    l_tbl_medication(3) := i_tbl_real_val(i) (1);
                    l_tbl_medication(4) := CASE
                                               WHEN l_id_detail IS NULL THEN
                                                'I'
                                               WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                                'D'
                                               ELSE
                                                'U'
                                           END;
                    l_tbl_medication(5) := '3';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_vital_signs
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 43);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_vs.extend(5);
                
                    l_tbl_vs(1) := l_id_detail;
                    l_tbl_vs(2) := '43';
                    l_tbl_vs(3) := i_tbl_real_val(i) (1);
                    l_tbl_vs(4) := CASE
                                       WHEN l_id_detail IS NULL THEN
                                        'I'
                                       WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                        'D'
                                       ELSE
                                        'U'
                                   END;
                    l_tbl_vs(5) := '9';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_personal_history
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 3);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_personal_history.extend(5);
                
                    l_tbl_personal_history(1) := l_id_detail;
                    l_tbl_personal_history(2) := '3';
                    l_tbl_personal_history(3) := i_tbl_real_val(i) (1);
                    l_tbl_personal_history(4) := CASE
                                                     WHEN l_id_detail IS NULL THEN
                                                      'I'
                                                     WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                                      'D'
                                                     ELSE
                                                      'U'
                                                 END;
                    l_tbl_personal_history(5) := '4';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_family_history
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 4);
            
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_family_history.extend(5);
                
                    l_tbl_family_history(1) := l_id_detail;
                    l_tbl_family_history(2) := '4';
                    l_tbl_family_history(3) := i_tbl_real_val(i) (1);
                    l_tbl_family_history(4) := CASE
                                                   WHEN l_id_detail IS NULL THEN
                                                    'I'
                                                   WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                                    'D'
                                                   ELSE
                                                    'U'
                                               END;
                    l_tbl_family_history(5) := '4';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_objective_examination_ft
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 5);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_objective_examination.extend(5);
                
                    l_tbl_objective_examination(1) := l_id_detail;
                    l_tbl_objective_examination(2) := '5';
                    l_tbl_objective_examination(3) := i_tbl_real_val(i) (1);
                    l_tbl_objective_examination(4) := CASE
                                                          WHEN l_id_detail IS NULL THEN
                                                           'I'
                                                          WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                                           'D'
                                                          ELSE
                                                           'U'
                                                      END;
                    l_tbl_objective_examination(5) := '5';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_executed_tests_ft
            THEN
                l_id_detail := pk_orders_utils.get_p1_id_detail(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_episode             => i_id_episode,
                                                                i_id_external_request => l_id_ext_req,
                                                                i_flg_type            => 6);
                IF l_id_detail IS NOT NULL
                   OR i_tbl_real_val(i) (1) IS NOT NULL
                THEN
                    l_tbl_mcdt.extend(5);
                
                    l_tbl_mcdt(1) := l_id_detail;
                    l_tbl_mcdt(2) := '6';
                    l_tbl_mcdt(3) := i_tbl_real_val(i) (1);
                    l_tbl_mcdt(4) := CASE
                                         WHEN l_id_detail IS NULL THEN
                                          'I'
                                         WHEN i_tbl_real_val(i) (1) IS NULL THEN
                                          'D'
                                         ELSE
                                          'U'
                                     END;
                    l_tbl_mcdt(5) := '6';
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_referral_consent
            THEN
                l_consent := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_health_coverage_plan
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_health_plan.extend();
                    l_tbl_health_plan(l_tbl_health_plan.count) := to_number(i_tbl_real_val(i) (j));
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_exemption
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    l_tbl_exemption.extend();
                    l_tbl_exemption(l_tbl_exemption.count) := to_number(i_tbl_real_val(i) (j));
                
                    IF l_tbl_exemption(l_tbl_exemption.count) IS NOT NULL
                    THEN
                        SELECT COUNT(1)
                          INTO l_count
                          FROM pat_isencao pi
                         WHERE pi.id_pat_isencao = l_tbl_exemption(l_tbl_exemption.count);
                    
                        IF l_count = 0
                        THEN
                            IF NOT pk_adt_core.set_pat_isencao(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_patient        => i_id_patient,
                                                               i_id_isencao     => l_tbl_exemption(l_tbl_exemption.count),
                                                               o_id_pat_isencao => l_id_pat_exemption,
                                                               o_error          => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            l_tbl_exemption(l_tbl_exemption.count) := l_id_pat_exemption;
                        END IF;
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_family_relationship
            THEN
                l_id_fam_rel := to_number(i_tbl_real_val(i) (1));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_family_relationship_spec
            THEN
                l_fam_rel_spec := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_lastname
            THEN
                l_last_name := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_middlename
            THEN
                l_middle_name := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_nombres
            THEN
                l_first_name := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_physician_name
            THEN
                l_physician_name := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_physician_surname
            THEN
                l_physician_surname := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_physician_phone
            THEN
                l_physician_phone := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_physician_license
            THEN
                l_physician_license := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
    
        IF l_tbl_flg_home.count > 0
           AND (l_tbl_flg_home.count = l_tbl_flg_priority.count)
        THEN
            FOR i IN l_tbl_flg_home.first .. l_tbl_flg_home.last
            LOOP
                l_tbl_flg_priority_home.extend();
                l_tbl_flg_priority_home(l_tbl_flg_priority_home.count) := table_varchar(l_tbl_flg_priority(i),
                                                                                        l_tbl_flg_home(i));
            END LOOP;
        ELSIF l_tbl_flg_home.count != l_tbl_flg_priority.count
        THEN
            g_error := 'Arrays of flg_priority and flg_home do not have the same size.';
            RAISE g_exception;
        END IF;
    
        g_error := 'Constructing table of mcdts';
        IF i_root_name != pk_orders_utils.g_p1_appointment
        THEN
            IF i_root_name != pk_orders_utils.g_p1_lab_test
            THEN
                FOR i IN l_tbl_records.first .. l_tbl_records.last
                LOOP
                    l_table_mcdt.extend();
                    l_table_mcdt(l_table_mcdt.count) := table_number();
                    l_table_mcdt(l_table_mcdt.count).extend(5);
                
                    IF i_root_name = pk_orders_utils.g_p1_rehab
                    THEN
                        l_tbl_session_type.extend();
                        l_tbl_session_type(l_tbl_session_type.count) := pk_orders_utils.get_rehab_session_type(i_lang              => i_lang,
                                                                                                               i_prof              => i_prof,
                                                                                                               i_rehab_area_interv => l_tbl_records(i));
                    
                        IF l_id_ext_req IS NULL
                        THEN
                            --NEW REQUEST
                            l_tbl_rehab_sch_need.extend();
                            l_tbl_rehab_sch_need(l_tbl_rehab_sch_need.count) := NULL;
                        
                            l_tbl_exec_per_session.extend();
                            l_tbl_exec_per_session(l_tbl_exec_per_session.count) := NULL;
                        
                            l_tbl_presc_notes.extend();
                            l_tbl_presc_notes(l_tbl_presc_notes.count) := NULL;
                        
                            l_tbl_sessions.extend();
                            l_tbl_sessions(l_tbl_sessions.count) := NULL;
                        
                            l_tbl_frequency.extend();
                            l_tbl_frequency(l_tbl_frequency.count) := NULL;
                        
                            l_tbl_flg_frequency.extend();
                            l_tbl_flg_frequency(l_tbl_flg_frequency.count) := NULL;
                        
                            l_tbl_flg_priority_rehab.extend();
                            l_tbl_flg_priority_rehab(l_tbl_flg_priority_rehab.count) := NULL;
                        
                            l_tbl_session_notes.extend();
                            l_tbl_session_notes(l_tbl_session_notes.count) := NULL;
                        
                            SELECT DISTINCT r.id_intervention
                              INTO l_table_mcdt(l_table_mcdt.count)(1)
                              FROM rehab_area_interv r
                             WHERE r.id_rehab_area_interv = l_tbl_records(i);
                        ELSE
                            --EDITION
                            l_tbl_rehab_sch_need.extend();
                            l_tbl_exec_per_session.extend();
                            l_tbl_presc_notes.extend();
                            l_tbl_sessions.extend();
                            l_tbl_frequency.extend();
                            l_tbl_flg_frequency.extend();
                            l_tbl_flg_priority_rehab.extend();
                            l_tbl_session_notes.extend();
                        
                            SELECT rp.id_rehab_sch_need,
                                   rp.exec_per_session,
                                   rp.notes,
                                   rsn.sessions,
                                   rsn.frequency,
                                   rsn.flg_frequency,
                                   rsn.flg_priority,
                                   rsn.notes AS session_notes
                              INTO l_tbl_rehab_sch_need(l_tbl_rehab_sch_need.count),
                                   l_tbl_exec_per_session(l_tbl_exec_per_session.count),
                                   l_tbl_presc_notes(l_tbl_presc_notes.count),
                                   l_tbl_sessions(l_tbl_sessions.count),
                                   l_tbl_frequency(l_tbl_frequency.count),
                                   l_tbl_flg_frequency(l_tbl_flg_frequency.count),
                                   l_tbl_flg_priority_rehab(l_tbl_flg_priority_rehab.count),
                                   l_tbl_session_notes(l_tbl_session_notes.count)
                              FROM rehab_presc rp
                              LEFT JOIN rehab_sch_need rsn
                                ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                             WHERE rp.id_rehab_presc = l_tbl_req_det(i);
                        
                            SELECT DISTINCT r.id_intervention
                              INTO l_table_mcdt(l_table_mcdt.count)(1)
                              FROM rehab_area_interv r
                             WHERE r.id_rehab_area_interv = l_tbl_records(i);
                        END IF;
                    ELSE
                        l_table_mcdt(l_table_mcdt.count)(1) := l_tbl_records(i);
                    END IF;
                
                    l_table_mcdt(l_table_mcdt.count)(2) := l_tbl_req_det(i);
                    l_table_mcdt(l_table_mcdt.count)(3) := l_tbl_dest_facility(i); --DEST FACILITY
                    l_table_mcdt(l_table_mcdt.count)(4) := l_tbl_quantity(i); --QUANTITY
                    l_table_mcdt(l_table_mcdt.count)(5) := NULL; --g_idx_id_sample_type
                
                    l_tbl_codification.extend();
                    l_tbl_codification(l_tbl_codification.count) := i_codification;
                
                    l_tbl_clinical_decision_rule.extend();
                    l_tbl_clinical_decision_rule(l_tbl_clinical_decision_rule.count) := NULL;
                
                    IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                    THEN
                        IF l_flg_origin <> pk_p1_ext_sys.g_p1_orders_origin
                        THEN
                            l_tbl_exam_req.extend();
                            l_tbl_exam_req(l_tbl_exam_req.count) := NULL;
                        
                            l_tbl_exam_req_det.extend();
                            l_tbl_exam_req_det(l_tbl_exam_req_det.count) := NULL;
                        END IF;
                        l_tbl_type.extend();
                        l_tbl_type(l_tbl_type.count) := 'E';
                    END IF;
                END LOOP;
            ELSE
                FOR i IN l_tbl_analysis.first .. l_tbl_analysis.last
                LOOP
                    l_table_mcdt.extend();
                    l_table_mcdt(l_table_mcdt.count) := table_number();
                    l_table_mcdt(l_table_mcdt.count).extend(5);
                    l_table_mcdt(l_table_mcdt.count)(1) := l_tbl_analysis(i);
                    l_table_mcdt(l_table_mcdt.count)(2) := l_tbl_req_det(i); --id_req_det
                    l_table_mcdt(l_table_mcdt.count)(3) := l_tbl_dest_facility(i); --DEST FACILITY
                    l_table_mcdt(l_table_mcdt.count)(4) := l_tbl_quantity(i); --QUANTITY
                    l_table_mcdt(l_table_mcdt.count)(5) := l_tbl_sample_type(i); --g_idx_id_sample_type
                
                    l_tbl_type.extend();
                    l_tbl_type(l_tbl_type.count) := 'A';
                
                    l_tbl_prof_order.extend();
                    l_tbl_prof_order(l_tbl_prof_order.count) := i_prof.id;
                
                    l_tbl_codification.extend();
                    l_tbl_codification(l_tbl_codification.count) := i_codification;
                
                    l_tbl_clinical_decision_rule.extend();
                    l_tbl_clinical_decision_rule(l_tbl_clinical_decision_rule.count) := NULL;
                
                    l_tbl_analysis_req.extend();
                    BEGIN
                        SELECT ard.id_analysis_req
                          INTO l_tbl_analysis_req(l_tbl_analysis_req.count)
                          FROM analysis_req_det ard
                         WHERE ard.id_analysis_req_det = l_tbl_req_det(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_tbl_analysis_req(l_tbl_analysis_req.count) := NULL;
                    END;
                
                    l_tbl_analysis_req_det.extend();
                    l_tbl_analysis_req_det(l_tbl_analysis_req_det.count) := l_tbl_req_det(i);
                
                    --to_do
                    l_tbl_analysis_group .extend();
                    l_tbl_analysis_group(l_tbl_analysis_group.count) := table_varchar('');
                END LOOP;
            END IF;
        END IF;
    
        g_error := 'Constructing table of details';
        IF l_tbl_reason.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_reason;
        END IF;
        IF l_tbl_notes.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_notes;
        END IF;
        IF l_tbl_symptoms.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_symptoms;
        END IF;
        IF l_tbl_course.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_course;
        END IF;
        IF l_tbl_medication.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_medication;
        END IF;
        IF l_tbl_vs.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_vs;
        END IF;
        IF l_tbl_personal_history.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_personal_history;
        END IF;
        IF l_tbl_family_history.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_family_history;
        END IF;
        IF l_tbl_objective_examination.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_objective_examination;
        END IF;
        IF l_tbl_mcdt.exists(1)
        THEN
            l_tbl_detail.extend();
            l_tbl_detail(l_tbl_detail.count) := l_tbl_mcdt;
        END IF;
    
        g_error := 'Creating P1 request';
        IF i_root_name = pk_orders_utils.g_p1_appointment
        THEN
            IF i_ref_completion != pk_ref_constant.g_ref_compl_ge
               OR i_ref_completion IS NULL
            THEN
                l_id_wf := NULL;
            ELSE
                l_id_wf := to_number(nvl(pk_sysconfig.get_config(pk_ref_constant.g_referral_button_wf, i_prof), 0));
            
                IF l_id_wf = 0
                THEN
                    l_id_wf := NULL;
                END IF;
            
            END IF;
            g_error := 'Call pk_ref_service.insert_referral i_workflow=' || l_id_wf || ' i_ref_completion =' ||
                       i_ref_completion;
        
            l_req_type := 'M';
            l_flg_type := 'C';
            IF NOT pk_ref_service.insert_referral(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_ext_req             => l_id_ext_req,
                                             i_dt_modified         => l_dt_modified,
                                             i_id_patient          => i_id_patient,
                                             i_speciality          => l_id_clinical_service,
                                             i_id_dep_clin_serv    => NULL,
                                             i_req_type            => l_req_type,
                                             i_flg_type            => l_flg_type,
                                             i_flg_priority        => l_tbl_flg_priority(1),
                                             i_flg_home            => l_tbl_flg_home(1),
                                             i_inst_orig           => i_prof.id,
                                             i_inst_dest           => l_tbl_dest_facility(1),
                                             i_problems            => l_problems,
                                             i_dt_problem_begin    => l_dt_problem_begin,
                                             i_detail              => l_tbl_detail,
                                             i_diagnosis           => l_diagnosis,
                                             i_completed           => CASE
                                                                          WHEN i_ref_completion = 1 THEN
                                                                           pk_alert_constant.g_yes
                                                                          ELSE
                                                                           pk_alert_constant.g_no
                                                                      END,
                                             i_id_tasks            => table_table_number(),
                                             i_id_info             => table_table_number(),
                                             i_epis                => i_id_episode,
                                             i_workflow            => l_id_wf,
                                             i_num_order           => NULL,
                                             i_prof_name           => NULL,
                                             i_prof_id             => NULL,
                                             i_institution_name    => NULL,
                                             i_external_sys        => NULL,
                                             i_comments            => NULL,
                                             i_prof_cert           => l_physician_license,
                                             i_prof_first_name     => l_physician_name,
                                             i_prof_surname        => l_physician_surname,
                                             i_prof_phone          => l_physician_phone,
                                             i_id_fam_rel          => l_id_fam_rel,
                                             i_fam_rel_spec        => l_fam_rel_spec,
                                             i_name_first_rel      => l_first_name,
                                             i_name_middle_rel     => l_middle_name,
                                             i_name_last_rel       => l_last_name,
                                             i_health_plan         => l_tbl_health_plan(1),
                                             i_exemption           => l_tbl_exemption(1),
                                             o_id_external_request => l_id_external_request,
                                             o_flg_show            => l_flg_show,
                                             o_msg                 => l_msg_req,
                                             o_msg_title           => l_msg_title,
                                             o_button              => l_button,
                                             o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_id_external_request := table_number(l_id_external_request);
            o_id_requisition      := NULL;
        ELSIF i_root_name = pk_orders_utils.g_p1_lab_test
        THEN
        
            l_req_type := 'M';
            l_flg_type := 'A';
            IF NOT create_lab_test_order_internal(i_lang                      => i_lang,
                                                  i_prof                      => i_prof,
                                                  i_patient                   => i_id_patient,
                                                  i_episode                   => i_id_episode,
                                                  i_analysis_req              => l_tbl_analysis_req, --5
                                                  i_analysis_req_det          => l_tbl_analysis_req_det,
                                                  i_dt_begin                  => l_dt_begin,
                                                  i_analysis                  => l_tbl_analysis,
                                                  i_analysis_group            => l_tbl_analysis_group,
                                                  i_flg_type                  => l_tbl_type, --10
                                                  i_prof_order                => l_tbl_prof_order,
                                                  i_codification              => l_tbl_codification,
                                                  i_clinical_decision_rule    => l_tbl_clinical_decision_rule,
                                                  i_reason                    => l_tbl_reason_mcdt,
                                                  i_complementary_information => l_tbl_complementary_information,
                                                  i_ext_req                   => l_id_ext_req,
                                                  i_dt_modified               => l_dt_modified, --15
                                                  i_req_type                  => l_req_type,
                                                  i_req_flg_type              => l_flg_type,
                                                  i_flg_priority_home         => l_tbl_flg_priority_home,
                                                  i_mcdt                      => l_table_mcdt,
                                                  i_problems                  => l_problems, --20
                                                  i_dt_problem_begin          => l_dt_problem_begin,
                                                  i_detail                    => l_tbl_detail,
                                                  i_req_diagnosis             => l_diagnosis,
                                                  i_completed                 => 'N',
                                                  i_id_tasks                  => table_table_number(), --25
                                                  i_id_info                   => table_table_number(),
                                                  i_ref_completion            => i_ref_completion,
                                                  i_consent                   => l_consent,
                                                  i_health_plan               => l_tbl_health_plan,
                                                  i_exemption                 => l_tbl_exemption,
                                                  i_id_fam_rel                => l_id_fam_rel,
                                                  i_fam_rel_spec              => l_fam_rel_spec,
                                                  i_name_first_rel            => l_first_name,
                                                  i_name_middle_rel           => l_middle_name,
                                                  i_name_last_rel             => l_last_name,
                                                  o_flg_show                  => l_flg_show,
                                                  o_msg_req                   => l_msg_req,
                                                  o_msg                       => l_msg,
                                                  o_msg_title                 => l_msg_title,
                                                  o_button                    => l_button,
                                                  o_id_external_request       => l_tbl_id_external_request,
                                                  o_error                     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_id_requisition := NULL;
        
        ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
        THEN
        
            l_req_type := 'M';
            l_flg_type := CASE i_root_name
                              WHEN pk_orders_utils.g_p1_imaging_exam THEN
                               'I'
                              WHEN pk_orders_utils.g_p1_other_exam THEN
                               'E'
                          END;
            IF NOT create_exam_order_internal(i_lang                      => i_lang,
                                              i_prof                      => i_prof,
                                              i_patient                   => i_id_patient,
                                              i_episode                   => i_id_episode,
                                              i_dt_begin                  => l_dt_begin, --5
                                              i_exam                      => l_tbl_records,
                                              i_exam_req                  => l_tbl_exam_req,
                                              i_exam_req_det              => l_tbl_exam_req_det,
                                              i_flg_type                  => l_tbl_type,
                                              i_dt_order                  => l_dt_order, --10
                                              i_codification              => l_tbl_codification,
                                              i_clinical_decision_rule    => l_tbl_clinical_decision_rule,
                                              i_flg_laterality            => l_tbl_flg_laterality,
                                              i_reason                    => l_tbl_reason_mcdt,
                                              i_complementary_information => l_tbl_complementary_information,
                                              i_ext_req                   => l_id_ext_req,
                                              i_dt_modified               => l_dt_modified, --15
                                              i_req_type                  => l_req_type,
                                              i_req_flg_type              => l_flg_type,
                                              i_flg_priority_home         => l_tbl_flg_priority_home,
                                              i_mcdt                      => l_table_mcdt,
                                              i_problems                  => l_problems, --20
                                              i_dt_problem_begin          => l_dt_problem_begin,
                                              i_detail                    => l_tbl_detail,
                                              i_req_diagnosis             => l_diagnosis,
                                              i_completed                 => 'N',
                                              i_id_tasks                  => table_table_number(), --25
                                              i_id_info                   => table_table_number(),
                                              i_ref_completion            => i_ref_completion,
                                              i_consent                   => l_consent,
                                              i_health_plan               => l_tbl_health_plan,
                                              i_exemption                 => l_tbl_exemption,
                                              i_id_fam_rel                => l_id_fam_rel,
                                              i_fam_rel_spec              => l_fam_rel_spec,
                                              i_name_first_rel            => l_first_name,
                                              i_name_middle_rel           => l_middle_name,
                                              i_name_last_rel             => l_last_name,
                                              o_flg_show                  => l_flg_show,
                                              o_msg_req                   => l_msg_req,
                                              o_msg                       => l_msg,
                                              o_msg_title                 => l_msg_title,
                                              o_exam_req_array            => o_id_requisition,
                                              o_button                    => l_button,
                                              o_id_external_request       => l_tbl_id_external_request,
                                              o_error                     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_root_name = pk_orders_utils.g_p1_intervention
        THEN
        
            l_req_type := 'M';
            l_flg_type := 'P';
            IF NOT create_interv_presc_internal(i_lang                      => i_lang,
                                                i_prof                      => i_prof,
                                                i_id_episode                => i_id_episode,
                                                i_id_patient                => i_id_patient,
                                                i_intervention              => l_tbl_records, --5
                                                i_dt_begin                  => l_dt_begin,
                                                i_dt_order                  => l_dt_order,
                                                i_codification              => l_tbl_codification,
                                                i_flg_laterality            => l_tbl_flg_laterality,
                                                i_clinical_decision_rule    => l_tbl_clinical_decision_rule, --10
                                                i_reason                    => l_tbl_reason_mcdt,
                                                i_complementary_information => l_tbl_complementary_information,
                                                i_ext_req                   => l_id_ext_req,
                                                i_dt_modified               => l_dt_modified,
                                                i_req_type                  => l_req_type,
                                                i_req_flg_type              => l_flg_type,
                                                i_flg_priority_home         => l_tbl_flg_priority_home, --15
                                                i_mcdt                      => l_table_mcdt,
                                                i_problems                  => l_problems,
                                                i_dt_problem_begin          => l_dt_problem_begin,
                                                i_detail                    => l_tbl_detail,
                                                i_req_diagnosis             => l_diagnosis, --20
                                                i_completed                 => 'N', ----------------
                                                i_id_tasks                  => table_table_number(),
                                                i_id_info                   => table_table_number(),
                                                i_ref_completion            => i_ref_completion,
                                                i_consent                   => l_consent, --25
                                                i_health_plan               => l_tbl_health_plan,
                                                i_exemption                 => l_tbl_exemption,
                                                i_id_fam_rel                => l_id_fam_rel,
                                                i_fam_rel_spec              => l_fam_rel_spec,
                                                i_name_first_rel            => l_first_name,
                                                i_name_middle_rel           => l_middle_name,
                                                i_name_last_rel             => l_last_name,
                                                o_flg_show                  => l_flg_show,
                                                o_msg_req                   => l_msg_req,
                                                o_msg_title                 => l_msg_title,
                                                o_id_interv_presc_det       => l_tbl_interv_presc_det,
                                                o_id_external_request       => l_tbl_id_external_request,
                                                o_error                     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_id_requisition := l_tbl_interv_presc_det;
        ELSIF i_root_name = pk_orders_utils.g_p1_rehab
        THEN
            l_req_type := 'M';
            l_flg_type := 'F';
            IF NOT create_rehab_presc_internal(i_lang                      => i_lang,
                                               i_prof                      => i_prof,
                                               i_id_patient                => i_id_patient,
                                               i_id_episode                => i_id_episode,
                                               i_id_rehab_area_interv      => i_tbl_records, --5
                                               i_id_rehab_sch_need         => l_tbl_rehab_sch_need,
                                               i_exec_per_session          => l_tbl_exec_per_session,
                                               i_presc_notes               => l_tbl_presc_notes,
                                               i_sessions                  => l_tbl_sessions,
                                               i_frequency                 => l_tbl_frequency, --10
                                               i_flg_frequency             => l_tbl_flg_frequency,
                                               i_flg_priority              => l_tbl_flg_priority_rehab,
                                               i_date_begin                => l_dt_begin,
                                               i_session_notes             => l_tbl_session_notes,
                                               i_session_type              => l_tbl_session_type, --15
                                               i_codification              => l_tbl_codification,
                                               i_flg_laterality            => l_tbl_flg_laterality,
                                               i_reason                    => l_tbl_reason_mcdt,
                                               i_complementary_information => l_tbl_complementary_information,
                                               i_ext_req                   => l_id_ext_req,
                                               i_dt_modified               => l_dt_modified,
                                               i_req_type                  => l_req_type, --20
                                               i_req_flg_type              => l_flg_type,
                                               i_flg_priority_home         => l_tbl_flg_priority_home,
                                               i_mcdt                      => l_table_mcdt,
                                               i_problems                  => l_problems,
                                               i_dt_problem_begin          => l_dt_problem_begin, --25
                                               i_detail                    => l_tbl_detail,
                                               i_req_diagnosis             => l_diagnosis,
                                               i_completed                 => 'N',
                                               i_id_tasks                  => table_table_number(),
                                               i_id_info                   => table_table_number(), --30
                                               i_ref_completion            => i_ref_completion,
                                               i_consent                   => l_consent,
                                               i_health_plan               => l_tbl_health_plan,
                                               i_exemption                 => l_tbl_exemption,
                                               i_id_fam_rel                => l_id_fam_rel,
                                               i_fam_rel_spec              => l_fam_rel_spec,
                                               i_name_first_rel            => l_first_name,
                                               i_name_middle_rel           => l_middle_name,
                                               i_name_last_rel             => l_last_name,
                                               o_flg_show                  => l_flg_show,
                                               o_msg                       => l_msg,
                                               o_msg_title                 => l_msg_title,
                                               o_button                    => l_button,
                                               o_id_rehab_presc            => l_tbl_interv_presc_det,
                                               o_id_external_request       => l_tbl_id_external_request,
                                               o_error                     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_id_requisition := l_tbl_interv_presc_det;
        END IF;
    
        IF i_root_name = pk_orders_utils.g_p1_appointment
        THEN
            o_id_external_request := table_number(l_id_external_request);
        ELSE
            o_id_external_request := l_tbl_id_external_request;
        END IF;
    
        IF (l_id_fam_rel IS NOT NULL OR l_first_name IS NOT NULL OR l_middle_name IS NOT NULL OR
           l_last_name IS NOT NULL)
        THEN
            --FALTA INCLUIR MIDDLE NAME - AGUARDAR POR ADT
            IF NOT pk_adt_core.save_caregiver_info(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_patient    => i_id_patient,
                                                   i_id_fam_rel    => l_id_fam_rel,
                                                   i_fam_rel_spec  => l_fam_rel_spec,
                                                   i_firstname     => l_first_name,
                                                   i_lastname      => l_last_name,
                                                   i_othernames1   => NULL,
                                                   i_othernames3   => l_middle_name, ----------
                                                   i_phone_no      => NULL,
                                                   i_id_care_giver => NULL)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_ref_completion = 1
           AND l_tbl_id_external_request.exists(1)
           AND i_root_name NOT IN (pk_orders_utils.g_p1_appointment)
        THEN
        
            FOR t IN (SELECT *
                        FROM p1_external_request a
                       WHERE a.id_external_request = l_tbl_id_external_request(1))
            LOOP
                IF t.flg_type = 'A'
                THEN
                    SELECT ard.id_analysis, ard.id_analysis_req_det, ard.id_sample_type
                      BULK COLLECT
                      INTO l_id_metadata, l_id_req_det, l_id_sample_type
                      FROM p1_exr_temp pet
                     INNER JOIN analysis_req_det ard
                        ON pet.id_analysis_req_det = ard.id_analysis_req_det
                     WHERE pet.id_external_request = t.id_external_request;
                ELSIF t.flg_type IN ('I', 'E')
                THEN
                    SELECT erd.id_exam, erd.id_exam_req_det, NULL
                      BULK COLLECT
                      INTO l_id_metadata, l_id_req_det, l_id_sample_type
                      FROM p1_exr_temp pet
                     INNER JOIN exam_req_det erd
                        ON pet.id_exam_req_det = erd.id_exam_req_det
                     WHERE pet.id_external_request = t.id_external_request;
                
                ELSIF t.flg_type = 'P'
                THEN
                    SELECT ipd.id_intervention, ipd.id_interv_presc_det, NULL
                      BULK COLLECT
                      INTO l_id_metadata, l_id_req_det, l_id_sample_type
                      FROM p1_exr_temp pet
                     INNER JOIN interv_presc_det ipd
                        ON pet.id_interv_presc_det = ipd.id_interv_presc_det
                     WHERE pet.id_external_request = t.id_external_request;
                ELSE
                    SELECT ipd.id_intervention, ipd.id_interv_presc_det, NULL
                      BULK COLLECT
                      INTO l_id_metadata, l_id_req_det, l_id_sample_type
                      FROM p1_exr_temp pet
                     INNER JOIN interv_presc_det ipd
                        ON pet.id_rehab_presc = ipd.id_interv_presc_det
                     WHERE pet.id_external_request = t.id_external_request;
                END IF;
            
                l_table_mcdt := table_table_number();
                FOR z IN 1 .. l_id_metadata.count
                LOOP
                    l_table_mcdt.extend();
                    l_table_mcdt(l_table_mcdt.count) := table_number();
                    l_table_mcdt(l_table_mcdt.count).extend(5);
                    l_table_mcdt(l_table_mcdt.count)(1) := l_id_metadata(z);
                    l_table_mcdt(l_table_mcdt.count)(2) := l_id_req_det(z);
                    l_table_mcdt(l_table_mcdt.count)(3) := t.id_inst_dest; --DEST FACILITY
                    l_table_mcdt(l_table_mcdt.count)(4) := 1; --QUANTITY
                    l_table_mcdt(l_table_mcdt.count)(5) := l_id_sample_type(z); --g_idx_id_sample_type
                END LOOP;
            END LOOP;
        
            IF NOT insert_external_request_mcdt(i_lang                => i_lang,
                                                i_ext_req             => l_tbl_id_external_request(1),
                                                i_dt_modified         => l_dt_modified,
                                                i_id_patient          => i_id_patient,
                                                i_id_episode          => i_id_episode,
                                                i_req_type            => l_req_type,
                                                i_flg_type            => l_flg_type,
                                                i_flg_priority_home   => l_tbl_flg_priority_home,
                                                i_mcdt                => l_table_mcdt,
                                                i_prof                => i_prof,
                                                i_problems            => l_problems,
                                                i_dt_problem_begin    => l_dt_problem_begin,
                                                i_detail              => l_tbl_detail,
                                                i_diagnosis           => l_diagnosis,
                                                i_completed           => 'Y',
                                                i_id_tasks            => table_table_number(),
                                                i_id_info             => table_table_number(),
                                                i_codification        => l_tbl_codification(1),
                                                i_flg_laterality      => l_tbl_flg_laterality,
                                                i_ref_completion      => i_ref_completion,
                                                i_consent             => l_consent,
                                                o_id_external_request => o_id_external_request,
                                                o_flg_show            => l_flg_show,
                                                o_msg                 => l_msg,
                                                o_msg_title           => l_msg_title,
                                                o_button              => l_button,
                                                o_error               => o_error)
            THEN
                RAISE g_exception;
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
                                              'CREATE_P1_REQUEST',
                                              o_error);
            RETURN FALSE;
    END create_p1_request;

    FUNCTION get_p1_order_for_edition
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
        l_min_val            ds_cmpt_mkt_rel.min_value%TYPE;
        l_max_val            ds_cmpt_mkt_rel.max_value%TYPE;
    
        l_reason_mandatory             VARCHAR2(1) := pk_alert_constant.g_yes;
        l_diagnosis_mandatory          sys_config.value%TYPE;
        l_consent_mandatory            sys_config.value%TYPE;
        l_laterality_mandatory         VARCHAR2(1) := pk_alert_constant.g_no;
        l_tbl_compl_info_mandatory     table_varchar := table_varchar();
        l_complementary_info_mandatory VARCHAR2(1) := pk_alert_constant.g_no;
    
        l_medication_available  sys_config.value%TYPE;
        l_vital_signs_available sys_config.value%TYPE;
    
        l_home_value     VARCHAR2(10);
        l_priority_value VARCHAR2(10);
    
        --Variables for edition
        c_patient          pk_types.cursor_type;
        c_detail           pk_types.cursor_type;
        c_text             pk_types.cursor_type;
        c_problem          pk_types.cursor_type;
        c_diagnosis        pk_types.cursor_type;
        c_mcdt             pk_types.cursor_type;
        c_needs            pk_types.cursor_type;
        c_info             pk_types.cursor_type;
        c_notes_status     pk_types.cursor_type;
        c_notes_status_det pk_types.cursor_type;
        c_answer           pk_types.cursor_type;
        c_title_status     VARCHAR2(1000);
        c_editable         VARCHAR2(1000);
        c_can_cancel       VARCHAR2(1000);
        c_ref_orig_data    pk_types.cursor_type;
        c_ref_comments     pk_types.cursor_type;
        c_fields_rank      pk_types.cursor_type;
    
        --Variables for the mcdt content
        l_mcdt_record mcdt_type;
        l_tbl_p1_mcdt tbl_mcdt_type := tbl_mcdt_type();
    
        --Variables for the P1 detail
        l_tbl_p1_detail tbl_p1_detail_type := tbl_p1_detail_type();
    
        --Variable for the P1 free text fields
        l_text_record p1_text_type;
        l_tbl_p1_text tbl_p1_text := tbl_p1_text();
    
        --Variables fpr the P1 diagnosis
        l_tbl_p1_diagnosis tbl_p1_diagnosis;
    
        --Variables fpr the P1 problems
        l_tbl_p1_problems tbl_p1_diagnosis;
    
        l_req_id  NUMBER(24);
        l_id_mcdt NUMBER(24);
    
        l_tbl_records_number       table_number := table_number();
        l_tbl_analysis_sample_type table_varchar;
        l_records_piped            VARCHAR2(4000);
    
        l_id_ext_req p1_external_request.id_external_request%TYPE;
    
        --Variables for health insurance and exemption
        l_id_pat_health_plan    exam_req_det.id_pat_health_plan%TYPE;
        l_id_pat_exemption      exam_req_det.id_pat_exemption%TYPE;
        l_id_health_plan_entity health_plan_entity.id_health_plan_entity%TYPE;
        l_num_health_plan       VARCHAR2(1000);
    
        l_id_fam_rel      p1_external_request.id_fam_rel%TYPE;
        l_fam_res_spec    VARCHAR2(200);
        l_id_pat_relative NUMBER(24) := pk_adt_core.get_id_pat_relative(i_patient);
        l_first_fam_name  VARCHAR2(4000);
        l_middle_name     VARCHAR2(4000);
        l_name            VARCHAR2(4000);
    
        l_msg       VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_button    VARCHAR2(4000);
    
        l_id_market market.id_market%TYPE;
    
        l_tbl_p1_priority t_tbl_core_domain;
        l_priority        VARCHAR2(10);
        l_priority_desc   VARCHAR2(100 CHAR);
    BEGIN
    
        g_error     := 'GET INSTITUTION MARKET';
        l_id_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        --Obtain the requisition id
        IF i_root_name = pk_orders_utils.g_p1_appointment
        THEN
            l_id_ext_req := i_tbl_id_pk(i_idx);
        ELSIF i_root_name = pk_orders_utils.g_p1_lab_test
        THEN
            SELECT ard.id_analysis_req
              INTO l_req_id
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = i_tbl_id_pk(i_idx);
        
            WITH cod AS
             (SELECT ac.id_analysis,
                     ac.id_sample_type,
                     ac.flg_mandatory_info,
                     row_number() over(PARTITION BY ac.id_analysis, ac.id_sample_type ORDER BY ac.id_analysis_codification ASC) AS rn
                FROM analysis_codification ac
                JOIN analysis_req_det ard
                  ON ard.id_analysis = ac.id_analysis
                 AND ard.id_sample_type = ac.id_sample_type
                 AND ard.id_analysis_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                   FROM TABLE(i_tbl_id_pk) t)
               WHERE ac.flg_available = pk_alert_constant.g_yes)
            SELECT ast.id_content, nvl(c.flg_mandatory_info, pk_alert_constant.g_no)
              BULK COLLECT
              INTO l_tbl_analysis_sample_type, l_tbl_compl_info_mandatory
              FROM analysis_req_det ard
              JOIN analysis_sample_type ast
                ON ast.id_analysis = ard.id_analysis
               AND ast.id_sample_type = ard.id_sample_type
               AND ast.flg_available = pk_alert_constant.g_yes
              LEFT JOIN cod c
                ON c.id_analysis = ast.id_analysis
               AND c.id_sample_type = ast.id_sample_type
               AND c.rn = 1
             WHERE ard.id_analysis_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                 FROM TABLE(i_tbl_id_pk) t);
        
            IF l_tbl_analysis_sample_type.count > 0
            THEN
                BEGIN
                    SELECT listagg(t.column_value, '|')
                      INTO l_records_piped
                      FROM TABLE(l_tbl_analysis_sample_type) t;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_records_piped := NULL;
                END;
            END IF;
        
            SELECT id_external_request
              INTO l_id_ext_req
              FROM (SELECT pt.id_external_request
                      FROM p1_exr_temp pt
                     WHERE pt.id_analysis_req_det = i_tbl_id_pk(i_idx)
                    UNION
                    SELECT pe.id_external_request
                      FROM p1_exr_analysis pe
                     WHERE pe.id_analysis_req_det = i_tbl_id_pk(i_idx));
        ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
        THEN
            SELECT erd.id_exam_req, erd.id_exam
              INTO l_req_id, l_id_mcdt
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = i_tbl_id_pk(i_idx);
        
            SELECT erd.id_exam
              BULK COLLECT
              INTO l_tbl_records_number
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                             FROM TABLE(i_tbl_id_pk) t);
        
            IF l_tbl_records_number.count > 0
            THEN
                BEGIN
                    SELECT listagg(t.column_value, '|')
                      INTO l_records_piped
                      FROM TABLE(l_tbl_records_number) t;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_records_piped := NULL;
                END;
            END IF;
        
            SELECT id_external_request
              INTO l_id_ext_req
              FROM (SELECT pt.id_external_request
                      FROM p1_exr_temp pt
                     WHERE pt.id_exam_req_det = i_tbl_id_pk(i_idx)
                    UNION
                    SELECT pe.id_external_request
                      FROM p1_exr_exam pe
                     WHERE pe.id_exam_req_det = i_tbl_id_pk(i_idx));
        
        ELSIF i_root_name = pk_orders_utils.g_p1_intervention
        THEN
            l_req_id := i_tbl_id_pk(i_idx);
        
            SELECT ipd.id_intervention
              BULK COLLECT
              INTO l_tbl_records_number
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                 FROM TABLE(i_tbl_id_pk) t);
            SELECT ipd.id_intervention
              INTO l_id_mcdt
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det = i_tbl_id_pk(i_idx);
        
            IF l_tbl_records_number.count > 0
            THEN
                BEGIN
                    SELECT listagg(t.column_value, '|')
                      INTO l_records_piped
                      FROM TABLE(l_tbl_records_number) t;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_records_piped := NULL;
                END;
            END IF;
        
            SELECT id_external_request
              INTO l_id_ext_req
              FROM (SELECT pt.id_external_request
                      FROM p1_exr_temp pt
                     WHERE pt.id_interv_presc_det = i_tbl_id_pk(i_idx)
                    UNION
                    SELECT pi.id_external_request
                      FROM p1_exr_intervention pi
                     WHERE pi.id_interv_presc_det = i_tbl_id_pk(i_idx));
        
        ELSIF i_root_name = pk_orders_utils.g_p1_rehab
        THEN
            l_req_id := i_tbl_id_pk(i_idx); --rehab_presc
        
            SELECT rp.id_rehab_area_interv
              BULK COLLECT
              INTO l_tbl_records_number
              FROM rehab_presc rp
             WHERE rp.id_rehab_presc IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                           FROM TABLE(i_tbl_id_pk) t);
            SELECT rp.id_rehab_area_interv
              INTO l_id_mcdt
              FROM rehab_presc rp
             WHERE rp.id_rehab_presc = i_tbl_id_pk(i_idx);
        
            IF l_tbl_records_number.count > 0
            THEN
                BEGIN
                    SELECT listagg(t.column_value, '|')
                      INTO l_records_piped
                      FROM TABLE(l_tbl_records_number) t;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_records_piped := NULL;
                END;
            END IF;
        
            SELECT id_external_request
              INTO l_id_ext_req
              FROM (SELECT pt.id_external_request
                      FROM p1_exr_temp pt
                     WHERE pt.id_rehab_presc = i_tbl_id_pk(i_idx)
                    UNION
                    SELECT pi.id_external_request
                      FROM p1_exr_intervention pi
                     WHERE pi.id_rehab_presc = i_tbl_id_pk(i_idx));
        END IF;
    
        --Check if field consent is mandatory
        l_consent_mandatory := pk_sysconfig.get_config('P1_CONSENT', i_prof);
    
        --Check if field diagnosis is mandatory
        l_diagnosis_mandatory := pk_sysconfig.get_config(pk_ref_constant.g_ref_diag_mandatory, i_prof);
    
        --Check if the field laterality is mandatory
        IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                           pk_orders_utils.g_p1_other_exam,
                           pk_orders_utils.g_p1_intervention,
                           pk_orders_utils.g_p1_rehab)
        THEN
            IF NOT pk_mcdt.check_mandatory_lat(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_mcdt_type => CASE i_root_name
                                                                  WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                   pk_ref_constant.g_p1_type_e
                                                                  WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                   pk_ref_constant.g_p1_type_i
                                                                  WHEN pk_orders_utils.g_p1_intervention THEN
                                                                   pk_ref_constant.g_p1_type_p
                                                                  WHEN pk_orders_utils.g_p1_rehab THEN
                                                                   pk_ref_constant.g_p1_type_f
                                                              END,
                                               i_mcdt      => table_number(l_id_mcdt),
                                               o_flg_show  => l_laterality_mandatory,
                                               o_msg       => l_msg,
                                               o_msg_title => l_msg_title,
                                               o_button    => l_button,
                                               o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --Check if field Medication is available                           
        l_medication_available := pk_sysconfig.get_config('REF_MEDICATION_ENABLE', i_prof);
    
        --Check if the field vital signs is available
        l_vital_signs_available := pk_sysconfig.get_config('REF_VITALSIGNS_ENABLE', i_prof);
    
        --Fill the form with values for the dummy fields (root_name, records ids, etc.)
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_root_name
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => i_root_name,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => NULL,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_tbl_records
                  AND i_root_name <> pk_orders_utils.g_p1_appointment
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => l_records_piped,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => NULL,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => l_id_ext_req,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => NULL,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            ELSIF l_ds_internal_name IN
                  (pk_orders_constant.g_ds_p1_import_ids, pk_orders_constant.g_ds_p1_import_values)
            THEN
                --This is necessary on order for the UX to be able to insert the Import data on these fields
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => NULL,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_p1_all_items_selected)
                  AND i_root_name <> pk_orders_utils.g_p1_appointment
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => pk_alert_constant.g_yes,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
            THEN
                tbl_result.extend();
                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                   id_ds_component    => l_id_ds_component,
                                                                   internal_name      => l_ds_internal_name,
                                                                   VALUE              => NULL,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => NULL,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
            END IF;
        END LOOP;
    
        IF NOT pk_p1_ext_sys.get_p1_detail_new(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_ext_req       => l_id_ext_req,
                                               i_status_detail    => 'A',
                                               i_flg_labels       => 'N',
                                               o_detail           => c_detail,
                                               o_text             => c_text,
                                               o_problem          => c_problem,
                                               o_diagnosis        => c_diagnosis,
                                               o_mcdt             => c_mcdt,
                                               o_needs            => c_needs,
                                               o_info             => c_info,
                                               o_notes_status     => c_notes_status,
                                               o_notes_status_det => c_notes_status_det,
                                               o_answer           => c_answer,
                                               o_title_status     => c_title_status,
                                               o_editable         => c_editable,
                                               o_can_cancel       => c_can_cancel,
                                               o_ref_comments     => c_ref_comments,
                                               o_fields_rank      => c_fields_rank,
                                               o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --This cursor is mainly used for appointments, however, the info regarding the 'Consent' field (which is only used in MCDTs)
        --and the Onset is sent in this cursor
        FETCH c_detail BULK COLLECT
            INTO l_tbl_p1_detail;
    
        IF i_root_name = pk_orders_utils.g_p1_appointment
        THEN
            IF NOT pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_type             => CASE i_root_name
                                                                                  WHEN pk_orders_utils.g_p1_appointment THEN
                                                                                   'C'
                                                                                  WHEN pk_orders_utils.g_p1_lab_test THEN
                                                                                   'A'
                                                                                  WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                   'P'
                                                                                  WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                   'I'
                                                                                  WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                   'E'
                                                                                  WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                   'F'
                                                                              END,
                                                        i_home             => table_varchar(l_tbl_p1_detail(1).flg_home),
                                                        i_priority         => table_varchar(l_tbl_p1_detail(1).flg_priority),
                                                        o_reason_mandatory => l_reason_mandatory,
                                                        o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF NOT pk_p1_ext_sys.get_p1_healthcare_insurance(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_id_ext_req            => l_tbl_p1_detail(1).id_external_request,
                                                             i_root_name             => i_root_name,
                                                             o_id_pat_health_plan    => l_id_pat_health_plan,
                                                             o_id_pat_exemption      => l_id_pat_exemption,
                                                             o_id_health_plan_entity => l_id_health_plan_entity,
                                                             o_num_health_plan       => l_num_health_plan,
                                                             o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_clinical_service
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).id_speciality,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).spec_name,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_destination_facility
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).id_inst_dest,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).inst_name,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).flg_home,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).desc_home,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_priority
                THEN
                    l_tbl_p1_priority := pk_ref_list.get_priority_list(i_lang, i_prof);
                    BEGIN
                        SELECT t.domain_value, t.desc_domain
                          INTO l_priority, l_priority_desc
                          FROM TABLE(l_tbl_p1_priority) t
                         WHERE t.domain_value = l_tbl_p1_detail(1).flg_priority;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_priority      := NULL;
                            l_priority_desc := NULL;
                    END;
                
                    IF l_priority IS NOT NULL
                       AND l_priority_desc IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_priority,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_priority_desc,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END IF;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_onset
                      AND l_tbl_p1_detail(1).dt_probl_begin_ts IS NOT NULL
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).dt_probl_begin_ts ||
                                                                                              '000000',
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).dt_probl_begin,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_financial_entity
                      AND l_id_pat_health_plan IS NOT NULL
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => to_char(l_id_health_plan_entity),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => pk_adt.get_pat_health_plan_info(i_lang,
                                                                                                                             i_prof,
                                                                                                                             l_id_pat_health_plan,
                                                                                                                             'F'),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE l_id_market
                                                                                                 WHEN
                                                                                                  pk_alert_constant.g_id_market_pt THEN
                                                                                                  pk_orders_constant.g_component_mandatory
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_active
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_health_coverage_plan
                      AND l_id_pat_health_plan IS NOT NULL
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => to_char(l_id_pat_health_plan),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => pk_adt.get_pat_health_plan_info(i_lang,
                                                                                                                             i_prof,
                                                                                                                             l_id_pat_health_plan,
                                                                                                                             'H'),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE l_id_market
                                                                                                 WHEN
                                                                                                  pk_alert_constant.g_id_market_pt THEN
                                                                                                  pk_orders_constant.g_component_mandatory
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_active
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_health_plan_number
                      AND l_num_health_plan IS NOT NULL
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_num_health_plan,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_num_health_plan,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_exemption
                      AND l_id_pat_exemption IS NOT NULL
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => to_char(l_id_pat_exemption),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => pk_adt.get_pat_exemption_detail(i_lang,
                                                                                                                             i_prof,
                                                                                                                             l_id_pat_exemption),
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_family_relationship
                      AND l_tbl_p1_detail(1).id_fam_rel IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => to_char(l_tbl_p1_detail(1).id_fam_rel),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).desc_fr,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_family_relationship_spec
                THEN
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).family_relationship_notes,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).family_relationship_notes,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => CASE
                                                                                              l_tbl_p1_detail(1).id_fam_rel
                                                                                                 WHEN 44 THEN
                                                                                                  pk_orders_constant.g_component_mandatory
                                                                                                 ELSE
                                                                                                  pk_orders_constant.g_component_inactive
                                                                                             END,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_lastname
                      AND l_tbl_p1_detail(1).name_last_rel IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).name_last_rel,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).name_last_rel,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_middlename
                      AND l_tbl_p1_detail(1).name_middle_rel IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).name_middle_rel,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).name_middle_rel,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_nombres
                      AND l_tbl_p1_detail(1).name_first_rel IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).name_first_rel,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).name_first_rel,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_physician_license
                      AND l_tbl_p1_detail(1).prof_certificate IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).prof_certificate,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).prof_certificate,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_physician_name
                      AND l_tbl_p1_detail(1).prof_name IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).prof_name,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).prof_name,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_physician_surname
                      AND l_tbl_p1_detail(1).prof_surname IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).prof_surname,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).prof_surname,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_physician_phone
                      AND l_tbl_p1_detail(1).prof_phone IS NOT NULL
                THEN
                
                    tbl_result.extend();
                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => l_ds_internal_name,
                                                                       VALUE              => l_tbl_p1_detail(1).prof_phone,
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_tbl_p1_detail(1).prof_phone,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
                
                END IF;
            END LOOP;
        ELSIF i_root_name IN (pk_orders_utils.g_p1_lab_test,
                              pk_orders_utils.g_p1_imaging_exam,
                              pk_orders_utils.g_p1_other_exam,
                              pk_orders_utils.g_p1_intervention,
                              pk_orders_utils.g_p1_rehab)
        THEN
            LOOP
                FETCH c_mcdt
                    INTO l_mcdt_record;
                EXIT WHEN c_mcdt%NOTFOUND;
            
                --selectionar apenas o registo do 1º pk (ver por área)
                IF (i_root_name = pk_orders_utils.g_p1_lab_test AND l_mcdt_record.p1_id_analysis_req = l_req_id)
                   OR (i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam) AND
                   l_mcdt_record.p1_id_exam_req = l_req_id)
                   OR (i_root_name = pk_orders_utils.g_p1_intervention AND l_mcdt_record.p1_id_req = l_req_id)
                   OR (i_root_name = pk_orders_utils.g_p1_rehab AND l_mcdt_record.p1_id_req = l_req_id)
                THEN
                    l_tbl_p1_mcdt.extend();
                    l_tbl_p1_mcdt(l_tbl_p1_mcdt.count) := mcdt_type(p1_id                        => l_mcdt_record.p1_id,
                                                                    p1_id_parent                 => l_mcdt_record.p1_id_parent,
                                                                    p1_id_req                    => l_mcdt_record.p1_id_req,
                                                                    p1_id_analysis_req           => l_mcdt_record.p1_id_analysis_req,
                                                                    p1_id_exam_req               => l_mcdt_record.p1_id_exam_req,
                                                                    p1_title                     => l_mcdt_record.p1_title,
                                                                    p1_text                      => l_mcdt_record.p1_text,
                                                                    p1_dt_insert                 => l_mcdt_record.p1_dt_insert,
                                                                    p1_prof_name                 => l_mcdt_record.p1_prof_name,
                                                                    p1_flg_type                  => l_mcdt_record.p1_flg_type,
                                                                    p1_flg_status                => l_mcdt_record.p1_flg_status,
                                                                    p1_id_institution            => l_mcdt_record.p1_id_institution,
                                                                    p1_abbreviation              => l_mcdt_record.p1_abbreviation,
                                                                    p1_desc_institution          => l_mcdt_record.p1_desc_institution,
                                                                    p1_flg_priority              => l_mcdt_record.p1_flg_priority,
                                                                    p1_flg_home                  => l_mcdt_record.p1_flg_home,
                                                                    p1_priority_desc             => l_mcdt_record.p1_priority_desc,
                                                                    p1_desc_home                 => l_mcdt_record.p1_desc_home,
                                                                    p1_label_priority            => l_mcdt_record.p1_label_priority,
                                                                    p1_priority_icon             => l_mcdt_record.p1_priority_icon,
                                                                    p1_label_home                => l_mcdt_record.p1_label_home,
                                                                    p1_id_codification           => l_mcdt_record.p1_id_codification,
                                                                    p1_desc_codification         => l_mcdt_record.p1_desc_codification,
                                                                    p1_id_mcdt_codification      => l_mcdt_record.p1_id_mcdt_codification,
                                                                    p1_product_desc              => l_mcdt_record.p1_product_desc,
                                                                    p1_id_sample_type            => l_mcdt_record.p1_id_sample_type,
                                                                    p1_id_rehab_area_interv      => l_mcdt_record.p1_id_rehab_area_interv,
                                                                    p1_desc_rehab_area           => l_mcdt_record.p1_desc_rehab_area,
                                                                    p1_flg_laterality            => l_mcdt_record.p1_flg_laterality,
                                                                    p1_desc_laterality           => l_mcdt_record.p1_desc_laterality,
                                                                    p1_flg_laterality_mcdt       => l_mcdt_record.p1_flg_laterality_mcdt,
                                                                    p1_label_laterality          => l_mcdt_record.p1_label_laterality,
                                                                    p1_label_amount              => l_mcdt_record.p1_label_amount,
                                                                    p1_mcdt_amount               => l_mcdt_record.p1_mcdt_amount,
                                                                    p1_id_rehab_session_type     => l_mcdt_record.p1_id_rehab_session_type,
                                                                    p1_reason                    => l_mcdt_record.p1_reason,
                                                                    p1_complementary_information => l_mcdt_record.p1_complementary_information);
                END IF;
            END LOOP;
        
            IF l_tbl_p1_mcdt.count > 0
            THEN
            
                IF NOT pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_type             => CASE i_root_name
                                                                                      WHEN pk_orders_utils.g_p1_appointment THEN
                                                                                       'C'
                                                                                      WHEN pk_orders_utils.g_p1_lab_test THEN
                                                                                       'A'
                                                                                      WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                       'P'
                                                                                      WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                       'I'
                                                                                      WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                       'E'
                                                                                      WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                       'F'
                                                                                  END,
                                                            i_home             => table_varchar(l_tbl_p1_mcdt(1).p1_flg_home),
                                                            i_priority         => table_varchar(l_tbl_p1_mcdt(1).p1_flg_priority),
                                                            o_reason_mandatory => l_reason_mandatory,
                                                            o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF NOT pk_p1_ext_sys.get_p1_healthcare_insurance(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_ext_req            => l_tbl_p1_detail(1).id_external_request,
                                                                 i_root_name             => i_root_name,
                                                                 i_req_det               => i_tbl_id_pk(1),
                                                                 o_id_pat_health_plan    => l_id_pat_health_plan,
                                                                 o_id_pat_exemption      => l_id_pat_exemption,
                                                                 o_id_health_plan_entity => l_id_health_plan_entity,
                                                                 o_num_health_plan       => l_num_health_plan,
                                                                 o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_destination_facility
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_mcdt(1).p1_id_institution,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_mcdt(1).p1_desc_institution,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_quantity
                    THEN
                        SELECT d.min_value, d.max_value
                          INTO l_min_val, l_max_val
                          FROM ds_cmpt_mkt_rel d
                         WHERE d.id_ds_cmpt_mkt_rel = i_tbl_mkt_rel(i);
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_mcdt(1).p1_mcdt_amount,
                                                                           value_clob         => NULL,
                                                                           min_value          => l_min_val,
                                                                           max_value          => l_max_val,
                                                                           desc_value         => l_tbl_p1_mcdt(1).p1_mcdt_amount,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_complementary_information
                    THEN
                        IF l_tbl_compl_info_mandatory.exists(1)
                        THEN
                            FOR j IN l_tbl_compl_info_mandatory.first .. l_tbl_compl_info_mandatory.last
                            LOOP
                                IF l_tbl_compl_info_mandatory(j) = pk_alert_constant.g_yes
                                THEN
                                    l_complementary_info_mandatory := l_tbl_compl_info_mandatory(j);
                                END IF;
                            END LOOP;
                        END IF;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_mcdt(1).p1_complementary_information,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_mcdt(1).p1_complementary_information,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                     WHEN l_complementary_info_mandatory = pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                    THEN
                        --For PT market and for the MCDTs, the field HOME
                        --should only ve available for Lab tests
                        IF l_id_market = pk_alert_constant.g_id_market_pt
                           AND i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                                               pk_orders_utils.g_p1_other_exam,
                                               pk_orders_utils.g_p1_intervention,
                                               pk_orders_utils.g_p1_rehab)
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSE
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_p1_mcdt(1).p1_flg_home,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_p1_mcdt(1).p1_desc_home,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_priority
                    THEN
                        l_tbl_p1_priority := pk_ref_list.get_priority_list(i_lang, i_prof);
                        BEGIN
                            SELECT t.domain_value, t.desc_domain
                              INTO l_priority, l_priority_desc
                              FROM TABLE(l_tbl_p1_priority) t
                             WHERE t.domain_value = l_tbl_p1_detail(1).flg_priority;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_priority      := NULL;
                                l_priority_desc := NULL;
                        END;
                    
                        IF l_priority IS NOT NULL
                           AND l_priority_desc IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_priority,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_priority_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_laterality
                    THEN
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_mcdt(1).p1_flg_laterality,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_mcdt(1).p1_desc_laterality,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE i_root_name
                                                                                                     WHEN
                                                                                                      pk_orders_utils.g_p1_lab_test THEN
                                                                                                      pk_orders_constant.g_component_inactive
                                                                                                     ELSE
                                                                                                      CASE
                                                                                                       l_laterality_mandatory
                                                                                                          WHEN
                                                                                                           pk_alert_constant.g_yes THEN
                                                                                                           pk_orders_constant.g_component_mandatory
                                                                                                          ELSE
                                                                                                           pk_orders_constant.g_component_active
                                                                                                      END
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_referral_reason
                          AND l_tbl_p1_mcdt(1).p1_reason IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_mcdt(1).p1_reason,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_mcdt(1).p1_reason,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_reason_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_financial_entity
                          AND l_id_pat_health_plan IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_id_health_plan_entity),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => pk_adt.get_pat_health_plan_info(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 l_id_pat_health_plan,
                                                                                                                                 'F'),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_id_market
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_id_market_pt THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_health_coverage_plan
                          AND l_id_pat_health_plan IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_id_pat_health_plan),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => pk_adt.get_pat_health_plan_info(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 l_id_pat_health_plan,
                                                                                                                                 'H'),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_id_market
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_id_market_pt THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_health_plan_number
                          AND l_num_health_plan IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_num_health_plan,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_num_health_plan,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_exemption
                          AND l_id_pat_exemption IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_id_pat_exemption),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => pk_adt.get_pat_exemption_detail(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 l_id_pat_exemption),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END IF;
                END LOOP;
            END IF;
        
            IF l_tbl_p1_detail.count > 0
            THEN
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_referral_consent
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_detail(1).consent,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_detail(1).desc_consent,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_consent_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_onset
                          AND l_tbl_p1_detail(1).dt_probl_begin_ts IS NOT NULL
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_detail(1).dt_probl_begin_ts ||
                                                                                                  '000000',
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_detail(1).dt_probl_begin,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_family_relationship
                          AND l_tbl_p1_detail(1).id_fam_rel IS NOT NULL
                    THEN
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_tbl_p1_detail(1).id_fam_rel),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_detail(1).desc_fr,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_family_relationship_spec
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_detail(1).family_relationship_notes,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_detail(1).family_relationship_notes,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                  l_tbl_p1_detail(1).id_fam_rel
                                                                                                     WHEN 44 THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_inactive
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_lastname
                          AND l_id_pat_relative IS NOT NULL
                    THEN
                        l_first_fam_name := pk_adt_core.get_1st_fam_name(l_id_pat_relative);
                    
                        IF l_first_fam_name IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_first_fam_name,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_first_fam_name,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_middlename
                          AND l_id_pat_relative IS NOT NULL
                    THEN
                        l_middle_name := pk_adt_core.get_1st_fam_otname3(l_id_pat_relative);
                    
                        IF l_middle_name IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_middle_name,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_middle_name,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_nombres
                          AND l_id_pat_relative IS NOT NULL
                    THEN
                    
                        l_name := pk_adt_core.get_1st_cgiver_1st_name(l_id_pat_relative);
                    
                        IF l_name IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_name,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_name,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END IF;
                
                END LOOP;
            END IF;
        END IF;
    
        --Obtain the free text records (Reason, notes, course, etc.)
        LOOP
            FETCH c_text
                INTO l_text_record;
            EXIT WHEN c_text%NOTFOUND;
        
            l_tbl_p1_text.extend();
            l_tbl_p1_text(l_tbl_p1_text.count) := p1_text_type(label_group        => l_text_record.label_group,
                                                               label              => l_text_record.label,
                                                               id                 => l_text_record.id,
                                                               id_parent          => l_text_record.id_parent,
                                                               id_req             => l_text_record.id_req,
                                                               title              => l_text_record.title,
                                                               text               => l_text_record.text,
                                                               dt_insert          => l_text_record.dt_insert,
                                                               prof_name          => l_text_record.prof_name,
                                                               prof_spec          => l_text_record.prof_spec,
                                                               flg_type           => l_text_record.flg_type,
                                                               flg_status         => l_text_record.flg_status,
                                                               id_institution     => l_text_record.id_institution,
                                                               flg_priority       => l_text_record.flg_priority,
                                                               flg_home           => l_text_record.flg_home,
                                                               id_group           => l_text_record.id_group,
                                                               rank_group_reports => l_text_record.rank_group_reports,
                                                               field_name         => l_text_record.field_name);
        END LOOP;
    
        IF l_tbl_p1_text.count > 0
        THEN
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                FOR j IN l_tbl_p1_text.first .. l_tbl_p1_text.last
                LOOP
                    IF (l_tbl_p1_text(j)
                       .field_name = 'REASON' AND l_ds_internal_name = pk_orders_constant.g_ds_referral_reason)
                       OR (l_tbl_p1_text(j)
                       .field_name = 'SYMPTOMS' AND l_ds_internal_name = pk_orders_constant.g_ds_symptoms)
                       OR
                       (l_tbl_p1_text(j).field_name = 'PROGRESS' AND l_ds_internal_name = pk_orders_constant.g_ds_course)
                       OR (l_tbl_p1_text(j)
                       .field_name = 'VITAL_SIGNES' AND l_ds_internal_name = pk_orders_constant.g_ds_vital_signs)
                       OR (l_tbl_p1_text(j)
                       .field_name = 'MEDICATION' AND l_ds_internal_name = pk_orders_constant.g_ds_medication)
                       OR
                       (l_tbl_p1_text(j)
                       .field_name = 'FAMILY_HISTORY' AND l_ds_internal_name = pk_orders_constant.g_ds_family_history)
                       OR (l_tbl_p1_text(j).field_name = 'OBJECTIVE_EXAM' AND
                        l_ds_internal_name = pk_orders_constant.g_ds_objective_examination_ft)
                       OR (l_tbl_p1_text(j).field_name = 'DIAGNOSTIC_TESTS' AND
                        l_ds_internal_name = pk_orders_constant.g_ds_executed_tests_ft)
                       OR (l_tbl_p1_text(j)
                       .field_name = 'HISTORY' AND l_ds_internal_name = pk_orders_constant.g_ds_personal_history)
                       OR
                       (l_tbl_p1_text(j).field_name = 'NOTES' AND l_ds_internal_name = pk_orders_constant.g_ds_notes)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => l_tbl_p1_text(j).text,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_text(j).text,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                     WHEN l_ds_internal_name = pk_orders_constant.g_ds_referral_reason THEN
                                                                                                      CASE l_reason_mandatory
                                                                                                          WHEN pk_alert_constant.g_yes THEN
                                                                                                           pk_orders_constant.g_component_mandatory
                                                                                                          ELSE
                                                                                                           pk_orders_constant.g_component_active
                                                                                                      END
                                                                                                     WHEN l_ds_internal_name = pk_orders_constant.g_ds_medication THEN
                                                                                                      CASE l_medication_available
                                                                                                          WHEN pk_alert_constant.g_no THEN
                                                                                                           pk_orders_constant.g_component_inactive
                                                                                                          ELSE
                                                                                                           pk_orders_constant.g_component_active
                                                                                                      END
                                                                                                     WHEN l_ds_internal_name = pk_orders_constant.g_ds_vital_signs THEN
                                                                                                      CASE l_vital_signs_available
                                                                                                          WHEN pk_alert_constant.g_no THEN
                                                                                                           pk_orders_constant.g_component_inactive
                                                                                                          ELSE
                                                                                                           pk_orders_constant.g_component_active
                                                                                                      END
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    
        --Obtain the diagnosis
        FETCH c_diagnosis BULK COLLECT
            INTO l_tbl_p1_diagnosis;
    
        IF l_tbl_p1_diagnosis.count > 0
        THEN
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_diagnosis
                THEN
                    FOR j IN l_tbl_p1_diagnosis.first .. l_tbl_p1_diagnosis.last
                    LOOP
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_tbl_p1_diagnosis(j).id_alert_diagnosis),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_diagnosis(j).title,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                  l_diagnosis_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
    
        --Obtain the problems
        FETCH c_problem BULK COLLECT
            INTO l_tbl_p1_problems;
    
        IF l_tbl_p1_problems.count > 0
        THEN
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_problems_addressed
                THEN
                    FOR j IN l_tbl_p1_problems.first .. l_tbl_p1_problems.last
                    LOOP
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => to_char(l_tbl_p1_problems(j).id_alert_diagnosis),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_tbl_p1_problems(j).title,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_P1_ORDER_FOR_EDITION',
                                              o_error);
            RETURN t_tbl_ds_get_value();
    END get_p1_order_for_edition;

    FUNCTION get_control_validation
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_root_name   IN VARCHAR2,
        i_action      IN NUMBER,
        i_flg_origin  IN VARCHAR2,
        i_flg_edition IN VARCHAR2,
        i_tbl_id_pk   IN table_number,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_value_desc  IN table_table_varchar,
        i_idx         IN NUMBER,
        io_tbl_result IN OUT t_tbl_ds_get_value,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ds_internal_name ds_component.internal_name%TYPE;
        l_id_ds_component  ds_component.id_ds_component%TYPE;
    
        l_ds_internal_name_control   ds_component.internal_name%TYPE;
        l_id_ds_component_control    ds_component.id_ds_component%TYPE;
        l_id_ds_cmpt_mkt_rel_control ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
    
        l_tbl_possible_mandatory_items table_varchar := table_varchar(pk_orders_constant.g_ds_quantity,
                                                                      pk_orders_constant.g_ds_laterality,
                                                                      pk_orders_constant.g_ds_complementary_information,
                                                                      pk_orders_constant.g_ds_referral_consent,
                                                                      pk_orders_constant.g_ds_financial_entity,
                                                                      pk_orders_constant.g_ds_health_coverage_plan,
                                                                      pk_orders_constant.g_ds_referral_reason,
                                                                      pk_orders_constant.g_ds_diagnosis,
                                                                      pk_orders_constant.g_ds_family_relationship_spec);
    
        l_tbl_configured_items   table_varchar := table_varchar();
        l_tbl_id_ds_cmpt_mkt_rel table_number;
    
        l_complementary_info_mandatory VARCHAR2(1) := pk_alert_constant.g_no;
        l_consent_mandatory            sys_config.value%TYPE := pk_sysconfig.get_config('P1_CONSENT', i_prof);
        l_reason_mandatory             VARCHAR2(1) := pk_alert_constant.g_yes;
        l_home_value                   VARCHAR2(10);
        l_priority_value               VARCHAR2(10);
        l_diagnosis_mandatory          sys_config.value%TYPE := pk_sysconfig.get_config(pk_ref_constant.g_ref_diag_mandatory,
                                                                                        i_prof);
        l_laterality_mandatory         VARCHAR2(1) := pk_alert_constant.g_no;
        l_msg                          VARCHAR2(4000);
        l_msg_title                    VARCHAR2(4000);
        l_button                       VARCHAR2(4000);
        l_tbl_records_number           table_number := table_number();
    
        l_id_market      market.id_market%TYPE;
        l_flg_validation VARCHAR2(1) := pk_orders_constant.g_component_valid;
    BEGIN
    
        g_error     := 'GET INSTITUTION MARKET';
        l_id_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        --Check which possible mandatory items are available on the form
        SELECT dc.internal_name_child, dc.id_ds_cmpt_mkt_rel
          BULK COLLECT
          INTO l_tbl_configured_items, l_tbl_id_ds_cmpt_mkt_rel
          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_patient        => NULL,
                                             i_component_name => i_root_name,
                                             i_action         => NULL)) dc
          JOIN (SELECT *
                  FROM TABLE(l_tbl_possible_mandatory_items)) t
            ON t.column_value = dc.internal_name_child;
    
        --Get the information of the element that will store the mandatory ids (DS_TBL_MANDATORY_ITEMS)
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
            THEN
                l_ds_internal_name_control   := l_ds_internal_name;
                l_id_ds_component_control    := l_id_ds_component;
                l_id_ds_cmpt_mkt_rel_control := i_tbl_mkt_rel(i);
                EXIT;
            END IF;
        END LOOP;
    
        IF i_action <> g_p1_edit_action
        THEN
            IF l_id_ds_cmpt_mkt_rel_control IS NOT NULL
            THEN
                --Run through all the elements of the form (for each selected item), and for each element that might be mandatory
                --check if it is indeed mandatory
                IF l_tbl_configured_items.exists(1)
                THEN
                    l_complementary_info_mandatory := pk_alert_constant.g_no;
                
                    FOR i IN l_tbl_configured_items.first .. l_tbl_configured_items.last
                    LOOP
                        IF l_tbl_configured_items(i) = pk_orders_constant.g_ds_quantity
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name = l_tbl_configured_items(i)
                                   AND i_value(j) (1) IS NULL
                                THEN
                                    l_flg_validation := pk_orders_constant.g_component_error;
                                    EXIT;
                                END IF;
                            END LOOP;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_complementary_information
                        THEN
                            IF i_root_name = pk_orders_utils.g_p1_lab_test
                            THEN
                                IF i_flg_edition = pk_alert_constant.g_yes
                                   OR i_action = pk_p1_ext_sys.g_p1_request_from_orders_area
                                   OR i_flg_origin = pk_p1_ext_sys.g_p1_orders_origin
                                THEN
                                    SELECT nvl(ac.flg_mandatory_info, pk_alert_constant.g_no)
                                      INTO l_complementary_info_mandatory
                                      FROM analysis_req_det ard
                                      LEFT JOIN analysis_codification ac
                                        ON ac.id_analysis = ard.id_analysis
                                       AND ac.id_sample_type = ard.id_sample_type
                                       AND ac.flg_available = pk_alert_constant.g_yes
                                     WHERE ard.id_analysis_req_det = i_tbl_id_pk(i_idx)
                                       AND rownum = 1;
                                ELSE
                                    SELECT nvl(ac.flg_mandatory_info, pk_alert_constant.g_no)
                                      INTO l_complementary_info_mandatory
                                      FROM analysis_instit_soft ais
                                      LEFT JOIN analysis_codification ac
                                        ON ac.id_analysis = ais.id_analysis
                                       AND ac.id_sample_type = ais.id_sample_type
                                       AND ac.flg_available = pk_alert_constant.g_yes
                                     WHERE ais.id_analysis_instit_soft = i_tbl_id_pk(i_idx)
                                       AND rownum = 1;
                                END IF;
                            END IF;
                        
                            IF l_complementary_info_mandatory = pk_alert_constant.g_yes
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                                
                                    IF l_ds_internal_name = l_tbl_configured_items(i)
                                       AND i_value(j) (1) IS NULL
                                    THEN
                                        l_flg_validation := pk_orders_constant.g_component_error;
                                        EXIT;
                                    END IF;
                                END LOOP;
                            END IF;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_referral_consent
                              AND l_consent_mandatory = pk_alert_constant.g_yes
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name = l_tbl_configured_items(i)
                                   AND i_value(j) (1) IS NULL
                                THEN
                                    l_flg_validation := pk_orders_constant.g_component_error;
                                    EXIT;
                                END IF;
                            END LOOP;
                        ELSIF l_tbl_configured_items(i) IN
                              (pk_orders_constant.g_ds_financial_entity, pk_orders_constant.g_ds_health_coverage_plan)
                              AND l_id_market = pk_alert_constant.g_id_market_pt
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name = l_tbl_configured_items(i)
                                   AND i_value(j) (1) IS NULL
                                THEN
                                    l_flg_validation := pk_orders_constant.g_component_error;
                                    EXIT;
                                END IF;
                            END LOOP;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_referral_reason
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                                THEN
                                    l_home_value := nvl(i_value(j) (1), pk_alert_constant.g_no);
                                
                                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_priority
                                THEN
                                    l_priority_value := nvl(i_value(j) (1), pk_alert_constant.g_no);
                                END IF;
                            END LOOP;
                        
                            IF NOT
                                pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_type             => CASE i_root_name
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_appointment THEN
                                                                                                'C'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_lab_test THEN
                                                                                                'A'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_intervention THEN
                                                                                                'P'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_imaging_exam THEN
                                                                                                'I'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_other_exam THEN
                                                                                                'E'
                                                                                               WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                                'F'
                                                                                           END,
                                                                     i_home             => table_varchar(l_home_value),
                                                                     i_priority         => table_varchar(l_priority_value),
                                                                     o_reason_mandatory => l_reason_mandatory,
                                                                     o_error            => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF l_reason_mandatory = pk_alert_constant.g_yes
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                                
                                    IF l_ds_internal_name = l_tbl_configured_items(i)
                                       AND i_value(j) (1) IS NULL
                                    THEN
                                        l_flg_validation := pk_orders_constant.g_component_error;
                                        EXIT;
                                    END IF;
                                END LOOP;
                            END IF;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_diagnosis
                              AND l_diagnosis_mandatory = pk_alert_constant.g_yes
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name = l_tbl_configured_items(i)
                                   AND i_value(j) (1) IS NULL
                                THEN
                                    l_flg_validation := pk_orders_constant.g_component_error;
                                    EXIT;
                                END IF;
                            END LOOP;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_laterality
                              AND i_root_name <> pk_orders_utils.g_p1_lab_test
                        THEN
                            IF i_flg_edition = pk_alert_constant.g_no
                            THEN
                                IF NOT pk_mcdt.check_mandatory_lat(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_mcdt_type => CASE i_root_name
                                                                                      WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                       pk_ref_constant.g_p1_type_e
                                                                                      WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                       pk_ref_constant.g_p1_type_i
                                                                                      WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                       pk_ref_constant.g_p1_type_p
                                                                                      WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                       pk_ref_constant.g_p1_type_f
                                                                                  END,
                                                                   i_mcdt      => table_number(i_tbl_id_pk(i_idx)),
                                                                   o_flg_show  => l_laterality_mandatory,
                                                                   o_msg       => l_msg,
                                                                   o_msg_title => l_msg_title,
                                                                   o_button    => l_button,
                                                                   o_error     => o_error)
                                THEN
                                    RAISE g_exception;
                                END IF;
                            ELSE
                                IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                                THEN
                                    SELECT erd.id_exam
                                      BULK COLLECT
                                      INTO l_tbl_records_number
                                      FROM exam_req_det erd
                                     WHERE erd.id_exam_req_det = i_tbl_id_pk(i_idx);
                                ELSIF i_root_name = pk_orders_utils.g_p1_intervention
                                THEN
                                    SELECT ipd.id_intervention
                                      BULK COLLECT
                                      INTO l_tbl_records_number
                                      FROM interv_presc_det ipd
                                     WHERE ipd.id_interv_presc_det = i_tbl_id_pk(i_idx);
                                ELSIF i_root_name = pk_orders_utils.g_p1_rehab
                                THEN
                                    SELECT rp.id_rehab_area_interv
                                      BULK COLLECT
                                      INTO l_tbl_records_number
                                      FROM rehab_presc rp
                                     WHERE rp.id_rehab_presc = i_tbl_id_pk(i_idx);
                                END IF;
                            
                                IF NOT pk_mcdt.check_mandatory_lat(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_mcdt_type => CASE i_root_name
                                                                                      WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                       pk_ref_constant.g_p1_type_e
                                                                                      WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                       pk_ref_constant.g_p1_type_i
                                                                                      WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                       pk_ref_constant.g_p1_type_p
                                                                                      WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                       pk_ref_constant.g_p1_type_f
                                                                                  END,
                                                                   i_mcdt      => l_tbl_records_number,
                                                                   o_flg_show  => l_laterality_mandatory,
                                                                   o_msg       => l_msg,
                                                                   o_msg_title => l_msg_title,
                                                                   o_button    => l_button,
                                                                   o_error     => o_error)
                                THEN
                                    RAISE g_exception;
                                END IF;
                            END IF;
                            IF l_laterality_mandatory = pk_alert_constant.g_yes
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                                
                                    IF l_ds_internal_name = l_tbl_configured_items(i)
                                       AND i_value(j) (1) IS NULL
                                    THEN
                                        l_flg_validation := pk_orders_constant.g_component_error;
                                        EXIT;
                                    END IF;
                                END LOOP;
                            END IF;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_family_relationship_spec
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name = pk_orders_constant.g_ds_family_relationship
                                THEN
                                    IF i_value(j) (1) = to_char(44) --OPTION 'OTHER'
                                    THEN
                                        FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                        LOOP
                                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                                        
                                            IF l_ds_internal_name = l_tbl_configured_items(i)
                                               AND i_value(j) (1) IS NULL
                                            THEN
                                                l_flg_validation := pk_orders_constant.g_component_error;
                                                EXIT;
                                            END IF;
                                        END LOOP;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;
                ELSE
                    l_flg_validation := pk_orders_constant.g_component_error;
                END IF;
            
                --Construct the object, for each i_tbl_id_pk, with the mandatory items
                io_tbl_result.extend();
                io_tbl_result(io_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => l_id_ds_cmpt_mkt_rel_control,
                                                                         id_ds_component    => l_id_ds_component_control,
                                                                         internal_name      => l_ds_internal_name_control,
                                                                         VALUE              => NULL,
                                                                         value_clob         => NULL,
                                                                         min_value          => NULL,
                                                                         max_value          => NULL,
                                                                         desc_value         => NULL,
                                                                         desc_clob          => NULL,
                                                                         id_unit_measure    => NULL,
                                                                         desc_unit_measure  => NULL,
                                                                         flg_validation     => l_flg_validation,
                                                                         err_msg            => NULL,
                                                                         flg_event_type     => 'A',
                                                                         flg_multi_status   => NULL,
                                                                         idx                => i_idx);
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
                                              'GET_CONTROL_VALIDATION',
                                              o_error);
            RETURN FALSE;
    END get_control_validation;

    FUNCTION get_p1_order_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
        l_min_val            ds_cmpt_mkt_rel.min_value%TYPE;
        l_max_val            ds_cmpt_mkt_rel.max_value%TYPE;
    
        l_ds_internal_name_aux ds_component.internal_name%TYPE;
        l_id_ds_component_aux  ds_component.id_ds_component%TYPE;
        l_flg_edition          VARCHAR2(1) := pk_alert_constant.g_no;
        l_flg_origin           VARCHAR2(1);
    
        --Variables for destination facility
        l_dest_facility      NUMBER(24);
        l_dest_facility_desc VARCHAR2(1000);
        l_records            VARCHAR2(1000);
    
        l_tbl_analysis_sample_type table_varchar;
    
        l_tbl_id_rehab_interv table_number;
    
        l_reason_mandatory             VARCHAR2(1) := pk_alert_constant.g_yes;
        l_diagnosis_mandatory          sys_config.value%TYPE;
        l_consent_mandatory            sys_config.value%TYPE;
        l_laterality_mandatory         VARCHAR2(1) := pk_alert_constant.g_no;
        l_tbl_compl_info_mandatory     table_varchar := table_varchar();
        l_complementary_info_mandatory VARCHAR2(1) := pk_alert_constant.g_no;
    
        l_flg_laterality VARCHAR2(1 CHAR) := NULL;
    
        l_medication_available  sys_config.value%TYPE;
        l_vital_signs_available sys_config.value%TYPE;
    
        l_home_value     VARCHAR2(10);
        l_priority_value VARCHAR2(10);
        l_priority_desc  VARCHAR2(100 CHAR);
    
        l_all_items_selected VARCHAR2(1) := pk_alert_constant.g_yes;
    
        l_id_clinical_service p1_speciality.id_speciality%TYPE;
    
        l_dt_patient_birth VARCHAR2(100);
        l_dt_onset         VARCHAR2(100);
        l_timezone         timezone_region.timezone_region%TYPE;
        l_onset_valid      VARCHAR2(1);
    
        l_reason_desc VARCHAR2(4000);
    
        l_id_financial_entity     NUMBER(24);
        l_id_health_coverage_plan NUMBER(24);
        l_beneficiary_number      VARCHAR2(1000 CHAR);
        l_exemption_desc          VARCHAR2(1000 CHAR);
        l_id_exemption            NUMBER(24);
        l_id_pat_health_plan      NUMBER(24);
    
        l_import_data_mode          BOOLEAN := FALSE;
        l_data_export               table_table_number := table_table_number();
        l_tbl_p1_data_export_ids    table_number := table_number();
        l_tbl_p1_data_export_values table_number := table_number();
    
        --Caregiver info
        l_has_caregiver_fields BOOLEAN := FALSE;
        l_id_pat_relative      NUMBER(24);
        l_id_fam_rel           p1_external_request.id_fam_rel%TYPE;
        l_fam_rel_desc         VARCHAR2(200);
        l_fam_res_spec         VARCHAR2(200);
        l_first_fam_name       VARCHAR2(4000);
        l_middle_name          VARCHAR2(4000);
        l_name                 VARCHAR2(4000);
    
        l_msg       VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_button    VARCHAR2(4000);
    
        l_tbl_records table_number;
        l_tbl_aux     table_number;
    
        l_id_market market.id_market%TYPE;
    
        --PATIENT INFORMATION
        l_pat_name          patient.name%TYPE;
        l_gender            patient.gender%TYPE;
        l_desc_gender       VARCHAR2(100);
        l_dt_birth          VARCHAR2(100);
        l_dt_deceased       VARCHAR2(100);
        l_flg_migrator      pat_soc_attributes.flg_migrator%TYPE;
        l_id_country_nation country.alpha2_code%TYPE;
        l_sns               pat_health_plan.num_health_plan%TYPE;
        l_valid_sns         VARCHAR2(100);
        l_flg_occ_disease   VARCHAR2(100);
        l_flg_independent   VARCHAR2(100);
        --L_num_health_plan          pat_health_plan.num_health_plan%TYPE;
        l_hp_entity VARCHAR2(100);
        --L_id_health_plan           NUMBER;
        l_flg_recm              VARCHAR2(100);
        l_main_phone            VARCHAR2(100);
        l_hp_alpha2_code        VARCHAR2(100);
        l_hp_country_desc       VARCHAR2(100);
        l_hp_national_ident_nbr VARCHAR2(100);
        l_hp_dt_effective       VARCHAR2(100);
        l_valid_hp              VARCHAR2(100);
        l_flg_type_hp           health_plan.flg_type%TYPE;
        l_hp_id_content         health_plan.id_content%TYPE;
        l_hp_inst_ident_nbr     pat_health_plan.inst_identifier_number%TYPE;
        l_hp_inst_ident_desc    pat_health_plan.inst_identifier_desc%TYPE;
        l_hp_dt_valid           VARCHAR2(100);
    
        l_tbl_p1_priority       t_tbl_core_domain;
        l_default_priority      VARCHAR2(10);
        l_default_priority_desc VARCHAR2(100 CHAR);
    
        l_tbl_mandatory_items table_varchar := table_varchar();
        l_mandatory_items     VARCHAR2(1000) := NULL;
    
        l_tbl_id_pk table_number;
    BEGIN
        --When 'deselecting' all items on the viewer, this function must return an empty object
        IF i_tbl_id_pk.count = 0
           AND i_root_name NOT IN (pk_orders_utils.g_p1_appointment)
        THEN
            RETURN t_tbl_ds_get_value();
        END IF;
    
        g_error     := 'GET INSTITUTION MARKET';
        l_id_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        g_error           := 'GET PRIORITY LIST';
        l_tbl_p1_priority := pk_ref_list.get_priority_list(i_lang, i_prof);
    
        g_error := 'DETERMINING REQUEST ORIGIN';
        IF i_action NOT IN (pk_p1_ext_sys.g_p1_request_from_orders_area)
           OR i_action IS NULL
        THEN
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_p1_origin_info
                THEN
                    l_flg_origin := nvl(i_value(i) (1), pk_p1_ext_sys.g_p1_referrals_origin);
                END IF;
            END LOOP;
        ELSE
            l_flg_origin := pk_p1_ext_sys.g_p1_orders_origin;
        END IF;
    
        g_error := 'CONSTRUCTING P1 FORM';
        IF i_action IS NULL
           OR i_action IN (pk_dyn_form_constant.get_submit_action, -1, pk_p1_ext_sys.g_p1_request_from_orders_area)
        THEN
            IF i_root_name = pk_orders_utils.g_p1_lab_test
            THEN
                IF i_action NOT IN (pk_p1_ext_sys.g_p1_request_from_orders_area)
                   AND l_flg_origin <> pk_p1_ext_sys.g_p1_orders_origin
                THEN
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        --The dummy number will only hold a value when editing
                        IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            IF i_value(i) (1) IS NOT NULL
                            THEN
                                l_flg_edition := pk_alert_constant.g_yes;
                            END IF;
                        END IF;
                    END LOOP;
                ELSE
                    l_flg_edition := pk_alert_constant.g_no;
                
                    IF i_action = pk_p1_ext_sys.g_p1_request_from_orders_area
                    THEN
                        BEGIN
                            SELECT t.domain_value, decode(t.domain_value, NULL, NULL, t.desc_domain)
                              INTO l_priority_value, l_priority_desc
                              FROM analysis_req_det ard
                              JOIN (SELECT *
                                      FROM TABLE(l_tbl_p1_priority)) t
                                ON (t.domain_value = ard.flg_urgency OR
                                   (t.domain_value IN ('Y', 'U') AND ard.flg_urgency IN ('U', 'E')))
                             WHERE ard.id_analysis_req_det = i_tbl_id_pk(i_idx)
                               AND rownum = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_priority_value := NULL;
                                l_priority_desc  := NULL;
                        END;
                    END IF;
                END IF;
            
                IF l_flg_edition = pk_alert_constant.g_yes
                   OR i_action = pk_p1_ext_sys.g_p1_request_from_orders_area
                   OR l_flg_origin = pk_p1_ext_sys.g_p1_orders_origin
                THEN
                    WITH cod AS
                     (SELECT ac.id_analysis,
                             ac.id_sample_type,
                             ac.flg_mandatory_info,
                             row_number() over(PARTITION BY ac.id_analysis, ac.id_sample_type ORDER BY ac.id_analysis_codification ASC) AS rn
                        FROM analysis_codification ac
                        JOIN analysis_req_det ard
                          ON ard.id_analysis = ac.id_analysis
                         AND ard.id_sample_type = ac.id_sample_type
                         AND ard.id_analysis_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                           FROM TABLE(i_tbl_id_pk) t)
                       WHERE ac.flg_available = pk_alert_constant.g_yes)
                    SELECT ast.id_content, nvl(c.flg_mandatory_info, pk_alert_constant.g_no)
                      BULK COLLECT
                      INTO l_tbl_analysis_sample_type, l_tbl_compl_info_mandatory
                      FROM analysis_req_det ard
                      JOIN analysis_sample_type ast
                        ON ast.id_analysis = ard.id_analysis
                       AND ast.id_sample_type = ard.id_sample_type
                       AND ast.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN cod c
                        ON c.id_analysis = ard.id_analysis
                       AND c.id_sample_type = ard.id_sample_type
                       AND c.rn = 1
                     WHERE ard.id_analysis_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                         FROM TABLE(i_tbl_id_pk) t);
                
                ELSE
                    WITH cod AS
                     (SELECT ac.id_analysis,
                             ac.id_sample_type,
                             ac.flg_mandatory_info,
                             row_number() over(PARTITION BY ac.id_analysis, ac.id_sample_type ORDER BY ac.id_analysis_codification ASC) AS rn
                        FROM analysis_codification ac
                        JOIN analysis_instit_soft ais
                          ON ais.id_analysis = ac.id_analysis
                         AND ais.id_sample_type = ac.id_sample_type
                         AND ais.id_analysis_instit_soft IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                               FROM TABLE(i_tbl_id_pk) t)
                       WHERE ac.flg_available = pk_alert_constant.g_yes)
                    SELECT ast.id_content, nvl(c.flg_mandatory_info, pk_alert_constant.g_no)
                      BULK COLLECT
                      INTO l_tbl_analysis_sample_type, l_tbl_compl_info_mandatory
                      FROM analysis_instit_soft ais
                      JOIN analysis_sample_type ast
                        ON ast.id_analysis = ais.id_analysis
                       AND ast.id_sample_type = ais.id_sample_type
                       AND ast.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN cod c
                        ON c.id_analysis = ais.id_analysis
                       AND c.id_sample_type = ais.id_sample_type
                       AND c.rn = 1
                     WHERE ais.id_analysis_instit_soft IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                             FROM TABLE(i_tbl_id_pk) t);
                
                    FOR i IN l_tbl_compl_info_mandatory.first .. l_tbl_compl_info_mandatory.last
                    LOOP
                        IF l_tbl_compl_info_mandatory(i) = pk_alert_constant.g_yes
                        THEN
                            l_complementary_info_mandatory := l_tbl_compl_info_mandatory(i);
                        END IF;
                    END LOOP;
                END IF;
            ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                  AND i_action IN (pk_p1_ext_sys.g_p1_request_from_orders_area)
            THEN
                SELECT erd.flg_laterality
                  INTO l_flg_laterality
                  FROM exam_req_det erd
                 WHERE erd.id_exam_req_det = i_tbl_id_pk(i_idx);
            
                BEGIN
                    SELECT t.domain_value, decode(t.domain_value, NULL, NULL, t.desc_domain)
                      INTO l_priority_value, l_priority_desc
                      FROM exam_req_det erd
                      JOIN (SELECT *
                              FROM TABLE(l_tbl_p1_priority)) t
                        ON (t.domain_value = erd.flg_priority OR
                           (t.domain_value IN ('Y', 'U') AND erd.flg_priority IN ('U', 'E')))
                     WHERE erd.id_exam_req_det = i_tbl_id_pk(i_idx)
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_priority_value := NULL;
                        l_priority_desc  := NULL;
                END;
            
            ELSIF i_root_name IN (pk_orders_utils.g_p1_intervention)
                  AND i_action IN (pk_p1_ext_sys.g_p1_request_from_orders_area)
            THEN
                SELECT ipd.flg_laterality
                  INTO l_flg_laterality
                  FROM interv_presc_det ipd
                 WHERE ipd.id_interv_presc_det = i_tbl_id_pk(i_idx);
            
                BEGIN
                    SELECT t.domain_value, decode(t.domain_value, NULL, NULL, t.desc_domain)
                      INTO l_priority_value, l_priority_desc
                      FROM interv_presc_det ipd
                      JOIN (SELECT *
                              FROM TABLE(l_tbl_p1_priority)) t
                        ON (t.domain_value = ipd.flg_prty OR
                           (t.domain_value IN ('Y', 'U') AND ipd.flg_prty IN ('U', 'E')))
                     WHERE ipd.id_interv_presc_det = i_tbl_id_pk(i_idx)
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_priority_value := NULL;
                        l_priority_desc  := NULL;
                END;
            ELSIF i_root_name = pk_orders_utils.g_p1_rehab
            THEN
                SELECT r.id_intervention
                  BULK COLLECT
                  INTO l_tbl_id_rehab_interv
                  FROM rehab_area_interv r
                 WHERE r.id_rehab_area_interv IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                    FROM TABLE(i_tbl_id_pk) t);
            
                IF i_action IN (pk_p1_ext_sys.g_p1_request_from_orders_area)
                THEN
                    SELECT rp.flg_laterality
                      INTO l_flg_laterality
                      FROM rehab_presc rp
                      JOIN rehab_sch_need rsn
                        ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                     WHERE rp.id_rehab_presc = i_tbl_id_pk(i_idx);
                
                    BEGIN
                        SELECT t.domain_value, decode(t.domain_value, NULL, NULL, t.desc_domain)
                          INTO l_priority_value, l_priority_desc
                          FROM rehab_presc rp
                          JOIN rehab_sch_need rsn
                            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                          JOIN (SELECT *
                                  FROM TABLE(l_tbl_p1_priority)) t
                            ON (t.domain_value = rsn.flg_priority OR
                               (t.domain_value IN ('Y', 'U') AND rsn.flg_priority IN ('U', 'M')))
                         WHERE rp.id_rehab_presc = i_tbl_id_pk(i_idx)
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_priority_value := NULL;
                            l_priority_desc  := NULL;
                    END;
                END IF;
            END IF;
        
            IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                               pk_orders_utils.g_p1_other_exam,
                               pk_orders_utils.g_p1_intervention,
                               pk_orders_utils.g_p1_rehab)
            THEN
                IF i_action NOT IN (pk_p1_ext_sys.g_p1_request_from_orders_area)
                   AND l_flg_origin <> pk_p1_ext_sys.g_p1_orders_origin
                THEN
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        --The dummy number will only hold a value when editing
                        IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            IF i_value(i) (1) IS NOT NULL
                            THEN
                                l_flg_edition := pk_alert_constant.g_yes;
                            END IF;
                        END IF;
                    END LOOP;
                ELSE
                    l_flg_edition := pk_alert_constant.g_no;
                END IF;
            END IF;
        END IF;
    
        IF (i_action IS NULL OR i_action IN (-1, pk_p1_ext_sys.g_p1_request_from_orders_area))
        THEN
            --NEW FORM
            IF l_flg_origin = pk_p1_ext_sys.g_p1_orders_origin
            THEN
                IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                THEN
                    SELECT erd.id_exam
                      BULK COLLECT
                      INTO l_tbl_id_pk
                      FROM exam_req_det erd
                      JOIN (SELECT column_value, rownum AS rn /*+opt_estimate(table t rows=1)*/
                              FROM TABLE(i_tbl_id_pk)) t
                        ON t.column_value = erd.id_exam_req_det
                     WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate(table tt rows=1)*/
                                                     FROM TABLE(i_tbl_id_pk) tt)
                     ORDER BY t.rn;
                ELSIF i_root_name = pk_orders_utils.g_p1_intervention
                THEN
                    SELECT ipd.id_intervention
                      BULK COLLECT
                      INTO l_tbl_id_pk
                      FROM interv_presc_det ipd
                      JOIN (SELECT column_value, rownum AS rn /*+opt_estimate(table t rows=1)*/
                              FROM TABLE(i_tbl_id_pk)) t
                        ON t.column_value = ipd.id_interv_presc_det
                     WHERE ipd.id_interv_presc_det IN (SELECT * /*+opt_estimate(table tt rows=1)*/
                                                         FROM TABLE(i_tbl_id_pk) tt)
                     ORDER BY t.rn;
                END IF;
            ELSE
                l_tbl_id_pk := i_tbl_id_pk;
            END IF;
        
            IF i_root_name IN
               (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam, pk_orders_utils.g_p1_intervention)
            THEN
                --Check destination facility            
                IF i_root_name = pk_orders_utils.g_p1_intervention
                THEN
                    SELECT t.domain_value, t.desc_domain
                      INTO l_dest_facility, l_dest_facility_desc
                      FROM TABLE(pk_p1_interv.get_interv_inst(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_interventions => to_char(i_tbl_id_pk(i_idx)))) t
                     WHERE rownum = 1;
                ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                THEN
                    SELECT t.domain_value, t.desc_domain
                      INTO l_dest_facility, l_dest_facility_desc
                      FROM TABLE(pk_p1_exam.get_exam_inst(i_lang  => i_lang,
                                                          i_prof  => i_prof,
                                                          i_exams => to_char(i_tbl_id_pk(i_idx)))) t
                     WHERE rownum = 1;
                END IF;
            ELSIF i_root_name = pk_orders_utils.g_p1_lab_test
            THEN
                SELECT t.domain_value, t.desc_domain
                  INTO l_dest_facility, l_dest_facility_desc
                  FROM TABLE(pk_p1_analysis.get_analysis_inst(i_lang     => i_lang,
                                                              i_prof     => i_prof,
                                                              i_analysis => to_char(i_tbl_id_pk(i_idx)))) t
                 WHERE rownum = 1;
            ELSIF i_root_name = pk_orders_utils.g_p1_rehab
            THEN
                SELECT t.domain_value, t.desc_domain
                  INTO l_dest_facility, l_dest_facility_desc
                  FROM TABLE(pk_p1_interv.get_rehab_inst(i_lang   => i_lang,
                                                         i_prof   => i_prof,
                                                         i_rehabs => to_char(i_tbl_id_pk(i_idx)))) t
                 WHERE rownum = 1;
            END IF;
        
            --Check if the Reason field should be mandatory
            IF NOT pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_type             => CASE i_root_name
                                                                                  WHEN pk_orders_utils.g_p1_appointment THEN
                                                                                   'C'
                                                                                  WHEN pk_orders_utils.g_p1_lab_test THEN
                                                                                   'A'
                                                                                  WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                   'P'
                                                                                  WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                   'I'
                                                                                  WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                   'E'
                                                                                  WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                   'F'
                                                                              END,
                                                        i_home             => table_varchar(pk_alert_constant.g_no),
                                                        i_priority         => table_varchar(nvl(l_priority_value,
                                                                                                pk_alert_constant.g_no)),
                                                        o_reason_mandatory => l_reason_mandatory,
                                                        o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --Check if field consent is mandatory
            l_consent_mandatory := pk_sysconfig.get_config('P1_CONSENT', i_prof);
        
            --Check if field diagnosis is mandatory
            l_diagnosis_mandatory := pk_sysconfig.get_config(pk_ref_constant.g_ref_diag_mandatory, i_prof);
        
            --Check if the field laterality is mandatory
            IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                               pk_orders_utils.g_p1_other_exam,
                               pk_orders_utils.g_p1_intervention,
                               pk_orders_utils.g_p1_rehab)
            THEN
                IF NOT pk_mcdt.check_mandatory_lat(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_mcdt_type => CASE i_root_name
                                                                      WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                       pk_ref_constant.g_p1_type_e
                                                                      WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                       pk_ref_constant.g_p1_type_i
                                                                      WHEN pk_orders_utils.g_p1_intervention THEN
                                                                       pk_ref_constant.g_p1_type_p
                                                                      WHEN pk_orders_utils.g_p1_rehab THEN
                                                                       pk_ref_constant.g_p1_type_f
                                                                  END,
                                                   i_mcdt      => table_number(l_tbl_id_pk(i_idx)),
                                                   o_flg_show  => l_laterality_mandatory,
                                                   o_msg       => l_msg,
                                                   o_msg_title => l_msg_title,
                                                   o_button    => l_button,
                                                   o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            --Check if field Medication is available                           
            l_medication_available := pk_sysconfig.get_config('REF_MEDICATION_ENABLE', i_prof);
        
            --Check if the field vital signs is available
            l_vital_signs_available := pk_sysconfig.get_config('REF_VITALSIGNS_ENABLE', i_prof);
        
            --Check caregiver info
            --EXEMPTION INFO
            --HEALTH INSURANCE INFO
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name IN (pk_orders_constant.g_ds_family_relationship,
                                          pk_orders_constant.g_ds_family_relationship_spec,
                                          pk_orders_constant.g_ds_lastname,
                                          pk_orders_constant.g_ds_middlename,
                                          pk_orders_constant.g_ds_nombres)
                THEN
                    l_has_caregiver_fields := TRUE;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_exemption
                THEN
                    IF NOT pk_orders_utils.get_pat_default_exemption(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_patient     => i_patient,
                                                                     i_current_date   => NULL,
                                                                     o_id_exemption   => l_id_exemption,
                                                                     o_exemption_desc => l_exemption_desc)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_financial_entity)
                THEN
                    IF l_id_market = pk_alert_constant.g_id_market_pt
                    THEN
                        IF NOT pk_adt.get_pat_info(i_lang                    => i_lang,
                                                   i_id_patient              => i_patient,
                                                   i_prof                    => i_prof,
                                                   i_id_episode              => i_episode,
                                                   i_flg_info_for_medication => CASE l_id_market
                                                                                    WHEN pk_alert_constant.g_id_market_pt THEN
                                                                                     pk_alert_constant.g_yes --To fetch the SNS
                                                                                    ELSE
                                                                                     NULL
                                                                                END,
                                                   o_name                    => l_pat_name,
                                                   o_gender                  => l_gender,
                                                   o_desc_gender             => l_desc_gender,
                                                   o_dt_birth                => l_dt_birth,
                                                   o_dt_deceased             => l_dt_deceased,
                                                   o_flg_migrator            => l_flg_migrator,
                                                   o_id_country_nation       => l_id_country_nation,
                                                   o_sns                     => l_sns,
                                                   o_valid_sns               => l_valid_sns,
                                                   o_flg_occ_disease         => l_flg_occ_disease,
                                                   o_flg_independent         => l_flg_independent,
                                                   o_num_health_plan         => l_beneficiary_number,
                                                   o_hp_entity               => l_hp_entity,
                                                   o_id_health_plan          => l_id_health_coverage_plan,
                                                   o_flg_recm                => l_flg_recm,
                                                   o_main_phone              => l_main_phone,
                                                   o_hp_alpha2_code          => l_hp_alpha2_code,
                                                   o_hp_country_desc         => l_hp_country_desc,
                                                   o_hp_national_ident_nbr   => l_hp_national_ident_nbr,
                                                   o_hp_dt_effective         => l_hp_dt_effective,
                                                   o_valid_hp                => l_valid_hp,
                                                   o_flg_type_hp             => l_flg_type_hp,
                                                   o_hp_id_content           => l_hp_id_content,
                                                   o_hp_inst_ident_nbr       => l_hp_inst_ident_nbr,
                                                   o_hp_inst_ident_desc      => l_hp_inst_ident_desc,
                                                   o_hp_dt_valid             => l_hp_dt_valid,
                                                   o_error                   => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        IF l_beneficiary_number IS NOT NULL
                           AND l_valid_hp = pk_alert_constant.g_yes
                        THEN
                            BEGIN
                                SELECT hpe.id_health_plan_entity, php.id_pat_health_plan
                                  INTO l_id_financial_entity, l_id_pat_health_plan
                                  FROM pat_health_plan php
                                  JOIN health_plan hp
                                    ON php.id_health_plan = hp.id_health_plan
                                  LEFT JOIN health_plan_entity hpe
                                    ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                 WHERE php.num_health_plan = l_beneficiary_number
                                   AND php.id_patient = i_patient
                                   AND php.id_health_plan = l_id_health_coverage_plan
                                   AND php.id_institution = i_prof.institution
                                   AND php.flg_status = pk_alert_constant.g_active;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_beneficiary_number      := NULL;
                                    l_id_pat_health_plan      := NULL;
                                    l_id_health_coverage_plan := NULL;
                            END;
                        ELSIF l_beneficiary_number IS NOT NULL
                              AND l_valid_hp = pk_alert_constant.g_no
                        THEN
                            l_beneficiary_number := NULL;
                        END IF;
                    ELSIF i_action = pk_p1_ext_sys.g_p1_request_from_orders_area
                    THEN
                        IF i_root_name = pk_orders_utils.g_p1_lab_test
                        THEN
                            BEGIN
                                SELECT ard.id_pat_health_plan, hpe.id_health_plan_entity, php.num_health_plan
                                  INTO l_id_pat_health_plan, l_id_financial_entity, l_beneficiary_number
                                  FROM analysis_req_det ard
                                  JOIN pat_health_plan php
                                    ON php.id_pat_health_plan = ard.id_pat_health_plan
                                  JOIN health_plan hp
                                    ON php.id_health_plan = hp.id_health_plan
                                  LEFT JOIN health_plan_entity hpe
                                    ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                 WHERE ard.id_analysis_req_det = i_tbl_id_pk(i_idx);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_beneficiary_number      := NULL;
                                    l_id_pat_health_plan      := NULL;
                                    l_id_health_coverage_plan := NULL;
                            END;
                        ELSIF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                        THEN
                            BEGIN
                                SELECT erd.id_pat_health_plan, hpe.id_health_plan_entity, php.num_health_plan
                                  INTO l_id_pat_health_plan, l_id_financial_entity, l_beneficiary_number
                                  FROM exam_req_det erd
                                  JOIN pat_health_plan php
                                    ON php.id_pat_health_plan = erd.id_pat_health_plan
                                  JOIN health_plan hp
                                    ON php.id_health_plan = hp.id_health_plan
                                  LEFT JOIN health_plan_entity hpe
                                    ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                 WHERE erd.id_exam_req_det = i_tbl_id_pk(i_idx);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_beneficiary_number      := NULL;
                                    l_id_pat_health_plan      := NULL;
                                    l_id_health_coverage_plan := NULL;
                            END;
                        ELSIF i_root_name = pk_orders_utils.g_p1_intervention
                        THEN
                            BEGIN
                                SELECT ipd.id_pat_health_plan, hpe.id_health_plan_entity, php.num_health_plan
                                  INTO l_id_pat_health_plan, l_id_financial_entity, l_beneficiary_number
                                  FROM interv_presc_det ipd
                                  JOIN pat_health_plan php
                                    ON php.id_pat_health_plan = ipd.id_pat_health_plan
                                  JOIN health_plan hp
                                    ON php.id_health_plan = hp.id_health_plan
                                  LEFT JOIN health_plan_entity hpe
                                    ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                 WHERE ipd.id_interv_presc_det = i_tbl_id_pk(i_idx);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_beneficiary_number      := NULL;
                                    l_id_pat_health_plan      := NULL;
                                    l_id_health_coverage_plan := NULL;
                            END;
                        ELSIF i_root_name = pk_orders_utils.g_p1_rehab
                        THEN
                            BEGIN
                                SELECT rp.id_pat_health_plan, hpe.id_health_plan_entity, php.num_health_plan
                                  INTO l_id_pat_health_plan, l_id_financial_entity, l_beneficiary_number
                                  FROM rehab_presc rp
                                  JOIN pat_health_plan php
                                    ON php.id_pat_health_plan = rp.id_pat_health_plan
                                  JOIN health_plan hp
                                    ON php.id_health_plan = hp.id_health_plan
                                  LEFT JOIN health_plan_entity hpe
                                    ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                 WHERE rp.id_rehab_presc = i_tbl_id_pk(i_idx);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_beneficiary_number      := NULL;
                                    l_id_pat_health_plan      := NULL;
                                    l_id_health_coverage_plan := NULL;
                            END;
                        END IF;
                    END IF;
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_priority
                THEN
                    --If the priority 'Normal' is available for selection, then this option should be presented by default for PT
                    BEGIN
                        SELECT domain_value, desc_domain
                          INTO l_default_priority, l_default_priority_desc
                          FROM (SELECT tt.domain_value,
                                       tt.desc_domain,
                                       decode(tt.def_val, 1, pk_ref_constant.g_yes, pk_ref_constant.g_no) default_priority
                                  FROM (SELECT t.*, row_number() over(ORDER BY t.order_rank DESC) def_val
                                          FROM TABLE(l_tbl_p1_priority) t) tt)
                         WHERE (domain_value = 'N' AND l_id_market = pk_alert_constant.g_id_market_pt)
                            OR (default_priority = pk_alert_constant.g_yes AND domain_value NOT IN ('U', 'Y'));
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_default_priority      := NULL;
                            l_default_priority_desc := NULL;
                    END;
                END IF;
            END LOOP;
        
            IF l_has_caregiver_fields = TRUE
            THEN
                l_id_pat_relative := pk_adt_core.get_id_pat_relative(i_patient);
            
                l_id_fam_rel     := pk_adt_core.get_fam_relationship(i_id_patient => i_patient);
                l_fam_rel_desc   := pk_family.get_family_relationship_desc(i_lang, l_id_fam_rel);
                l_fam_res_spec   := pk_adt_core.get_fam_relationship_spec(i_id_patient => i_patient);
                l_first_fam_name := pk_adt_core.get_1st_fam_name(l_id_pat_relative);
                l_middle_name    := pk_adt_core.get_1st_fam_otname3(l_id_pat_relative);
                l_name           := pk_adt_core.get_1st_cgiver_1st_name(l_id_pat_relative);
            END IF;
        
            --NEW FORM (default values)
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_patient_id THEN
                                                                  to_char(i_patient)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_destination_facility THEN
                                                                  to_char(l_dest_facility)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_quantity THEN
                                                                  '1'
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_root_name THEN
                                                                  i_root_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_tbl_records THEN
                                                                  (SELECT listagg(t.column_value, '|')
                                                                     FROM TABLE(l_tbl_id_pk) t)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_p1_all_items_selected THEN
                                                                  pk_alert_constant.g_yes
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_family_relationship THEN
                                                                  to_char(l_id_fam_rel)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_family_relationship_spec THEN
                                                                  l_fam_res_spec
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_lastname THEN
                                                                  l_first_fam_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_middlename THEN
                                                                  l_middle_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_nombres THEN
                                                                  l_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_p1_home THEN
                                                                  pk_alert_constant.g_no
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_priority THEN
                                                                  nvl(l_priority_value, l_default_priority)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exemption THEN
                                                                  to_char(l_id_exemption)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_financial_entity THEN
                                                                  to_char(l_id_financial_entity)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_coverage_plan THEN
                                                                  to_char(l_id_pat_health_plan)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_financial_entity THEN
                                                                  to_char(l_id_financial_entity)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_plan_number THEN
                                                                  to_char(l_beneficiary_number)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_p1_origin_info THEN
                                                                  CASE
                                                                      WHEN i_action = pk_p1_ext_sys.g_p1_request_from_orders_area THEN
                                                                       pk_p1_ext_sys.g_p1_orders_origin
                                                                      ELSE
                                                                       pk_p1_ext_sys.g_p1_referrals_origin
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_laterality THEN
                                                                  l_flg_laterality
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => t.min_value,
                                       max_value          => t.max_value,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_destination_facility THEN
                                                                  l_dest_facility_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_quantity THEN
                                                                  '1'
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_p1_all_items_selected THEN
                                                                  pk_alert_constant.g_yes
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_family_relationship THEN
                                                                  l_fam_rel_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_family_relationship_spec THEN
                                                                  l_fam_res_spec
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_lastname THEN
                                                                  l_first_fam_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_middlename THEN
                                                                  l_middle_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_nombres THEN
                                                                  l_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_p1_home THEN
                                                                  (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_HOME', pk_alert_constant.g_no, i_lang)
                                                                     FROM dual)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_priority THEN
                                                                  nvl(l_priority_desc, l_default_priority_desc)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exemption THEN
                                                                  l_exemption_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_financial_entity THEN
                                                                  decode(l_id_pat_health_plan,
                                                                         NULL,
                                                                         NULL,
                                                                         pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'F'))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_coverage_plan THEN
                                                                  decode(l_id_pat_health_plan,
                                                                         NULL,
                                                                         NULL,
                                                                         pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'H'))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_plan_number THEN
                                                                  to_char(l_beneficiary_number)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_laterality
                                                                      AND l_flg_laterality IS NOT NULL THEN
                                                                  (SELECT pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LATERALITY', l_flg_laterality, i_lang)
                                                                     FROM dual)
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_ok_button_control THEN
                                                                  pk_orders_constant.g_component_error
                                                                 ELSE
                                                                  pk_orders_constant.g_component_valid
                                                             END,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE t.internal_name_child
                                                                 WHEN pk_orders_constant.g_ds_referral_reason THEN
                                                                  decode(l_reason_mandatory, pk_alert_constant.g_yes, pk_orders_constant.g_component_mandatory)
                                                                 WHEN pk_orders_constant.g_ds_diagnosis THEN
                                                                  decode(l_diagnosis_mandatory, pk_alert_constant.g_yes, pk_orders_constant.g_component_mandatory)
                                                                 WHEN pk_orders_constant.g_ds_referral_consent THEN
                                                                  decode(l_consent_mandatory, pk_alert_constant.g_yes, pk_orders_constant.g_component_mandatory)
                                                                 WHEN pk_orders_constant.g_ds_medication THEN
                                                                  decode(l_medication_available, pk_alert_constant.g_no, pk_orders_constant.g_component_inactive)
                                                                 WHEN pk_orders_constant.g_ds_vital_signs THEN
                                                                  decode(l_vital_signs_available, pk_alert_constant.g_no, pk_orders_constant.g_component_inactive)
                                                                 WHEN pk_orders_constant.g_ds_laterality THEN
                                                                  decode(i_root_name,
                                                                         pk_orders_utils.g_p1_lab_test,
                                                                         pk_orders_constant.g_component_inactive,
                                                                         decode(l_laterality_mandatory,
                                                                                pk_alert_constant.g_yes,
                                                                                pk_orders_constant.g_component_mandatory,
                                                                                'A'))
                                                                 WHEN pk_orders_constant.g_ds_family_relationship_spec THEN
                                                                  nvl2(l_fam_res_spec,
                                                                       pk_orders_constant.g_component_active,
                                                                       pk_orders_constant.g_component_inactive)
                                                                 WHEN pk_orders_constant.g_ds_quantity THEN
                                                                  pk_orders_constant.g_component_mandatory
                                                                 WHEN pk_orders_constant.g_ds_p1_home THEN
                                                                 --For PT market and for the MCDTs, the field HOME
                                                                 --should only ve available for Lab tests
                                                                  CASE
                                                                      WHEN l_id_market = pk_alert_constant.g_id_market_pt
                                                                           AND i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                                                                                               pk_orders_utils.g_p1_other_exam,
                                                                                               pk_orders_utils.g_p1_intervention,
                                                                                               pk_orders_utils.g_p1_rehab) THEN
                                                                       pk_orders_constant.g_component_inactive
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_financial_entity THEN
                                                                  CASE l_id_market
                                                                      WHEN pk_alert_constant.g_id_market_pt THEN
                                                                       pk_orders_constant.g_component_mandatory
                                                                      ELSE
                                                                       pk_orders_constant.g_component_active
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_health_coverage_plan THEN
                                                                  CASE l_id_market
                                                                      WHEN pk_alert_constant.g_id_market_pt THEN
                                                                       pk_orders_constant.g_component_mandatory
                                                                      ELSE
                                                                       pk_orders_constant.g_component_active
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_health_plan_number THEN
                                                                  CASE
                                                                      WHEN l_beneficiary_number IS NOT NULL THEN
                                                                       pk_orders_constant.g_component_read_only
                                                                      ELSE
                                                                       pk_orders_constant.g_component_inactive
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_complementary_information THEN
                                                                  CASE
                                                                      WHEN l_complementary_info_mandatory = pk_alert_constant.g_yes THEN
                                                                       pk_orders_constant.g_component_mandatory
                                                                      ELSE
                                                                       pk_orders_constant.g_component_active
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_priority THEN
                                                                  pk_orders_constant.g_component_mandatory
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure,
                           dc.min_value,
                           dc.max_value
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN (pk_orders_constant.g_ds_patient_id,
                                       pk_orders_constant.g_ds_destination_facility,
                                       pk_orders_constant.g_ds_quantity,
                                       pk_orders_constant.g_ds_root_name,
                                       pk_orders_constant.g_ds_tbl_records,
                                       pk_orders_constant.g_ds_laterality,
                                       pk_orders_constant.g_ds_referral_reason,
                                       pk_orders_constant.g_ds_diagnosis,
                                       pk_orders_constant.g_ds_referral_consent,
                                       pk_orders_constant.g_ds_medication,
                                       pk_orders_constant.g_ds_vital_signs,
                                       pk_orders_constant.g_ds_p1_import_ids,
                                       pk_orders_constant.g_ds_p1_import_values,
                                       pk_orders_constant.g_ds_p1_all_items_selected,
                                       pk_orders_constant.g_ds_family_relationship_spec,
                                       pk_orders_constant.g_ds_lastname,
                                       pk_orders_constant.g_ds_middlename,
                                       pk_orders_constant.g_ds_nombres,
                                       pk_orders_constant.g_ds_p1_home,
                                       pk_orders_constant.g_ds_exemption,
                                       pk_orders_constant.g_ds_priority,
                                       pk_orders_constant.g_ds_complementary_information,
                                       pk_orders_constant.g_ds_p1_origin_info,
                                       pk_orders_constant.g_ds_health_plan_number,
                                       pk_orders_constant.g_ds_financial_entity,
                                       pk_orders_constant.g_ds_health_coverage_plan,
                                       pk_orders_constant.g_ds_ok_button_control)
                OR (d.internal_name = pk_orders_constant.g_ds_family_relationship AND l_id_fam_rel IS NOT NULL);
        
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            --First it is necessary to check if this submit refers to the action 'Import data'
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_p1_import_ids
                THEN
                    IF i_value(i).exists(1)
                    THEN
                        IF i_value(i) (1) IS NOT NULL
                        THEN
                            l_import_data_mode := TRUE;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        
            IF l_import_data_mode = FALSE
            THEN
                --Action of submiting a value on any given element of the form
                IF i_curr_component IS NOT NULL
                THEN
                    --Check which element has been changed
                    SELECT d.internal_name_child
                      INTO l_curr_comp_int_name
                      FROM ds_cmpt_mkt_rel d
                     WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
                
                    IF l_curr_comp_int_name IN (pk_orders_constant.g_ds_p1_home, pk_orders_constant.g_ds_priority)
                    THEN
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name = pk_orders_constant.g_ds_priority
                            THEN
                                l_priority_value := nvl(i_value(i) (1), pk_alert_constant.g_no);
                            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                            THEN
                                l_home_value := nvl(i_value(i) (1), pk_alert_constant.g_no);
                            END IF;
                        END LOOP;
                    
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name IN (pk_orders_constant.g_ds_referral_reason)
                            THEN
                                --Check if the Reason field should be mandatory
                                IF NOT pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                                            i_prof             => i_prof,
                                                                            i_type             => CASE i_root_name
                                                                                                      WHEN
                                                                                                       pk_orders_utils.g_p1_appointment THEN
                                                                                                       'C'
                                                                                                      WHEN
                                                                                                       pk_orders_utils.g_p1_lab_test THEN
                                                                                                       'A'
                                                                                                      WHEN
                                                                                                       pk_orders_utils.g_p1_intervention THEN
                                                                                                       'P'
                                                                                                      WHEN
                                                                                                       pk_orders_utils.g_p1_imaging_exam THEN
                                                                                                       'I'
                                                                                                      WHEN
                                                                                                       pk_orders_utils.g_p1_other_exam THEN
                                                                                                       'E'
                                                                                                      WHEN
                                                                                                       pk_orders_utils.g_p1_rehab THEN
                                                                                                       'F'
                                                                                                  END,
                                                                            i_home             => table_varchar(l_home_value),
                                                                            i_priority         => table_varchar(l_priority_value),
                                                                            o_reason_mandatory => l_reason_mandatory,
                                                                            o_error            => o_error)
                                THEN
                                    RAISE g_exception;
                                END IF;
                            
                                l_reason_desc := i_value(i) (1);
                            
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => l_reason_desc,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   value_clob         => NULL,
                                                                                   desc_value         => l_reason_desc,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                          l_reason_mandatory
                                                                                                             WHEN
                                                                                                              pk_alert_constant.g_yes THEN
                                                                                                              'M'
                                                                                                             ELSE
                                                                                                              'A'
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        END LOOP;
                    ELSIF i_root_name = pk_orders_utils.g_p1_appointment
                          AND l_curr_comp_int_name = pk_orders_constant.g_ds_clinical_service
                    THEN
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                            IF l_ds_internal_name = pk_orders_constant.g_ds_clinical_service
                            THEN
                                l_id_clinical_service := to_number(i_value(i) (1));
                            END IF;
                        END LOOP;
                    
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name = pk_orders_constant.g_ds_destination_facility
                            THEN
                                BEGIN
                                    SELECT domain_value, desc_domain
                                      INTO l_dest_facility, l_dest_facility_desc
                                      FROM (SELECT domain_value, desc_domain
                                              FROM TABLE(pk_p1_data_export.get_clinical_institution(i_lang => i_lang,
                                                                                                    i_prof => i_prof,
                                                                                                    i_spec => l_id_clinical_service)) t
                                             WHERE rownum = 1);
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_dest_facility      := NULL;
                                        l_dest_facility_desc := NULL;
                                END;
                            
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => l_dest_facility,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => l_dest_facility_desc,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => 'M',
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        END LOOP;
                    ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_onset
                    THEN
                    
                        SELECT pk_date_utils.date_send_str(i_lang,
                                                           to_char(dt_birth, pk_date_utils.g_dateformat),
                                                           i_prof,
                                                           l_timezone) o_dt_birth_send
                          INTO l_dt_patient_birth
                          FROM patient p
                         WHERE p.id_patient = i_patient;
                    
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name = pk_orders_constant.g_ds_onset
                            THEN
                                l_dt_onset := substr(i_value(i) (1), 1, 8) || '000000';
                            END IF;
                        END LOOP;
                    
                        IF l_dt_patient_birth IS NOT NULL
                           AND l_dt_onset IS NOT NULL
                        THEN
                            l_onset_valid := pk_date_utils.compare_dates(i_date1 => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                  i_prof      => i_prof,
                                                                                                                  i_timestamp => l_dt_onset,
                                                                                                                  i_timezone  => NULL),
                                                                         i_date2 => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                  i_prof      => i_prof,
                                                                                                                  i_timestamp => l_dt_patient_birth,
                                                                                                                  i_timezone  => NULL));
                        END IF;
                    
                        --Assess if the Onset date is not before the patient birth date
                        IF l_onset_valid = 'L'
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_curr_component,
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_curr_component),
                                                                               internal_name      => pk_orders_utils.get_ds_internal_name(i_curr_component),
                                                                               VALUE              => l_dt_onset,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => 'E',
                                                                               err_msg            => pk_message.get_message(i_lang,
                                                                                                                            'P1_COMMON_T012'),
                                                                               flg_event_type     => NULL,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSE
                            l_onset_valid := pk_date_utils.compare_dates(i_date1 => current_timestamp,
                                                                         i_date2 => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                  i_prof      => i_prof,
                                                                                                                  i_timestamp => l_dt_onset,
                                                                                                                  i_timezone  => NULL));
                            --Assess if the Onset date is not after the current date
                            IF l_onset_valid = 'L'
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_curr_component,
                                                                                   id_ds_component    => pk_orders_utils.get_id_ds_component(i_curr_component),
                                                                                   internal_name      => pk_orders_utils.get_ds_internal_name(i_curr_component),
                                                                                   VALUE              => l_dt_onset,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => 'E',
                                                                                   err_msg            => pk_message.get_message(i_lang,
                                                                                                                                'P1_COMMON_T013'),
                                                                                   flg_event_type     => NULL,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        END IF;
                    ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_health_coverage_plan
                    THEN
                        FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                        
                            IF l_ds_internal_name IN (pk_orders_constant.g_ds_health_coverage_plan)
                            THEN
                                l_id_health_coverage_plan := i_value(j) (1);
                            END IF;
                        END LOOP;
                    
                        FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                        
                            IF l_ds_internal_name IN (pk_orders_constant.g_ds_financial_entity)
                            THEN
                                l_id_financial_entity := i_value(j) (1);
                                IF l_id_financial_entity IS NULL
                                   AND l_id_health_coverage_plan IS NOT NULL
                                THEN
                                    SELECT hpe.id_health_plan_entity
                                      INTO l_id_financial_entity
                                      FROM pat_health_plan php
                                      JOIN health_plan hp
                                        ON php.id_health_plan = hp.id_health_plan
                                      LEFT JOIN health_plan_entity hpe
                                        ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                     WHERE php.id_pat_health_plan = l_id_health_coverage_plan;
                                END IF;
                            END IF;
                        END LOOP;
                    
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name IN (pk_orders_constant.g_ds_health_plan_number)
                            THEN
                            
                                l_beneficiary_number := pk_orders_utils.get_patient_beneficiary_number(i_lang               => i_lang,
                                                                                                       i_prof               => i_prof,
                                                                                                       i_patient            => i_patient,
                                                                                                       i_health_plan_entity => l_id_financial_entity,
                                                                                                       i_health_plan        => l_id_health_coverage_plan);
                                IF l_beneficiary_number IS NOT NULL
                                THEN
                                
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => l_ds_internal_name,
                                                                                       VALUE              => l_beneficiary_number,
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => l_beneficiary_number,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => 'Y',
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => 'R',
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                ELSE
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => l_ds_internal_name,
                                                                                       VALUE              => NULL,
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => NULL,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => 'Y',
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => 'I',
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                END IF;
                            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_financial_entity
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => to_char(l_id_financial_entity),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => pk_adt.get_pat_health_plan_info(i_lang,
                                                                                                                                         i_prof,
                                                                                                                                         l_id_health_coverage_plan,
                                                                                                                                         'F'),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE l_id_market
                                                                                                             WHEN
                                                                                                              pk_alert_constant.g_id_market_pt THEN
                                                                                                              'M'
                                                                                                             ELSE
                                                                                                              'A'
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        END LOOP;
                    ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_financial_entity
                    THEN
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name IN (pk_orders_constant.g_ds_health_coverage_plan)
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => 'Y',
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE l_id_market
                                                                                                             WHEN
                                                                                                              pk_alert_constant.g_id_market_pt THEN
                                                                                                              'M'
                                                                                                             ELSE
                                                                                                              'A'
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_health_plan_number)
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => 'Y',
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => 'I',
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        END LOOP;
                    END IF;
                ELSE
                    --Selecting items in the viewer
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_priority
                        THEN
                            l_priority_value := nvl(i_value(i) (1), pk_alert_constant.g_no);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                        THEN
                            l_home_value := nvl(i_value(i) (1), pk_alert_constant.g_no);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_all_items_selected
                        THEN
                            --This value is updated by the UX layer, and indicates if all items are selected in the viewer
                            l_all_items_selected := i_value(i) (1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_complementary_information
                              AND l_tbl_compl_info_mandatory.exists(1)
                        THEN
                            FOR j IN l_tbl_compl_info_mandatory.first .. l_tbl_compl_info_mandatory.last
                            LOOP
                                IF l_tbl_compl_info_mandatory(j) = pk_alert_constant.g_yes
                                THEN
                                    l_complementary_info_mandatory := l_tbl_compl_info_mandatory(j);
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                        l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_referral_reason
                        THEN
                            --Check if the Reason field should be mandatory
                            IF NOT
                                pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_type             => CASE i_root_name
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_appointment THEN
                                                                                                'C'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_lab_test THEN
                                                                                                'A'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_intervention THEN
                                                                                                'P'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_imaging_exam THEN
                                                                                                'I'
                                                                                               WHEN
                                                                                                pk_orders_utils.g_p1_other_exam THEN
                                                                                                'E'
                                                                                               WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                                'F'
                                                                                           END,
                                                                     i_home             => table_varchar(l_home_value),
                                                                     i_priority         => table_varchar(l_priority_value),
                                                                     o_reason_mandatory => l_reason_mandatory,
                                                                     o_error            => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            l_reason_desc := i_value(i) (1);
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_reason_desc,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_reason_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_id_market = pk_alert_constant.g_id_market_pt THEN
                                                                                                          CASE
                                                                                                              WHEN l_all_items_selected = pk_alert_constant.g_yes THEN
                                                                                                               CASE l_reason_mandatory
                                                                                                                   WHEN pk_alert_constant.g_yes THEN
                                                                                                                    'M'
                                                                                                                   ELSE
                                                                                                                    'A'
                                                                                                               END
                                                                                                              ELSE
                                                                                                               'R'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE l_reason_mandatory
                                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                                               'M'
                                                                                                              ELSE
                                                                                                               'A'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_priority
                        THEN
                        
                            l_priority_desc := i_value_desc(i) (1);
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_priority_value,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_priority_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_all_items_selected
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'A'
                                                                                                         ELSE
                                                                                                          'R'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                              AND i_root_name = pk_orders_utils.g_p1_lab_test
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_home_value,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_id_market = pk_alert_constant.g_id_market_pt THEN
                                                                                                          CASE l_all_items_selected
                                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                                               pk_orders_constant.g_component_active
                                                                                                              ELSE
                                                                                                               pk_orders_constant.g_component_read_only
                                                                                                          END
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_active
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_referral_consent
                        THEN
                            IF l_all_items_selected = pk_alert_constant.g_yes
                            THEN
                                --Check if field consent is mandatory
                                l_consent_mandatory := pk_sysconfig.get_config('P1_CONSENT', i_prof);
                            END IF;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          CASE l_consent_mandatory
                                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                                               'M'
                                                                                                              ELSE
                                                                                                               'A'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_notes,
                                                     pk_orders_constant.g_ds_symptoms,
                                                     pk_orders_constant.g_ds_course,
                                                     pk_orders_constant.g_ds_personal_history,
                                                     pk_orders_constant.g_ds_family_history,
                                                     pk_orders_constant.g_ds_objective_examination_ft,
                                                     pk_orders_constant.g_ds_executed_tests_ft,
                                                     pk_orders_constant.g_ds_lastname,
                                                     pk_orders_constant.g_ds_middlename,
                                                     pk_orders_constant.g_ds_nombres)
                        THEN
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          'A'
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_destination_facility,
                                                     pk_orders_constant.g_ds_quantity,
                                                     pk_orders_constant.g_ds_patient_id,
                                                     pk_orders_constant.g_ds_root_name,
                                                     pk_orders_constant.g_ds_dummy_number,
                                                     pk_orders_constant.g_ds_p1_origin_info)
                        THEN
                            IF l_ds_internal_name = pk_orders_constant.g_ds_quantity
                            THEN
                                SELECT d.min_value, d.max_value
                                  INTO l_min_val, l_max_val
                                  FROM ds_cmpt_mkt_rel d
                                 WHERE d.id_ds_cmpt_mkt_rel = i_tbl_mkt_rel(i);
                            ELSE
                                l_min_val := NULL;
                                l_max_val := NULL;
                            END IF;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => CASE
                                                                                                         WHEN l_ds_internal_name = pk_orders_constant.g_ds_quantity THEN
                                                                                                          l_min_val
                                                                                                         ELSE
                                                                                                          NULL
                                                                                                     END,
                                                                               max_value          => CASE
                                                                                                         WHEN l_ds_internal_name = pk_orders_constant.g_ds_quantity THEN
                                                                                                          l_max_val
                                                                                                         ELSE
                                                                                                          NULL
                                                                                                     END,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_medication
                        THEN
                            IF l_all_items_selected = pk_alert_constant.g_yes
                            THEN
                                --Check if field Medication is available                           
                                l_medication_available := pk_sysconfig.get_config('REF_MEDICATION_ENABLE', i_prof);
                            END IF;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          CASE l_medication_available
                                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                                               'A'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_vital_signs
                        THEN
                            IF l_all_items_selected = pk_alert_constant.g_yes
                            THEN
                                --Check if the field vital signs is available
                                l_vital_signs_available := pk_sysconfig.get_config('REF_VITALSIGNS_ENABLE', i_prof);
                            END IF;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          CASE l_vital_signs_available
                                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                                               'A'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_onset
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          'A'
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_family_relationship)
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          'A'
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_family_relationship_spec)
                        THEN
                        
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name_aux := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name_aux = pk_orders_constant.g_ds_family_relationship
                                THEN
                                    l_id_fam_rel := to_number(i_value(j) (1));
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          CASE l_id_fam_rel
                                                                                                              WHEN '44' THEN
                                                                                                               'M'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name IN
                              (pk_orders_constant.g_ds_diagnosis, pk_orders_constant.g_ds_problems_addressed)
                        THEN
                            IF i_value(i) (1) IS NOT NULL
                            THEN
                                FOR j IN i_value(i).first .. i_value(i).last
                                LOOP
                                    IF i_value(i).exists(j)
                                    THEN
                                        IF i_value(i) (j) IS NOT NULL
                                        THEN
                                            tbl_result.extend();
                                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                               id_ds_component    => l_id_ds_component,
                                                                                               internal_name      => l_ds_internal_name,
                                                                                               VALUE              => i_value(i) (j),
                                                                                               value_clob         => NULL,
                                                                                               min_value          => NULL,
                                                                                               max_value          => NULL,
                                                                                               desc_value         => i_value_desc(i) (j) /*pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_id_institution  => i_prof.institution,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_id_software     => i_prof.software,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_id_concept_term => to_number(i_value(i) (j)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_concept_type    => 'DIAGNOSIS',
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_id_task_type    => CASE
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                l_ds_internal_name
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   WHEN
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    pk_orders_constant.g_ds_diagnosis THEN
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    pk_alert_constant.g_task_diagnosis
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ELSE
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    pk_alert_constant.g_task_problems
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               END)*/,
                                                                                               desc_clob          => NULL,
                                                                                               id_unit_measure    => NULL,
                                                                                               desc_unit_measure  => NULL,
                                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                                               err_msg            => NULL,
                                                                                               flg_event_type     => CASE
                                                                                                                      l_all_items_selected
                                                                                                                         WHEN
                                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                                          'A'
                                                                                                                         ELSE
                                                                                                                          'R'
                                                                                                                     END,
                                                                                               flg_multi_status   => NULL,
                                                                                               idx                => i_idx);
                                        END IF;
                                    END IF;
                                END LOOP;
                            ELSE
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                          l_all_items_selected
                                                                                                             WHEN
                                                                                                              pk_alert_constant.g_yes THEN
                                                                                                              'A'
                                                                                                             ELSE
                                                                                                              'I'
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_tbl_records
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name_aux := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                                l_id_ds_component_aux  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                            
                                IF l_ds_internal_name_aux = pk_orders_constant.g_ds_dummy_number
                                THEN
                                    IF i_value(j) (1) IS NOT NULL
                                    THEN
                                        l_flg_edition := pk_alert_constant.g_yes;
                                    END IF;
                                END IF;
                            END LOOP;
                        
                            IF l_flg_edition = pk_alert_constant.g_no
                            THEN
                                IF i_root_name = pk_orders_utils.g_p1_lab_test
                                THEN
                                    SELECT listagg(ast.id_content, '|')
                                      INTO l_records
                                      FROM analysis_instit_soft ais
                                      JOIN analysis_sample_type ast
                                        ON ast.id_analysis = ais.id_analysis
                                       AND ast.id_sample_type = ais.id_sample_type
                                       AND ast.flg_available = pk_alert_constant.g_yes
                                     WHERE ais.id_analysis_instit_soft IN
                                           (SELECT * /*+opt_estimate(table t rows=1)*/
                                              FROM TABLE(i_tbl_id_pk) t);
                                ELSE
                                    SELECT (SELECT listagg(t.column_value, '|')
                                              FROM TABLE(i_tbl_id_pk) t)
                                      INTO l_records
                                      FROM dual;
                                END IF;
                            ELSE
                                IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam, pk_orders_utils.g_p1_other_exam)
                                THEN
                                    SELECT listagg(erd.id_exam, '|')
                                      INTO l_records
                                      FROM exam_req_det erd
                                     WHERE erd.id_exam_req_det IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                                     FROM TABLE(i_tbl_id_pk) t);
                                ELSIF i_root_name = pk_orders_utils.g_p1_intervention
                                THEN
                                    SELECT listagg(ipd.id_intervention, '|')
                                      INTO l_records
                                      FROM interv_presc_det ipd
                                     WHERE ipd.id_interv_presc_det IN
                                           (SELECT * /*+opt_estimate(table t rows=1)*/
                                              FROM TABLE(i_tbl_id_pk) t);
                                ELSIF i_root_name = pk_orders_utils.g_p1_lab_test
                                THEN
                                    SELECT listagg(ast.id_content, '|')
                                      INTO l_records
                                      FROM analysis_req_det ard
                                      JOIN analysis_sample_type ast
                                        ON ast.id_analysis = ard.id_analysis
                                       AND ast.id_sample_type = ard.id_sample_type
                                       AND ast.flg_available = pk_alert_constant.g_yes
                                     WHERE ard.id_analysis_req_det IN
                                           (SELECT * /*+opt_estimate(table t rows=1)*/
                                              FROM TABLE(i_tbl_id_pk) t);
                                ELSIF i_root_name = pk_orders_utils.g_p1_rehab
                                THEN
                                    SELECT listagg(rp.id_rehab_area_interv, '|')
                                      INTO l_records
                                      FROM rehab_presc rp
                                     WHERE rp.id_rehab_presc IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                                   FROM TABLE(i_tbl_id_pk) t);
                                END IF;
                            END IF;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_records,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => NULL,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                              AND i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                                                  pk_orders_utils.g_p1_other_exam,
                                                  pk_orders_utils.g_p1_intervention,
                                                  pk_orders_utils.g_p1_rehab)
                        THEN
                            --For PT market and for the MCDTs, the field HOME
                            --should only ve available for Lab tests            
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_id_market = pk_alert_constant.g_id_market_pt THEN
                                                                                                          'I'
                                                                                                         ELSE
                                                                                                          'A'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_complementary_information
                        THEN
                            FOR j IN i_value(i).first .. i_value(i).last
                            LOOP
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => i_value(i) (j),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value(i) (j),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                             WHEN l_complementary_info_mandatory = pk_alert_constant.g_yes THEN
                                                                                                              'M'
                                                                                                             ELSE
                                                                                                              'A'
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END LOOP;
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_financial_entity
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j)) =
                                   pk_orders_constant.g_ds_health_coverage_plan
                                THEN
                                    l_id_pat_health_plan := to_number(i_value(j) (1));
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          CASE l_id_market
                                                                                                              WHEN pk_alert_constant.g_id_market_pt THEN
                                                                                                               'M'
                                                                                                              ELSE
                                                                                                               'A'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_health_coverage_plan
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          CASE l_id_market
                                                                                                              WHEN pk_alert_constant.g_id_market_pt THEN
                                                                                                               'M'
                                                                                                              ELSE
                                                                                                               'A'
                                                                                                          END
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name IN (pk_orders_constant.g_ds_health_plan_number)
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          'R'
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_exemption
                        --                              AND i_value(i) (1) IS NOT NULL
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_all_items_selected
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          'A'
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN i_value(i) (1) IS NOT NULL THEN
                                                                                                               'R'
                                                                                                              ELSE
                                                                                                               'I'
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END LOOP;
                
                    IF i_root_name IN (pk_orders_utils.g_p1_lab_test,
                                       pk_orders_utils.g_p1_imaging_exam,
                                       pk_orders_utils.g_p1_other_exam,
                                       pk_orders_utils.g_p1_intervention,
                                       pk_orders_utils.g_p1_rehab)
                    THEN
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                            l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_ds_internal_name = pk_orders_constant.g_ds_laterality
                            THEN
                                IF i_root_name <> pk_orders_utils.g_p1_lab_test
                                THEN
                                    IF l_flg_edition = pk_alert_constant.g_no
                                    THEN
                                        l_tbl_records := table_number();
                                        l_tbl_records := table_number(i_tbl_id_pk(i_idx));
                                    ELSE
                                        l_tbl_records := table_number();
                                        l_tbl_aux     := table_number();
                                        l_tbl_aux     := pk_utils.str_split_n(i_list => l_records, i_delim => '|');
                                        l_tbl_records := table_number(l_tbl_aux(i_idx));
                                    END IF;
                                
                                    IF NOT
                                        pk_mcdt.check_mandatory_lat(i_lang      => i_lang,
                                                                    i_prof      => i_prof,
                                                                    i_mcdt_type => CASE i_root_name
                                                                                       WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                        pk_ref_constant.g_p1_type_e
                                                                                       WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                        pk_ref_constant.g_p1_type_i
                                                                                       WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                        pk_ref_constant.g_p1_type_p
                                                                                       WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                        pk_ref_constant.g_p1_type_f
                                                                                   END,
                                                                    i_mcdt      => l_tbl_records,
                                                                    o_flg_show  => l_laterality_mandatory,
                                                                    o_msg       => l_msg,
                                                                    o_msg_title => l_msg_title,
                                                                    o_button    => l_button,
                                                                    o_error     => o_error)
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => i_value(i) (1),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value_desc(i) (1),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE i_root_name
                                                                                                             WHEN
                                                                                                              pk_orders_utils.g_p1_lab_test THEN
                                                                                                              'I'
                                                                                                             ELSE
                                                                                                              CASE
                                                                                                               l_laterality_mandatory
                                                                                                                  WHEN
                                                                                                                   pk_alert_constant.g_yes THEN
                                                                                                                   'M'
                                                                                                                  ELSE
                                                                                                                   'A'
                                                                                                              END
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        
                        END LOOP;
                    END IF;
                END IF;
            ELSE
                --IMPORTING DATA                
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_p1_import_ids
                    THEN
                        FOR j IN i_value(i).first .. i_value(i).last
                        LOOP
                            l_tbl_p1_data_export_ids.extend();
                            l_tbl_p1_data_export_ids(l_tbl_p1_data_export_ids.count) := to_number(i_value(i) (j));
                        END LOOP;
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_import_values
                    THEN
                        FOR j IN i_value(i).first .. i_value(i).last
                        LOOP
                            l_tbl_p1_data_export_values.extend();
                            l_tbl_p1_data_export_values(l_tbl_p1_data_export_values.count) := to_number(i_value(i) (j));
                        END LOOP;
                    
                    END IF;
                END LOOP;
            
                IF l_tbl_p1_data_export_ids.count <> l_tbl_p1_data_export_values.count
                THEN
                    g_error := 'Import data arrays do not have the same size.';
                    RAISE g_exception;
                ELSE
                    FOR i IN l_tbl_p1_data_export_ids.first .. l_tbl_p1_data_export_ids.last
                    LOOP
                        l_data_export.extend();
                        l_data_export(l_data_export.count) := table_number(l_tbl_p1_data_export_ids(i),
                                                                           l_tbl_p1_data_export_values(i));
                    END LOOP;
                END IF;
            
                tbl_result := pk_p1_data_export.get_p1_data_export(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_episode        => i_episode,
                                                                   i_patient        => i_patient,
                                                                   i_action         => i_action,
                                                                   i_root_name      => i_root_name,
                                                                   i_curr_component => i_curr_component,
                                                                   i_tbl_id_pk      => i_tbl_id_pk,
                                                                   i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                   i_value          => i_value,
                                                                   i_data_export    => l_data_export,
                                                                   i_ref_type       => 'F',
                                                                   o_error          => o_error);
            
                --Due to limitations in the UX layer, it is necessary to recalculate the mandatory parameters
                --Check if the Reason field should be mandatory
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_priority
                    THEN
                        l_priority_value := nvl(i_value(i) (1), pk_alert_constant.g_no);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                    THEN
                        l_home_value := nvl(i_value(i) (1), pk_alert_constant.g_no);
                    END IF;
                END LOOP;
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(i));
                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    IF l_ds_internal_name = pk_orders_constant.g_ds_referral_reason
                    THEN
                        IF NOT
                            pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_type             => CASE i_root_name
                                                                                           WHEN
                                                                                            pk_orders_utils.g_p1_appointment THEN
                                                                                            'C'
                                                                                           WHEN pk_orders_utils.g_p1_lab_test THEN
                                                                                            'A'
                                                                                           WHEN
                                                                                            pk_orders_utils.g_p1_intervention THEN
                                                                                            'P'
                                                                                           WHEN
                                                                                            pk_orders_utils.g_p1_imaging_exam THEN
                                                                                            'I'
                                                                                           WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                            'E'
                                                                                           WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                            'F'
                                                                                       END,
                                                                 i_home             => table_varchar(l_home_value),
                                                                 i_priority         => table_varchar(l_priority_value),
                                                                 o_reason_mandatory => l_reason_mandatory,
                                                                 o_error            => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_reason_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      'M'
                                                                                                     ELSE
                                                                                                      'A'
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_referral_consent
                    THEN
                        --Check if field consent is mandatory
                        l_consent_mandatory := pk_sysconfig.get_config('P1_CONSENT', i_prof);
                        IF l_consent_mandatory = pk_alert_constant.g_yes
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_consent_mandatory
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          'M'
                                                                                                         ELSE
                                                                                                          'A'
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                        --The Diagnosis field is already verified in function pk_p1_data_export.get_p1_data_export,
                        --therefore is is not necessary to do it again.
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_laterality
                    THEN
                        IF i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                                           pk_orders_utils.g_p1_other_exam,
                                           pk_orders_utils.g_p1_intervention,
                                           pk_orders_utils.g_p1_rehab)
                        THEN
                            IF l_flg_edition = pk_alert_constant.g_no
                            THEN
                                l_tbl_records := table_number();
                                l_tbl_records := i_tbl_id_pk;
                            ELSE
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j));
                                    l_id_ds_component  := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                                    IF l_ds_internal_name = pk_orders_constant.g_ds_tbl_records
                                    THEN
                                        l_records := i_value(j) (1);
                                    END IF;
                                END LOOP;
                            
                                l_tbl_records := table_number();
                                l_tbl_records := pk_utils.str_split_n(i_list => l_records, i_delim => '|');
                            END IF;
                        
                            IF NOT pk_mcdt.check_mandatory_lat(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_mcdt_type => CASE i_root_name
                                                                                  WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                                   pk_ref_constant.g_p1_type_e
                                                                                  WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                                   pk_ref_constant.g_p1_type_i
                                                                                  WHEN pk_orders_utils.g_p1_intervention THEN
                                                                                   pk_ref_constant.g_p1_type_p
                                                                                  WHEN pk_orders_utils.g_p1_rehab THEN
                                                                                   pk_ref_constant.g_p1_type_f
                                                                              END,
                                                               i_mcdt      => l_tbl_records,
                                                               o_flg_show  => l_laterality_mandatory,
                                                               o_msg       => l_msg,
                                                               o_msg_title => l_msg_title,
                                                               o_button    => l_button,
                                                               o_error     => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        END IF;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => l_ds_internal_name,
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE i_root_name
                                                                                                     WHEN
                                                                                                      pk_orders_utils.g_p1_lab_test THEN
                                                                                                      'I'
                                                                                                     ELSE
                                                                                                      CASE
                                                                                                       l_laterality_mandatory
                                                                                                          WHEN
                                                                                                           pk_alert_constant.g_yes THEN
                                                                                                           'M'
                                                                                                          ELSE
                                                                                                           'A'
                                                                                                      END
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
                    THEN
                        --For PT market and for the MCDTs, the field HOME
                        --should only ve available for Lab tests
                        IF l_id_market = pk_alert_constant.g_id_market_pt
                           AND i_root_name IN (pk_orders_utils.g_p1_imaging_exam,
                                               pk_orders_utils.g_p1_other_exam,
                                               pk_orders_utils.g_p1_intervention,
                                               pk_orders_utils.g_p1_rehab)
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => 'I',
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        ELSE
            --Editing the form        
            tbl_result := pk_p1_ext_sys.get_p1_order_for_edition(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_episode        => i_episode,
                                                                 i_patient        => i_patient,
                                                                 i_action         => i_action,
                                                                 i_root_name      => i_root_name,
                                                                 i_curr_component => i_curr_component,
                                                                 i_idx            => i_idx,
                                                                 i_tbl_id_pk      => i_tbl_id_pk,
                                                                 i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                 i_value          => i_value,
                                                                 i_value_desc     => i_value_desc,
                                                                 o_error          => o_error);
        
            l_flg_edition := pk_alert_constant.g_yes;
        
        END IF;
    
        --Call to the mechanism that will indicate which elements are mandatory after every action
        --This is needed for the UX layer to control the pencil icon on the viewer
        --(The id_ds_cmpt_mkt_rel that are mandatory are sent (piped) in DS_TBL_MANDATORY_ITEMS) 
        IF i_root_name NOT IN (pk_orders_utils.g_p1_appointment)
           AND (i_action IS NOT NULL AND i_action NOT IN (-1, pk_p1_ext_sys.g_p1_request_from_orders_area))
        THEN
            IF NOT pk_p1_ext_sys.get_control_validation(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_root_name   => i_root_name,
                                                        i_action      => i_action,
                                                        i_flg_origin  => l_flg_origin,
                                                        i_flg_edition => l_flg_edition,
                                                        i_tbl_id_pk   => i_tbl_id_pk,
                                                        i_tbl_mkt_rel => i_tbl_mkt_rel,
                                                        i_value       => i_value,
                                                        i_value_desc  => i_value_desc,
                                                        i_idx         => i_idx,
                                                        io_tbl_result => tbl_result,
                                                        o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    END get_p1_order_values;

    PROCEDURE init_params_list
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_episode    episode.id_episode%TYPE := i_context_ids(g_episode);
        l_id_patient patient.id_patient%TYPE := i_context_ids(g_patient);
    
        l_rank_p1_type_request sys_domain.rank%TYPE;
        l_flg_p1_type_request  sys_domain.val%TYPE := NULL;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_context_vals IS NOT NULL
           AND i_context_vals.count > 0
        THEN
            l_rank_p1_type_request := i_context_vals(1);
        
            SELECT sd.val
              INTO l_flg_p1_type_request
              FROM sys_domain sd
             WHERE sd.id_language = l_lang
               AND sd.code_domain = 'P1_EXTERNAL_REQUEST.FLG_TYPE'
               AND sd.rank = l_rank_p1_type_request
               AND rownum = 1;
        
        END IF;
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('i_id_patient', l_id_patient);
    
        CASE i_name
            WHEN 'lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_flg_type' THEN
                o_vc2 := l_flg_p1_type_request;
        END CASE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_P1_EXT_SYS',
                                              i_function => 'INIT_PARAMS_GRID',
                                              o_error    => l_error);
    END init_params_list;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_ext_sys;
/
