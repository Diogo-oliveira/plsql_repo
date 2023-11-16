/*-- Last Change Revision: $Rev: 2027511 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:27 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_problems IS

    FUNCTION get_pat_problem_tf_dash
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_history_diagnosis.id_patient%TYPE,
        i_id_episode        IN pat_problem.id_episode%TYPE,
        i_flg_visit_or_epis IN VARCHAR2,
        i_tv_flg_status     IN table_varchar,
        i_tv_flg_type       IN table_varchar,
        i_dt_ini            IN VARCHAR2,
        i_dt_end            IN VARCHAR2
    ) RETURN pat_problem_table
        PIPELINED IS
    
        l_count NUMBER(12);
    
    BEGIN
    
        IF i_tv_flg_type IS NULL
        THEN
            l_count := 0;
        ELSE
            l_count := i_tv_flg_type.count;
        END IF;
    
        g_error := 'CALL get_pat_problem_tf';
        FOR row_i IN (SELECT *
                        FROM TABLE(get_pat_problem_tf(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_pat     => i_id_patient,
                                                      i_status  => i_tv_flg_status,
                                                      i_type    => NULL,
                                                      i_problem => NULL,
                                                      i_episode => i_id_episode,
                                                      i_report  => i_flg_visit_or_epis,
                                                      i_dt_ini  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                 i_prof,
                                                                                                 i_dt_ini,
                                                                                                 NULL),
                                                      i_dt_end  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                 i_prof,
                                                                                                 i_dt_end,
                                                                                                 NULL))) tf
                       WHERE l_count = 0
                          OR tf.flg_source IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                                column_value
                                                 FROM TABLE(i_tv_flg_type) d))
        
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
        RETURN;
    
    END get_pat_problem_tf_dash;

    FUNCTION get_pat_problem_tf_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_history_diagnosis.id_patient%TYPE,
        i_status      IN table_varchar,
        i_type        IN VARCHAR2,
        i_problem     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_scopeid     IN pat_problem.id_episode%TYPE,
        i_flg_scope   IN VARCHAR2,
        i_dt_ini      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_show_ph     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_review IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pat_problem_table
        PIPELINED IS
    
    BEGIN
    
        g_error := 'CALL get_phd';
        FOR row_i IN (SELECT *
                        FROM (SELECT *
                                FROM TABLE(get_phd(i_lang,
                                                   i_prof,
                                                   i_pat,
                                                   i_status,
                                                   i_problem,
                                                   i_scopeid,
                                                   i_flg_scope,
                                                   i_dt_ini,
                                                   i_dt_end,
                                                   i_show_ph,
                                                   i_show_review)) phd1
                              UNION ALL
                              SELECT *
                                FROM TABLE(get_pp(i_lang,
                                                  i_prof,
                                                  i_pat,
                                                  i_status,
                                                  i_type,
                                                  i_problem,
                                                  i_scopeid,
                                                  i_flg_scope,
                                                  i_dt_ini,
                                                  i_dt_end)) pp2) t
                       WHERE t.flg_source IN (g_problem_type_pmh, g_problem_type_problem)
                          OR (t.flg_source = g_problem_type_diag)
                       ORDER BY rank_status, dt_order DESC)
        
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
        RETURN;
    END get_pat_problem_tf_cda;

    FUNCTION get_pat_problem_tf
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_type    IN VARCHAR2,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN pat_problem_table
        PIPELINED IS
    
        l_show_allergy sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_ALLERGY_IN_PROBLEM', i_prof);
        l_show_habit   sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_HABIT_IN_PROBLEM', i_prof);
    
    BEGIN
    
        g_error := 'CALL get_phd';
    
        FOR row_i IN (SELECT *
                        FROM (SELECT *
                                FROM TABLE(get_phd(i_lang,
                                                   i_prof,
                                                   i_pat,
                                                   i_status,
                                                   i_problem,
                                                   i_episode,
                                                   i_report,
                                                   i_dt_ini,
                                                   i_dt_end)) phd1
                              UNION ALL
                              SELECT *
                                FROM TABLE(get_pp(i_lang,
                                                  i_prof,
                                                  i_pat,
                                                  i_status,
                                                  i_type,
                                                  i_problem,
                                                  i_episode,
                                                  i_report,
                                                  i_dt_ini,
                                                  i_dt_end)) pp2
                              UNION ALL
                              SELECT *
                                FROM TABLE(get_pa(i_lang,
                                                  i_prof,
                                                  i_pat,
                                                  i_status,
                                                  i_problem,
                                                  i_episode,
                                                  i_report,
                                                  i_dt_ini,
                                                  i_dt_end))) t
                       WHERE t.flg_source IN (g_problem_type_pmh, g_problem_type_problem)
                          OR (t.flg_source = g_problem_type_allergy AND l_show_allergy = pk_alert_constant.g_yes)
                          OR (t.flg_source = g_problem_type_habit AND l_show_habit = pk_alert_constant.g_yes)
                          OR (t.flg_source = g_problem_type_diag)
                       ORDER BY rank_cancelled, rank_area, rank_status, dt_order DESC)
        
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
        RETURN;
    END get_pat_problem_tf;

    FUNCTION get_phd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_history_diagnosis.id_patient%TYPE,
        i_status      IN table_varchar,
        i_problem     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_id_scope    IN NUMBER,
        i_scope       IN VARCHAR2,
        i_dt_ini      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_show_ph     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_review IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pat_problem_table
        PIPELINED IS
    
        l_count                NUMBER;
        v_tab                  pat_problem_rec;
        c_result               pk_types.cursor_type;
        l_headerviolenceicon   sys_message.desc_message%TYPE := 'HeaderViolenceIcon';
        l_headervirusicon      sys_message.desc_message%TYPE := 'HeaderVirusIcon';
        l_problem_list_t069    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'PROBLEM_LIST_T069');
        l_common_m008          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M008');
        l_common_m028          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
        l_show_all             sys_config.value%TYPE := pk_sysconfig.get_config('SUMMARY_VIEW_ALL', i_prof);
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_sc_show_surgical     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                        i_prof);
        l_episode              table_number := table_number();
    BEGIN
        --find list of episodes
        IF i_scope = g_scope_visit
        THEN
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_pat,
                                                     i_id_episode        => NULL,
                                                     i_id_visit          => i_id_scope,
                                                     i_flg_visit_or_epis => i_scope);
        ELSE
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_pat,
                                                     i_id_episode        => i_id_scope,
                                                     i_id_visit          => NULL,
                                                     i_flg_visit_or_epis => i_scope);
        END IF;
    
        IF i_status IS NULL
        THEN
            l_count := 0;
        ELSE
            l_count := i_status.count;
        END IF;
    
        g_error := 'CALL get_phd';
        -------------------
        -- Relevant diseases
        -------------------  
        OPEN c_result FOR
            SELECT k.id_diagnosis id,
                   k.id_pat_history_diagnosis id_problem,
                   g_type_d TYPE,
                   pk_date_utils.date_char_tsz(i_lang,
                                               k.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_problem2,
                   decode(k.dt_diagnosed_precision,
                          g_unknown,
                          g_unknown,
                          pk_date_utils.date_send_tsz(i_lang, k.dt_diagnosed, i_prof)) dt_problem,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => k.dt_diagnosed,
                                                           i_precision => k.dt_diagnosed_precision) dt_problem_to_print,
                   decode(k.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => k.id_alert_diagnosis,
                                                     i_id_diagnosis       => k.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => k.flg_area,
                                                                                                    i_flg_type => k.flg_type),
                                                     i_code               => k.code_icd,
                                                     i_flg_other          => k.flg_other,
                                                     i_flg_std_diag       => k.flg_icd9),
                          decode(k.id_alert_diagnosis,
                                 NULL,
                                 k.desc_pat_history_diagnosis,
                                 k.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => k.id_alert_diagnosis,
                                                            i_id_diagnosis       => k.id_diagnosis,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => k.flg_area,
                                                                                                           i_flg_type => k.flg_type),
                                                            i_code               => k.code_icd,
                                                            i_flg_other          => k.flg_other,
                                                            i_flg_std_diag       => k.flg_icd9))) desc_probl,
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => k.flg_area,
                                         i_id_alert_diagnosis => k.id_alert_diagnosis,
                                         i_flg_type           => k.flg_type) title,
                   decode(k.id_alert_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh) flg_source,
                   pk_date_utils.date_send_tsz(i_lang, k.dt_pat_history_diagnosis_tstz, i_prof) dt_order,
                   flg_status,
                   pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', k.flg_status) rank_type,
                   decode(k.flg_status, g_cancelled, 1, 0) rank_cancelled,
                   pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', k.flg_area) rank_area,
                   decode(k.flg_status, 'C', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', k.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', k.flg_nature, i_lang) desc_nature,
                   pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', k.flg_status) rank_status,
                   nvl(pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_NATURE', k.flg_nature), -1) rank_nature,
                   k.flg_nature flg_nature,
                   decode(k.flg_status,
                          'C',
                          decode(k.cancel_notes, NULL, '', '(' || l_common_m008 || ')'),
                          decode(k.notes, NULL, '', '(' || l_common_m008 || ')')) title_notes,
                   decode(k.flg_status, 'C', k.cancel_notes, k.notes) prob_notes,
                   decode(k.flg_status, 'C', l_common_m028, '') title_canceled,
                   k.id_pat_history_diagnosis id_prob,
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => k.flg_area,
                                         i_id_alert_diagnosis => k.id_alert_diagnosis,
                                         i_flg_type           => k.flg_type) viewer_category,
                   
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => k.flg_area,
                                         i_id_alert_diagnosis => k.id_alert_diagnosis,
                                         i_flg_type           => k.flg_type) viewer_category_desc,
                   k.id_professional viewer_id_prof,
                   k.id_episode viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, k.dt_pat_history_diagnosis_tstz, i_prof) viewer_date,
                   pk_problems.get_registered_by_me(i_prof, k.id_pat_history_diagnosis, g_type_d) registered_by_me,
                   nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        k.id_professional,
                                                        k.dt_pat_history_diagnosis_tstz,
                                                        k.id_episode),
                       l_problem_list_t069) origin_specialty,
                   pk_prof_utils.get_prof_speciality_id(i_lang,
                                                        profissional(k.id_professional,
                                                                     i_prof.institution,
                                                                     i_prof.software)) id_origin_specialty,
                   pk_problems.get_pat_precaution_list_desc(i_lang, i_prof, k.id_pat_history_diagnosis) precaution_measures_str,
                   pk_problems.get_pat_precaution_list_cod(i_lang, i_prof, k.id_pat_history_diagnosis) id_precaution_measures,
                   k.flg_warning header_warning,
                   pk_sysdomain.get_domain(pk_list.g_yes_no, k.flg_warning, i_lang) header_warning_str,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => k.dt_resolved,
                                                           i_precision => k.dt_resolved_precision) resolution_date_str,
                   decode(k.dt_resolved_precision,
                          pk_past_history.g_date_unknown,
                          pk_past_history.g_date_unknown,
                          pk_date_utils.date_send_tsz(i_lang, k.dt_resolved, i_prof)) resolution_date,
                   k.dt_resolved_precision dt_resolved_precision,
                   decode((SELECT pk_alert_constant.g_yes
                            FROM diag_diag_condition ddc
                           WHERE ddc.id_software IN (0, i_prof.software)
                             AND ddc.id_institution IN (0, i_prof.institution)
                             AND ddc.id_diagnosis IN
                                 (k.id_diagnosis,
                                  (SELECT ad1.id_diagnosis
                                     FROM alert_diagnosis ad1
                                    WHERE ad1.id_alert_diagnosis = k.id_alert_diagnosis))
                             AND rownum = 1),
                          pk_alert_constant.g_yes,
                          l_headervirusicon,
                          decode(k.flg_warning, pk_alert_constant.g_yes, l_headerviolenceicon, NULL)) warning_icon,
                   get_review(i_lang,
                              i_prof,
                              k.id_pat_history_diagnosis,
                              decode(k.id_alert_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh),
                              k.id_episode,
                              k.flg_status) review_info,
                   NULL,
                   get_flg_area(i_flg_area => k.flg_area, i_flg_type => k.flg_type) flg_area,
                   id_terminology_version,
                   id_content,
                   code_icd,
                   term_international_code,
                   get_flg_info_button(i_lang, i_prof, k.id_diagnosis) flg_info_button,
                   k.dt_pat_history_diagnosis_tstz update_time,
                   pk_past_history.get_partial_date_format_serial(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_date      => k.dt_diagnosed,
                                                                  i_precision => k.dt_diagnosed_precision) dt_problem_serial,
                   k.id_professional id_professional,
                   k.dt_pat_history_diagnosis_tstz dt_updated
              FROM (SELECT --p.id_professional,
                     d.id_diagnosis,
                     phd.id_pat_history_diagnosis,
                     phd.dt_pat_history_diagnosis_tstz,
                     phd.dt_diagnosed_precision,
                     phd.dt_diagnosed,
                     phd.desc_pat_history_diagnosis,
                     ad.id_alert_diagnosis,
                     phd.flg_area,
                     phd.flg_type,
                     d.code_icd,
                     d.flg_other,
                     ad.flg_icd9,
                     phd.flg_status flg_status,
                     phd.flg_nature,
                     phd.cancel_notes,
                     phd.notes,
                     phd.id_professional,
                     phd.id_episode,
                     phd.flg_warning,
                     phd.dt_resolved,
                     phd.dt_resolved_precision,
                     d.id_terminology_version,
                     d.id_content,
                     d.term_international_code
                      FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                     WHERE phd.id_pat_history_diagnosis = nvl(i_problem, phd.id_pat_history_diagnosis)
                       AND phd.id_diagnosis = d.id_diagnosis(+)
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND phd.id_patient = i_pat
                       AND phd.dt_pat_history_diagnosis_tstz BETWEEN nvl(i_dt_ini, phd.dt_pat_history_diagnosis_tstz) AND
                           nvl(i_dt_end, current_timestamp)
                       AND phd.flg_type IN
                           (pk_past_history.g_alert_diag_type_med, pk_past_history.g_alert_diag_type_surg)
                       AND (l_count = 0 OR
                           phd.flg_status IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                                column_value
                                                 FROM TABLE(i_status) d))
                       AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                       AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                           (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                           phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
                       AND ((l_sc_show_surgical = g_yes) OR phd.flg_area <> pk_alert_constant.g_diag_area_surgical_hist)
                       AND (i_show_ph = pk_alert_constant.g_yes OR
                           (i_show_ph = pk_alert_constant.g_no AND
                           phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
                          --eliminate outdated records due to editions
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                           phd.id_alert_diagnosis IS NULL)
                          --
                       AND NOT EXISTS
                     (SELECT 1
                              FROM pat_problem pp, epis_diagnosis ed, diagnosis d1
                             WHERE pp.id_diagnosis = d.id_diagnosis
                               AND pp.id_alert_diagnosis(+) = phd.id_alert_diagnosis
                               AND pp.id_patient = phd.id_patient
                               AND pp.id_habit IS NULL
                               AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                               AND pp.id_diagnosis = d1.id_diagnosis(+)
                               AND nvl(d1.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                               AND (nvl(d1.flg_type, 'Y') <> pk_diagnosis.g_diag_type_x OR
                                   (d1.flg_type = pk_diagnosis.g_diag_type_x AND l_show_all = pk_alert_constant.g_yes))
                               AND ( --final diagnosis 
                                    (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                                    OR -- differencial diagnosis only 
                                    (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                    ed.id_diagnosis NOT IN
                                    (SELECT ed3.id_diagnosis
                                        FROM epis_diagnosis ed3
                                       WHERE ed3.id_diagnosis = ed.id_diagnosis
                                         AND ed3.id_patient = pp.id_patient
                                         AND ed3.flg_type = pk_diagnosis.g_diag_type_d)) --
                                    OR -- n??m diagn?co
                                    (pp.id_habit IS NOT NULL))
                               AND pp.flg_status <> g_pat_probl_invest
                               AND pp.dt_pat_problem_tstz > phd.dt_pat_history_diagnosis_tstz
                               AND rownum = 1
                               AND pp.dt_pat_problem_tstz BETWEEN nvl(i_dt_ini, pp.dt_pat_problem_tstz) AND
                                   nvl(i_dt_end, current_timestamp))
                    UNION ALL
                    SELECT d.id_diagnosis,
                           phd.id_pat_history_diagnosis      id_problem,
                           phd.dt_pat_history_diagnosis_tstz,
                           phd.dt_diagnosed_precision,
                           phd.dt_diagnosed,
                           phd.desc_pat_history_diagnosis,
                           ad.id_alert_diagnosis,
                           phd.flg_area,
                           phd.flg_type,
                           d.code_icd,
                           d.flg_other,
                           ad.flg_icd9,
                           phd.flg_status                    flg_status,
                           phd.flg_nature,
                           phd.cancel_notes,
                           phd.notes,
                           phd.id_professional,
                           i_id_scope                        id_episode,
                           phd.flg_warning,
                           phd.dt_resolved,
                           phd.dt_resolved_precision,
                           d.id_terminology_version,
                           d.id_content,
                           d.term_international_code
                      FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                     WHERE phd.id_pat_history_diagnosis = nvl(i_problem, phd.id_pat_history_diagnosis)
                       AND phd.id_diagnosis = d.id_diagnosis(+)
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND phd.id_patient = i_pat
                       AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                       AND phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)
                          --eliminate outdated records due to editions
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                           phd.id_alert_diagnosis IS NULL)
                       AND i_show_review = pk_alert_constant.g_yes
                       AND phd.id_pat_history_diagnosis IN
                           (SELECT /*+ opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(pk_past_history.get_past_hist_ids_review(i_lang        => i_lang,
                                                                                  i_prof        => i_prof,
                                                                                  i_episode     => l_episode,
                                                                                  i_flg_context => pk_review.get_past_history_context,
                                                                                  i_flg_area    => table_varchar(pk_alert_constant.g_diag_area_problems),
                                                                                  i_doc_area    => NULL)) t)) k
             WHERE nvl(i_scope, g_report_p) = g_report_p
                OR k.id_episode IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                     j.column_value
                                      FROM TABLE(l_episode) j);
    
        LOOP
            FETCH c_result
                INTO v_tab;
            EXIT WHEN c_result%NOTFOUND;
            PIPE ROW(v_tab);
        END LOOP;
    
        RETURN;
    END get_phd;

    FUNCTION get_pp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_type    IN VARCHAR2,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_problem.dt_pat_problem_tstz%TYPE,
        i_dt_end  IN pat_problem.dt_pat_problem_tstz%TYPE
    ) RETURN pat_problem_table
        PIPELINED IS
        l_count             NUMBER;
        v_tab               pat_problem_rec;
        c_result            pk_types.cursor_type;
        l_problem_list_t069 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069');
        l_show_all          sys_config.value%TYPE := pk_sysconfig.get_config('SUMMARY_VIEW_ALL', i_prof);
        l_problems_m001     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M001');
        l_common_m008       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M008');
        l_problems_m009     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M009');
    
        l_common_m028   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
        l_problems_m008 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M008');
        l_problems_m007 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M007');
        l_problems_m006 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M006');
        l_episode       table_number := table_number();
    
        l_allow_diagnoses_same_icd sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_PROBLEMS_SAME_ICD', i_prof);
    
    BEGIN
        --find list of episodes
        IF i_report = g_scope_visit
        THEN
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_pat,
                                                     i_id_episode        => NULL,
                                                     i_id_visit          => i_episode,
                                                     i_flg_visit_or_epis => i_report);
        ELSE
            l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_pat,
                                                     i_id_episode        => i_episode,
                                                     i_id_visit          => NULL,
                                                     i_flg_visit_or_epis => i_report);
        END IF;
    
        IF i_status IS NULL
        THEN
            l_count := 0;
        ELSE
            l_count := i_status.count;
        END IF;
    
        g_error := 'CALL get_pp';
        OPEN c_result FOR
            SELECT *
              FROM (SELECT /*+ push_pred(d) push_pred(d1) */
                     pp.id_diagnosis id,
                     pp.id_pat_problem id_problem,
                     g_type_p TYPE,
                     pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_problem2,
                     decode(pp.year_begin,
                            g_year_unknown,
                            g_unknown,
                            pp.year_begin || lpad(pp.month_begin, 2, '0') || lpad(pp.day_begin, 2, '0')) dt_problem,
                     get_dt_str(i_lang, i_prof, pp.year_begin, pp.month_begin, pp.day_begin) dt_problem_to_print,
                     decode(pp.desc_pat_problem,
                            '',
                            decode(pp.id_habit,
                                   '',
                                   decode(nvl(ed.id_epis_diagnosis, 0),
                                          0,
                                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                     i_id_diagnosis       => d.id_diagnosis,
                                                                     i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                     i_code               => d.code_icd,
                                                                     i_flg_other          => d.flg_other,
                                                                     i_flg_std_diag       => ad.flg_icd9),
                                          pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                     i_id_diagnosis        => d1.id_diagnosis,
                                                                     i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                     i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                     i_code                => d1.code_icd,
                                                                     i_flg_other           => d1.flg_other,
                                                                     i_flg_std_diag        => ad1.flg_icd9,
                                                                     i_epis_diag           => ed.id_epis_diagnosis)),
                                   pk_translation.get_translation(i_lang, h.code_habit)),
                            pp.desc_pat_problem) desc_probl,
                     decode(pp.desc_pat_problem,
                            '',
                            decode(pp.id_habit,
                                   '',
                                   decode(nvl(ed.id_epis_diagnosis, 0),
                                          0,
                                          l_problems_m009,
                                          decode(ed.flg_type, g_epis_diag_passive, l_problems_m008, l_problems_m007)),
                                   l_problems_m006),
                            decode(pp.id_diagnosis, NULL, l_problems_m001, l_problems_m009)) title,
                     decode(pp.desc_pat_problem,
                            '',
                            decode(pp.id_habit,
                                   '',
                                   decode(nvl(ed.id_epis_diagnosis, 0), 0, g_problem_type_pmh, g_problem_type_diag),
                                   g_problem_type_habit),
                            decode(pp.id_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh)) flg_source,
                     pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order,
                     decode(nvl(ed.id_epis_diagnosis, 0),
                            0,
                            pp.flg_status,
                            decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status)) flg_status,
                     pk_sysdomain.get_rank(i_lang,
                                           'PAT_PROBLEM.FLG_STATUS',
                                           decode(nvl(ed.id_epis_diagnosis, 0),
                                                  0,
                                                  pp.flg_status,
                                                  decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status))) rank_type,
                     decode(pp.flg_status, g_cancelled, 1, 0) rank_cancelled,
                     NULL rank_area,
                     decode(decode(nvl(ed.id_epis_diagnosis, 0),
                                   0,
                                   pp.flg_status,
                                   decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status)),
                            g_pat_probl_cancel,
                            pk_alert_constant.g_yes,
                            pk_alert_constant.g_no) flg_cancel,
                     decode(nvl(ed.id_epis_diagnosis, 0),
                            0,
                            pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang),
                            decode(ed.flg_status,
                                   'C',
                                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', ed.flg_status, i_lang),
                                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang))) desc_status,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp.flg_nature, i_lang) desc_nature,
                     pk_sysdomain.get_rank(i_lang,
                                           'PAT_PROBLEM.FLG_STATUS',
                                           decode(nvl(ed.id_epis_diagnosis, 0),
                                                  0,
                                                  pp.flg_status,
                                                  decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status))) rank_status,
                     nvl(pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_NATURE', pp.flg_nature), -1) rank_nature,
                     pp.flg_nature,
                     decode(pp.flg_status,
                            'C',
                            decode(pp.cancel_notes, NULL, '', '(' || l_common_m008 || ')'),
                            decode(pp.notes, NULL, '', '(' || l_common_m008 || ')')) title_notes,
                     decode(pp.flg_status, 'C', pp.cancel_notes, pp.notes) prob_notes,
                     decode(decode(nvl(ed.id_epis_diagnosis, 0),
                                   0,
                                   pp.flg_status,
                                   decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status)),
                            g_pat_probl_cancel,
                            l_common_m028,
                            '') title_canceled,
                     nvl(pp.id_habit, pp.id_diagnosis) id_prob,
                     --needed for the problems screen on Viewer
                     decode(pp.desc_pat_problem,
                            '',
                            decode(pp.id_habit,
                                   '',
                                   decode(nvl(ed.id_epis_diagnosis, 0),
                                          0,
                                          l_problems_m009,
                                          decode(ed.flg_type, g_epis_diag_passive, l_problems_m008, l_problems_m007)),
                                   l_problems_m006),
                            decode(pp.id_diagnosis, NULL, l_problems_m001, l_problems_m009)) viewer_category,
                     decode(pp.desc_pat_problem,
                            '',
                            decode(pp.id_habit,
                                   '',
                                   decode(nvl(ed.id_epis_diagnosis, 0),
                                          0,
                                          l_problems_m009,
                                          decode(ed.flg_type, g_epis_diag_passive, l_problems_m008, l_problems_m007)),
                                   l_problems_m006),
                            decode(pp.id_diagnosis, NULL, l_problems_m001, l_problems_m009)) viewer_category_desc,
                     pp.id_professional_ins viewer_id_prof,
                     pp.id_episode viewer_id_epis,
                     pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) viewer_date,
                     pk_problems.get_registered_by_me(i_prof, nvl(i_problem, pp.id_pat_problem), g_type_p) registered_by_me,
                     nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                          i_prof,
                                                          pp.id_professional_ins,
                                                          pp.dt_pat_problem_tstz,
                                                          pp.id_episode),
                         l_problem_list_t069) origin_specialty,
                     pk_prof_utils.get_prof_speciality_id(i_lang,
                                                          profissional(pp.id_professional_ins,
                                                                       i_prof.institution,
                                                                       i_prof.software)) id_origin_specialty,
                     table_varchar() precaution_measures_str,
                     table_number() id_precaution_measures,
                     NULL header_warning,
                     NULL header_warning_str,
                     get_dt_str(i_lang, i_prof, pp.dt_resolution) resolution_date_str,
                     pp.dt_resolution resolution_date,
                     NULL dt_resolved_precision,
                     NULL warning_icon,
                     get_review(i_lang,
                                i_prof,
                                pp.id_pat_problem,
                                decode(pp.desc_pat_problem,
                                       '',
                                       decode(pp.id_habit,
                                              '',
                                              decode(nvl(ed.id_epis_diagnosis, 0),
                                                     0,
                                                     g_problem_type_pmh,
                                                     g_problem_type_diag),
                                              g_problem_type_habit),
                                       decode(pp.id_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh)),
                                pp.id_episode,
                                decode(nvl(ed.id_epis_diagnosis, 0),
                                       0,
                                       pp.flg_status,
                                       decode(ed.flg_status, 'C', ed.flg_status, pp.flg_status))) review_info,
                     pp.id_pat_habit,
                     NULL flg_area,
                     d.id_terminology_version,
                     d.id_content,
                     d.code_icd,
                     d.term_international_code,
                     get_flg_info_button(i_lang, i_prof, d.id_diagnosis) flg_info_button,
                     pp.dt_pat_problem_tstz update_time,
                     
                     CASE
                          WHEN pp.year_begin IS NOT NULL
                               AND pp.month_begin IS NOT NULL
                               AND pp.day_begin IS NOT NULL THEN
                           to_char(to_timestamp(pp.year_begin || lpad(pp.month_begin, 2, '0') ||
                                                lpad(pp.day_begin, 2, '0'),
                                                'YYYYMMDD'),
                                   'YYYYMMDD')
                          ELSE
                           to_char(pp.year_begin)
                      END dt_problem_serial,
                     pp.id_professional_ins id_professional,
                     pp.dt_pat_problem_tstz dt_updated
                      FROM pat_problem     pp,
                           diagnosis       d,
                           alert_diagnosis ad,
                           professional    p,
                           epis_diagnosis  ed,
                           diagnosis       d1,
                           alert_diagnosis ad1,
                           habit           h
                     WHERE pp.id_pat_problem = nvl(i_problem, pp.id_pat_problem)
                       AND pp.id_patient = i_pat
                       AND pp.id_diagnosis = d.id_diagnosis(+)
                       AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+) -- ALERT 736: diagnosis synonyms
                       AND pp.id_professional_ins = p.id_professional(+)
                       AND (l_count = 0 OR pp.flg_status IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                                              column_value
                                                               FROM TABLE(i_status) d))
                       AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                       AND ed.id_diagnosis = d1.id_diagnosis(+)
                       AND ed.id_alert_diagnosis = ad1.id_alert_diagnosis(+) -- ALERT 736: diagnosis synonyms
                       AND pp.id_habit = h.id_habit(+)
                       AND (nvl(d.flg_type, 'Y') <> pk_diagnosis.g_diag_type_x OR
                           (d.flg_type = pk_diagnosis.g_diag_type_x AND l_show_all = pk_alert_constant.g_yes))
                       AND ((i_type = g_type_d AND pp.id_diagnosis = d.id_diagnosis) OR
                           (i_type = 'H' AND pp.id_habit = h.id_habit) OR
                           (i_type = g_type_p AND pp.id_diagnosis IS NULL AND pp.id_epis_diagnosis IS NULL) OR
                           (i_type = 'E' AND ed.id_epis_diagnosis = pp.id_epis_diagnosis) OR nvl(i_type, 'X') = 'X')
                          -- RdSN To exclude relev.diseases and problems
                       AND (pp.id_habit = h.id_habit OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
                       AND ( --final diagnosis 
                            (ed.flg_type = pk_diagnosis.g_diag_type_d) OR -- differencial diagnosis only 
                            (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                            ed.id_diagnosis NOT IN
                            (SELECT ed3.id_diagnosis
                                FROM epis_diagnosis ed3
                               WHERE ed3.id_diagnosis = ed.id_diagnosis
                                 AND ed3.id_patient = pp.id_patient
                                 AND ed3.flg_type = pk_diagnosis.g_diag_type_d
                                 AND ed3.flg_status != pk_diagnosis.g_ed_flg_status_ca
                                 AND ((l_allow_diagnoses_same_icd = pk_alert_constant.g_yes AND
                                     ed3.id_alert_diagnosis = pp.id_alert_diagnosis AND
                                     nvl(pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                                          i_id_concept_term    => ed3.id_alert_diagnosis,
                                                                          i_id_concept_version => ed3.id_diagnosis,
                                                                          i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                          i_id_institution     => i_prof.institution,
                                                                          i_id_software        => i_prof.software),
                                           pk_alert_constant.g_yes) = pk_alert_constant.g_yes) OR
                                     l_allow_diagnoses_same_icd = pk_alert_constant.g_no))) OR (pp.id_habit IS NOT NULL))
                       AND pp.dt_pat_problem_tstz BETWEEN nvl(i_dt_ini, pp.dt_pat_problem_tstz) AND
                           nvl(i_dt_end, current_timestamp)
                       AND NOT EXISTS
                     (SELECT 1
                              FROM pat_history_diagnosis phd
                              LEFT JOIN diagnosis d2
                                ON d2.id_diagnosis = phd.id_diagnosis
                             WHERE phd.id_patient = i_pat
                               AND phd.flg_type = g_flg_type_med
                               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                                   phd.id_alert_diagnosis IS NULL)
                               AND phd.id_diagnosis = pp.id_diagnosis
                               AND phd.id_alert_diagnosis = pp.id_alert_diagnosis
                               AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                               AND nvl(d2.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                               AND pp.dt_pat_problem_tstz < phd.dt_pat_history_diagnosis_tstz
                               AND rownum = 1
                               AND phd.dt_pat_history_diagnosis_tstz BETWEEN
                                   nvl(i_dt_ini, phd.dt_pat_history_diagnosis_tstz) AND nvl(i_dt_end, current_timestamp))) k
             WHERE nvl(i_report, g_report_p) = g_report_p
                OR k.viewer_id_epis IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                         j.column_value
                                          FROM TABLE(l_episode) j);
    
        LOOP
            FETCH c_result
                INTO v_tab;
            EXIT WHEN c_result%NOTFOUND;
            PIPE ROW(v_tab);
        END LOOP;
    
        RETURN;
    END get_pp;

    FUNCTION get_pa
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_allergy.dt_pat_allergy_tstz%TYPE,
        i_dt_end  IN pat_allergy.dt_pat_allergy_tstz%TYPE
    ) RETURN pat_problem_table
        PIPELINED IS
        l_count             NUMBER;
        v_tab               pat_problem_rec;
        c_result            pk_types.cursor_type;
        l_problem_list_t069 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069');
        l_common_m028       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
        l_common_m008       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M008');
    
        l_episode table_number := table_number();
    BEGIN
        --find list of episodes
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_pat,
                                                 i_id_episode        => i_episode,
                                                 i_flg_visit_or_epis => i_report);
        IF i_status IS NULL
        THEN
            l_count := 0;
        ELSE
            l_count := i_status.count;
        END IF;
    
        g_error := 'CALL get_pa';
        OPEN c_result FOR
            SELECT *
              FROM (SELECT NULL id,
                           pa.id_pat_allergy id_problem,
                           g_problem_type_allergy TYPE,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       pa.dt_pat_allergy_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_problem2,
                           to_char(pa.year_begin) dt_problem,
                           get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) dt_problem_to_print,
                           nvl2(pa.id_allergy, pk_translation.get_translation(i_lang, a.code_allergy), pa.desc_allergy) desc_probl, -- TB
                           pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) title, -- TB
                           g_problem_type_allergy flg_source,
                           pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                           pa.flg_status,
                           pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', pa.flg_status) rank_type,
                           decode(pa.flg_status, g_cancelled, 1, 0) rank_cancelled,
                           NULL rank_area,
                           decode(pa.flg_status, g_pat_allergy_cancel, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pa.flg_status, i_lang) desc_status,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pa.flg_nature, i_lang) desc_nature,
                           pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', pa.flg_status) rank_status,
                           nvl(pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_NATURE', pa.flg_nature), -1) rank_nature,
                           pa.flg_nature,
                           decode(pa.flg_status,
                                  g_pat_probl_cancel,
                                  decode(pa.cancel_notes, NULL, '', '(' || l_common_m008 || ')'),
                                  decode(pa.notes, NULL, '', '(' || l_common_m008 || ')')) title_notes,
                           decode(pa.flg_status, 'C', pa.cancel_notes, pa.notes) prob_notes,
                           decode(pa.flg_status, g_pat_probl_cancel, l_common_m028, '') title_canceled,
                           pa.id_allergy id_prob,
                           --needed for the problems screen on Viewer
                           pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) viewer_category,
                           pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) viewer_category_desc,
                           pa.id_prof_write viewer_id_prof,
                           pa.id_episode viewer_id_epis,
                           pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) viewer_date,
                           pk_problems.get_registered_by_me(i_prof, nvl(i_problem, pa.id_pat_allergy), g_type_a) registered_by_me,
                           nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                pa.id_prof_write,
                                                                pa.dt_pat_allergy_tstz,
                                                                pa.id_episode),
                               l_problem_list_t069) origin_specialty,
                           pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                profissional(pa.id_prof_write,
                                                                             i_prof.institution,
                                                                             i_prof.software)) id_origin_specialty,
                           
                           table_varchar() precaution_measures_str,
                           table_number() id_precaution_measures,
                           NULL header_warning,
                           NULL header_warning_str,
                           get_dt_str(i_lang, i_prof, pa.dt_resolution) resolution_date_str,
                           pa.dt_resolution resolution_date,
                           NULL dt_resolved_precision,
                           NULL warning_icon,
                           get_review(i_lang,
                                      i_prof,
                                      pa.id_pat_allergy,
                                      g_problem_type_allergy,
                                      pa.id_episode,
                                      pa.flg_status) review_info,
                           NULL,
                           NULL flg_area,
                           NULL id_terminology_version,
                           NULL id_content,
                           NULL code_icd,
                           NULL term_international_code,
                           pk_alert_constant.g_no flg_info_button,
                           pa.dt_pat_allergy_tstz update_time,
                           CASE
                                WHEN pa.year_begin IS NOT NULL
                                     AND pa.month_begin IS NOT NULL
                                     AND pa.day_begin IS NOT NULL THEN
                                 to_char(to_timestamp(pa.year_begin || lpad(pa.month_begin, 2, '0') ||
                                                      lpad(pa.day_begin, 2, '0'),
                                                      'YYYYMMDD'),
                                         'YYYYMMDD')
                                ELSE
                                 to_char(pa.year_begin)
                            END dt_problem_serial,
                           NULL dt_updated,
                           NULL id_professional
                      FROM pat_allergy pa, allergy a, professional p
                     WHERE pa.id_pat_allergy = nvl(i_problem, pa.id_pat_allergy)
                       AND pa.id_patient = i_pat
                       AND a.id_allergy(+) = pa.id_allergy -- TB
                       AND p.id_professional = pa.id_prof_write
                       AND (l_count = 0 OR pa.flg_status IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                                              column_value
                                                               FROM TABLE(i_status) d))
                       AND pa.dt_pat_allergy_tstz BETWEEN nvl(i_dt_ini, pa.dt_pat_allergy_tstz) AND
                           nvl(i_dt_end, current_timestamp)) k
             WHERE nvl(i_report, g_report_p) = g_report_p
                OR k.viewer_id_epis IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                         j.column_value
                                          FROM TABLE(l_episode) j);
    
        LOOP
            FETCH c_result
                INTO v_tab;
            EXIT WHEN c_result%NOTFOUND;
            PIPE ROW(v_tab);
        END LOOP;
    
        RETURN;
    END get_pa;

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_pat_problem';
    
        IF NOT get_pat_problem(i_lang                      => i_lang,
                               i_pat                       => i_pat,
                               i_status                    => i_status,
                               i_type                      => i_type,
                               i_prof                      => i_prof,
                               i_problem                   => NULL,
                               o_pat_problem               => o_pat_problem,
                               o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                               o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                               o_error                     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PAT_PROBLEM');
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_pat_problem);
                pk_types.open_my_cursor(o_pat_prob_unaware_active);
                pk_types.open_my_cursor(o_pat_prob_unaware_outdated); -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure
                RETURN FALSE;
            END;
    END get_pat_problem;

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_pat_problem';
    
        IF NOT get_pat_problem(i_lang                      => i_lang,
                               i_pat                       => i_pat,
                               i_status                    => i_status,
                               i_type                      => i_type,
                               i_prof                      => i_prof,
                               i_problem                   => i_problem,
                               i_episode                   => NULL,
                               i_report                    => NULL,
                               o_pat_problem               => o_pat_problem,
                               o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                               o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                               o_error                     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PAT_PROBLEM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_pat_problem);
                pk_types.open_my_cursor(o_pat_prob_unaware_active);
                pk_types.open_my_cursor(o_pat_prob_unaware_outdated); -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure
                RETURN FALSE;
            END;
    END get_pat_problem;

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL GET_PAT_PROBLEM_INTERNAL';
    
        IF NOT get_pat_problem_internal(i_lang                      => i_lang,
                                        i_pat                       => i_pat,
                                        i_status                    => i_status,
                                        i_type                      => i_type,
                                        i_prof                      => i_prof,
                                        i_problem                   => i_problem,
                                        i_episode                   => i_episode,
                                        i_report                    => i_report,
                                        o_pat_problem               => o_pat_problem,
                                        o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                                        o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                        o_error                     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PAT_PROBLEM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_pat_problem);
                pk_types.open_my_cursor(o_pat_prob_unaware_active);
                pk_types.open_my_cursor(o_pat_prob_unaware_outdated); -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure
                RETURN FALSE;
            END;
    END get_pat_problem;

    FUNCTION get_pat_problem_internal
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE DEFAULT NULL,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL PK_PROBLEMS.GET_PAT_PROBLEM_NEW';
        IF NOT pk_problems.get_pat_problem_new(i_lang                      => i_lang,
                                               i_pat                       => i_pat,
                                               i_status                    => i_status,
                                               i_type                      => i_type,
                                               i_prof                      => i_prof,
                                               i_problem                   => i_problem,
                                               i_episode                   => i_episode,
                                               i_report                    => i_report,
                                               o_pat_problem               => o_pat_problem,
                                               o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                                               o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                               o_error                     => o_error)
        THEN
            pk_types.open_my_cursor(o_pat_problem);
            pk_types.open_my_cursor(o_pat_prob_unaware_active);
            pk_types.open_my_cursor(o_pat_prob_unaware_outdated);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_pat_problem);
                pk_types.open_my_cursor(o_pat_prob_unaware_active);
                pk_types.open_my_cursor(o_pat_prob_unaware_outdated); -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_prob_active_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_epis_diagnosis OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PAT_PROB_ACTIVE_DIAG';
    
    BEGIN
        g_error := 'GET ACTIVE DIAGNOSIS_PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT id_epis_diagnosis
          BULK COLLECT
          INTO o_epis_diagnosis
          FROM pat_problem p
         WHERE p.id_epis_diagnosis IS NOT NULL
           AND p.flg_status = 'A'
           AND p.id_patient = i_patient
           AND p.id_episode <> nvl(i_episode, -1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_pat_prob_active_diag;

    FUNCTION get_problem_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_status OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status_excluded sys_config.value%TYPE := pk_sysconfig.get_config('PROBLEMS_STATUS_EXT', i_prof);
        l_tab_excluded    table_varchar := table_varchar();
    
    BEGIN
        l_tab_excluded := pk_string_utils.str_split(l_status_excluded, ',');
    
        g_error := 'GET DOMAIN';
        RETURN pk_sysdomain.get_values_domain(i_code_dom      => 'PAT_PROBLEM.FLG_STATUS',
                                              i_lang          => i_lang,
                                              o_data          => o_problem_status,
                                              i_vals_included => NULL,
                                              i_vals_excluded => l_tab_excluded);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PROBLEM_STATUS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem_status);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_problem_nature
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_nature OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'OPEN o_problem_nature';
        OPEN o_problem_nature FOR
            SELECT sd.desc_val, sd.val, sd.img_name, sd.rank
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'PAT_PROBLEM.FLG_NATURE', NULL)) sd;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PROBLEM_NATURE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem_nature);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_criteria      IN VARCHAR2,
        i_diag_parent   IN diagnosis.id_diagnosis_parent%TYPE,
        i_flg_type      IN diagnosis.flg_type%TYPE,
        i_prof          IN profissional,
        i_flg_task_type IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_types table_varchar;
        l_func  VARCHAR(20) := 'get_diagnosis';
    
    BEGIN
        IF i_flg_type IS NULL
        THEN
            l_types := table_varchar();
        ELSE
            l_types := table_varchar(i_flg_type);
        END IF;
    
        g_error := 'CALL get_diagnosis_mt_new';
        IF NOT get_diagnosis_mt_new(i_lang          => i_lang,
                                    i_episode       => i_episode,
                                    i_patient       => i_patient,
                                    i_prof          => i_prof,
                                    i_flg_type      => l_types,
                                    i_diag_parent   => i_diag_parent,
                                    i_criteria      => i_criteria,
                                    i_format_text   => pk_alert_constant.g_no,
                                    i_flg_task_type => i_flg_task_type,
                                    o_diagnosis     => o_diagnosis,
                                    o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diagnosis;

    FUNCTION get_diagnosis_mt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN table_varchar,
        i_diag_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_criteria    IN VARCHAR2,
        i_format_text IN VARCHAR2,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_default CONSTANT VARCHAR2(1) := 'I';
        --
        l_tbl_diags t_coll_diagnosis_config;
    BEGIN
        g_error := 'GET CONFIG';
    
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => NULL,
                                                               i_text_search              => i_criteria,
                                                               i_format_text              => i_format_text,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                               i_term_task_type           => pk_alert_constant.g_task_problems,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_tbl_terminologies        => i_flg_type,
                                                               i_parent_diagnosis         => i_diag_parent);
    
        -- diagnosis data
        g_error := 'GET CURSOR';
        OPEN o_diagnosis FOR
            SELECT /*+ordered use_nl(adrowids ad d)*/
            DISTINCT d.id_diagnosis,
                     d.desc_diagnosis, -- ALERT-736: diagnosis synonyms
                     l_flg_default flg_default,
                     d.flg_other,
                     d.avail_for_select flg_select,
                     NULL flg_icd,
                     d.id_alert_diagnosis,
                     (SELECT DISTINCT pk_alert_constant.g_yes
                        FROM diag_diag_condition ddc
                       WHERE ddc.id_diagnosis = d.id_diagnosis) flg_warning
              FROM TABLE(l_tbl_diags) d;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_DIAGNOSIS_MT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_diagnosis);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END get_diagnosis_mt;

    FUNCTION get_diagnosis_mt_new
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_diag_parent   IN diagnosis.id_diagnosis_parent%TYPE,
        i_criteria      IN VARCHAR2,
        i_format_text   IN VARCHAR2,
        i_flg_task_type IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_default CONSTANT VARCHAR2(1) := 'I';
        l_criteria_count PLS_INTEGER := 0;
    
        l_patient             patient.id_patient%TYPE;
        l_tbl_diags           t_coll_diagnosis_config;
        l_tbl_most_freq_diags t_coll_diagnosis_config;
        l_task_type           task_type.id_task_type%TYPE;
    BEGIN
    
        g_error := 'DECODE i_flg_task_type';
        pk_alertlog.log_debug(g_error);
        l_task_type := get_flg_area_task_type(i_flg_area => i_flg_task_type);
    
        IF i_patient IS NULL
        THEN
            SELECT e.id_patient
              INTO l_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
        ELSE
            l_patient := i_patient;
        END IF;
    
        l_criteria_count := length(i_criteria);
        IF i_flg_task_type IN (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_surgical_hist)
        THEN
            -- if it is a past history type, load most frequents as they are normally loaded in the past history screens
            IF NOT
                pk_past_history.get_past_hist_diagnoses(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_episode           => i_episode,
                                                        i_patient           => l_patient,
                                                        i_doc_area          => CASE i_flg_task_type
                                                                                   WHEN pk_past_history.g_alert_diag_type_surg THEN
                                                                                    pk_past_history.g_doc_area_past_surg
                                                                                   ELSE
                                                                                    pk_past_history.g_doc_area_past_med
                                                                               END,
                                                        i_text_search       => i_criteria,
                                                        i_flg_screen        => pk_alert_constant.g_diag_area_problems,
                                                        i_tbl_terminologies => i_flg_type,
                                                        o_diagnosis         => l_tbl_diags,
                                                        o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'GET CURSOR';
            OPEN o_diagnosis FOR
                SELECT fin.id_diagnosis,
                       fin.desc_diagnosis,
                       fin.flg_default,
                       fin.flg_other,
                       fin.flg_select,
                       fin.id_alert_diagnosis,
                       fin.flg_warning,
                       fin.dt_initial_diag,
                       fin.dt_initial_diag_rv,
                       NULL position,
                       fin.rank,
                       fin.notes,
                       fin.code_icd,
                       fin.id_epis_diagnosis
                  FROM (SELECT dc.id_diagnosis,
                               dc.desc_diagnosis,
                               l_flg_default flg_default,
                               dc.flg_other,
                               dc.avail_for_select flg_select,
                               dc.id_alert_diagnosis,
                               (SELECT DISTINCT pk_alert_constant.g_yes
                                  FROM diag_diag_condition ddc
                                 WHERE ddc.id_diagnosis = dc.id_diagnosis) flg_warning,
                               NULL dt_initial_diag,
                               NULL dt_initial_diag_rv,
                               '' notes,
                               dc.code_icd,
                               dc.id_epis_diagnosis,
                               dc.rank
                          FROM TABLE(l_tbl_diags) dc) fin
                 ORDER BY fin.rank, desc_diagnosis ASC;
        ELSIF (l_criteria_count IS NULL)
        THEN
            l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                   i_prof                     => i_prof,
                                                                   i_patient                  => l_patient,
                                                                   i_terminologies_task_types => table_number(l_task_type),
                                                                   i_term_task_type           => l_task_type,
                                                                   i_tbl_terminologies        => i_flg_type,
                                                                   i_list_type                => pk_diagnosis_core.g_diag_list_most_freq);
        
            g_error := 'GET CURSOR';
            OPEN o_diagnosis FOR
                SELECT fin2.id_diagnosis,
                       fin2.desc_diagnosis,
                       fin2.flg_default,
                       fin2.flg_other,
                       fin2.flg_select,
                       fin2.id_alert_diagnosis,
                       fin2.flg_warning,
                       fin2.rownumber,
                       fin2.dt_initial_diag,
                       fin2.dt_initial_diag_rv,
                       fin2.position,
                       fin2.rank,
                       fin2.notes,
                       fin2.code_icd,
                       fin2.id_epis_diagnosis
                  FROM (SELECT fin.id_diagnosis,
                               fin.desc_diagnosis,
                               fin.flg_default,
                               fin.flg_other,
                               fin.flg_select,
                               fin.id_alert_diagnosis,
                               fin.flg_warning,
                               row_number() over(PARTITION BY fin.id_alert_diagnosis ORDER BY fin.position) rownumber,
                               fin.dt_initial_diag,
                               fin.dt_initial_diag_rv,
                               fin.position,
                               fin.notes,
                               fin.code_icd,
                               fin.id_epis_diagnosis,
                               fin.rank
                          FROM (SELECT dc.id_diagnosis,
                                       dc.desc_diagnosis,
                                       l_flg_default flg_default,
                                       dc.flg_other,
                                       dc.avail_for_select flg_select,
                                       dc.id_alert_diagnosis,
                                       (SELECT DISTINCT pk_alert_constant.g_yes
                                          FROM diag_diag_condition ddc
                                         WHERE ddc.id_diagnosis = dc.id_diagnosis) flg_warning,
                                       NULL dt_initial_diag,
                                       NULL dt_initial_diag_rv,
                                       2 position,
                                       '' notes,
                                       dc.code_icd,
                                       dc.id_epis_diagnosis,
                                       dc.rank
                                  FROM TABLE(l_tbl_diags) dc
                                UNION ALL
                                SELECT tb_epis.id_diagnosis,
                                       tb_epis.desc_diagnosis desc_diagnosis,
                                       pk_alert_constant.g_no AS flg_default,
                                       tb_epis.flg_other,
                                       pk_alert_constant.g_yes AS flg_select,
                                       tb_epis.id_alert_diagnosis AS id_alert_diagnosis,
                                       (SELECT DISTINCT pk_alert_constant.g_yes
                                          FROM diag_diag_condition ddc
                                         WHERE ddc.id_diagnosis = tb_epis.id_diagnosis) flg_warning,
                                       tb_epis.dt_initial_diag_chr dt_initial_diag,
                                       pk_date_utils.date_send_tsz(i_lang, tb_epis.dt_epis_diagnosis, i_prof) dt_initial_diag_rv,
                                       1 position,
                                       tb_epis.notes notes,
                                       NULL code_icd,
                                       tb_epis.id_epis_diagnosis,
                                       tb_epis.rank
                                  FROM TABLE(pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => i_lang,
                                                                                          i_prof        => i_prof,
                                                                                          i_patient     => l_patient,
                                                                                          i_id_scope    => i_episode,
                                                                                          i_flg_scope   => pk_patient.g_scope_episode,
                                                                                          i_flg_type    => pk_diagnosis.g_diag_type_p,
                                                                                          i_criteria    => i_criteria,
                                                                                          i_format_text => i_format_text,
                                                                                          i_tbl_status  => table_varchar(pk_diagnosis.g_ed_flg_status_d,
                                                                                                                         pk_diagnosis.g_ed_flg_status_co,
                                                                                                                         pk_diagnosis.g_ed_flg_status_b))) tb_epis) fin) fin2
                 WHERE fin2.rownumber = 1
                 ORDER BY position, rank, desc_diagnosis ASC;
        ELSIF (l_criteria_count < g_search_number_char)
        THEN
            l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                   i_prof                     => i_prof,
                                                                   i_patient                  => l_patient,
                                                                   i_text_search              => i_criteria,
                                                                   i_format_text              => i_format_text,
                                                                   i_terminologies_task_types => table_number(l_task_type),
                                                                   i_term_task_type           => l_task_type,
                                                                   i_list_type                => pk_diagnosis_core.g_diag_list_most_freq,
                                                                   i_tbl_terminologies        => i_flg_type);
        
            g_error := 'GET CURSOR';
            OPEN o_diagnosis FOR
                SELECT fin2.id_diagnosis,
                       fin2.desc_diagnosis,
                       fin2.flg_default,
                       fin2.flg_other,
                       fin2.flg_select,
                       fin2.id_alert_diagnosis,
                       fin2.flg_warning,
                       fin2.rownumber,
                       fin2.dt_initial_diag,
                       fin2.dt_initial_diag_rv,
                       fin2.position,
                       fin2.rank,
                       fin2.notes,
                       fin2.code_icd,
                       fin2.id_epis_diagnosis
                  FROM (SELECT fin.id_diagnosis,
                               fin.desc_diagnosis,
                               fin.flg_default,
                               fin.flg_other,
                               fin.flg_select,
                               fin.id_alert_diagnosis,
                               fin.flg_warning,
                               row_number() over(PARTITION BY fin.id_alert_diagnosis ORDER BY fin.position) rownumber,
                               fin.dt_initial_diag,
                               fin.dt_initial_diag_rv,
                               fin.position,
                               fin.notes,
                               fin.code_icd,
                               fin.id_epis_diagnosis,
                               fin.rank
                          FROM (SELECT dc.id_diagnosis,
                                       dc.desc_diagnosis,
                                       l_flg_default flg_default,
                                       dc.flg_other,
                                       dc.avail_for_select flg_select,
                                       dc.id_alert_diagnosis,
                                       (SELECT DISTINCT pk_alert_constant.g_yes
                                          FROM diag_diag_condition ddc
                                         WHERE ddc.id_diagnosis = dc.id_diagnosis) flg_warning,
                                       NULL dt_initial_diag,
                                       NULL dt_initial_diag_rv,
                                       2 position,
                                       '' notes,
                                       dc.code_icd,
                                       dc.id_epis_diagnosis,
                                       dc.rank
                                  FROM TABLE(l_tbl_diags) dc
                                UNION ALL
                                SELECT tb_epis.id_diagnosis,
                                       tb_epis.desc_diagnosis desc_diagnosis,
                                       pk_alert_constant.g_no AS flg_default,
                                       tb_epis.flg_other,
                                       pk_alert_constant.g_yes AS flg_select,
                                       tb_epis.id_alert_diagnosis AS id_alert_diagnosis,
                                       (SELECT DISTINCT pk_alert_constant.g_yes
                                          FROM diag_diag_condition ddc
                                         WHERE ddc.id_diagnosis = tb_epis.id_diagnosis) flg_warning,
                                       tb_epis.dt_initial_diag_chr dt_initial_diag,
                                       pk_date_utils.date_send_tsz(i_lang, tb_epis.dt_epis_diagnosis, i_prof) dt_initial_diag_rv,
                                       1 position,
                                       tb_epis.notes notes,
                                       NULL code_icd,
                                       tb_epis.id_epis_diagnosis,
                                       tb_epis.rank
                                  FROM TABLE(pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => i_lang,
                                                                                          i_prof        => i_prof,
                                                                                          i_patient     => l_patient,
                                                                                          i_id_scope    => i_episode,
                                                                                          i_flg_scope   => pk_patient.g_scope_episode,
                                                                                          i_flg_type    => pk_diagnosis.g_diag_type_p,
                                                                                          i_criteria    => i_criteria,
                                                                                          i_format_text => i_format_text,
                                                                                          i_tbl_status  => table_varchar(pk_diagnosis.g_ed_flg_status_d,
                                                                                                                         pk_diagnosis.g_ed_flg_status_co,
                                                                                                                         pk_diagnosis.g_ed_flg_status_b))) tb_epis) fin) fin2
                 WHERE fin2.rownumber = 1
                 ORDER BY position, rank, desc_diagnosis ASC;
        ELSE
            l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                   i_prof                     => i_prof,
                                                                   i_patient                  => l_patient,
                                                                   i_text_search              => i_criteria,
                                                                   i_format_text              => i_format_text,
                                                                   i_terminologies_task_types => table_number(l_task_type),
                                                                   i_term_task_type           => l_task_type,
                                                                   i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                   i_tbl_terminologies        => i_flg_type,
                                                                   i_parent_diagnosis         => i_diag_parent);
        
            l_tbl_most_freq_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                             i_prof                     => i_prof,
                                                                             i_patient                  => l_patient,
                                                                             i_text_search              => i_criteria,
                                                                             i_format_text              => i_format_text,
                                                                             i_terminologies_task_types => table_number(l_task_type),
                                                                             i_term_task_type           => l_task_type,
                                                                             i_list_type                => pk_diagnosis_core.g_diag_list_most_freq);
        
            g_error := 'GET CURSOR';
            OPEN o_diagnosis FOR
                SELECT fin2.id_diagnosis,
                       fin2.desc_diagnosis,
                       fin2.flg_default,
                       fin2.flg_other,
                       fin2.flg_select,
                       fin2.id_alert_diagnosis,
                       fin2.flg_warning,
                       fin2.rownumber,
                       fin2.dt_initial_diag,
                       fin2.dt_initial_diag_rv,
                       fin2.position,
                       fin2.rank,
                       fin2.notes,
                       fin2.code_icd,
                       fin2.id_epis_diagnosis
                  FROM (SELECT DISTINCT fin.id_diagnosis,
                                        fin.desc_diagnosis,
                                        fin.flg_default,
                                        fin.flg_other,
                                        fin.flg_select,
                                        fin.id_alert_diagnosis,
                                        fin.flg_warning,
                                        row_number() over(PARTITION BY fin.id_alert_diagnosis ORDER BY fin.position) rownumber,
                                        fin.dt_initial_diag,
                                        fin.dt_initial_diag_rv,
                                        fin.position,
                                        fin.notes,
                                        fin.code_icd,
                                        fin.id_epis_diagnosis,
                                        fin.rank
                          FROM (SELECT /*+opt_estimate (table tf rows=0.0001)*/
                                 dc.id_diagnosis,
                                 dc.desc_diagnosis, -- ALERT-736: diagnosis synonyms
                                 l_flg_default flg_default,
                                 dc.flg_other,
                                 avail_for_select flg_select,
                                 dc.id_alert_diagnosis,
                                 (SELECT DISTINCT pk_alert_constant.g_yes
                                    FROM diag_diag_condition ddc
                                   WHERE ddc.id_diagnosis = dc.id_diagnosis) flg_warning,
                                 NULL dt_initial_diag,
                                 NULL dt_initial_diag_rv,
                                 decode(dc.flg_other, pk_alert_constant.g_yes, 999999999, 3) position,
                                 '' notes,
                                 dc.code_icd,
                                 dc.id_epis_diagnosis,
                                 dc.rank
                                  FROM TABLE(l_tbl_diags) dc
                                -- Differencial Diagnoses 
                                UNION ALL
                                SELECT tb_epis.id_diagnosis,
                                       tb_epis.desc_diagnosis desc_diagnosis,
                                       pk_alert_constant.g_no AS flg_default,
                                       tb_epis.flg_other,
                                       pk_alert_constant.g_yes AS flg_select,
                                       tb_epis.id_alert_diagnosis AS id_alert_diagnosis,
                                       (SELECT DISTINCT pk_alert_constant.g_yes
                                          FROM diag_diag_condition ddc
                                         WHERE ddc.id_diagnosis = tb_epis.id_diagnosis) flg_warning,
                                       tb_epis.dt_initial_diag_chr dt_initial_diag,
                                       pk_date_utils.date_send_tsz(i_lang, tb_epis.dt_epis_diagnosis, i_prof) dt_initial_diag_rv,
                                       1 position,
                                       tb_epis.notes notes,
                                       NULL code_icd,
                                       tb_epis.id_epis_diagnosis,
                                       tb_epis.rank
                                  FROM TABLE(pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => i_lang,
                                                                                          i_prof        => i_prof,
                                                                                          i_patient     => l_patient,
                                                                                          i_id_scope    => i_episode,
                                                                                          i_flg_scope   => pk_patient.g_scope_episode,
                                                                                          i_flg_type    => pk_diagnosis.g_diag_type_p,
                                                                                          i_criteria    => i_criteria,
                                                                                          i_format_text => i_format_text,
                                                                                          i_tbl_status  => table_varchar(pk_diagnosis.g_ed_flg_status_d,
                                                                                                                         pk_diagnosis.g_ed_flg_status_co,
                                                                                                                         pk_diagnosis.g_ed_flg_status_b))) tb_epis
                                
                                -- Most frequents  problems for dep_clin_serv
                                UNION ALL
                                SELECT dc.id_diagnosis,
                                       dc.desc_diagnosis,
                                       l_flg_default flg_default,
                                       dc.flg_other,
                                       dc.avail_for_select flg_select,
                                       dc.id_alert_diagnosis,
                                       (SELECT DISTINCT pk_alert_constant.g_yes
                                          FROM diag_diag_condition ddc
                                         WHERE ddc.id_diagnosis = dc.id_diagnosis) flg_warning,
                                       NULL dt_initial_diag,
                                       NULL dt_initial_diag_rv,
                                       2 position,
                                       '' notes,
                                       dc.code_icd,
                                       dc.id_epis_diagnosis,
                                       dc.rank
                                  FROM TABLE(l_tbl_most_freq_diags) dc) fin) fin2
                 WHERE fin2.rownumber = 1
                 ORDER BY fin2.position, fin2.rank, desc_diagnosis ASC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_DIAGNOSIS_MT_NEW');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_diagnosis);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END get_diagnosis_mt_new;

    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar DEFAULT NULL,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE,
        i_flg_cda_reconciliation IN pat_history_diagnosis.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number DEFAULT NULL,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'call create_pat_problem_array_nc';
        IF NOT create_pat_problem_array_nc(i_lang                   => i_lang,
                                           i_epis                   => i_epis,
                                           i_pat                    => i_pat,
                                           i_prof                   => i_prof,
                                           i_desc_problem           => i_desc_problem,
                                           i_flg_status             => i_flg_status,
                                           i_notes                  => i_notes,
                                           i_prof_cat_type          => i_prof_cat_type,
                                           i_diagnosis              => i_diagnosis,
                                           i_flg_nature             => i_flg_nature,
                                           i_alert_diag             => i_alert_diag,
                                           i_precaution_measure     => i_precaution_measure,
                                           i_header_warning         => i_header_warning,
                                           i_cdr_call               => i_cdr_call,
                                           i_dt_register            => current_timestamp,
                                           i_flg_area               => i_flg_area,
                                           i_flg_complications      => i_flg_complications,
                                           i_flg_cda_reconciliation => i_flg_cda_reconciliation,
                                           i_dt_diagnosed           => i_dt_diagnosed,
                                           i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                           i_dt_resolved            => i_dt_resolved,
                                           i_dt_resolved_precision  => i_dt_resolved_precision,
                                           i_location               => i_location,
                                           i_flg_epis_prob          => i_flg_epis_prob,
                                           i_prob_group             => i_prob_group,
                                           o_msg                    => o_msg,
                                           o_msg_title              => o_msg_title,
                                           o_flg_show               => o_flg_show,
                                           o_button                 => o_button,
                                           o_type                   => o_type,
                                           o_ids                    => o_ids,
                                           o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            IF o_error.ora_sqlcode <> g_error_group_code
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  'CREATE_PAT_PROBLEM_ARRAY',
                                                  o_error);
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'CREATE_PAT_PROBLEM_ARRAY');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END create_pat_problem_array;

    FUNCTION create_pat_problem_array_nc
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar DEFAULT NULL,
        i_dt_register            IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE,
        i_flg_cda_reconciliation IN pat_history_diagnosis.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number DEFAULT NULL,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_alert_diagnosis  table_number := table_number();
        l_seq_phd             table_number := table_number();
        l_id_pat_prob_unaware pat_prob_unaware.id_pat_prob_unaware%TYPE;
        l_id_prev_problem     table_number := table_number();
        l_seq_num             table_number := table_number();
    
        CURSOR c_prev_epis_prob(i_id_problem table_number) IS
            SELECT ep.id_problem, ep.rank
              FROM epis_prob ep
             WHERE ep.id_episode = i_epis
               AND ep.flg_type = g_type_d
               AND ep.id_problem IN (SELECT phd.id_pat_history_diagnosis
                                       FROM pat_history_diagnosis phd
                                      WHERE phd.id_pat_history_diagnosis_new IN
                                            (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                              column_value
                                               FROM TABLE(i_id_problem) d));
    
    BEGIN
        -- get the diagnosis associated
        -- only one diagnosis at once
        g_error := 'GET L_ID_DIAGNOSIS';
    
        -- ALERT-736 diagnosis synonyms
        -- when the id_alert_diagnosis is not provided, the below added query conditions will get the
        -- default id_alert_diagnosis based on id_diagnosis
        IF (i_alert_diag IS NULL OR i_alert_diag.count = 0)
           AND i_diagnosis IS NOT NULL
           AND i_diagnosis.count > 0
        THEN
            SELECT ad.id_alert_diagnosis
              BULK COLLECT
              INTO l_id_alert_diagnosis
              FROM alert_diagnosis ad
             WHERE ad.id_diagnosis = i_diagnosis(1)
               AND ad.flg_type IN (g_medical_diagnosis_type, pk_diagnosis.g_diag_type_x)
               AND (ad.flg_icd9 = g_yes OR ad.flg_type = pk_diagnosis.g_diag_type_x)
               AND ad.flg_available = g_yes;
        ELSIF i_alert_diag IS NOT NULL
              AND i_alert_diag.count > 0
        THEN
            l_id_alert_diagnosis := i_alert_diag;
        END IF;
    
        IF NOT
            pk_past_history.set_past_hist_diagnosis(i_lang                       => i_lang,
                                                    i_prof                       => i_prof,
                                                    i_episode                    => i_epis,
                                                    i_pat                        => i_pat,
                                                    i_doc_area                   => NULL,
                                                    i_flg_status                 => i_flg_status,
                                                    i_flg_nature                 => i_flg_nature,
                                                    i_diagnosis                  => l_id_alert_diagnosis,
                                                    i_phd_outdated               => NULL,
                                                    i_desc_pat_history_diagnosis => nvl(i_desc_problem, table_varchar()),
                                                    i_notes                      => i_notes,
                                                    i_id_cancel_reason           => table_number(NULL),
                                                    i_cancel_notes               => table_varchar(NULL),
                                                    i_precaution_measure         => i_precaution_measure,
                                                    i_flg_warning                => i_header_warning,
                                                    i_dt_register                => nvl(i_dt_register, current_timestamp),
                                                    i_exam                       => NULL,
                                                    i_intervention               => NULL,
                                                    dt_execution                 => NULL,
                                                    i_dt_execution_precision     => NULL,
                                                    i_cdr_call                   => NULL, --i_cdr_event,
                                                    i_dt_review                  => NULL,
                                                    i_flg_area                   => i_flg_area,
                                                    i_flg_complications          => i_flg_complications,
                                                    i_flg_screen                 => pk_alert_constant.g_diag_area_problems,
                                                    i_flg_cda_reconciliation     => i_flg_cda_reconciliation,
                                                    i_dt_diagnosed               => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision     => i_dt_diagnosed_precision,
                                                    i_dt_resolved                => i_dt_resolved,
                                                    i_dt_resolved_precision      => i_dt_resolved_precision,
                                                    i_location                   => i_location,
                                                    i_id_family_relationship     => NULL,
                                                    i_flg_death_cause            => NULL,
                                                    i_familiar_age               => NULL,
                                                    i_phd_diagnosis              => NULL,
                                                    o_seq_phd                    => l_seq_phd,
                                                    o_error                      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_type := table_varchar();
        FOR i IN 1 .. l_seq_phd.count
        LOOP
            o_type.extend(1);
            o_type(o_type.count) := g_type_d;
        END LOOP;
    
        g_error := 'call set_epis_problem_group_array';
        IF i_flg_epis_prob = pk_alert_constant.g_yes
        THEN
            l_id_prev_problem.extend(l_seq_phd.count);
            l_seq_num.extend(l_seq_phd.count);
        
            g_error := 'GET L_ID_PREV_PROBLEM/L_SEQ_NUM';
            OPEN c_prev_epis_prob(l_seq_phd);
            FOR i IN 1 .. l_seq_phd.count
            LOOP
                FETCH c_prev_epis_prob
                    INTO l_id_prev_problem(i), l_seq_num(i);
                EXIT WHEN c_prev_epis_prob%NOTFOUND;
            END LOOP;
            CLOSE c_prev_epis_prob;
        
            IF NOT set_epis_problem_group_array(i_lang            => i_lang,
                                                i_episode         => i_epis,
                                                i_prof            => i_prof,
                                                i_id_problem      => l_seq_phd,
                                                i_prev_id_problem => l_id_prev_problem,
                                                i_flg_status      => i_flg_status,
                                                i_prob_group      => i_prob_group,
                                                i_seq_num         => l_seq_num,
                                                i_flg_type        => o_type,
                                                o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FOR i IN 1 .. l_seq_phd.count
        LOOP
            IF i_flg_area IS NULL
               OR i_flg_area(i) = pk_alert_constant.g_diag_area_problems
            THEN
                g_error := 'call set_pat_problem_review';
                IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_pat_problem => l_seq_phd(i),
                                                          i_flg_source     => g_problem_type_problem,
                                                          i_review_notes   => NULL,
                                                          i_episode        => i_epis,
                                                          i_flg_auto       => pk_alert_constant.g_yes,
                                                          o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END LOOP;
    
        IF NOT pk_problems.cancel_pat_prob_unaware_nc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_patient          => i_pat,
                                                      i_id_episode          => i_epis,
                                                      i_notes               => NULL,
                                                      i_id_cancel_reason    => NULL,
                                                      i_cancel_notes        => NULL,
                                                      i_flg_status          => i_flg_status,
                                                      o_id_pat_prob_unaware => l_id_pat_prob_unaware,
                                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_ids := l_seq_phd;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            IF o_error.ora_sqlcode <> g_error_group_code
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  'CREATE_PAT_PROBLEM_ARRAY_NC',
                                                  o_error);
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'CREATE_PAT_PROBLEM_ARRAY');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_diagnosis              IN table_number,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_adiag          table_number := table_number();
        e_call_exception EXCEPTION;
    
    BEGIN
        -- legacy support, create empty (null values) array of alert_diagnosis
        l_adiag.extend(i_diagnosis.count);
    
        g_error := 'CREATING DIAGNOSIS (NO COMMIT, NO SYNONYMS)';
        IF NOT pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                    i_epis                   => i_epis,
                                                    i_pat                    => i_pat,
                                                    i_prof                   => i_prof,
                                                    i_desc_problem           => i_desc_problem,
                                                    i_flg_status             => i_flg_status,
                                                    i_notes                  => i_notes,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_diagnosis              => i_diagnosis,
                                                    i_flg_nature             => i_flg_nature,
                                                    i_alert_diag             => NULL,
                                                    i_precaution_measure     => i_precaution_measure,
                                                    i_header_warning         => i_header_warning,
                                                    i_cdr_call               => NULL,
                                                    i_flg_area               => table_varchar(pk_alert_constant.g_diag_area_problems),
                                                    i_flg_cda_reconciliation => pk_alert_constant.g_no,
                                                    i_dt_diagnosed           => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                                    i_dt_resolved            => i_dt_resolved,
                                                    i_dt_resolved_precision  => i_dt_resolved_precision,
                                                    i_location               => i_location,
                                                    o_msg                    => o_msg,
                                                    o_msg_title              => o_msg_title,
                                                    o_flg_show               => o_flg_show,
                                                    o_button                 => o_button,
                                                    o_type                   => o_type,
                                                    o_ids                    => o_ids,
                                                    o_error                  => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'CREATE_PAT_PROBLEM_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_pat_problem_det
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2 DEFAULT g_problem_view_patient,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL get_pat_problem_internal';
    
        IF NOT get_pat_problem_det_internal(i_lang         => i_lang,
                                            i_pat_prob     => i_pat_prob,
                                            i_type         => i_type,
                                            i_prof         => i_prof,
                                            i_problem_view => i_problem_view,
                                            o_problem      => o_problem,
                                            o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PAT_PROBLEM_DET',
                                              o_error);
            -- fechar os cursores
            pk_types.open_my_cursor(o_problem);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            -- return failure   
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END get_pat_problem_det;

    FUNCTION get_pat_problem_det_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_problem pk_types.cursor_type;
    
    BEGIN
        g_error := 'CALL GET_PAT_PROBLEM_DET_NEW_AUX';
        IF NOT pk_problems.get_pat_problem_det_new_aux(i_lang,
                                                       i_pat_prob,
                                                       i_type,
                                                       i_prof,
                                                       i_problem_view,
                                                       l_problem,
                                                       o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_problem := l_problem;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PAT_PROBLEM_DET_INTERNAL',
                                              o_error);
            -- fechar os cursores
            pk_types.open_my_cursor(o_problem);
            -- return failure   
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem);
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION set_pat_problem_array_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        i_dt_resolution  IN table_varchar,
        i_dt_register    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status       pat_problem.flg_status%TYPE;
        l_prof_upd         pat_problem.id_professional_ins%TYPE;
        l_dt_update        TIMESTAMP WITH TIME ZONE;
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
        l_flg_show         VARCHAR2(1);
        l_msg_title        VARCHAR2(2000);
        l_msg_text         VARCHAR2(2000);
        l_button           VARCHAR2(6);
        --ID da epis_diagnosis
        l_epis_diagnosis pat_problem.id_epis_diagnosis%TYPE;
        --ID do diag
        l_diagnosis pat_problem.id_diagnosis%TYPE;
    
        l_ret BOOLEAN;
    
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   flg_nature,
                   id_diagnosis,
                   id_cancel_reason,
                   cancel_notes,
                   dt_resolution
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    
        --procura o diagn?co correspondente
        CURSOR c_epis_d(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT pp.id_epis_diagnosis, pp.id_diagnosis
              FROM pat_problem pp
             WHERE pp.id_pat_problem = l_id;
    
        l_rowids_aux table_varchar;
    
        l_notes_aux pat_problem.notes%TYPE;
    
        lv_id_pat_problem PLS_INTEGER;
        lv_notes          VARCHAR2(4000);
        lv_flg_status     VARCHAR2(1);
        lv_flg_nature     VARCHAR2(1);
        lv_dt_resolution  pat_problem.dt_resolution%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := nvl(i_dt_register, current_timestamp);
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_pat_problem.count
        LOOP
            -- Loop sobre o array de IDs de registos 
            g_error            := 'GET TYPE / STATUS';
            v_pat_problem_hist := NULL;
            l_flg_status       := i_flg_status(i);
            l_prof_upd         := i_prof.id;
            l_dt_update        := g_sysdate_tstz;
        
            lv_id_pat_problem := NULL;
            lv_notes          := NULL;
            lv_flg_status     := NULL;
            lv_flg_nature     := NULL;
            lv_dt_resolution  := NULL;
        
            IF (i_id_pat_problem.exists(i))
            THEN
                lv_id_pat_problem := i_id_pat_problem(i);
            ELSE
                lv_id_pat_problem := NULL;
            END IF;
        
            IF (i_notes.exists(i))
            THEN
                lv_notes := i_notes(i);
            ELSE
                lv_notes := NULL;
            END IF;
        
            IF (i_flg_status.exists(i))
            THEN
                lv_flg_status := i_flg_status(i);
            ELSE
                lv_flg_status := NULL;
            END IF;
        
            IF (i_flg_nature.exists(i))
            THEN
                lv_flg_nature := i_flg_nature(i);
            ELSE
                lv_flg_nature := NULL;
            END IF;
        
            IF (i_dt_resolution.exists(i))
            THEN
                lv_dt_resolution := substr(i_dt_resolution(i), 0, 8);
            ELSE
                lv_dt_resolution := NULL;
            END IF;
        
            IF i_type(i) = g_pat_prob_allrg
            THEN
                IF NOT set_pat_allergy(i_lang             => i_lang,
                                       i_epis             => i_epis,
                                       i_id_pat_allergy   => lv_id_pat_problem,
                                       i_id_pat           => i_pat,
                                       i_prof             => i_prof,
                                       i_allergy          => NULL,
                                       i_drug_pharma      => NULL,
                                       i_notes            => lv_notes,
                                       i_dt_first_time    => NULL,
                                       i_flg_type         => NULL,
                                       i_flg_approved     => NULL,
                                       i_flg_status       => lv_flg_status,
                                       i_flg_nature       => lv_flg_nature,
                                       i_dt_symptoms      => NULL,
                                       i_id_cancel_reason => NULL,
                                       i_cancel_notes     => NULL,
                                       i_prof_cat_type    => i_prof_cat_type,
                                       i_dt_resolution    => lv_dt_resolution,
                                       o_flg_show         => l_flg_show,
                                       o_msg_title        => l_msg_title,
                                       o_msg_text         => l_msg_text,
                                       o_button           => l_button,
                                       o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSIF i_type(i) = g_pat_prob_prob
            THEN
                g_error := 'OPEN CURSOR';
                OPEN c_prob(i_id_pat_problem(i));
                FETCH c_prob
                    INTO v_pat_problem_hist.id_pat_problem,
                         v_pat_problem_hist.id_patient,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_alert_diagnosis,
                         v_pat_problem_hist.id_professional_ins,
                         v_pat_problem_hist.dt_pat_problem_tstz,
                         v_pat_problem_hist.desc_pat_problem,
                         v_pat_problem_hist.notes,
                         v_pat_problem_hist.flg_age,
                         v_pat_problem_hist.year_begin,
                         v_pat_problem_hist.month_begin,
                         v_pat_problem_hist.day_begin,
                         v_pat_problem_hist.year_end,
                         v_pat_problem_hist.month_end,
                         v_pat_problem_hist.day_end,
                         v_pat_problem_hist.pct_incapacity,
                         v_pat_problem_hist.flg_surgery,
                         v_pat_problem_hist.notes_support,
                         v_pat_problem_hist.dt_confirm_tstz,
                         v_pat_problem_hist.rank,
                         v_pat_problem_hist.flg_status,
                         v_pat_problem_hist.id_epis_diagnosis,
                         v_pat_problem_hist.flg_aproved,
                         v_pat_problem_hist.id_institution,
                         v_pat_problem_hist.id_pat_habit,
                         v_pat_problem_hist.id_episode,
                         v_pat_problem_hist.id_epis_anamnesis,
                         v_pat_problem_hist.flg_nature,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_cancel_reason,
                         v_pat_problem_hist.cancel_notes,
                         v_pat_problem_hist.dt_resolution;
                g_found := c_prob%NOTFOUND;
                CLOSE c_prob;
            
                IF v_pat_problem_hist.id_pat_habit IS NOT NULL
                   OR v_pat_problem_hist.id_diagnosis IS NOT NULL
                THEN
                    g_error := 'INSERT HIST';
                    IF NOT pk_patient.ins_pat_problem_hist_no_commit(i_lang             => i_lang,
                                                                     i_pat_problem_hist => v_pat_problem_hist,
                                                                     o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                g_error := 'UPDATE PAT_PROBLEM';
                SELECT notes
                  INTO l_notes_aux
                  FROM pat_problem
                 WHERE id_pat_problem = i_id_pat_problem(i);
            
                ts_pat_problem.upd(id_pat_problem_in       => i_id_pat_problem(i),
                                   flg_status_in           => l_flg_status,
                                   dt_pat_problem_tstz_in  => l_dt_update,
                                   dt_pat_problem_tstz_nin => FALSE,
                                   id_professional_ins_in  => l_prof_upd,
                                   id_professional_ins_nin => FALSE,
                                   id_institution_in       => i_prof.institution,
                                   id_institution_nin      => FALSE,
                                   notes_in                => i_notes(i),
                                   notes_nin               => FALSE,
                                   id_episode_in           => i_epis,
                                   id_episode_nin          => FALSE,
                                   flg_nature_in           => i_flg_nature(i),
                                   flg_nature_nin          => FALSE,
                                   id_cancel_reason_in     => NULL,
                                   id_cancel_reason_nin    => FALSE,
                                   cancel_notes_in         => NULL,
                                   cancel_notes_nin        => FALSE,
                                   dt_resolution_in        => lv_dt_resolution,
                                   dt_resolution_nin       => FALSE,
                                   rows_out                => l_rowids_aux);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids_aux,
                                              o_error      => o_error);
            
                l_rowids_aux := table_varchar();
            
                IF v_pat_problem_hist.id_pat_habit IS NOT NULL
                THEN
                    g_error := 'UPDATE PAT HABIT';
                    pk_alertlog.log_debug(g_error);
                    l_rowids_aux := table_varchar();
                    ts_pat_habit.upd(id_pat_habit_in     => v_pat_problem_hist.id_pat_habit,
                                     flg_status_in       => l_flg_status,
                                     id_episode_in       => i_epis,
                                     id_prof_cancel_in   => NULL,
                                     note_cancel_in      => NULL,
                                     id_cancel_reason_in => NULL,
                                     cancel_notes_in     => NULL,
                                     dt_cancel_tstz_in   => NULL,
                                     rows_out            => l_rowids_aux);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HABIT',
                                                  i_rowids     => l_rowids_aux,
                                                  o_error      => o_error);
                
                    l_rowids_aux := table_varchar();
                
                    --
                END IF;
            
                --get epis_diagnosys
                g_error := 'OPEN EPIS_DIAGNOSIS';
                OPEN c_epis_d(i_id_pat_problem(i));
                FETCH c_epis_d
                    INTO l_epis_diagnosis, l_diagnosis;
                CLOSE c_epis_d;
            
                l_epis_diagnosis := NULL;
            END IF;
        
        END LOOP;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes 
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION set_pat_problem_array_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        i_dt_resolution  IN table_varchar,
        i_dt_register    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status       pat_problem.flg_status%TYPE;
        l_prof_upd         pat_problem.id_professional_ins%TYPE;
        l_dt_update        TIMESTAMP WITH TIME ZONE;
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
        l_flg_show         VARCHAR2(1);
        l_msg_title        VARCHAR2(2000);
        l_msg_text         VARCHAR2(2000);
        l_button           VARCHAR2(6);
        --ID da epis_diagnosis
        l_epis_diagnosis pat_problem.id_epis_diagnosis%TYPE;
        --ID do diag
        l_diagnosis pat_problem.id_diagnosis%TYPE;
    
        l_ret BOOLEAN;
    
        l_year_begin_chr  VARCHAR2(200);
        l_month_begin_chr VARCHAR2(200);
        l_day_begin_chr   VARCHAR2(200);
    
        l_year_begin  NUMBER := NULL;
        l_month_begin NUMBER := NULL;
        l_day_begin   NUMBER := NULL;
    
        l_exception EXCEPTION;
    
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   flg_nature,
                   id_diagnosis,
                   id_cancel_reason,
                   cancel_notes
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    
        --procura o diag correspondente
        CURSOR c_epis_d(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT pp.id_epis_diagnosis, pp.id_diagnosis
              FROM pat_problem pp
             WHERE pp.id_pat_problem = l_id;
    
        l_rowids_aux table_varchar;
    
        l_notes_aux pat_problem.notes%TYPE;
    
        l_rec_diag        pk_edis_types.rec_in_diagnosis;
        l_rec_epis_diag   pk_edis_types.rec_in_epis_diagnoses;
        l_diag_out_params pk_edis_types.table_out_epis_diags;
    BEGIN
    
        g_sysdate_tstz := nvl(i_dt_register, current_timestamp);
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_pat_problem.count
        LOOP
            -- Loop sobre o array de IDs de registos 
            g_error            := 'GET TYPE / STATUS';
            v_pat_problem_hist := NULL;
            l_flg_status       := i_flg_status(i);
            l_prof_upd         := i_prof.id;
            l_dt_update        := g_sysdate_tstz;
        
            -- parses the i_dt_symptoms string so that we can make an update to the YEAR, MONTH and DAY fields
            g_error          := 'I_DT_SYMPTOMS PARSE';
            l_year_begin_chr := substr(i_dt_symptoms(i), 1, instr(i_dt_symptoms(i), '-') - 1);
            IF l_year_begin_chr IS NOT NULL
            THEN
                l_year_begin := to_number(l_year_begin_chr);
            END IF;
            --
            l_month_begin_chr := substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                        1,
                                        instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') - 1);
            IF l_month_begin_chr IS NOT NULL
            THEN
                l_month_begin := to_number(l_month_begin_chr);
            ELSE
                l_month_begin := NULL;
            END IF;
            --
            l_day_begin_chr := substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                      instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') + 1);
            IF l_day_begin_chr IS NOT NULL
            THEN
                l_day_begin := to_number(l_day_begin_chr);
            ELSE
                l_day_begin := NULL;
            END IF;
        
            --Validation of the data provided by Flash, in order to avoid storing invalid data
            g_error := 'INVALID DATE PROVIDED';
            IF (l_year_begin < 1000 AND l_year_begin IS NOT NULL)
               OR (l_month_begin < 1 AND l_month_begin IS NOT NULL)
               OR (l_month_begin > 12 AND l_month_begin IS NOT NULL)
               OR (l_day_begin < 1 AND l_day_begin IS NOT NULL)
               OR (l_day_begin > 31 AND l_day_begin IS NOT NULL)
            THEN
                RAISE l_exception;
            END IF;
        
            IF i_type(i) = g_pat_prob_allrg
            THEN
                IF NOT set_pat_allergy(i_lang             => i_lang,
                                       i_epis             => i_epis,
                                       i_id_pat_allergy   => i_id_pat_problem(i),
                                       i_id_pat           => i_pat,
                                       i_prof             => i_prof,
                                       i_allergy          => NULL,
                                       i_drug_pharma      => NULL,
                                       i_notes            => i_notes(i),
                                       i_dt_first_time    => NULL,
                                       i_flg_type         => NULL,
                                       i_flg_approved     => NULL,
                                       i_flg_status       => i_flg_status(i),
                                       i_flg_nature       => i_flg_nature(i),
                                       i_dt_symptoms      => l_year_begin,
                                       i_id_cancel_reason => NULL,
                                       i_cancel_notes     => NULL,
                                       i_prof_cat_type    => i_prof_cat_type,
                                       i_dt_resolution    => substr(i_dt_resolution(i), 0, 8),
                                       o_flg_show         => l_flg_show,
                                       o_msg_title        => l_msg_title,
                                       o_msg_text         => l_msg_text,
                                       o_button           => l_button,
                                       o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSIF i_type(i) = g_pat_prob_prob
            THEN
                g_error := 'OPEN CURSOR';
                OPEN c_prob(i_id_pat_problem(i));
                FETCH c_prob
                    INTO v_pat_problem_hist.id_pat_problem,
                         v_pat_problem_hist.id_patient,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_alert_diagnosis,
                         v_pat_problem_hist.id_professional_ins,
                         v_pat_problem_hist.dt_pat_problem_tstz,
                         v_pat_problem_hist.desc_pat_problem,
                         v_pat_problem_hist.notes,
                         v_pat_problem_hist.flg_age,
                         v_pat_problem_hist.year_begin,
                         v_pat_problem_hist.month_begin,
                         v_pat_problem_hist.day_begin,
                         v_pat_problem_hist.year_end,
                         v_pat_problem_hist.month_end,
                         v_pat_problem_hist.day_end,
                         v_pat_problem_hist.pct_incapacity,
                         v_pat_problem_hist.flg_surgery,
                         v_pat_problem_hist.notes_support,
                         v_pat_problem_hist.dt_confirm_tstz,
                         v_pat_problem_hist.rank,
                         v_pat_problem_hist.flg_status,
                         v_pat_problem_hist.id_epis_diagnosis,
                         v_pat_problem_hist.flg_aproved,
                         v_pat_problem_hist.id_institution,
                         v_pat_problem_hist.id_pat_habit,
                         v_pat_problem_hist.id_episode,
                         v_pat_problem_hist.id_epis_anamnesis,
                         v_pat_problem_hist.flg_nature,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_cancel_reason,
                         v_pat_problem_hist.cancel_notes;
                g_found := c_prob%NOTFOUND;
                CLOSE c_prob;
            
                IF v_pat_problem_hist.id_pat_habit IS NOT NULL
                THEN
                    g_error := 'INSERT HIST';
                    IF NOT pk_patient.ins_pat_problem_hist_no_commit(i_lang             => i_lang,
                                                                     i_pat_problem_hist => v_pat_problem_hist,
                                                                     o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                g_error := 'UPDATE PAT_PROBLEM';
                SELECT notes
                  INTO l_notes_aux
                  FROM pat_problem
                 WHERE id_pat_problem = i_id_pat_problem(i);
            
                ts_pat_problem.upd(id_pat_problem_in       => i_id_pat_problem(i),
                                   flg_status_in           => l_flg_status,
                                   dt_pat_problem_tstz_in  => l_dt_update,
                                   dt_pat_problem_tstz_nin => FALSE,
                                   id_professional_ins_in  => l_prof_upd,
                                   id_professional_ins_nin => FALSE,
                                   id_institution_in       => i_prof.institution,
                                   id_institution_nin      => FALSE,
                                   notes_in                => i_notes(i),
                                   notes_nin               => FALSE,
                                   year_begin_in           => l_year_begin,
                                   year_begin_nin          => FALSE,
                                   month_begin_in          => l_month_begin,
                                   month_begin_nin         => FALSE,
                                   day_begin_in            => l_day_begin,
                                   day_begin_nin           => FALSE,
                                   id_episode_in           => i_epis,
                                   id_episode_nin          => FALSE,
                                   flg_nature_in           => i_flg_nature(i),
                                   flg_nature_nin          => FALSE,
                                   dt_resolution_in        => substr(i_dt_resolution(i), 0, 8),
                                   dt_resolution_nin       => FALSE,
                                   rows_out                => l_rowids_aux);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids_aux,
                                              o_error      => o_error);
            
                l_rowids_aux := table_varchar();
            
                --Habitos
                IF v_pat_problem_hist.id_pat_habit IS NOT NULL
                THEN
                    g_error := 'UPDATE PAT HABIT';
                    pk_alertlog.log_debug(g_error);
                    l_rowids_aux := table_varchar();
                    ts_pat_habit.upd(id_pat_habit_in   => v_pat_problem_hist.id_pat_habit,
                                     flg_status_in     => l_flg_status,
                                     dt_cancel_tstz_in => CASE
                                                              WHEN l_flg_status = g_pat_habit_canc THEN
                                                               l_dt_update
                                                              ELSE
                                                               NULL
                                                          END,
                                     id_prof_cancel_in => i_prof.id,
                                     note_cancel_in    => i_notes(i),
                                     id_episode_in     => i_epis,
                                     rows_out          => l_rowids_aux);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HABIT',
                                                  i_rowids     => l_rowids_aux,
                                                  o_error      => o_error);
                
                    l_rowids_aux := table_varchar();
                
                END IF;
            
                --get epis_diagnosys
                g_error := 'OPEN EPIS_DIAGNOSIS';
                OPEN c_epis_d(i_id_pat_problem(i));
                FETCH c_epis_d
                    INTO l_epis_diagnosis, l_diagnosis;
                CLOSE c_epis_d;
            
                -- Diag
                g_error := 'UPDATE EPIS_DIAGNOSIS';
                IF l_epis_diagnosis IS NOT NULL
                THEN
                    SELECT ep.flg_type,
                           ep.flg_final_type,
                           ep.id_diagnosis,
                           ep.id_alert_diagnosis,
                           ep.desc_epis_diagnosis
                      INTO l_rec_epis_diag.epis_diagnosis.flg_type,
                           l_rec_diag.flg_final_type,
                           l_rec_diag.id_diagnosis,
                           l_rec_diag.id_alert_diagnosis,
                           l_rec_diag.desc_diagnosis
                      FROM epis_diagnosis ep
                     WHERE ep.id_epis_diagnosis = l_epis_diagnosis;
                    --TODO
                
                    l_rec_diag.flg_status := l_flg_status;
                    l_rec_diag.notes      := i_notes(i);
                
                    l_rec_epis_diag.epis_diagnosis.id_episode        := i_epis;
                    l_rec_epis_diag.epis_diagnosis.id_epis_diagnosis := l_epis_diagnosis;
                    l_rec_epis_diag.epis_diagnosis.tbl_diagnosis     := pk_edis_types.table_in_diagnosis(l_rec_diag);
                
                    g_error := 'CALL SET_EPIS_DIAGNOSIS';
                    IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_epis_diagnoses => l_rec_epis_diag,
                                                           o_params         => l_diag_out_params,
                                                           o_error          => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                l_epis_diagnosis := NULL;
            
            END IF;
        
            g_error := 'call set_problem_history';
            IF NOT pk_problems.set_problem_history(i_lang           => i_lang,
                                                   i_pat            => i_pat,
                                                   i_prof           => i_prof,
                                                   i_id_pat_problem => i_id_pat_problem(1),
                                                   o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes 
            pk_utils.undo_changes;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY_INTERNAL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar DEFAULT NULL,
        i_dt_resolved_precision IN table_varchar DEFAULT NULL,
        i_flg_epis_prob         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group            IN table_number DEFAULT NULL,
        i_seq_num               IN table_number DEFAULT NULL,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT set_pat_problem_array_nc(i_lang                  => i_lang,
                                        i_epis                  => i_epis,
                                        i_pat                   => i_pat,
                                        i_prof                  => i_prof,
                                        i_id_pat_problem        => i_id_pat_problem,
                                        i_flg_status            => i_flg_status,
                                        i_notes                 => i_notes,
                                        i_type                  => i_type,
                                        i_prof_cat_type         => i_prof_cat_type,
                                        i_flg_nature            => i_flg_nature,
                                        i_precaution_measure    => i_precaution_measure,
                                        i_header_warning        => i_header_warning,
                                        i_dt_register           => current_timestamp,
                                        i_dt_resolved           => i_dt_resolved,
                                        i_dt_resolved_precision => i_dt_resolved_precision,
                                        i_flg_epis_prob         => i_flg_epis_prob,
                                        i_prob_group            => i_prob_group,
                                        i_seq_num               => i_seq_num,
                                        o_type                  => o_type,
                                        o_ids                   => o_ids,
                                        o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            IF o_error.ora_sqlcode <> g_error_group_code
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM_ARRAY',
                                                  o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
            END IF;
            -- return failure
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END set_pat_problem_array;

    FUNCTION set_pat_problem_array_nc
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_register           IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        i_flg_epis_prob         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group            IN table_number,
        i_seq_num               IN table_number,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_alert_diagnosis          table_number;
        l_dt_pat_history_diagnosis_tz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_desc_phd                    VARCHAR2(2000);
        l_desc_phd_arr                table_varchar;
    
        l_id_habit          pat_problem.id_habit%TYPE;
        l_id_epis_diagnosis pat_problem.id_epis_diagnosis%TYPE;
        l_id_epis_anamnesis pat_problem.id_epis_anamnesis%TYPE;
    
        l_notes     pat_problem.notes%TYPE;
        l_notes_arr table_varchar;
    
        l_dt_diagnosed           pat_history_diagnosis.dt_diagnosed%TYPE;
        l_dt_diagnosed_precision pat_history_diagnosis.dt_diagnosed_precision%TYPE;
    
        CURSOR c_dt_phd IS
            SELECT phd.dt_pat_history_diagnosis_tstz,
                   phd.desc_pat_history_diagnosis,
                   phd.id_alert_diagnosis,
                   phd.desc_pat_history_diagnosis,
                   phd.notes,
                   phd.dt_diagnosed,
                   phd.dt_diagnosed_precision,
                   phd.id_diagnosis
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_pat_problem(1); -- only changes a phd at once
    
        CURSOR c_pp IS
            SELECT id_habit, id_epis_diagnosis, id_epis_anamnesis
              FROM pat_problem
             WHERE id_pat_problem = i_id_pat_problem(1);
    
        CURSOR c_epis_prob
        (
            l_id_problem table_number,
            l_id_episode episode.id_episode%TYPE
        ) IS
            SELECT ep.id_problem, ep.id_epis_prob_group, ep.rank seq_num
              FROM epis_prob ep
             WHERE ep.id_episode = l_id_episode
               AND ep.id_problem IN ((SELECT /*+ opt_estimate(table t rows=1) */
                                      column_value
                                       FROM TABLE(l_id_problem) t));
    
        l_id_alert_diagnosis_num     pat_history_diagnosis.id_alert_diagnosis%TYPE;
        l_id_diagnosis               pat_history_diagnosis.id_diagnosis%TYPE;
        l_desc_pat_history_diagnosis pat_history_diagnosis.desc_pat_history_diagnosis%TYPE;
        l_flg_source                 VARCHAR2(2 CHAR);
        l_id_pat_problem             NUMBER(24);
        l_seq_phd                    table_number := table_number();
        l_id_pat_prob_unaware        pat_prob_unaware.id_pat_prob_unaware%TYPE;
        l_flg_area                   pat_history_diagnosis.flg_area%TYPE;
        l_rowids                     table_varchar;
    
        r_epis_prob  c_epis_prob%ROWTYPE;
        l_id_problem table_number := table_number();
        l_prob_group table_number := table_number();
        l_seq_num    table_number := table_number();
        l_has_group  sys_config.value%TYPE := pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof);
    BEGIN
        l_id_pat_problem := i_id_pat_problem(1);
        -- get the problem details (just to check if it's a habit)
        g_error := 'GET L_ID_DIAGNOSIS';
        OPEN c_pp;
        FETCH c_pp
            INTO l_id_habit, l_id_epis_diagnosis, l_id_epis_anamnesis;
        CLOSE c_pp;
    
        g_error := 'IF ALLERGIES/HABITS..';
        IF i_type(1) = g_pat_prob_allrg
           OR (i_type(1) = g_pat_prob_prob AND
               (l_id_habit IS NOT NULL OR l_id_epis_diagnosis IS NOT NULL OR l_id_epis_anamnesis IS NOT NULL))
        THEN
        
            g_error := 'CALL SET_PAT_ARRAY_INTERNAL';
            IF NOT set_pat_problem_array_internal(i_lang,
                                                  i_epis,
                                                  i_pat,
                                                  i_prof,
                                                  i_id_pat_problem,
                                                  i_flg_status,
                                                  i_notes,
                                                  i_type,
                                                  i_prof_cat_type,
                                                  i_flg_nature,
                                                  i_dt_resolved,
                                                  nvl(i_dt_register, current_timestamp),
                                                  o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_type := i_type;
            o_ids  := i_id_pat_problem;
        ELSE
        
            -- gets the date associated with this phd
            g_error := 'GET DT_PAT_HISTORY_DIAGNOSIS';
            OPEN c_dt_phd;
            FETCH c_dt_phd
                INTO l_dt_pat_history_diagnosis_tz,
                     l_desc_phd,
                     l_id_alert_diagnosis_num,
                     l_desc_pat_history_diagnosis,
                     l_notes,
                     l_dt_diagnosed,
                     l_dt_diagnosed_precision,
                     l_id_diagnosis;
            CLOSE c_dt_phd;
        
            l_desc_phd_arr := table_varchar();
            l_desc_phd_arr.extend;
            l_desc_phd_arr(1) := l_desc_phd;
        
            IF l_id_alert_diagnosis_num IS NULL
               AND l_id_diagnosis IS NOT NULL
            THEN
                l_id_alert_diagnosis_num := pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => l_id_diagnosis,
                                                                                               i_task_type       => pk_alert_constant.g_task_problems);
            
                IF l_id_alert_diagnosis_num IS NOT NULL
                THEN
                    ts_pat_history_diagnosis.upd(id_pat_history_diagnosis_in => i_id_pat_problem(1),
                                                 id_alert_diagnosis_in       => l_id_alert_diagnosis_num,
                                                 rows_out                    => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            END IF;
        
            l_id_alert_diagnosis := table_number();
            l_id_alert_diagnosis.extend;
            l_id_alert_diagnosis(1) := l_id_alert_diagnosis_num;
        
            l_notes_arr := table_varchar();
            l_notes_arr.extend;
            l_notes_arr(1) := nvl(i_notes(1), l_notes);
        
            -- this function checks which type is being edited. If it an old record (flg_area N), converts it to a current one (H/P/S)
            g_error := 'GET flg_area. id_pat_history_diagnosis: ' || i_id_pat_problem(1);
            pk_alertlog.log_debug(g_error);
            SELECT get_flg_area(i_flg_area => phd.flg_area, i_flg_type => phd.flg_type)
              INTO l_flg_area
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_pat_problem(1)
               AND rownum = 1;
        
            IF NOT pk_past_history.set_past_hist_diagnosis(i_lang                       => i_lang,
                                                           i_prof                       => i_prof,
                                                           i_episode                    => i_epis,
                                                           i_pat                        => i_pat,
                                                           i_doc_area                   => CASE l_flg_area
                                                                                               WHEN
                                                                                                pk_past_history.g_alert_diag_type_surg THEN
                                                                                                pk_past_history.g_doc_area_past_surg
                                                                                               ELSE
                                                                                                pk_past_history.g_doc_area_past_med
                                                                                           END,
                                                           i_flg_status                 => i_flg_status,
                                                           i_flg_nature                 => i_flg_nature,
                                                           i_diagnosis                  => l_id_alert_diagnosis,
                                                           i_phd_outdated               => i_id_pat_problem(1),
                                                           i_desc_pat_history_diagnosis => l_desc_phd_arr,
                                                           i_notes                      => l_notes_arr,
                                                           i_id_cancel_reason           => table_number(NULL),
                                                           i_cancel_notes               => table_varchar(NULL),
                                                           i_precaution_measure         => i_precaution_measure,
                                                           i_flg_warning                => i_header_warning,
                                                           i_dt_register                => nvl(i_dt_register,
                                                                                               current_timestamp),
                                                           i_exam                       => NULL,
                                                           i_intervention               => NULL,
                                                           dt_execution                 => NULL,
                                                           i_dt_execution_precision     => NULL,
                                                           i_cdr_call                   => NULL, --i_cdr_event,
                                                           i_dt_review                  => NULL,
                                                           i_flg_area                   => table_varchar(l_flg_area),
                                                           i_flg_complications          => NULL,
                                                           i_flg_screen                 => pk_alert_constant.g_diag_area_problems,
                                                           i_dt_diagnosed               => table_varchar(pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                                                                                                         i_prof      => i_prof,
                                                                                                                                         i_timestamp => l_dt_diagnosed,
                                                                                                                                         i_timezone  => NULL)),
                                                           i_dt_diagnosed_precision     => table_varchar(l_dt_diagnosed_precision),
                                                           i_dt_resolved                => i_dt_resolved,
                                                           i_dt_resolved_precision      => i_dt_resolved_precision,
                                                           i_location                   => NULL,
                                                           i_id_family_relationship     => NULL,
                                                           i_flg_death_cause            => NULL,
                                                           i_familiar_age               => NULL,
                                                           i_phd_diagnosis              => NULL,
                                                           o_seq_phd                    => l_seq_phd,
                                                           o_error                      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_id_pat_problem := l_seq_phd(1);
        
            o_ids  := l_seq_phd;
            o_type := i_type;
        
        END IF;
    
        g_error := 'call set_epis_problem_group_array';
        IF i_flg_epis_prob = pk_alert_constant.g_yes
           AND l_has_group = pk_alert_constant.g_yes
        THEN
            l_id_problem := i_id_pat_problem;
            l_prob_group := i_prob_group;
            l_seq_num    := i_seq_num;
        ELSE
            OPEN c_epis_prob(i_id_pat_problem, i_epis);
            LOOP
                FETCH c_epis_prob
                    INTO r_epis_prob;
                EXIT WHEN c_epis_prob%NOTFOUND;
                l_id_problem.extend;
                l_id_problem(l_id_problem.count) := r_epis_prob.id_problem;
                l_prob_group.extend;
                l_prob_group(l_prob_group.count) := get_prob_group(i_epis, r_epis_prob.id_epis_prob_group);
                l_seq_num.extend;
                l_seq_num(l_seq_num.count) := r_epis_prob.seq_num;
            END LOOP;
            CLOSE c_epis_prob;
        END IF;
    
        IF l_id_problem IS NOT NULL
           AND l_id_problem.count > 0
        THEN
            IF NOT set_epis_problem_group_array(i_lang            => i_lang,
                                                i_episode         => i_epis,
                                                i_prof            => i_prof,
                                                i_id_problem      => o_ids,
                                                i_prev_id_problem => l_id_problem,
                                                i_flg_status      => i_flg_status,
                                                i_prob_group      => l_prob_group,
                                                i_seq_num         => l_seq_num,
                                                i_flg_type        => i_type,
                                                o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'call set_problem_history';
        IF NOT pk_problems.set_problem_history(i_lang           => i_lang,
                                               i_pat            => i_pat,
                                               i_prof           => i_prof,
                                               i_id_pat_problem => i_id_pat_problem(1),
                                               o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_type(1) = g_pat_prob_prob
           AND l_id_habit IS NOT NULL
        THEN
            l_flg_source := g_problem_type_habit;
        ELSE
            l_flg_source := i_type(1);
        END IF;
        IF l_flg_area IN (pk_alert_constant.g_diag_area_problems)
        THEN
            g_error := 'call set_pat_problem_review';
            IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_pat_problem => l_id_pat_problem,
                                                      i_flg_source     => l_flg_source,
                                                      i_review_notes   => NULL,
                                                      i_episode        => i_epis,
                                                      i_flg_auto       => pk_alert_constant.g_yes,
                                                      o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF NOT pk_problems.cancel_pat_prob_unaware_nc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_patient          => i_pat,
                                                      i_id_episode          => i_epis,
                                                      i_notes               => NULL,
                                                      i_id_cancel_reason    => NULL,
                                                      i_cancel_notes        => NULL,
                                                      i_flg_status          => i_flg_status,
                                                      o_id_pat_prob_unaware => l_id_pat_prob_unaware,
                                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            IF o_error.ora_sqlcode <> g_error_group_code
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  'set_pat_problem_array_nc',
                                                  o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
            END IF;
            -- return failure
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'set_pat_problem_array_nc');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END set_pat_problem_array_nc;

    FUNCTION set_pat_problem_array_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        i_seq_num                IN table_number DEFAULT NULL,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'call set_pat_problem_array_dt_nc';
        IF NOT set_pat_problem_array_dt_nc(i_lang                   => i_lang,
                                           i_epis                   => i_epis,
                                           i_pat                    => i_pat,
                                           i_prof                   => i_prof,
                                           i_id_pat_problem         => i_id_pat_problem,
                                           i_flg_status             => i_flg_status,
                                           i_notes                  => i_notes,
                                           i_type                   => i_type,
                                           i_prof_cat_type          => i_prof_cat_type,
                                           i_flg_nature             => i_flg_nature,
                                           i_precaution_measure     => i_precaution_measure,
                                           i_header_warning         => i_header_warning,
                                           i_dt_register            => current_timestamp,
                                           i_flg_area               => i_flg_area,
                                           i_flg_complications      => i_flg_complications,
                                           i_dt_diagnosed           => i_dt_diagnosed,
                                           i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                           i_dt_resolved            => i_dt_resolved,
                                           i_dt_resolved_precision  => i_dt_resolved_precision,
                                           i_location               => i_location,
                                           i_flg_epis_prob          => i_flg_epis_prob,
                                           i_prob_group             => i_prob_group,
                                           i_seq_num                => i_seq_num,
                                           o_type                   => o_type,
                                           o_ids                    => o_ids,
                                           o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            IF o_error.ora_sqlcode <> g_error_group_code
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM_ARRAY_DT',
                                                  o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
            END IF;
            -- return failure
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY_DT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END set_pat_problem_array_dt;

    FUNCTION set_pat_problem_array_dt_nc
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_dt_register            IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number DEFAULT NULL,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        i_seq_num                IN table_number DEFAULT NULL,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_alert_diagnosis          table_number;
        l_dt_pat_history_diagnosis_tz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_desc_phd                    VARCHAR2(2000);
        l_desc_phd_arr                table_varchar;
    
        l_id_habit          pat_problem.id_habit%TYPE;
        l_id_epis_diagnosis pat_problem.id_epis_diagnosis%TYPE;
        l_id_epis_anamnesis pat_problem.id_epis_anamnesis%TYPE;
    
        l_notes     pat_problem.notes%TYPE;
        l_notes_arr table_varchar;
    
        CURSOR c_dt_phd IS
            SELECT phd.dt_pat_history_diagnosis_tstz,
                   phd.desc_pat_history_diagnosis,
                   phd.id_alert_diagnosis,
                   phd.desc_pat_history_diagnosis,
                   phd.notes,
                   phd.id_diagnosis
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_pat_problem(1); -- only changes a phd at once
    
        CURSOR c_pp IS
            SELECT id_habit, id_epis_diagnosis, id_epis_anamnesis
              FROM pat_problem
             WHERE id_pat_problem = i_id_pat_problem(1);
    
        CURSOR c_epis_prob
        (
            l_id_problem table_number,
            l_id_episode episode.id_episode%TYPE
        ) IS
            SELECT ep.id_problem, ep.id_epis_prob_group, ep.rank seq_num
              FROM epis_prob ep
             WHERE ep.id_episode = l_id_episode
               AND ep.id_problem IN ((SELECT /*+ opt_estimate(table t rows=1) */
                                      column_value
                                       FROM TABLE(l_id_problem) t));
    
        l_id_alert_diagnosis_num     pat_history_diagnosis.id_alert_diagnosis%TYPE;
        l_desc_pat_history_diagnosis pat_history_diagnosis.desc_pat_history_diagnosis%TYPE;
        l_flg_source                 VARCHAR2(2 CHAR);
        l_id_pat_problem             NUMBER(24);
        l_seq_phd                    table_number := table_number();
        l_id_pat_prob_unaware        pat_prob_unaware.id_pat_prob_unaware%TYPE;
        l_id_diagnosis               pat_history_diagnosis.id_diagnosis%TYPE;
        l_rowids                     table_varchar;
    
        r_epis_prob  c_epis_prob%ROWTYPE;
        l_id_problem table_number := table_number();
        l_prob_group table_number := table_number();
        l_seq_num    table_number := table_number();
        l_has_group  sys_config.value%TYPE := pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof);
    BEGIN
        l_id_pat_problem := i_id_pat_problem(1);
        -- get the problem details (just to check if it's a habit)
        g_error := 'GET L_ID_DIAGNOSIS';
        OPEN c_pp;
        FETCH c_pp
            INTO l_id_habit, l_id_epis_diagnosis, l_id_epis_anamnesis;
        CLOSE c_pp;
    
        g_error := 'IF ALLERGIES/HABITS..';
        IF i_type(1) = g_pat_prob_allrg
           OR (i_type(1) = g_pat_prob_prob AND
               (l_id_habit IS NOT NULL OR l_id_epis_diagnosis IS NOT NULL OR l_id_epis_anamnesis IS NOT NULL))
        THEN
        
            g_error := 'CALL SET_PAT_ARRAY_INTERNAL';
            IF NOT set_pat_problem_array_internal(i_lang,
                                                  i_epis,
                                                  i_pat,
                                                  i_prof,
                                                  i_id_pat_problem,
                                                  i_flg_status,
                                                  i_dt_diagnosed,
                                                  i_notes,
                                                  i_type,
                                                  i_prof_cat_type,
                                                  i_flg_nature,
                                                  i_dt_resolved,
                                                  nvl(i_dt_register, current_timestamp),
                                                  o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_type := i_type;
            o_ids  := i_id_pat_problem;
        
        ELSE
        
            -- gets the date associated with this phd
            g_error := 'GET DT_PAT_HISTORY_DIAGNOSIS';
            OPEN c_dt_phd;
            FETCH c_dt_phd
                INTO l_dt_pat_history_diagnosis_tz,
                     l_desc_phd,
                     l_id_alert_diagnosis_num,
                     l_desc_pat_history_diagnosis,
                     l_notes,
                     l_id_diagnosis;
            CLOSE c_dt_phd;
        
            l_desc_phd_arr := table_varchar();
            l_desc_phd_arr.extend;
            l_desc_phd_arr(1) := l_desc_phd;
        
            IF l_id_alert_diagnosis_num IS NULL
               AND l_id_diagnosis IS NOT NULL
            THEN
                l_id_alert_diagnosis_num := pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => l_id_diagnosis,
                                                                                               i_task_type       => pk_alert_constant.g_task_problems);
                IF l_id_alert_diagnosis_num IS NOT NULL
                THEN
                    ts_pat_history_diagnosis.upd(id_pat_history_diagnosis_in => i_id_pat_problem(1),
                                                 id_alert_diagnosis_in       => l_id_alert_diagnosis_num,
                                                 rows_out                    => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            END IF;
        
            l_id_alert_diagnosis := table_number();
            l_id_alert_diagnosis.extend;
            l_id_alert_diagnosis(1) := l_id_alert_diagnosis_num;
        
            l_notes_arr := table_varchar();
            l_notes_arr.extend;
            --l_notes_arr(1) := nvl(i_notes(1), l_notes);
            l_notes_arr(1) := i_notes(1);
            IF NOT pk_past_history.set_past_hist_diagnosis(i_lang                       => i_lang,
                                                           i_prof                       => i_prof,
                                                           i_episode                    => i_epis,
                                                           i_pat                        => i_pat,
                                                           i_doc_area                   => CASE i_flg_area
                                                                                               WHEN
                                                                                                pk_past_history.g_alert_diag_type_surg THEN
                                                                                                pk_past_history.g_doc_area_past_surg
                                                                                               ELSE
                                                                                                pk_past_history.g_doc_area_past_med
                                                                                           END,
                                                           i_flg_status                 => i_flg_status,
                                                           i_flg_nature                 => i_flg_nature,
                                                           i_diagnosis                  => l_id_alert_diagnosis,
                                                           i_phd_outdated               => i_id_pat_problem(1),
                                                           i_desc_pat_history_diagnosis => l_desc_phd_arr,
                                                           i_notes                      => l_notes_arr,
                                                           i_id_cancel_reason           => table_number(NULL),
                                                           i_cancel_notes               => table_varchar(NULL),
                                                           i_precaution_measure         => i_precaution_measure,
                                                           i_flg_warning                => i_header_warning,
                                                           i_dt_register                => nvl(i_dt_register,
                                                                                               current_timestamp),
                                                           i_exam                       => NULL,
                                                           i_intervention               => NULL,
                                                           dt_execution                 => NULL,
                                                           i_dt_execution_precision     => NULL,
                                                           i_cdr_call                   => NULL, --i_cdr_event,
                                                           i_dt_review                  => NULL,
                                                           i_flg_area                   => table_varchar(i_flg_area),
                                                           i_flg_complications          => i_flg_complications,
                                                           i_flg_screen                 => pk_alert_constant.g_diag_area_problems,
                                                           i_dt_diagnosed               => i_dt_diagnosed,
                                                           i_dt_diagnosed_precision     => i_dt_diagnosed_precision,
                                                           i_dt_resolved                => i_dt_resolved,
                                                           i_dt_resolved_precision      => i_dt_resolved_precision,
                                                           i_location                   => i_location,
                                                           i_id_family_relationship     => NULL,
                                                           i_flg_death_cause            => NULL,
                                                           i_familiar_age               => NULL,
                                                           i_phd_diagnosis              => NULL,
                                                           o_seq_phd                    => l_seq_phd,
                                                           o_error                      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_id_pat_problem := l_seq_phd(1);
        
            o_ids  := l_seq_phd;
            o_type := i_type;
        END IF;
    
        g_error := 'call set_epis_problem_group_array';
        IF i_flg_epis_prob = pk_alert_constant.g_yes
           AND l_has_group = pk_alert_constant.g_yes
        THEN
            l_id_problem := i_id_pat_problem;
            l_prob_group := i_prob_group;
            l_seq_num    := i_seq_num;
        ELSE
            OPEN c_epis_prob(i_id_pat_problem, i_epis);
            LOOP
                FETCH c_epis_prob
                    INTO r_epis_prob;
                EXIT WHEN c_epis_prob%NOTFOUND;
                l_id_problem.extend;
                l_id_problem(l_id_problem.count) := r_epis_prob.id_problem;
                l_prob_group.extend;
                l_prob_group(l_prob_group.count) := get_prob_group(i_epis, r_epis_prob.id_epis_prob_group);
                l_seq_num.extend;
                l_seq_num(l_seq_num.count) := r_epis_prob.seq_num;
            END LOOP;
            CLOSE c_epis_prob;
        END IF;
    
        IF l_id_problem IS NOT NULL
           AND l_id_problem.count > 0
        THEN
            IF NOT set_epis_problem_group_array(i_lang            => i_lang,
                                                i_episode         => i_epis,
                                                i_prof            => i_prof,
                                                i_id_problem      => o_ids,
                                                i_prev_id_problem => l_id_problem,
                                                i_flg_status      => i_flg_status,
                                                i_prob_group      => l_prob_group,
                                                i_seq_num         => l_seq_num,
                                                i_flg_type        => i_type,
                                                o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'call set_problem_history';
        IF NOT pk_problems.set_problem_history(i_lang           => i_lang,
                                               i_pat            => i_pat,
                                               i_prof           => i_prof,
                                               i_id_pat_problem => i_id_pat_problem(1),
                                               o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_type(1) = g_pat_prob_prob
           AND l_id_habit IS NOT NULL
        THEN
            l_flg_source := g_problem_type_habit;
        ELSE
            l_flg_source := i_type(1);
        END IF;
    
        IF i_flg_area IN (pk_alert_constant.g_diag_area_problems)
        THEN
            g_error := 'call set_pat_problem_review';
            IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_pat_problem => l_id_pat_problem,
                                                      i_flg_source     => l_flg_source,
                                                      i_review_notes   => NULL,
                                                      i_episode        => i_epis,
                                                      i_flg_auto       => pk_alert_constant.g_yes,
                                                      o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF NOT pk_problems.cancel_pat_prob_unaware_nc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_patient          => i_pat,
                                                      i_id_episode          => i_epis,
                                                      i_notes               => NULL,
                                                      i_id_cancel_reason    => NULL,
                                                      i_cancel_notes        => NULL,
                                                      i_flg_status          => i_flg_status,
                                                      o_id_pat_prob_unaware => l_id_pat_prob_unaware,
                                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            IF o_error.ora_sqlcode <> g_error_group_code
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM_ARRAY_DT_NC',
                                                  o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
            END IF;
            -- return failure
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY_DT_NC');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END set_pat_problem_array_dt_nc;

    FUNCTION get_problem_protocol
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN pat_history_diagnosis.flg_area%TYPE,
        o_problem_prot OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
    
        OPEN o_problem_prot FOR
            SELECT s.desc_terminology desc_val, s.flg_terminology val, NULL img_name, s.rank
              FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_tbl_task_type => table_number(get_flg_area_task_type(i_flg_area => i_task_type)))) s
             ORDER BY s.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PROBLEM_PROTOCOL');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem_prot);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION set_pat_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_id_pat_allergy   IN pat_allergy.id_pat_allergy%TYPE,
        i_id_pat           IN pat_allergy.id_patient%TYPE,
        i_prof             IN profissional,
        i_allergy          IN pat_allergy.id_allergy%TYPE,
        i_drug_pharma      IN pat_allergy.id_drug_pharma%TYPE,
        i_notes            IN pat_allergy.notes%TYPE,
        i_dt_first_time    IN pat_allergy.dt_first_time_tstz%TYPE,
        i_flg_type         IN pat_allergy.flg_type%TYPE,
        i_flg_approved     IN pat_allergy.flg_aproved%TYPE,
        i_flg_status       IN pat_allergy.flg_status%TYPE,
        i_flg_nature       IN pat_allergy.flg_nature%TYPE,
        i_dt_symptoms      IN VARCHAR2,
        i_id_cancel_reason IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_dt_resolution    IN pat_allergy.dt_resolution%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_allergy pat_allergy.id_pat_allergy%TYPE;
        l_desc_allergy   pat_allergy.desc_allergy%TYPE;
    
        l_desc_aproved        pat_allergy.desc_aproved%TYPE;
        l_year_begin          pat_allergy.year_begin%TYPE;
        l_month_begin         pat_allergy.month_begin%TYPE;
        l_day_begin           pat_allergy.day_begin%TYPE;
        l_id_allergy_severity pat_allergy.id_allergy_severity%TYPE;
        l_desc_edit           pat_allergy.desc_edit%TYPE;
    
        l_id_symptoms table_number;
    
        l_exception EXCEPTION;
    BEGIN
    
        BEGIN
        
            SELECT pa.desc_aproved,
                   pa.year_begin,
                   pa.month_begin,
                   pa.day_begin,
                   pa.id_allergy_severity,
                   pa.desc_edit,
                   pa.desc_allergy
              INTO l_desc_aproved,
                   l_year_begin,
                   l_month_begin,
                   l_day_begin,
                   l_id_allergy_severity,
                   l_desc_edit,
                   l_desc_allergy
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_pat_allergy;
        
            SELECT pas.id_allergy_symptoms
              BULK COLLECT
              INTO l_id_symptoms
              FROM pat_allergy_symptoms pas
             WHERE pas.id_pat_allergy = i_id_pat_allergy;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_desc_aproved        := NULL;
                l_year_begin          := NULL;
                l_month_begin         := NULL;
                l_day_begin           := NULL;
                l_id_allergy_severity := NULL;
                l_desc_edit           := NULL;
                l_desc_allergy        := NULL;
        END;
    
        IF NOT pk_allergy.set_allergy_problem_nc(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_patient          => i_id_pat,
                                                 i_id_episode          => i_epis,
                                                 i_id_pat_allergy      => i_id_pat_allergy,
                                                 i_id_allergy          => i_allergy,
                                                 i_desc_allergy        => l_desc_allergy,
                                                 i_notes               => i_notes,
                                                 i_flg_status          => i_flg_status,
                                                 i_flg_type            => i_flg_type,
                                                 i_flg_aproved         => i_flg_approved,
                                                 i_desc_aproved        => l_desc_aproved,
                                                 i_year_begin          => l_year_begin,
                                                 i_month_begin         => l_month_begin,
                                                 i_day_begin           => l_day_begin,
                                                 i_id_symptoms         => l_id_symptoms,
                                                 i_id_allergy_severity => l_id_allergy_severity,
                                                 i_flg_edit            => 'O',
                                                 i_desc_edit           => l_desc_edit,
                                                 i_flg_nature          => i_flg_nature,
                                                 i_dt_resolution       => i_dt_resolution,
                                                 o_id_pat_allergy      => l_id_pat_allergy,
                                                 o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              '',
                                              o_error);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            -- undo changes
            pk_utils.undo_changes;
            -- return failure   
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, '');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_problem_list
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_flg_type  IN diagnosis.flg_type%TYPE,
        i_search    IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_diags t_coll_diagnosis_config;
    
    BEGIN
    
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => i_patient,
                                                               i_text_search              => i_search,
                                                               i_format_text              => NULL,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                               i_term_task_type           => pk_alert_constant.g_task_problems,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                               i_tbl_terminologies        => table_varchar(i_flg_type),
                                                               i_parent_diagnosis         => i_id_parent,
                                                               i_only_diag_filter_by_prt  => pk_alert_constant.g_yes);
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table tf rows=10)*/
             d.id_diagnosis,
             d.id_alert_diagnosis,
             d.desc_diagnosis,
             d.id_diagnosis_parent,
             d.avail_for_select flg_select,
             d.flg_other
              FROM TABLE(l_tbl_diags) d
             ORDER BY decode(i_search, NULL, d.desc_diagnosis, rownum);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PROBLEM_LIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_problem_system
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_search      IN VARCHAR2,
        o_problem_sys OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_column_name system_apparati.code_system_apparati%TYPE;
    
    BEGIN
    
        SELECT pk_translation.format_column_name(sa.code_system_apparati)
          INTO l_column_name
          FROM system_apparati sa
         WHERE rownum < 2;
    
        g_error := 'GET CURSOR';
        OPEN o_problem_sys FOR
            SELECT /*+opt_estimate (table tf rows=10)*/
             sa.id_system_apparati, pk_translation.get_translation(i_lang, sa.code_system_apparati), rank
              FROM system_apparati sa,
                   professional prof,
                   TABLE(pk_translation.get_search_translation(i_lang, i_search, l_column_name)) tf
             WHERE (sa.gender IS NULL OR prof.gender = sa.gender)
               AND to_char(SYSDATE, 'YYYY') - to_char(prof.dt_birth, 'YYYY') < nvl(sa.age_max, 200)
               AND to_char(SYSDATE, 'YYYY') - to_char(prof.dt_birth, 'YYYY') > nvl(sa.age_min, 0)
               AND prof.id_professional = i_prof.id
               AND tf.code_translation = sa.code_system_apparati
             ORDER BY tf.position;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PROBLEM_SYSTEM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem_sys);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_problem_organ
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_search      IN VARCHAR2,
        i_system_app  IN system_apparati.id_system_apparati%TYPE,
        o_problem_org OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_column_name system_organ.code_system_organ%TYPE;
    
    BEGIN
        SELECT pk_translation.format_column_name(so.code_system_organ)
          INTO l_column_name
          FROM system_organ so
         WHERE rownum < 2;
    
        g_error := 'GET CURSOR';
        OPEN o_problem_org FOR
            SELECT /*+opt_estimate (table tf rows=10)*/
             so.id_system_organ, pk_translation.get_translation(i_lang, so.code_system_organ), rank
              FROM system_organ so,
                   sys_appar_organ sao,
                   TABLE(pk_translation.get_search_translation(i_lang, i_search, l_column_name)) tf
             WHERE sao.id_system_organ = so.id_system_organ
               AND sao.id_system_organ = i_system_app
               AND tf.code_translation = so.code_system_organ
             ORDER BY tf.position;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_PROBLEM_ORGAN');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_problem_org);
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION set_pat_problem_array_int_new
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status       pat_problem.flg_status%TYPE;
        l_prof_upd         pat_problem.id_professional_ins%TYPE;
        l_dt_update        TIMESTAMP WITH TIME ZONE;
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
        l_flg_show         VARCHAR2(1);
        l_msg_title        VARCHAR2(2000);
        l_msg_text         VARCHAR2(2000);
        l_button           VARCHAR2(6);
    
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_alert_diagnosis,
                   id_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   flg_nature
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    
        l_rowids_aux table_varchar;
    
        l_notes_aux VARCHAR2(4000);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_pat_problem.count
        LOOP
            -- Loop sobre o array de IDs de registos 
            g_error            := 'GET TYPE / STATUS';
            v_pat_problem_hist := NULL;
            l_flg_status       := i_flg_status(i);
            l_prof_upd         := i_prof.id;
            l_dt_update        := g_sysdate_tstz;
        
            IF i_type(i) = g_pat_prob_allrg
            THEN
                g_error := 'SET ALLERGY';
                IF NOT set_pat_allergy(i_lang             => i_lang,
                                       i_epis             => i_epis,
                                       i_id_pat_allergy   => i_id_pat_problem(i),
                                       i_id_pat           => i_pat,
                                       i_prof             => i_prof,
                                       i_allergy          => NULL,
                                       i_drug_pharma      => NULL,
                                       i_notes            => i_notes(i),
                                       i_dt_first_time    => NULL,
                                       i_flg_type         => NULL,
                                       i_flg_approved     => NULL,
                                       i_flg_status       => i_flg_status(i),
                                       i_flg_nature       => i_flg_nature(i),
                                       i_dt_symptoms      => NULL,
                                       i_id_cancel_reason => NULL,
                                       i_cancel_notes     => NULL,
                                       i_prof_cat_type    => i_prof_cat_type,
                                       i_dt_resolution    => NULL,
                                       o_flg_show         => l_flg_show,
                                       o_msg_title        => l_msg_title,
                                       o_msg_text         => l_msg_text,
                                       o_button           => l_button,
                                       o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSIF i_type(i) = g_pat_prob_prob
            THEN
                g_error := 'OPEN CURSOR PROBLEMS';
            
                OPEN c_prob(i_id_pat_problem(i));
                FETCH c_prob
                    INTO v_pat_problem_hist.id_pat_problem,
                         v_pat_problem_hist.id_patient,
                         v_pat_problem_hist.id_alert_diagnosis,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_professional_ins,
                         v_pat_problem_hist.dt_pat_problem_tstz,
                         v_pat_problem_hist.desc_pat_problem,
                         v_pat_problem_hist.notes,
                         v_pat_problem_hist.flg_age,
                         v_pat_problem_hist.year_begin,
                         v_pat_problem_hist.month_begin,
                         v_pat_problem_hist.day_begin,
                         v_pat_problem_hist.year_end,
                         v_pat_problem_hist.month_end,
                         v_pat_problem_hist.day_end,
                         v_pat_problem_hist.pct_incapacity,
                         v_pat_problem_hist.flg_surgery,
                         v_pat_problem_hist.notes_support,
                         v_pat_problem_hist.dt_confirm_tstz,
                         v_pat_problem_hist.rank,
                         v_pat_problem_hist.flg_status,
                         v_pat_problem_hist.id_epis_diagnosis,
                         v_pat_problem_hist.flg_aproved,
                         v_pat_problem_hist.id_institution,
                         v_pat_problem_hist.id_pat_habit,
                         v_pat_problem_hist.id_episode,
                         v_pat_problem_hist.id_epis_anamnesis,
                         v_pat_problem_hist.flg_nature;
                g_found := c_prob%NOTFOUND;
                CLOSE c_prob;
            
                g_error := 'SET PROBLEM';
                SELECT notes
                  INTO l_notes_aux
                  FROM pat_problem
                 WHERE id_pat_problem = i_id_pat_problem(i);
            
                ts_pat_problem.upd(id_pat_problem_in      => i_id_pat_problem(i),
                                   flg_status_in          => l_flg_status,
                                   dt_pat_problem_tstz_in => l_dt_update,
                                   id_professional_ins_in => l_prof_upd,
                                   id_institution_in      => i_prof.institution,
                                   notes_in               => nvl(i_notes(i), l_notes_aux),
                                   notes_nin              => FALSE,
                                   id_episode_in          => i_epis,
                                   id_episode_nin         => FALSE,
                                   flg_nature_in          => i_flg_nature(i),
                                   flg_nature_nin         => FALSE,
                                   rows_out               => l_rowids_aux);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids_aux,
                                              o_error      => o_error);
            
                g_error := 'PAT_HABIT P';
                pk_alertlog.log_debug(g_error);
                l_rowids_aux := table_varchar();
                ts_pat_habit.upd(id_pat_habit_in   => v_pat_problem_hist.id_pat_habit,
                                 flg_status_in     => l_flg_status,
                                 dt_cancel_tstz_in => l_dt_update,
                                 id_prof_cancel_in => i_prof.id,
                                 note_cancel_in    => i_notes(i),
                                 id_episode_in     => i_epis,
                                 rows_out          => l_rowids_aux);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_HABIT',
                                              i_rowids     => l_rowids_aux,
                                              o_error      => o_error);
            
                l_rowids_aux := table_varchar();
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY_INTERNAL_NEW');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION set_pat_problem_array_new
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_PAT_ARRAY_INTERNAL';
        IF NOT set_pat_problem_array_internal(i_lang,
                                              i_epis,
                                              i_pat,
                                              i_prof,
                                              i_id_pat_problem,
                                              i_flg_status,
                                              i_notes,
                                              i_type,
                                              i_prof_cat_type,
                                              i_flg_nature,
                                              table_varchar(NULL),
                                              current_timestamp,
                                              o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'SET_PAT_PROBLEM_ARRAY_NEW');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION create_pat_problem_epis_diag
    (
        i_lang            IN language.id_language%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        i_pat             IN pat_problem.id_patient%TYPE,
        i_prof            IN profissional,
        i_desc_problem    IN table_varchar,
        i_flg_status      IN table_varchar,
        i_notes           IN table_varchar,
        i_dt_symptoms     IN table_varchar,
        i_diagnosis       IN table_number,
        i_alert_diagnosis IN table_number,
        i_epis_anamnesis  IN table_number,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_epis_diagnosis  IN table_number,
        i_flg_nature      IN table_varchar,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_prob_unaware pat_prob_unaware.id_pat_prob_unaware%TYPE;
        l_next                pat_problem.id_pat_problem%TYPE;
        l_year_begin          pat_problem.year_begin%TYPE;
        l_month_begin         pat_problem.month_begin%TYPE;
        l_day_begin           pat_problem.day_begin%TYPE;
    
        l_diagnosis       pat_problem.id_diagnosis%TYPE;
        l_alert_diagnosis pat_problem.id_alert_diagnosis%TYPE;
        l_desc_diag       epis_diagnosis.desc_epis_diagnosis%TYPE;
        l_flg_other       diagnosis.flg_other%TYPE;
    
        l_rowids     table_varchar;
        l_rowids_aux table_varchar;
    
        l_id_pat_problem   NUMBER;
        l_flg_cur_status   pat_problem.flg_status%TYPE;
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
        l_flg_status       pat_problem.flg_status%TYPE;
    
        l_flg_type     epis_diagnosis.flg_type%TYPE;
        l_flg_type_new epis_diagnosis.flg_type%TYPE;
    
        l_allow_diagnoses_same_icd sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_PROBLEMS_SAME_ICD', i_prof);
    
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   flg_nature,
                   id_diagnosis,
                   id_cancel_reason,
                   cancel_notes,
                   dt_resolution
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_flg_status.count
        LOOP
        
            g_error       := 'GET DATE SYMPTOMS';
            l_year_begin  := NULL;
            l_month_begin := NULL;
            l_day_begin   := NULL;
            IF i_dt_symptoms IS NOT NULL
            THEN
                l_year_begin  := to_number(substr(i_dt_symptoms(i), 1, instr(i_dt_symptoms(i), '-') - 1));
                l_month_begin := to_number(substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                                  1,
                                                  instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') - 1));
                l_day_begin   := to_number(substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                                  instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') + 1));
            END IF;
        
            g_error := 'GET ID_DIAGNOSIS';
            --get the id_diagnosis
            BEGIN
                SELECT ed.id_diagnosis, ed.id_alert_diagnosis, ed.desc_epis_diagnosis, d.flg_other, ed.flg_type
                  INTO l_diagnosis, l_alert_diagnosis, l_desc_diag, l_flg_other, l_flg_type_new
                  FROM epis_diagnosis ed
                  JOIN diagnosis d
                    ON d.id_diagnosis = ed.id_diagnosis
                 WHERE ed.id_epis_diagnosis = i_epis_diagnosis(i);
            EXCEPTION
                WHEN no_data_found THEN
                    l_diagnosis       := i_diagnosis(i);
                    l_alert_diagnosis := i_alert_diagnosis(i);
            END;
        
            IF i_flg_status(i) IS NOT NULL
            THEN
            
                g_error := 'GET ID_PAT_PROBLEM';
                BEGIN
                    SELECT id_pat_problem, flg_type
                      INTO l_id_pat_problem, l_flg_type
                      FROM (SELECT id_pat_problem, ed.flg_type
                              FROM pat_problem pp
                              LEFT JOIN epis_diagnosis ed
                                ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                             WHERE pp.id_patient = i_pat
                               AND (((pp.id_diagnosis = l_diagnosis OR pp.id_alert_diagnosis = l_alert_diagnosis) AND
                                   l_allow_diagnoses_same_icd = pk_alert_constant.g_no) OR
                                   ((pp.id_diagnosis = l_diagnosis AND pp.id_alert_diagnosis = l_alert_diagnosis) AND
                                   l_allow_diagnoses_same_icd = pk_alert_constant.g_yes AND
                                   nvl(pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                                        i_id_concept_term    => pp.id_alert_diagnosis,
                                                                        i_id_concept_version => pp.id_diagnosis,
                                                                        i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                        i_id_institution     => i_prof.institution,
                                                                        i_id_software        => i_prof.software),
                                         pk_alert_constant.g_yes) = pk_alert_constant.g_yes))
                               AND ((ed.desc_epis_diagnosis = l_desc_diag AND
                                   nvl(l_flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_yes) OR
                                   (nvl(l_flg_other, pk_alert_constant.g_no) != pk_alert_constant.g_yes AND
                                   l_desc_diag IS NULL))
                             ORDER BY pp.dt_pat_problem_tstz DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_pat_problem := NULL;
                END;
            
                IF l_id_pat_problem IS NULL
                THEN
                
                    g_error := 'GET SEQ_PATIENT.NEXTVAL';
                    SELECT ts_pat_problem.next_key
                      INTO l_next
                      FROM dual;
                
                    g_error := 'INSERT PAT_PROBLEM';
                    ts_pat_problem.ins(id_pat_problem_in      => l_next,
                                       id_patient_in          => i_pat,
                                       id_diagnosis_in        => l_diagnosis,
                                       id_professional_ins_in => i_prof.id,
                                       dt_pat_problem_tstz_in => g_sysdate_tstz,
                                       flg_status_in          => i_flg_status(i),
                                       desc_pat_problem_in    => i_desc_problem(i),
                                       notes_in               => i_notes(i),
                                       year_begin_in          => l_year_begin,
                                       month_begin_in         => l_month_begin,
                                       day_begin_in           => l_day_begin,
                                       id_institution_in      => i_prof.institution,
                                       id_episode_in          => i_epis,
                                       id_epis_anamnesis_in   => i_epis_anamnesis(i),
                                       flg_nature_in          => i_flg_nature(i),
                                       id_alert_diagnosis_in  => l_alert_diagnosis,
                                       id_epis_diagnosis_in   => i_epis_diagnosis(i),
                                       rows_out               => l_rowids_aux);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_PROBLEM',
                                                  i_rowids     => l_rowids_aux,
                                                  o_error      => o_error);
                ELSE
                    g_error := 'OPEN CURSOR C_PROB';
                    OPEN c_prob(l_id_pat_problem);
                    FETCH c_prob
                        INTO v_pat_problem_hist.id_pat_problem,
                             v_pat_problem_hist.id_patient,
                             v_pat_problem_hist.id_diagnosis,
                             v_pat_problem_hist.id_alert_diagnosis,
                             v_pat_problem_hist.id_professional_ins,
                             v_pat_problem_hist.dt_pat_problem_tstz,
                             v_pat_problem_hist.desc_pat_problem,
                             v_pat_problem_hist.notes,
                             v_pat_problem_hist.flg_age,
                             v_pat_problem_hist.year_begin,
                             v_pat_problem_hist.month_begin,
                             v_pat_problem_hist.day_begin,
                             v_pat_problem_hist.year_end,
                             v_pat_problem_hist.month_end,
                             v_pat_problem_hist.day_end,
                             v_pat_problem_hist.pct_incapacity,
                             v_pat_problem_hist.flg_surgery,
                             v_pat_problem_hist.notes_support,
                             v_pat_problem_hist.dt_confirm_tstz,
                             v_pat_problem_hist.rank,
                             v_pat_problem_hist.flg_status,
                             v_pat_problem_hist.id_epis_diagnosis,
                             v_pat_problem_hist.flg_aproved,
                             v_pat_problem_hist.id_institution,
                             v_pat_problem_hist.id_pat_habit,
                             v_pat_problem_hist.id_episode,
                             v_pat_problem_hist.id_epis_anamnesis,
                             v_pat_problem_hist.flg_nature,
                             v_pat_problem_hist.id_diagnosis,
                             v_pat_problem_hist.id_cancel_reason,
                             v_pat_problem_hist.cancel_notes,
                             v_pat_problem_hist.dt_resolution;
                    g_found := c_prob%NOTFOUND;
                    CLOSE c_prob;
                
                    -- sincronize problem status only when diagnostic is cancelled on diagnosis area
                    -- When problem is already cancelled and a new diagnostic is createtd then this problem should became active)
                    IF (v_pat_problem_hist.flg_status = pk_problems.g_cancelled AND
                       i_flg_status(i) = pk_problems.g_active AND
                       v_pat_problem_hist.id_epis_diagnosis <> i_epis_diagnosis(i))
                       OR (v_pat_problem_hist.flg_status <> pk_problems.g_cancelled AND
                       i_flg_status(i) = pk_problems.g_cancelled)
                       OR (v_pat_problem_hist.id_epis_diagnosis <> i_epis_diagnosis(i) AND
                       l_flg_type = pk_diagnosis.g_diag_type_p AND l_flg_type_new = pk_diagnosis.g_diag_type_d)
                    THEN
                    
                        ts_pat_problem_hist.ins(id_pat_problem_hist_in => ts_pat_problem_hist.next_key,
                                                id_pat_problem_in      => v_pat_problem_hist.id_pat_problem,
                                                id_patient_in          => v_pat_problem_hist.id_patient,
                                                id_diagnosis_in        => v_pat_problem_hist.id_diagnosis,
                                                id_professional_ins_in => v_pat_problem_hist.id_professional_ins,
                                                dt_pat_problem_tstz_in => v_pat_problem_hist.dt_pat_problem_tstz,
                                                desc_pat_problem_in    => v_pat_problem_hist.desc_pat_problem,
                                                notes_in               => v_pat_problem_hist.notes,
                                                flg_age_in             => v_pat_problem_hist.flg_age,
                                                year_begin_in          => v_pat_problem_hist.year_begin,
                                                month_begin_in         => v_pat_problem_hist.month_begin,
                                                day_begin_in           => v_pat_problem_hist.day_begin,
                                                year_end_in            => v_pat_problem_hist.year_end,
                                                month_end_in           => v_pat_problem_hist.month_end,
                                                day_end_in             => v_pat_problem_hist.day_end,
                                                pct_incapacity_in      => v_pat_problem_hist.pct_incapacity,
                                                flg_surgery_in         => v_pat_problem_hist.flg_surgery,
                                                notes_support_in       => v_pat_problem_hist.notes_support,
                                                dt_confirm_tstz_in     => v_pat_problem_hist.dt_confirm_tstz,
                                                rank_in                => v_pat_problem_hist.rank,
                                                flg_status_in          => v_pat_problem_hist.flg_status,
                                                id_epis_diagnosis_in   => v_pat_problem_hist.id_epis_diagnosis,
                                                flg_aproved_in         => v_pat_problem_hist.flg_aproved,
                                                id_institution_in      => v_pat_problem_hist.id_institution,
                                                id_pat_habit_in        => v_pat_problem_hist.id_pat_habit,
                                                id_episode_in          => v_pat_problem_hist.id_episode,
                                                id_epis_anamnesis_in   => v_pat_problem_hist.id_epis_anamnesis,
                                                flg_nature_in          => v_pat_problem_hist.flg_nature,
                                                id_alert_diagnosis_in  => v_pat_problem_hist.id_alert_diagnosis,
                                                id_cancel_reason_in    => v_pat_problem_hist.id_cancel_reason,
                                                cancel_notes_in        => v_pat_problem_hist.cancel_notes,
                                                dt_resolution_in       => v_pat_problem_hist.dt_resolution,
                                                rows_out               => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_PROBLEM_HIST',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        g_error := 'UPDATE PAT_PROBLEM';
                        ts_pat_problem.upd(id_pat_problem_in      => l_id_pat_problem,
                                           id_diagnosis_in        => l_diagnosis,
                                           id_professional_ins_in => i_prof.id,
                                           dt_pat_problem_tstz_in => g_sysdate_tstz,
                                           flg_status_in          => i_flg_status(i),
                                           desc_pat_problem_in    => i_desc_problem(i),
                                           notes_in               => i_notes(i),
                                           notes_nin              => FALSE,
                                           year_begin_in          => l_year_begin,
                                           year_begin_nin         => FALSE,
                                           month_begin_in         => l_month_begin,
                                           month_begin_nin        => FALSE,
                                           day_begin_in           => l_day_begin,
                                           day_begin_nin          => FALSE,
                                           id_institution_in      => i_prof.institution,
                                           id_episode_in          => i_epis,
                                           id_epis_anamnesis_in   => i_epis_anamnesis(i),
                                           flg_nature_in          => i_flg_nature(i),
                                           flg_nature_nin         => FALSE,
                                           id_alert_diagnosis_in  => l_alert_diagnosis,
                                           id_epis_diagnosis_in   => i_epis_diagnosis(i),
                                           rows_out               => l_rowids_aux);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_PROBLEM',
                                                      i_rowids     => l_rowids_aux,
                                                      o_error      => o_error);
                    
                    END IF;
                END IF;
            
                l_rowids_aux := table_varchar();
            
                o_msg       := NULL;
                o_msg_title := NULL;
                o_flg_show  := 'N';
                o_button    := NULL;
            
                g_error := 'call set_pat_problem_review';
                IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_pat_problem => nvl(l_id_pat_problem, l_next),
                                                          i_flg_source     => 'P',
                                                          i_review_notes   => NULL,
                                                          i_episode        => i_epis,
                                                          i_flg_auto       => pk_alert_constant.g_yes,
                                                          o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END LOOP;
    
        IF NOT pk_problems.cancel_pat_prob_unaware_nc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_patient          => i_pat,
                                                      i_id_episode          => i_epis,
                                                      i_notes               => NULL,
                                                      i_id_cancel_reason    => NULL,
                                                      i_cancel_notes        => NULL,
                                                      i_flg_status          => i_flg_status,
                                                      o_id_pat_prob_unaware => l_id_pat_prob_unaware,
                                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'CREATE_PAT_PROBLEM_EPIS_DIAG');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_prob_unaware_active
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN pat_prob_unaware.id_patient%TYPE,
        i_episode                 IN pat_prob_unaware.id_episode%TYPE,
        o_pat_prob_unaware_active OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(60 CHAR) := 'get_pat_prob_unaware_active';
        l_documented          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T081');
        l_notes_label         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T009');
        l_cancel_reason_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T026');
    BEGIN
        g_error := 'OPEN o_pat_prob_unaware_active';
        OPEN o_pat_prob_unaware_active FOR
            SELECT *
              FROM (SELECT ppu.id_prob_unaware id_prob_unaware,
                           ppu.id_pat_prob_unaware id_pat_prob_unaware,
                           ppu.id_episode id_episode,
                           ppu.flg_status flg_status,
                           NULL desc_status,
                           pk_date_utils.date_send_tsz(i_lang, ppu.dt_last_update, i_prof) date_creation_rep,
                           pk_date_utils.date_char_tsz(i_lang, ppu.dt_last_update, i_prof.institution, i_prof.software) dt_creation,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ppu.id_prof_last_update) prof_nick_name,
                           decode(pk_prof_utils.get_prof_speciality(i_lang,
                                                                    profissional(ppu.id_prof_last_update,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)),
                                  NULL,
                                  NULL,
                                  g_open_parentheses ||
                                  pk_prof_utils.get_prof_speciality(i_lang,
                                                                    profissional(ppu.id_prof_last_update,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)) || g_close_parentheses) desc_specialty,
                           decode(i_episode, ppu.id_episode, NULL, l_documented) msg_previous_episode,
                           pk_translation.get_translation(i_lang, pu.code_prob_unaware) title,
                           l_notes_label msg_notes,
                           ppu.notes notes,
                           l_cancel_reason_label msg_cancel_reason,
                           ppu.id_cancel_reason id_cancel_reason,
                           pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason_desc,
                           decode(i_episode, ppu.id_episode, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_previous_episode
                      FROM pat_prob_unaware ppu
                      LEFT JOIN prob_unaware pu
                        ON pu.id_prob_unaware = ppu.id_prob_unaware
                      LEFT JOIN cancel_reason cr
                        ON cr.id_cancel_reason = ppu.id_cancel_reason
                     WHERE ppu.id_patient = i_patient
                       AND ppu.flg_status = g_status_ppu_active
                     ORDER BY date_creation_rep DESC)
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_prob_unaware_active);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_prob_unaware_active;

    FUNCTION get_pat_prob_unaware_outdated
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN pat_prob_unaware_hist.id_patient%TYPE,
        i_episode                   IN pat_prob_unaware_hist.id_episode%TYPE,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name           VARCHAR2(60 CHAR) := 'get_pat_prob_unaware_outdated';
        l_documented          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T081');
        l_notes_label         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T009');
        l_cancel_notes_label  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T027');
        l_cancel_reason_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'PROBLEM_LIST_T026');
    BEGIN
    
        g_error := 'OPEN o_pat_prob_unaware_outdated';
        OPEN o_pat_prob_unaware_outdated FOR
            SELECT *
              FROM (SELECT ppuh.id_prob_unaware id_prob_unaware,
                           ppuh.id_pat_prob_unaware id_pat_prob_unaware,
                           ppuh.id_episode id_episode,
                           ppuh.flg_status flg_status,
                           CASE ppuh.flg_status
                               WHEN g_status_ppu_active THEN
                                pk_sysdomain.get_domain('PAT_PROB_UNAWARE.FLG_STATUS', g_status_ppu_outdated, i_lang)
                               ELSE
                                pk_sysdomain.get_domain('PAT_PROB_UNAWARE.FLG_STATUS', ppuh.flg_status, i_lang)
                           END desc_status,
                           pk_date_utils.date_send_tsz(i_lang, ppuh.dt_last_update, i_prof) date_creation_rep,
                           pk_date_utils.date_char_tsz(i_lang, ppuh.dt_last_update, i_prof.institution, i_prof.software) dt_creation,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ppuh.id_prof_last_update) prof_nick_name,
                           decode(pk_prof_utils.get_prof_speciality(i_lang,
                                                                    profissional(ppuh.id_prof_last_update,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)),
                                  NULL,
                                  NULL,
                                  g_open_parentheses ||
                                  pk_prof_utils.get_prof_speciality(i_lang,
                                                                    profissional(ppuh.id_prof_last_update,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)) || g_close_parentheses) desc_specialty,
                           decode(i_episode, ppuh.id_episode, NULL, l_documented) msg_previous_episode,
                           pk_translation.get_translation(i_lang, pu.code_prob_unaware) title,
                           CASE
                                WHEN ppuh.flg_status IN (g_status_ppu_active, g_status_ppu_outdated) THEN
                                 l_notes_label
                                WHEN ppuh.flg_status = g_status_ppu_cancel THEN
                                 l_cancel_notes_label
                                ELSE
                                 NULL
                            END msg_notes,
                           CASE
                                WHEN ppuh.flg_status IN (g_status_ppu_active, g_status_ppu_outdated) THEN
                                 ppuh.notes
                                WHEN ppuh.flg_status = g_status_ppu_cancel THEN
                                 ppuh.cancel_notes
                                ELSE
                                 NULL
                            END notes,
                           l_cancel_reason_label msg_cancel_reason,
                           ppuh.id_cancel_reason id_cancel_reason,
                           pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason_desc,
                           decode(i_episode, ppuh.id_episode, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_previous_episode
                      FROM pat_prob_unaware_hist ppuh
                      JOIN pat_prob_unaware ppu
                        ON ppuh.id_pat_prob_unaware = ppu.id_pat_prob_unaware
                      LEFT JOIN prob_unaware pu
                        ON pu.id_prob_unaware = ppuh.id_prob_unaware
                      LEFT JOIN cancel_reason cr
                        ON cr.id_cancel_reason = ppuh.id_cancel_reason
                     WHERE ppu.id_patient = i_patient
                    UNION ALL
                    SELECT *
                      FROM (SELECT ppu.id_prob_unaware id_prob_unaware,
                                   ppu.id_pat_prob_unaware id_pat_prob_unaware,
                                   ppu.id_episode id_episode,
                                   ppu.flg_status flg_status,
                                   CASE ppu.flg_status
                                       WHEN g_status_ppu_active THEN
                                        pk_sysdomain.get_domain('PAT_PROB_UNAWARE.FLG_STATUS',
                                                                g_status_ppu_outdated,
                                                                i_lang)
                                       ELSE
                                        pk_sysdomain.get_domain('PAT_PROB_UNAWARE.FLG_STATUS', ppu.flg_status, i_lang)
                                   END desc_status,
                                   pk_date_utils.date_send_tsz(i_lang, ppu.dt_last_update, i_prof) date_creation_rep,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               ppu.dt_last_update,
                                                               i_prof.institution,
                                                               i_prof.software) dt_creation,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, ppu.id_prof_last_update) prof_nick_name,
                                   decode(pk_prof_utils.get_prof_speciality(i_lang,
                                                                            profissional(ppu.id_prof_last_update,
                                                                                         i_prof.institution,
                                                                                         i_prof.software)),
                                          NULL,
                                          NULL,
                                          g_open_parentheses ||
                                          pk_prof_utils.get_prof_speciality(i_lang,
                                                                            profissional(ppu.id_prof_last_update,
                                                                                         i_prof.institution,
                                                                                         i_prof.software)) ||
                                          g_close_parentheses) desc_specialty,
                                   decode(i_episode, ppu.id_episode, NULL, l_documented) msg_previous_episode,
                                   pk_translation.get_translation(i_lang, pu.code_prob_unaware) title,
                                   CASE
                                        WHEN ppu.flg_status IN (g_status_ppu_active, g_status_ppu_outdated) THEN
                                         l_notes_label
                                        WHEN ppu.flg_status = g_status_ppu_cancel THEN
                                         l_cancel_notes_label
                                        ELSE
                                         NULL
                                    END msg_notes,
                                   CASE
                                        WHEN ppu.flg_status IN (g_status_ppu_active, g_status_ppu_outdated) THEN
                                         ppu.notes
                                        WHEN ppu.flg_status = g_status_ppu_cancel THEN
                                         ppu.cancel_notes
                                        ELSE
                                         NULL
                                    END notes,
                                   l_cancel_reason_label msg_cancel_reason,
                                   ppu.id_cancel_reason id_cancel_reason,
                                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason_desc,
                                   decode(i_episode, ppu.id_episode, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_previous_episode
                              FROM pat_prob_unaware ppu
                              LEFT JOIN prob_unaware pu
                                ON pu.id_prob_unaware = ppu.id_prob_unaware
                              LEFT JOIN cancel_reason cr
                                ON cr.id_cancel_reason = ppu.id_cancel_reason
                             WHERE ppu.id_patient = i_patient
                               AND ppu.flg_status IN (g_status_ppu_cancel)
                             ORDER BY date_creation_rep DESC)
                     WHERE rownum = 1)
             ORDER BY date_creation_rep DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_prob_unaware_outdated);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_prob_unaware_outdated;

    FUNCTION get_pat_problem_new
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE DEFAULT NULL,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT NOCOPY pat_problem_cur,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status table_varchar := table_varchar();
    
    BEGIN
    
        IF i_status IS NOT NULL
        THEN
            l_status.extend(1);
            l_status(1) := i_status;
        END IF;
    
        OPEN o_pat_problem FOR
            SELECT *
              FROM TABLE(get_pat_problem_tf(i_lang,
                                            i_prof,
                                            i_pat,
                                            l_status,
                                            i_type,
                                            i_problem,
                                            i_episode,
                                            i_report,
                                            NULL,
                                            NULL));
    
        IF NOT get_pat_prob_unaware_active(i_lang                    => i_lang,
                                           i_prof                    => i_prof,
                                           i_patient                 => i_pat,
                                           i_episode                 => i_episode,
                                           o_pat_prob_unaware_active => o_pat_prob_unaware_active,
                                           o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT get_pat_prob_unaware_outdated(i_lang                      => i_lang,
                                             i_prof                      => i_prof,
                                             i_patient                   => i_pat,
                                             i_episode                   => i_episode,
                                             o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                             o_error                     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_NEW');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_pat_problem);
                pk_types.open_my_cursor(o_pat_prob_unaware_active);
                pk_types.open_my_cursor(o_pat_prob_unaware_outdated);
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_problem_det_new
    (
        i_lang     IN language.id_language%TYPE,
        i_pat_prob IN pat_problem.id_pat_problem%TYPE,
        i_type     IN VARCHAR2,
        i_prof     IN profissional,
        o_problem  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_label_onset                sys_message.desc_message%TYPE;
        l_label_status               sys_message.desc_message%TYPE;
        l_label_nature               sys_message.desc_message%TYPE;
        l_label_type                 sys_message.desc_message%TYPE;
        l_label_notes                sys_message.desc_message%TYPE;
        l_label_edited               sys_message.desc_message%TYPE;
        l_label_created              sys_message.desc_message%TYPE;
        l_label_problem_cancellation sys_message.desc_message%TYPE;
        l_label_cancellation_reason  sys_message.desc_message%TYPE;
        l_label_cancellation_notes   sys_message.desc_message%TYPE;
        l_label_cancelled            sys_message.desc_message%TYPE;
        l_fst_dt_order               VARCHAR2(200);
        l_detail_common_m004         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'DETAIL_COMMON_M004');
        l_detail_common_m005         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'DETAIL_COMMON_M005');
        l_pat_prob                   table_number := table_number();
    BEGIN
        l_label_onset                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T006');
        l_label_status               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T003');
        l_label_nature               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T004');
        l_label_type                 := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T008');
        l_label_notes                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T009');
        l_label_edited               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T023');
        l_label_created              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T024');
        l_label_problem_cancellation := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T025');
        l_label_cancellation_reason  := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T026');
        l_label_cancellation_notes   := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T027');
        l_label_cancelled            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T028');
        --get problem first record date (oldest)
    
        l_pat_prob := pk_problems.get_phd_ids(i_pat_prob);
    
        SELECT MIN(dt_order)
          INTO l_fst_dt_order
          FROM (
                ----------------
                -- relevant diseases and problems
                ----------------          
                SELECT phd.dt_pat_history_diagnosis_tstz dt_order
                  FROM pat_history_diagnosis phd
                 WHERE 'D' = i_type
                   AND phd.id_pat_history_diagnosis IN
                       (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                         column_value
                          FROM TABLE(CAST(l_pat_prob AS table_number)) d)
                UNION ALL
                ----------------
                -- habits and diagnosis
                ----------------
                SELECT pp1.dt_pat_problem_tstz dt_order
                  FROM pat_problem pp1
                 WHERE pp1.id_pat_problem = i_pat_prob
                   AND 'P' = i_type
                UNION ALL
                SELECT pp1.dt_pat_problem_tstz dt_order
                  FROM pat_problem_hist pp1
                 WHERE pp1.id_pat_problem = i_pat_prob
                   AND 'P' = i_type
                UNION ALL
                ----------------
                -- alergies
                ----------------            
                SELECT pa.dt_pat_allergy_tstz dt_order
                  FROM pat_allergy pa
                 WHERE pa.id_pat_allergy = i_pat_prob
                   AND 'A' = i_type
                UNION ALL
                SELECT pa.dt_pat_allergy_tstz dt_order
                  FROM pat_allergy_hist pa
                 WHERE pa.id_pat_allergy = i_pat_prob
                   AND 'A' = i_type);
    
        g_error := 'OPEN O_PROBLEM';
        OPEN o_problem FOR
        ----------------
        -- relevant diseases and problems
        ----------------
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_order,
                   phd.dt_pat_history_diagnosis_tstz dt_order_tstz,
                   decode(phd.flg_status, g_cancelled, NULL, phd.notes) notes,
                   phd.flg_status,
                   pk_date_utils.date_char_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_pat_problem,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    phd.id_professional,
                                                    phd.dt_pat_history_diagnosis_tstz,
                                                    phd.id_episode) desc_speciality,
                   l_label_onset label_onset,
                   l_label_status label_status,
                   l_label_nature label_nature,
                   l_label_type label_type,
                   l_label_notes label_notes,
                   decode(phd.flg_status,
                          g_pat_probl_cancel,
                          l_label_cancelled,
                          decode(phd.dt_pat_history_diagnosis_tstz, l_fst_dt_order, l_label_created, l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(phd.id_professional, phd.id_institution, NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof) dt_problem,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_diagnosed,
                                                           i_precision => phd.dt_diagnosed_precision) dt_problem_to_print,
                   l_label_problem_cancellation label_prob_cancel,
                   l_label_cancellation_reason label_cancel_reason,
                   l_label_cancellation_notes label_cancel_notes,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || phd.id_cancel_reason) cancel_reason,
                   decode(phd.flg_status, g_cancelled, phd.cancel_notes, NULL) cancel_notes,
                   g_flg_hist_y flg_hist,
                   'N' flg_review,
                   NULL desc_review
              FROM pat_history_diagnosis phd
             WHERE 'D' = i_type
               AND phd.id_pat_history_diagnosis IN
                   (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                     column_value
                      FROM TABLE(CAST(l_pat_prob AS table_number)) d)
            UNION ALL
            ----------------
            -- habits and diagnosis
            ----------------
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pp1.id_professional_ins) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof) dt_order,
                   pp1.dt_pat_problem_tstz dt_order_tstz,
                   pp1.notes,
                   pp1.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_pat_problem,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp1.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp1.flg_nature, i_lang) desc_nature,
                   
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pp1.id_professional_ins,
                                                    pp1.dt_pat_problem_tstz,
                                                    pp1.id_episode) desc_speciality,
                   l_label_onset label_onset,
                   l_label_status label_status,
                   l_label_nature label_nature,
                   l_label_type label_type,
                   l_label_notes label_notes,
                   decode(pp1.flg_status,
                          g_pat_habit_canc,
                          l_label_cancelled,
                          decode(pp1.dt_pat_problem_tstz, l_fst_dt_order, l_label_created, l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(pp1.id_professional_ins,
                                                                         pp1.id_institution,
                                                                         NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   NULL dt_problem,
                   get_dt_str(i_lang, i_prof, pp1.year_begin, pp1.month_begin, pp1.day_begin) dt_problem_to_print,
                   l_label_problem_cancellation label_prob_cancel,
                   l_label_cancellation_reason label_cancel_reason,
                   l_label_cancellation_notes label_cancel_notes,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || pp1.id_cancel_reason) cancel_reason,
                   pp1.cancel_notes cancel_notes,
                   g_flg_hist_n flg_hist,
                   'N' flg_review,
                   NULL desc_review
              FROM pat_problem pp1
             WHERE pp1.id_pat_problem = i_pat_prob
               AND 'P' = i_type
            UNION ALL
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pp1.id_professional_ins) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof) dt_order,
                   pp1.dt_pat_problem_tstz dt_order_tstz,
                   pp1.notes,
                   pp1.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_pat_problem,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp1.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp1.flg_nature, i_lang) desc_nature,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pp1.id_professional_ins,
                                                    pp1.dt_pat_problem_tstz,
                                                    pp1.id_episode) desc_speciality,
                   l_label_onset label_onset,
                   l_label_status label_status,
                   l_label_nature label_nature,
                   l_label_type label_type,
                   l_label_notes label_notes,
                   decode(pp1.flg_status,
                          g_pat_habit_canc,
                          l_label_cancelled,
                          decode(pp1.dt_pat_problem_tstz, l_fst_dt_order, l_label_created, l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(pp1.id_professional_ins,
                                                                         pp1.id_institution,
                                                                         NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   NULL dt_problem,
                   get_dt_str(i_lang, i_prof, pp1.year_begin, pp1.month_begin, pp1.day_begin) dt_problem_to_print,
                   l_label_problem_cancellation label_prob_cancel,
                   l_label_cancellation_reason label_cancel_reason,
                   l_label_cancellation_notes label_cancel_notes,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || pp1.id_cancel_reason) cancel_reason,
                   pp1.cancel_notes cancel_notes,
                   g_flg_hist_y flg_hist,
                   'N' flg_review,
                   NULL desc_review
              FROM pat_problem_hist pp1
             WHERE pp1.id_pat_problem = i_pat_prob
               AND 'P' = i_type
            UNION ALL
            ----------------
            -- alergies
            ----------------
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   pa.dt_pat_allergy_tstz dt_order_tstz,
                   pa.notes,
                   pa.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pa.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pa.flg_nature, i_lang) desc_nature,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pa.id_prof_write,
                                                    pa.dt_pat_allergy_tstz,
                                                    pa.id_episode) desc_speciality,
                   l_label_onset label_onset,
                   l_label_status label_status,
                   l_label_nature label_nature,
                   l_label_type label_type,
                   l_label_notes label_notes,
                   decode(pa.flg_status,
                          g_pat_allergy_cancel,
                          l_label_cancelled,
                          decode(pa.dt_pat_allergy_tstz, l_fst_dt_order, l_label_created, l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(pa.id_prof_write, pa.id_institution, NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   to_char(pa.year_begin) dt_problem,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) dt_problem_to_print,
                   l_label_problem_cancellation label_prob_cancel,
                   l_label_cancellation_reason label_cancel_reason,
                   l_label_cancellation_notes label_cancel_notes,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || pa.id_cancel_reason) cancel_reason,
                   pa.cancel_notes cancel_notes,
                   g_flg_hist_n flg_hist,
                   'N' flg_review,
                   NULL desc_review
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_pat_prob
               AND 'A' = i_type
            UNION ALL
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   pa.dt_pat_allergy_tstz dt_order_tstz,
                   pa.notes,
                   pa.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pa.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pa.flg_nature, i_lang) desc_nature,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pa.id_prof_write,
                                                    pa.dt_pat_allergy_tstz,
                                                    pa.id_episode) desc_speciality,
                   l_label_onset label_onset,
                   l_label_status label_status,
                   l_label_nature label_nature,
                   l_label_type label_type,
                   l_label_notes label_notes,
                   decode(pa.flg_status,
                          g_pat_allergy_cancel,
                          l_label_cancelled,
                          decode(pa.dt_pat_allergy_tstz, l_fst_dt_order, l_label_created, l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(pa.id_prof_write, pa.id_institution, NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   to_char(pa.year_begin) dt_problem,
                   get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin) dt_problem_to_print,
                   l_label_problem_cancellation label_prob_cancel,
                   l_label_cancellation_reason label_cancel_reason,
                   l_label_cancellation_notes label_cancel_notes,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || pa.id_cancel_reason) cancel_reason,
                   pa.cancel_notes cancel_notes,
                   g_flg_hist_y flg_hist,
                   'N' flg_review,
                   NULL desc_review
              FROM pat_allergy_hist pa
             WHERE pa.id_pat_allergy = i_pat_prob
               AND 'A' = i_type
            UNION ALL
            ----------------
            -- reviews
            ----------------
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, r.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, r.dt_review, i_prof) dt_order,
                   r.dt_review dt_order_tstz,
                   r.review_notes,
                   NULL flg_status,
                   pk_date_utils.date_char_tsz(i_lang, r.dt_review, i_prof.institution, i_prof.software) dt_review,
                   NULL desc_status,
                   NULL desc_nature,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, r.id_professional, r.dt_review, NULL) desc_speciality,
                   NULL label_onset,
                   NULL label_status,
                   NULL label_nature,
                   NULL label_type,
                   l_label_notes label_notes,
                   l_detail_common_m004 desc_edit,
                   NULL dt_problem,
                   NULL dt_problem_to_print,
                   NULL label_prob_cancel,
                   NULL label_cancel_reason,
                   NULL label_cancel_notes,
                   NULL cancel_reason,
                   NULL cancel_notes,
                   NULL flg_hist,
                   'Y' flg_review,
                   l_detail_common_m005 desc_review
              FROM review_detail r
             INNER JOIN (
                         --reviews from relevant diseases and problems and diagnosis
                         SELECT phd.id_pat_history_diagnosis AS id_problem,
                                 phd.id_episode,
                                 pk_review.get_problems_context() AS flg_context
                           FROM pat_history_diagnosis phd
                          WHERE phd.id_pat_history_diagnosis IN
                                (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                  column_value
                                   FROM TABLE(CAST(l_pat_prob AS table_number)) d)
                         UNION ALL
                         SELECT phd.id_pat_history_diagnosis AS id_problem,
                                 phd.id_episode id_episode,
                                 pk_review.get_past_history_context() AS flg_context
                           FROM pat_history_diagnosis phd
                          WHERE phd.id_pat_history_diagnosis IN
                                (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                  column_value
                                   FROM TABLE(CAST(l_pat_prob AS table_number)) d)
                         UNION ALL
                         SELECT pp.id_pat_problem AS id_problem,
                                 pp.id_episode,
                                 pk_review.get_problems_context() AS flg_context
                           FROM pat_problem pp
                          WHERE pp.id_pat_problem = i_pat_prob
                         UNION ALL
                         --reviews for habits
                         SELECT pp.id_pat_habit AS id_problem,
                                 pp.id_episode,
                                 pk_review.get_habits_context() AS flg_context
                           FROM pat_problem pp
                          WHERE pp.id_pat_problem = i_pat_prob
                         UNION ALL
                         --reviews for allergies
                         SELECT pa.id_pat_allergy AS id_problem,
                                 pa.id_episode,
                                 pk_review.get_allergies_context() AS flg_context
                           FROM pat_allergy pa
                          WHERE pa.id_pat_allergy = i_pat_prob) prob
                ON r.id_record_area = prob.id_problem
               AND r.flg_context = prob.flg_context
             WHERE nvl(r.flg_auto, pk_alert_constant.g_no) = pk_alert_constant.g_no
             ORDER BY dt_order_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_NEW');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_problem_det_new_aux
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_label_onset               sys_message.desc_message%TYPE;
        l_label_onset_habits        sys_message.desc_message%TYPE;
        l_label_status              sys_message.desc_message%TYPE;
        l_label_location            sys_message.desc_message%TYPE;
        l_label_nature              sys_message.desc_message%TYPE;
        l_label_type                sys_message.desc_message%TYPE;
        l_label_notes               sys_message.desc_message%TYPE;
        l_label_cancellation_reason sys_message.desc_message%TYPE;
        l_label_cancellation_notes  sys_message.desc_message%TYPE;
        l_label_registered          sys_message.desc_message%TYPE;
        l_label_precaution          sys_message.desc_message%TYPE;
        l_label_header              sys_message.desc_message%TYPE;
        l_label_specialty           sys_message.desc_message%TYPE;
        l_label_resolution_date     sys_message.desc_message%TYPE;
        l_label_problem             sys_message.desc_message%TYPE;
        l_label_registered_review   sys_message.desc_message%TYPE;
        l_label_review_notes        sys_message.desc_message%TYPE;
        l_problem_list_t069         sys_message.desc_message%TYPE;
        l_label_complications       sys_message.desc_message%TYPE;
        l_label_cancel_date         sys_message.desc_message%TYPE;
        l_label_cancel_prof         sys_message.desc_message%TYPE;
        l_record_origin             sys_message.desc_message%TYPE;
        l_label_problem_group       sys_message.desc_message%TYPE;
    
        l_type_bold         VARCHAR2(1 CHAR);
        l_type_italic       VARCHAR2(1 CHAR);
        l_registered_review VARCHAR2(200 CHAR);
        l_review_notes      review_detail.review_notes%TYPE;
        l_problems_m008     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M008');
        l_problems_m007     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M007');
        l_problems_m006     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M006');
        l_problems_m004     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M004');
        l_problems_m001     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M001');
    
    BEGIN
    
        l_label_onset               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T006');
        l_label_onset_habits        := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T084');
        l_label_status              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T003');
        l_label_location            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T099');
        l_label_nature              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T004');
        l_label_type                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T008');
        l_label_notes               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T009');
        l_label_cancellation_reason := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T026');
        l_label_cancellation_notes  := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T027');
        l_label_registered          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T046');
        l_label_precaution          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T047');
        l_label_header              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T037');
        l_label_specialty           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T032');
        l_label_resolution_date     := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T033');
        l_label_problem             := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T001');
        l_label_registered_review   := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T062');
        l_label_review_notes        := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T063');
        l_problem_list_t069         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069');
        l_label_complications       := pk_message.get_message(i_lang, i_prof, 'COMPLICATION_MSG001');
        l_label_cancel_date         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T095');
        l_label_cancel_prof         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T094');
        l_record_origin             := pk_message.get_message(i_lang, i_prof, 'ALLERGY_M066');
        l_label_problem_group       := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T101');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
    
        -- get latest review for problem or past medical history 
        g_error := 'SELECT REVIEW FIELDS';
        IF i_type = g_type_d
        THEN
            BEGIN
            
                SELECT pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) ||
                       g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, NULL),
                           l_problem_list_t069) || ')' registered_review,
                       rd.review_notes review_notes
                  INTO l_registered_review, l_review_notes
                  FROM review_detail rd
                 WHERE rd.id_record_area = i_pat_prob
                   AND rd.flg_context IN (pk_review.get_problems_context(), pk_review.get_past_history_context())
                   AND dt_review =
                       (SELECT MAX(rd1.dt_review)
                          FROM review_detail rd1
                         WHERE rd1.id_record_area = i_pat_prob
                           AND rd1.flg_context IN
                               (pk_review.get_problems_context(), pk_review.get_past_history_context()));
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_registered_review := NULL;
                    l_review_notes      := NULL;
            END;
        END IF;
    
        -- get latest review for allergy
        IF i_type = g_type_a
        THEN
            BEGIN
                SELECT pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) ||
                       g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, NULL),
                           l_problem_list_t069) || ')' registered_review,
                       rd.review_notes review_notes
                  INTO l_registered_review, l_review_notes
                  FROM review_detail rd, pat_allergy pa
                 WHERE rd.id_record_area = i_pat_prob
                   AND pa.id_pat_allergy = rd.id_record_area
                   AND rd.flg_context = pk_review.get_allergies_context()
                   AND rd.dt_review = (SELECT MAX(rd1.dt_review)
                                         FROM review_detail rd1
                                        WHERE rd1.id_record_area = pa.id_pat_allergy
                                          AND rd.flg_context = pk_review.get_allergies_context());
            EXCEPTION
                WHEN OTHERS THEN
                    l_registered_review := NULL;
                    l_review_notes      := NULL;
            END;
        END IF;
    
        -- get latest review for diagnosis or habit
        IF i_type = g_type_p
        THEN
            BEGIN
                SELECT pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) ||
                       g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, NULL),
                           l_problem_list_t069) || ')' registered_review,
                       rd.review_notes review_notes
                  INTO l_registered_review, l_review_notes
                  FROM review_detail rd, pat_problem pp
                 WHERE rd.id_record_area = decode(pp.id_pat_habit, NULL, i_pat_prob, pp.id_pat_habit)
                   AND pp.id_pat_problem = i_pat_prob
                   AND rd.flg_context =
                       decode(pp.id_pat_habit, NULL, pk_review.get_problems_context(), pk_review.get_habits_context())
                   AND rd.dt_review =
                       (SELECT MAX(rd1.dt_review)
                          FROM review_detail rd1
                         WHERE rd1.id_record_area = decode(pp.id_pat_habit, NULL, i_pat_prob, pp.id_pat_habit)
                           AND rd1.flg_context = decode(pp.id_pat_habit,
                                                        NULL,
                                                        pk_review.get_problems_context(),
                                                        pk_review.get_habits_context()));
            EXCEPTION
                WHEN OTHERS THEN
                    l_registered_review := NULL;
                    l_review_notes      := NULL;
            END;
        END IF;
    
        g_error := 'OPEN O_PROBLEM';
        OPEN o_problem FOR
        ----------------
        -- relevant diseases and problems
        ----------------
            SELECT table_varchar(l_type_bold,
                                 l_label_problem,
                                 decode(phd.desc_pat_history_diagnosis,
                                        NULL,
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                   i_id_diagnosis       => d.id_diagnosis,
                                                                   i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                  i_flg_type => phd.flg_type),
                                                                   i_code               => d.code_icd,
                                                                   i_flg_other          => d.flg_other,
                                                                   i_flg_std_diag       => ad.flg_icd9),
                                        decode(phd.id_alert_diagnosis,
                                               NULL,
                                               phd.desc_pat_history_diagnosis,
                                               phd.desc_pat_history_diagnosis || ' - ' ||
                                               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                          i_prof               => i_prof,
                                                                          i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                          i_id_diagnosis       => d.id_diagnosis,
                                                                          i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                         i_flg_type => phd.flg_type),
                                                                          i_code               => d.code_icd,
                                                                          i_flg_other          => d.flg_other,
                                                                          i_flg_std_diag       => ad.flg_icd9)))) problem,
                   table_varchar(l_type_bold,
                                 l_label_precaution,
                                 pk_utils.concat_table(pk_problems.get_pat_precaution_list_desc(i_lang,
                                                                                                i_prof,
                                                                                                i_pat_prob),
                                                       ', ',
                                                       1,
                                                       -1)) precaution_measures,
                   table_varchar(l_type_bold,
                                 l_label_header,
                                 pk_sysdomain.get_domain(pk_list.g_yes_no, phd.flg_warning, i_lang)) header_warning,
                   
                   table_varchar(l_type_bold,
                                 l_label_type,
                                 get_problem_type_desc(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_flg_area           => phd.flg_area,
                                                       i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                       i_flg_type           => phd.flg_type)) type_prob,
                   table_varchar(l_type_bold,
                                 l_label_complications,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang)) flg_complications,
                   table_varchar(l_type_bold,
                                 l_label_onset,
                                 pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_date      => phd.dt_diagnosed,
                                                                         i_precision => phd.dt_diagnosed_precision)) onset,
                   table_varchar(l_type_bold,
                                 l_label_location,
                                 nvl2(phd.id_location,
                                      pk_diagnosis.std_diag_desc(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_diagnosis          => pk_diagnosis_core.get_term_diagnosis_id(phd.id_location,
                                                                                                                                    i_prof.institution,
                                                                                                                                    i_prof.software),
                                                                 i_id_alert_diagnosis    => phd.id_location,
                                                                 i_code                  => pk_diagnosis_core.get_term_diagnosis_code(phd.id_location,
                                                                                                                                      i_prof.institution,
                                                                                                                                      i_prof.software),
                                                                 i_flg_other             => pk_alert_constant.g_no,
                                                                 i_flg_std_diag          => pk_alert_constant.g_yes,
                                                                 i_epis_diag             => NULL,
                                                                 i_show_aditional_info   => pk_alert_constant.g_no,
                                                                 i_flg_show_ae_diag_info => pk_alert_constant.g_no),
                                      '')) desc_location,
                   table_varchar(l_type_bold,
                                 l_label_nature,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang)) nature,
                   table_varchar(l_type_bold,
                                 l_label_specialty,
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  phd.id_professional,
                                                                  phd.dt_pat_history_diagnosis_tstz,
                                                                  phd.id_episode)) specialty,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang)) status,
                   table_varchar(l_type_bold,
                                 l_label_resolution_date,
                                 pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_date      => phd.dt_resolved,
                                                                         i_precision => phd.dt_resolved_precision)) resolution_date,
                   table_varchar(l_type_bold, l_label_notes, phd.notes) notes,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_reason,
                                 pk_translation.get_translation(i_lang,
                                                                'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                phd.id_cancel_reason)) cancel_reason,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_notes,
                                 decode(phd.flg_status, g_cancelled, phd.cancel_notes, NULL)) cancel_notes,
                   table_varchar(l_type_bold,
                                 l_label_cancel_date,
                                 pk_date_utils.date_char_tsz(i_lang, phd.dt_cancel, i_prof.institution, i_prof.software)) date_cancel,
                   table_varchar(l_type_bold,
                                 l_label_cancel_prof,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_prof_cancel)) prof_cancel_desc,
                   table_varchar(l_type_bold, l_label_registered_review, l_registered_review) registered_review,
                   table_varchar(l_type_bold, l_label_review_notes, l_review_notes) review_notes,
                   table_varchar(l_type_bold,
                                 l_record_origin,
                                 decode(phd.flg_cda_reconciliation,
                                        pk_allergy.g_allergy_from_cda_recon,
                                        pk_message.get_message(i_lang      => i_lang,
                                                               i_code_mess => pk_allergy.g_allergy_desc_record_origin))) record_origin,
                   CASE
                        WHEN i_problem_view = pk_problems.g_problem_view_episode
                             AND pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof.institution, i_prof.software) =
                             pk_alert_constant.get_yes THEN
                         table_varchar(l_type_bold,
                                       l_label_problem_group,
                                       get_prob_group(ep.id_episode, ep.id_epis_prob_group))
                        ELSE
                         NULL
                    END id_group,
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             phd.dt_pat_history_diagnosis_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) || g_semicolon ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      phd.id_professional,
                                                                      phd.dt_pat_history_diagnosis_tstz,
                                                                      phd.id_episode),
                                     l_problem_list_t069) || ')') registered
              FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d, epis_prob ep
             WHERE phd.id_pat_history_diagnosis = i_pat_prob
               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_episode = ep.id_episode(+)
               AND phd.id_pat_history_diagnosis = ep.id_problem(+)
               AND (ep.flg_type IS NULL OR (ep.flg_type IS NOT NULL AND ep.flg_type = g_type_d))
               AND g_type_d = i_type
            
            UNION ALL
            ----------------
            -- habits and diagnosis
            ----------------
            SELECT table_varchar(l_type_bold,
                                 l_label_problem,
                                 decode(pp1.desc_pat_problem,
                                        '',
                                        decode(pp1.id_habit,
                                               '',
                                               decode(nvl(ed.id_epis_diagnosis, 0),
                                                      0,
                                                      pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                 i_prof               => i_prof,
                                                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                                 i_id_diagnosis       => d.id_diagnosis,
                                                                                 i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                                 i_code               => d.code_icd,
                                                                                 i_flg_other          => d.flg_other,
                                                                                 i_flg_std_diag       => ad.flg_icd9),
                                                      pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                                 i_prof                => i_prof,
                                                                                 i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                                 i_id_diagnosis        => d1.id_diagnosis,
                                                                                 i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                                 i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                                 i_code                => d1.code_icd,
                                                                                 i_flg_other           => d1.flg_other,
                                                                                 i_flg_std_diag        => ad1.flg_icd9,
                                                                                 i_epis_diag           => ed.id_epis_diagnosis)),
                                               pk_translation.get_translation(i_lang, h.code_habit)),
                                        pp1.desc_pat_problem)) problem,
                   table_varchar(l_type_bold, l_label_precaution, NULL) precaution_measures,
                   table_varchar(l_type_bold, l_label_header, NULL) header_warning,
                   table_varchar(l_type_bold,
                                 l_label_type,
                                 decode(pp1.desc_pat_problem,
                                        '',
                                        decode(pp1.id_habit,
                                               '',
                                               decode(nvl(ed.id_epis_diagnosis, 0),
                                                      0,
                                                      l_problems_m004,
                                                      decode(ed.flg_type,
                                                             g_epis_diag_passive,
                                                             l_problems_m008,
                                                             l_problems_m007)),
                                               l_problems_m006),
                                        decode(pp1.id_diagnosis, NULL, l_problems_m001, l_problems_m004))) type_prob,
                   table_varchar(l_type_bold,
                                 decode(pp1.id_habit, '', l_label_onset, l_label_onset_habits),
                                 get_dt_str(i_lang, i_prof, pp1.year_begin, pp1.month_begin, pp1.day_begin)) onset,
                   table_varchar(l_type_bold, l_label_location, NULL) desc_location,
                   table_varchar(l_type_bold,
                                 l_label_nature,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp1.flg_nature, i_lang)) nature,
                   table_varchar(l_type_bold,
                                 l_label_specialty,
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  pp1.id_professional_ins,
                                                                  pp1.dt_pat_problem_tstz,
                                                                  pp1.id_episode)) specialty,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp1.flg_status, i_lang)) status,
                   table_varchar(l_type_bold, l_label_resolution_date, get_dt_str(i_lang, i_prof, pp1.dt_resolution)) resolution_date,
                   table_varchar(l_type_bold, l_label_notes, pp1.notes) notes,
                   table_varchar(l_type_bold, l_label_registered_review, l_registered_review) registered_review,
                   table_varchar(l_type_bold, l_label_review_notes, l_review_notes) review_notes,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_reason,
                                 pk_translation.get_translation(i_lang,
                                                                'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                pp1.id_cancel_reason)) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancellation_notes, pp1.cancel_notes) cancel_notes,
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             pp1.dt_pat_problem_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) || g_semicolon ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, pp1.id_professional_ins) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      pp1.id_professional_ins,
                                                                      pp1.dt_pat_problem_tstz,
                                                                      pp1.id_episode),
                                     l_problem_list_t069) || ')') registered,
                   NULL flg_complications,
                   table_varchar(l_type_bold,
                                 l_label_cancel_date,
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             ed.dt_cancel_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)) date_cancel,
                   table_varchar(l_type_bold,
                                 l_label_cancel_prof,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional_cancel)) prof_cancel_desc,
                   NULL id_group,
                   NULL record_origin
              FROM pat_problem     pp1,
                   epis_diagnosis  ed,
                   habit           h,
                   alert_diagnosis ad1,
                   diagnosis       d1,
                   alert_diagnosis ad,
                   diagnosis       d
             WHERE pp1.id_pat_problem = i_pat_prob
               AND ed.id_epis_diagnosis(+) = pp1.id_epis_diagnosis
               AND pp1.id_habit = h.id_habit(+)
               AND ed.id_alert_diagnosis = ad1.id_alert_diagnosis(+)
               AND ed.id_diagnosis = d1.id_diagnosis(+)
               AND pp1.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pp1.id_diagnosis = d.id_diagnosis(+)
               AND g_type_p = i_type
            
            UNION ALL
            ----------------
            -- alergies
            ----------------
            SELECT table_varchar(l_type_bold,
                                 l_label_problem,
                                 nvl2(pa.id_allergy,
                                      pk_translation.get_translation(i_lang, a.code_allergy),
                                      pa.desc_allergy)) problem,
                   
                   table_varchar(l_type_bold, l_label_precaution, NULL) precaution_measures,
                   table_varchar(l_type_bold, l_label_header, NULL) header_warning,
                   table_varchar(l_type_bold,
                                 l_label_type,
                                 pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang)) type_prob,
                   table_varchar(l_type_bold,
                                 l_label_onset,
                                 get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin)) onset,
                   table_varchar(l_type_bold, l_label_location, NULL) desc_location,
                   table_varchar(l_type_bold,
                                 l_label_nature,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pa.flg_nature, i_lang)) nature,
                   table_varchar(l_type_bold,
                                 l_label_specialty,
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  pa.id_prof_write,
                                                                  pa.dt_pat_allergy_tstz,
                                                                  pa.id_episode)) specialty,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pa.flg_status, i_lang)) status,
                   table_varchar(l_type_bold, l_label_resolution_date, get_dt_str(i_lang, i_prof, pa.dt_resolution)) resolution_date,
                   table_varchar(l_type_bold, l_label_notes, pa.notes) notes,
                   table_varchar(l_type_bold, l_label_registered_review, l_registered_review) registered_review,
                   table_varchar(l_type_bold, l_label_review_notes, l_review_notes) review_notes,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_reason,
                                 pk_translation.get_translation(i_lang,
                                                                'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                pa.id_cancel_reason)) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancellation_notes, pa.cancel_notes) cancel_notes,
                   table_varchar(l_type_bold,
                                 l_record_origin,
                                 decode(pa.id_cancel_reason,
                                        NULL,
                                        decode(pa.flg_cda_reconciliation,
                                               pk_allergy.g_allergy_from_cda_recon,
                                               pk_message.get_message(i_lang      => i_lang,
                                                                      i_code_mess => pk_allergy.g_allergy_desc_record_origin),
                                               NULL),
                                        NULL)) record_origin,
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             pa.dt_pat_allergy_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) || g_semicolon ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      pa.id_prof_write,
                                                                      pa.dt_pat_allergy_tstz,
                                                                      pa.id_episode),
                                     l_problem_list_t069) || ')') registered,
                   NULL flg_complications,
                   table_varchar() date_cancel,
                   NULL id_group,
                   table_varchar() prof_cancel_desc
              FROM pat_allergy pa, allergy a
             WHERE pa.id_pat_allergy = i_pat_prob
               AND a.id_allergy(+) = pa.id_allergy
               AND g_type_a = i_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_NEW_AUX');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_problem_det_new_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2 DEFAULT g_problem_view_patient,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- problem or past medical history 
        IF i_type = g_type_d
        THEN
            g_error := 'CALL get_pat_problem_det_new_hist_d';
            IF NOT get_pat_problem_det_new_hist_d(i_lang         => i_lang,
                                                  i_pat_prob     => i_pat_prob,
                                                  i_type         => i_type,
                                                  i_prof         => i_prof,
                                                  i_problem_view => i_problem_view,
                                                  o_problem      => o_problem,
                                                  o_problem_hist => o_problem_hist,
                                                  o_review_hist  => o_review_hist,
                                                  o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- allergy
        IF i_type = g_type_a
        THEN
            g_error := 'CALL get_pat_problem_det_new_hist_a';
            IF NOT get_pat_problem_det_new_hist_a(i_lang         => i_lang,
                                                  i_pat_prob     => i_pat_prob,
                                                  i_type         => i_type,
                                                  i_prof         => i_prof,
                                                  o_problem      => o_problem,
                                                  o_problem_hist => o_problem_hist,
                                                  o_review_hist  => o_review_hist,
                                                  o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- diagnosis or habit
        IF i_type = g_type_p
        THEN
            g_error := 'CALL get_pat_problem_det_new_hist_p';
            IF NOT get_pat_problem_det_new_hist_p(i_lang         => i_lang,
                                                  i_pat_prob     => i_pat_prob,
                                                  i_type         => i_type,
                                                  i_prof         => i_prof,
                                                  o_problem      => o_problem,
                                                  o_problem_hist => o_problem_hist,
                                                  o_review_hist  => o_review_hist,
                                                  o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_NEW_HIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_problem);
                pk_types.open_my_cursor(o_review_hist);
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_problem_det_new_hist_d
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        problem_dif_table_rec       problem_dif_table;
        problem_record              problem_type;
        problem_record_previous     problem_type;
        problem_record_first        problem_type;
        i                           NUMBER := 0;
        first_rec                   NUMBER := 0;
        l_label_onset               sys_message.desc_message%TYPE;
        l_label_status              sys_message.desc_message%TYPE;
        l_label_location            sys_message.desc_message%TYPE;
        l_label_nature              sys_message.desc_message%TYPE;
        l_label_type                sys_message.desc_message%TYPE;
        l_label_notes               sys_message.desc_message%TYPE;
        l_label_cancellation_reason sys_message.desc_message%TYPE;
        l_label_cancellation_notes  sys_message.desc_message%TYPE;
        l_label_precaution          sys_message.desc_message%TYPE;
        l_label_header              sys_message.desc_message%TYPE;
        l_label_specialty           sys_message.desc_message%TYPE;
        l_label_resolution_date     sys_message.desc_message%TYPE;
        l_label_problem             sys_message.desc_message%TYPE;
    
        l_label_onset_hist           sys_message.desc_message%TYPE;
        l_label_status_hist          sys_message.desc_message%TYPE;
        l_label_location_hist        sys_message.desc_message%TYPE;
        l_label_nature_hist          sys_message.desc_message%TYPE;
        l_label_type_hist            sys_message.desc_message%TYPE;
        l_label_notes_hist           sys_message.desc_message%TYPE;
        l_label_precaution_hist      sys_message.desc_message%TYPE;
        l_label_header_hist          sys_message.desc_message%TYPE;
        l_label_specialty_hist       sys_message.desc_message%TYPE;
        l_label_resolution_date_hist sys_message.desc_message%TYPE;
        l_label_problem_hist         sys_message.desc_message%TYPE;
        l_label_registered_review    sys_message.desc_message%TYPE;
        l_label_review_notes         sys_message.desc_message%TYPE;
        l_problem_list_t069          sys_message.desc_message%TYPE;
        l_label_cancel_date          sys_message.desc_message%TYPE;
        l_label_cancel_prof          sys_message.desc_message%TYPE;
        l_record_origin              sys_message.desc_message%TYPE;
        l_label_complications        sys_message.desc_message%TYPE;
        l_label_complications_hist   sys_message.desc_message%TYPE;
    
        l_label_registered sys_message.desc_message%TYPE;
        l_na               sys_message.desc_message%TYPE;
        l_label_group      sys_message.desc_message%TYPE;
        l_label_group_hist sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR);
        l_type_red    VARCHAR2(1 CHAR);
        l_type_italic VARCHAR2(1 CHAR);
        sel_problem   pk_types.cursor_type;
    
        l_counter     NUMBER;
        l_flag_change NUMBER := 0;
        l_pat_prob    table_number := table_number();
    BEGIN
        l_pat_prob                   := pk_problems.get_phd_ids(i_pat_prob);
        l_problem_list_t069          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069');
        l_label_onset                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T006');
        l_label_status               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T003');
        l_label_location             := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T099');
        l_label_nature               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T004');
        l_label_type                 := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T008');
        l_label_notes                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T009');
        l_label_cancellation_reason  := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T026');
        l_label_cancellation_notes   := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T027');
        l_label_registered           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T046');
        l_label_precaution           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T047');
        l_label_header               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T037');
        l_label_specialty            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T032');
        l_label_resolution_date      := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T033');
        l_label_problem              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T001');
        l_label_onset_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T058');
        l_label_status_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T049');
        l_label_location_hist        := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T099');
        l_label_nature_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T059');
        l_label_type_hist            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T057');
        l_label_notes_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T056');
        l_label_precaution_hist      := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T048');
        l_label_header_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T050');
        l_label_specialty_hist       := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T052');
        l_label_resolution_date_hist := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T051');
        l_label_problem_hist         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T055');
        l_label_registered_review    := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T062');
        l_label_review_notes         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T063');
        l_label_cancel_date          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T095');
        l_label_cancel_prof          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T094');
        l_record_origin              := pk_message.get_message(i_lang, i_prof, 'ALLERGY_M066');
        l_label_complications_hist   := pk_message.get_message(i_lang, i_prof, 'COMPLICATION_MSG081');
        l_label_complications        := pk_message.get_message(i_lang, i_prof, 'COMPLICATION_MSG001');
        l_na                         := pk_message.get_message(i_lang, i_prof, 'N/A');
        l_label_group                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T101');
        l_label_group_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T108');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
        l_type_red    := 'R';
    
        -- query all records
        g_error := 'OPEN sel_problem';
        OPEN sel_problem FOR
            SELECT /*+ use_nl(phd,t,d,ad)*/
             nvl(decode(phd.desc_pat_history_diagnosis,
                        NULL,
                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                   i_id_diagnosis       => d.id_diagnosis,
                                                   i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                  i_flg_type => phd.flg_type),
                                                   i_code               => d.code_icd,
                                                   i_flg_other          => d.flg_other,
                                                   i_flg_std_diag       => ad.flg_icd9),
                        decode(phd.id_alert_diagnosis,
                               NULL,
                               phd.desc_pat_history_diagnosis,
                               phd.desc_pat_history_diagnosis || ' - ' ||
                               pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                          i_id_diagnosis       => d.id_diagnosis,
                                                          i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                         i_flg_type => phd.flg_type),
                                                          i_code               => d.code_icd,
                                                          i_flg_other          => d.flg_other,
                                                          i_flg_std_diag       => ad.flg_icd9))),
                 l_na) problem,
             
             nvl(pk_utils.concat_table(pk_problems.get_pat_precaution_list_desc(i_lang,
                                                                                i_prof,
                                                                                phd.id_pat_history_diagnosis),
                                       ', ',
                                       1,
                                       -1),
                 l_na) precaution_measures,
             nvl(pk_sysdomain.get_domain(pk_list.g_yes_no, phd.flg_warning, i_lang), l_na) header_warning,
             get_problem_type_desc(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_flg_area           => phd.flg_area,
                                   i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                   i_flg_type           => phd.flg_type) type_prob,
             nvl(pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_date      => phd.dt_diagnosed,
                                                         i_precision => phd.dt_diagnosed_precision),
                 l_na) onset,
             NULL id_habit,
             nvl2(phd.id_location,
                  pk_diagnosis.std_diag_desc(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             i_id_diagnosis          => pk_diagnosis_core.get_term_diagnosis_id(phd.id_location,
                                                                                                                i_prof.institution,
                                                                                                                i_prof.software),
                                             i_id_alert_diagnosis    => phd.id_location,
                                             i_code                  => pk_diagnosis_core.get_term_diagnosis_code(phd.id_location,
                                                                                                                  i_prof.institution,
                                                                                                                  i_prof.software),
                                             i_flg_other             => pk_alert_constant.g_no,
                                             i_flg_std_diag          => pk_alert_constant.g_yes,
                                             i_epis_diag             => NULL,
                                             i_show_aditional_info   => pk_alert_constant.g_no,
                                             i_flg_show_ae_diag_info => pk_alert_constant.g_no),
                  '') desc_location,
             nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang), l_na) nature,
             nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  phd.id_professional,
                                                  phd.dt_pat_history_diagnosis_tstz,
                                                  phd.id_episode),
                 l_na) specialty,
             nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang), l_na) status,
             nvl(pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_date      => phd.dt_resolved,
                                                         i_precision => phd.dt_resolved_precision),
                 l_na) resolution_date,
             phd.notes notes,
             nvl(pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || phd.id_cancel_reason),
                 l_na) cancel_reason,
             phd.cancel_notes cancel_notes,
             nvl(pk_date_utils.date_char_tsz(i_lang,
                                             phd.dt_pat_history_diagnosis_tstz,
                                             i_prof.institution,
                                             i_prof.software) || g_semicolon ||
                 pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) || ' (' ||
                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      phd.id_professional,
                                                      phd.dt_pat_history_diagnosis_tstz,
                                                      phd.id_episode),
                     l_problem_list_t069) || ')',
                 l_na) registered,
             to_char(phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDhh24miss') create_time,
             phd.id_prof_cancel cancel_prof,
             phd.dt_cancel cancel_date,
             decode(phd.flg_cda_reconciliation,
                    pk_allergy.g_allergy_from_cda_recon,
                    pk_message.get_message(i_lang => i_lang, i_code_mess => pk_allergy.g_allergy_desc_record_origin)) record_origin,
             pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) complications,
             CASE
                  WHEN i_problem_view = pk_problems.g_problem_view_episode
                       AND pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof.institution, i_prof.software) =
                       pk_alert_constant.get_yes THEN
                   get_prob_group(ep.id_episode, ep.id_epis_prob_group)
                  ELSE
                   NULL
              END id_group
              FROM pat_history_diagnosis phd,
                   alert_diagnosis ad,
                   diagnosis d,
                   (SELECT p.id_pat_history_diagnosis
                      FROM pat_history_diagnosis p
                     START WITH p.id_pat_history_diagnosis IN
                                (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                  column_value
                                   FROM TABLE(CAST(l_pat_prob AS table_number)) d)
                    CONNECT BY PRIOR p.id_pat_history_diagnosis = p.id_pat_history_diagnosis_new) t,
                   epis_prob ep
             WHERE phd.id_pat_history_diagnosis = t.id_pat_history_diagnosis
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_episode = ep.id_episode(+)
               AND phd.id_pat_history_diagnosis = ep.id_problem(+)
               AND (ep.flg_type IS NULL OR (ep.flg_type IS NOT NULL AND ep.flg_type = g_type_d))
               AND g_type_d = i_type
             ORDER BY create_time;
    
        -- find differences    
        g_error := 'LOOP sel_problem';
        LOOP
            FETCH sel_problem
                INTO problem_record;
            EXIT WHEN sel_problem%NOTFOUND;
        
            IF first_rec = 0
            THEN
                problem_record_first.precaution_measures := problem_record.precaution_measures;
                problem_record_first.header_warning      := problem_record.header_warning;
                problem_record_first.specialty           := problem_record.specialty;
                problem_record_first.resolution_date     := problem_record.resolution_date;
                problem_record_first.status              := problem_record.status;
                problem_record_first.location            := problem_record.location;
                problem_record_first.nature              := problem_record.nature;
                problem_record_first.onset               := problem_record.onset;
                problem_record_first.type_prob           := problem_record.type_prob;
                problem_record_first.problem             := problem_record.problem;
                problem_record_first.notes               := problem_record.notes;
                problem_record_first.cancel_notes        := problem_record.cancel_notes;
                problem_record_first.cancel_reason       := problem_record.cancel_reason;
                problem_record_first.registered          := problem_record.registered;
                problem_record_first.create_time         := problem_record.create_time;
                problem_record_first.cancel_prof         := problem_record.cancel_prof;
                problem_record_first.cancel_date         := problem_record.cancel_date;
                problem_record_first.record_origin       := problem_record.record_origin;
                problem_record_first.complications       := problem_record.complications;
                problem_record_first.id_group            := problem_record.id_group;
                first_rec                                := 1;
                i                                        := i + 1;
            ELSE
                l_flag_change := 0;
                IF problem_record_previous.precaution_measures <> problem_record.precaution_measures
                THEN
                    problem_dif_table_rec(i).precaution_measures_b := problem_record_previous.precaution_measures;
                    problem_dif_table_rec(i).precaution_measures_a := problem_record.precaution_measures;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.header_warning <> problem_record.header_warning
                THEN
                    problem_dif_table_rec(i).header_warning_b := problem_record_previous.header_warning;
                    problem_dif_table_rec(i).header_warning_a := problem_record.header_warning;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.specialty <> problem_record.specialty
                THEN
                    problem_dif_table_rec(i).specialty_b := problem_record_previous.specialty;
                    problem_dif_table_rec(i).specialty_a := problem_record.specialty;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.resolution_date <> problem_record.resolution_date
                THEN
                    problem_dif_table_rec(i).resolution_date_b := problem_record_previous.resolution_date;
                    problem_dif_table_rec(i).resolution_date_a := problem_record.resolution_date;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.status <> problem_record.status
                THEN
                    problem_dif_table_rec(i).status_b := problem_record_previous.status;
                    problem_dif_table_rec(i).status_a := problem_record.status;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.location <> problem_record.location
                THEN
                    problem_dif_table_rec(i).location_b := problem_record_previous.location;
                    problem_dif_table_rec(i).location_a := problem_record.location;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.nature <> problem_record.nature
                THEN
                    problem_dif_table_rec(i).nature_b := problem_record_previous.nature;
                    problem_dif_table_rec(i).nature_a := problem_record.nature;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.onset <> problem_record.onset
                THEN
                    problem_dif_table_rec(i).onset_b := problem_record_previous.onset;
                    problem_dif_table_rec(i).onset_a := problem_record.onset;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.type_prob <> problem_record.type_prob
                THEN
                    problem_dif_table_rec(i).type_prob_b := problem_record_previous.type_prob;
                    problem_dif_table_rec(i).type_prob_a := problem_record.type_prob;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.problem <> problem_record.problem
                THEN
                    problem_dif_table_rec(i).problem_b := problem_record_previous.problem;
                    problem_dif_table_rec(i).problem_a := problem_record.problem;
                    l_flag_change := 1;
                END IF;
            
                IF (problem_record_previous.notes <> problem_record.notes)
                   OR (problem_record_previous.notes IS NOT NULL AND problem_record.notes IS NULL)
                   OR (problem_record_previous.notes IS NULL AND problem_record.notes IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).notes_b := problem_record_previous.notes;
                    problem_dif_table_rec(i).notes_a := problem_record.notes;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_notes <> problem_record.cancel_notes
                   OR (problem_record_previous.cancel_notes IS NOT NULL AND problem_record.cancel_notes IS NULL)
                   OR (problem_record_previous.cancel_notes IS NULL AND problem_record.cancel_notes IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).cancel_notes_b := problem_record_previous.cancel_notes;
                    problem_dif_table_rec(i).cancel_notes_a := problem_record.cancel_notes;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_reason <> problem_record.cancel_reason
                   AND problem_record.cancel_date IS NOT NULL
                THEN
                    problem_dif_table_rec(i).cancel_reason_b := problem_record_previous.cancel_reason;
                    problem_dif_table_rec(i).cancel_reason_a := problem_record.cancel_reason;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_prof <> problem_record.cancel_prof
                   OR (problem_record_previous.cancel_prof IS NOT NULL AND problem_record.cancel_prof IS NULL)
                   OR (problem_record_previous.cancel_prof IS NULL AND problem_record.cancel_prof IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).cancel_prof_b := problem_record_previous.cancel_prof;
                    problem_dif_table_rec(i).cancel_prof_a := problem_record.cancel_prof;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_date <> problem_record.cancel_date
                   OR (problem_record_previous.cancel_date IS NOT NULL AND problem_record.cancel_date IS NULL)
                   OR (problem_record_previous.cancel_date IS NULL AND problem_record.cancel_date IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).cancel_date_b := problem_record_previous.cancel_date;
                    problem_dif_table_rec(i).cancel_date_a := problem_record.cancel_date;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.record_origin <> problem_record.record_origin
                   OR (problem_record_previous.record_origin IS NOT NULL AND problem_record.record_origin IS NULL)
                   OR (problem_record_previous.record_origin IS NULL AND problem_record.record_origin IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).record_origin_b := problem_record_previous.record_origin;
                    problem_dif_table_rec(i).record_origin_a := problem_record.record_origin;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.complications <> problem_record.complications
                   OR (problem_record_previous.complications IS NOT NULL AND problem_record.complications IS NULL)
                   OR (problem_record_previous.complications IS NULL AND problem_record.complications IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).complications_b := problem_record_previous.complications;
                    problem_dif_table_rec(i).complications_a := problem_record.complications;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.id_group <> problem_record.id_group
                   OR (problem_record_previous.id_group IS NOT NULL AND problem_record.id_group IS NULL)
                   OR (problem_record_previous.id_group IS NULL AND problem_record.id_group IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).id_group_b := problem_record_previous.id_group;
                    problem_dif_table_rec(i).id_group_a := problem_record.id_group;
                    l_flag_change := 1;
                END IF;
            
                IF l_flag_change = 1
                THEN
                    problem_dif_table_rec(i).registered_b := problem_record_previous.registered;
                    problem_dif_table_rec(i).registered_a := problem_record.registered;
                    problem_dif_table_rec(i).create_time := problem_record.create_time;
                    i := i + 1;
                END IF;
            
            END IF;
            problem_record_previous.precaution_measures := problem_record.precaution_measures;
            problem_record_previous.header_warning      := problem_record.header_warning;
            problem_record_previous.specialty           := problem_record.specialty;
            problem_record_previous.resolution_date     := problem_record.resolution_date;
            problem_record_previous.status              := problem_record.status;
            problem_record_previous.location            := problem_record.location;
            problem_record_previous.nature              := problem_record.nature;
            problem_record_previous.onset               := problem_record.onset;
            problem_record_previous.type_prob           := problem_record.type_prob;
            problem_record_previous.problem             := problem_record.problem;
            problem_record_previous.notes               := problem_record.notes;
            problem_record_previous.cancel_notes        := problem_record.cancel_notes;
            problem_record_previous.cancel_reason       := problem_record.cancel_reason;
            problem_record_previous.registered          := problem_record.registered;
            problem_record_previous.create_time         := problem_record.create_time;
            problem_record_previous.cancel_prof         := problem_record.cancel_prof;
            problem_record_previous.cancel_date         := problem_record.cancel_date;
            problem_record_previous.record_origin       := problem_record.record_origin;
            problem_record_previous.complications       := problem_record.complications;
            problem_record_previous.id_group            := problem_record.id_group;
        
        END LOOP;
    
        CLOSE sel_problem;
    
        -- build first history record = creation record
        g_error := 'OPEN o_problem';
        OPEN o_problem FOR
            SELECT table_varchar(l_type_bold, l_label_problem, problem_record_first.problem) problem,
                   table_varchar(l_type_bold,
                                 l_label_precaution,
                                 decode(problem_record_first.precaution_measures,
                                        l_na,
                                        NULL,
                                        problem_record_first.precaution_measures)) precaution_measures,
                   table_varchar(l_type_bold,
                                 l_label_header,
                                 decode(problem_record_first.header_warning,
                                        l_na,
                                        NULL,
                                        problem_record_first.header_warning)) header_warning,
                   table_varchar(l_type_bold,
                                 l_label_type,
                                 decode(problem_record_first.type_prob, l_na, NULL, problem_record_first.type_prob)) type_prob,
                   table_varchar(l_type_bold,
                                 l_label_onset,
                                 decode(problem_record_first.onset, l_na, NULL, problem_record_first.onset)) onset,
                   table_varchar(l_type_bold,
                                 l_label_location,
                                 decode(problem_record_first.location, l_na, NULL, problem_record_first.location)) location,
                   table_varchar(l_type_bold,
                                 l_label_nature,
                                 decode(problem_record_first.nature, l_na, NULL, problem_record_first.nature)) nature,
                   table_varchar(l_type_bold,
                                 l_label_specialty,
                                 decode(problem_record_first.specialty, l_na, NULL, problem_record_first.specialty)) specialty,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 decode(problem_record_first.status, l_na, NULL, problem_record_first.status)) status,
                   
                   table_varchar(l_type_bold,
                                 l_label_complications,
                                 decode(problem_record_first.complications,
                                        l_na,
                                        NULL,
                                        problem_record_first.complications)) complications,
                   
                   table_varchar(l_type_bold,
                                 l_label_resolution_date,
                                 decode(problem_record_first.resolution_date,
                                        l_na,
                                        NULL,
                                        problem_record_first.resolution_date)) resolution_date,
                   table_varchar(l_type_bold, l_label_notes, problem_record_first.notes) notes,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_reason,
                                 decode(problem_record_first.cancel_reason,
                                        l_na,
                                        NULL,
                                        problem_record_first.cancel_reason)) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancellation_notes, problem_record_first.cancel_notes) cancel_notes,
                   table_varchar(l_type_bold,
                                 l_record_origin,
                                 decode(problem_record_first.record_origin,
                                        l_na,
                                        NULL,
                                        problem_record_first.record_origin)) record_origin,
                   table_varchar(l_type_bold, l_label_group, problem_record_first.id_group) id_group,
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 decode(problem_record_first.registered, l_na, NULL, problem_record_first.registered)) registered,
                   table_varchar(l_type_bold,
                                 l_label_cancel_date,
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             problem_record_first.cancel_date,
                                                             i_prof.institution,
                                                             i_prof.software)) date_cancel,
                   table_varchar(l_type_bold,
                                 l_label_cancel_prof,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, problem_record_first.cancel_prof)) prof_cancel_desc
              FROM dual;
    
        -- build history review record
        g_error := 'open o_review_hist';
        OPEN o_review_hist FOR
            SELECT table_varchar(l_type_italic,
                                 l_label_registered_review,
                                 pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) ||
                                 g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      rd.id_professional,
                                                                      rd.dt_review,
                                                                      NULL),
                                     l_problem_list_t069) || ')',
                                 to_char(rd.dt_review, 'YYYYMMDDhh24miss')) registered_review,
                   table_varchar(l_type_bold, l_label_review_notes, rd.review_notes) review_notes
              FROM review_detail rd
             WHERE rd.id_record_area IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                          column_value
                                           FROM TABLE(CAST(l_pat_prob AS table_number)) d)
               AND rd.flg_context IN (pk_review.get_problems_context(), pk_review.get_past_history_context())
             ORDER BY rd.dt_review ASC;
    
        -- build before / after problem history information    
        g_error := 'build o_problem_hist';
        IF problem_dif_table_rec.count <> 0
        THEN
            o_problem_hist := table_table_varchar();
        END IF;
    
        FOR k IN 1 .. problem_dif_table_rec.count
        LOOP
            IF problem_dif_table_rec(k).problem_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_problem,
                                                               problem_dif_table_rec(k).problem_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_problem_hist,
                                                               problem_dif_table_rec(k).problem_a);
            END IF;
            IF problem_dif_table_rec(k).precaution_measures_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_precaution,
                                                               problem_dif_table_rec(k).precaution_measures_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_precaution_hist,
                                                               problem_dif_table_rec(k).precaution_measures_a);
            END IF;
        
            IF problem_dif_table_rec(k).header_warning_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_header,
                                                               problem_dif_table_rec(k).header_warning_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_header_hist,
                                                               problem_dif_table_rec(k).header_warning_a);
            END IF;
            IF problem_dif_table_rec(k).type_prob_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_type,
                                                               problem_dif_table_rec(k).type_prob_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_type_hist,
                                                               problem_dif_table_rec(k).type_prob_a);
            END IF;
            IF problem_dif_table_rec(k).onset_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_onset,
                                                               problem_dif_table_rec(k).onset_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_onset_hist,
                                                               problem_dif_table_rec(k).onset_a);
            END IF;
            IF problem_dif_table_rec(k).location_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_location,
                                                               problem_dif_table_rec(k).location_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_location_hist,
                                                               problem_dif_table_rec(k).location_a);
            END IF;
            IF problem_dif_table_rec(k).nature_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_nature,
                                                               problem_dif_table_rec(k).nature_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_nature_hist,
                                                               problem_dif_table_rec(k).nature_a);
            END IF;
            IF problem_dif_table_rec(k).specialty_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_specialty,
                                                               problem_dif_table_rec(k).specialty_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_specialty_hist,
                                                               problem_dif_table_rec(k).specialty_a);
            END IF;
            IF problem_dif_table_rec(k).status_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_status,
                                                               problem_dif_table_rec(k).status_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_status_hist,
                                                               problem_dif_table_rec(k).status_a);
            END IF;
        
            IF problem_dif_table_rec(k).complications_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_complications,
                                                               nvl(problem_dif_table_rec(k).complications_b, l_na));
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_complications_hist,
                                                               problem_dif_table_rec(k).complications_a);
            END IF;
            IF problem_dif_table_rec(k).resolution_date_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_resolution_date,
                                                               problem_dif_table_rec(k).resolution_date_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_resolution_date_hist,
                                                               problem_dif_table_rec(k).resolution_date_a);
            END IF;
            IF problem_dif_table_rec(k).notes_b IS NOT NULL
                OR problem_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_notes,
                                                               nvl(problem_dif_table_rec(k).notes_b, l_na));
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_notes_hist,
                                                               nvl(problem_dif_table_rec(k).notes_a, l_na));
            END IF;
            IF problem_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancellation_reason,
                                                               problem_dif_table_rec(k).cancel_reason_a);
            END IF;
            IF problem_dif_table_rec(k).cancel_prof_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancel_prof,
                                                               pk_prof_utils.get_name_signature(i_lang,
                                                                                                i_prof,
                                                                                                problem_dif_table_rec(k).cancel_prof_a));
            END IF;
            IF problem_dif_table_rec(k).cancel_date_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancel_date,
                                                               pk_date_utils.date_char_tsz(i_lang,
                                                                                           problem_dif_table_rec(k).cancel_date_a,
                                                                                           i_prof.institution,
                                                                                           i_prof.software));
            END IF;
            IF problem_dif_table_rec(k).cancel_notes_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancellation_notes,
                                                               nvl(problem_dif_table_rec(k).cancel_notes_a, l_na));
            END IF;
        
            IF problem_dif_table_rec(k).record_origin_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_record_origin,
                                                               nvl(problem_dif_table_rec(k).record_origin_a, l_na));
            END IF;
        
            IF problem_dif_table_rec(k).id_group_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_group,
                                                               problem_dif_table_rec(k).id_group_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_group_hist,
                                                               problem_dif_table_rec(k).id_group_a);
            END IF;
        
            l_counter := o_problem_hist.count;
            o_problem_hist.extend(1);
            o_problem_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                           l_label_registered,
                                                           problem_dif_table_rec(k).registered_a,
                                                           problem_dif_table_rec(k).create_time);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_NEW_HIST_D');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_problem);
                pk_types.open_my_cursor(o_review_hist);
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_problem_det_new_hist_a
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        problem_dif_table_rec       problem_dif_table;
        problem_record              problem_type;
        problem_record_previous     problem_type;
        problem_record_first        problem_type;
        i                           NUMBER := 0;
        first_rec                   NUMBER := 0;
        l_label_onset               sys_message.desc_message%TYPE;
        l_label_status              sys_message.desc_message%TYPE;
        l_label_nature              sys_message.desc_message%TYPE;
        l_label_type                sys_message.desc_message%TYPE;
        l_label_notes               sys_message.desc_message%TYPE;
        l_label_cancellation_reason sys_message.desc_message%TYPE;
        l_label_cancellation_notes  sys_message.desc_message%TYPE;
        l_label_precaution          sys_message.desc_message%TYPE;
        l_label_header              sys_message.desc_message%TYPE;
        l_label_specialty           sys_message.desc_message%TYPE;
        l_label_resolution_date     sys_message.desc_message%TYPE;
        l_label_problem             sys_message.desc_message%TYPE;
    
        l_label_onset_hist           sys_message.desc_message%TYPE;
        l_label_status_hist          sys_message.desc_message%TYPE;
        l_label_nature_hist          sys_message.desc_message%TYPE;
        l_label_type_hist            sys_message.desc_message%TYPE;
        l_label_notes_hist           sys_message.desc_message%TYPE;
        l_label_precaution_hist      sys_message.desc_message%TYPE;
        l_label_header_hist          sys_message.desc_message%TYPE;
        l_label_specialty_hist       sys_message.desc_message%TYPE;
        l_label_resolution_date_hist sys_message.desc_message%TYPE;
        l_label_problem_hist         sys_message.desc_message%TYPE;
        l_label_registered_review    sys_message.desc_message%TYPE;
        l_label_review_notes         sys_message.desc_message%TYPE;
        l_problem_list_t069          sys_message.desc_message%TYPE;
        l_record_origin              sys_message.desc_message%TYPE;
    
        l_label_registered sys_message.desc_message%TYPE;
        l_na               sys_message.desc_message%TYPE;
        l_type_bold        VARCHAR2(1 CHAR);
        l_type_red         VARCHAR2(1 CHAR);
        l_type_italic      VARCHAR2(1 CHAR);
        sel_problem        pk_types.cursor_type;
    
        l_flag_change NUMBER := 0;
    
        l_counter NUMBER;
    BEGIN
        l_problem_list_t069          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069');
        l_label_onset                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T006');
        l_label_status               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T003');
        l_label_nature               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T004');
        l_label_type                 := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T008');
        l_label_notes                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T009');
        l_label_cancellation_reason  := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T026');
        l_label_cancellation_notes   := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T027');
        l_label_registered           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T046');
        l_label_precaution           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T047');
        l_label_header               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T037');
        l_label_specialty            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T032');
        l_label_resolution_date      := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T033');
        l_label_problem              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T001');
        l_label_onset_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T058');
        l_label_status_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T049');
        l_label_nature_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T059');
        l_label_type_hist            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T057');
        l_label_notes_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T056');
        l_label_precaution_hist      := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T048');
        l_label_header_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T050');
        l_label_specialty_hist       := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T052');
        l_label_resolution_date_hist := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T051');
        l_label_problem_hist         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T055');
        l_label_registered_review    := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T062');
        l_label_review_notes         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T063');
        l_record_origin              := pk_message.get_message(i_lang, i_prof, 'ALLERGY_M066');
        l_na                         := pk_message.get_message(i_lang, i_prof, 'N/A');
        l_type_bold                  := 'B';
        l_type_italic                := 'N';
        l_type_red                   := 'R';
    
        -- query all records    
        g_error := 'OPEN sel_problem';
        OPEN sel_problem FOR
            SELECT nvl(nvl2(pa.id_allergy, pk_translation.get_translation(i_lang, a.code_allergy), pa.desc_allergy),
                       l_na) problem,
                   l_na precaution_measures,
                   l_na header_warning,
                   nvl(pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang), l_na) type_prob,
                   nvl(get_dt_str(i_lang, i_prof, pa.year_begin, pa.month_begin, pa.day_begin), l_na) onset,
                   NULL id_habit,
                   NULL location,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pa.flg_nature, i_lang), l_na) nature,
                   nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        pa.id_prof_write,
                                                        pa.dt_pat_allergy_tstz,
                                                        pa.id_episode),
                       l_na) specialty,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pa.flg_status, i_lang), l_na) status,
                   nvl(get_dt_str(i_lang, i_prof, pa.dt_resolution), l_na) resolution_date,
                   pa.notes notes,
                   nvl(pk_translation.get_translation(i_lang,
                                                      'CANCEL_REASON.CODE_CANCEL_REASON.' || pa.id_cancel_reason),
                       l_na) cancel_reason,
                   pa.cancel_notes cancel_notes,
                   nvl(pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) ||
                       g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, pa.id_prof_write) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pa.id_prof_write,
                                                            pa.dt_pat_allergy_tstz,
                                                            pa.id_episode),
                           l_problem_list_t069) || ')',
                       l_na) registered,
                   to_char(pa.dt_pat_allergy_tstz, 'YYYYMMDDhh24miss') create_time,
                   NULL cancel_prof,
                   NULL cancel_date,
                   decode(pa.flg_cda_reconciliation,
                          pk_allergy.g_allergy_from_cda_recon,
                          pk_message.get_message(i_lang      => i_lang,
                                                 i_code_mess => pk_allergy.g_allergy_desc_record_origin)) record_origin,
                   l_na complications,
                   NULL id_group
              FROM pat_allergy pa, allergy a
             WHERE pa.id_pat_allergy = i_pat_prob
               AND a.id_allergy(+) = pa.id_allergy
               AND g_type_a = i_type
            UNION ALL
            SELECT nvl(nvl2(pah.id_allergy, pk_translation.get_translation(i_lang, a.code_allergy), pah.desc_allergy),
                       l_na) problem,
                   l_na precaution_measures,
                   l_na header_warning,
                   nvl(pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pah.flg_type, i_lang), l_na) type_prob,
                   nvl(get_dt_str(i_lang, i_prof, pah.year_begin, pah.month_begin, pah.day_begin), l_na) onset,
                   NULL id_habit,
                   NULL location,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pah.flg_nature, i_lang), l_na) nature,
                   nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        pah.id_prof_write,
                                                        pah.dt_pat_allergy_tstz,
                                                        pah.id_episode),
                       l_na) specialty,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pah.flg_status, i_lang), l_na) status,
                   nvl(get_dt_str(i_lang, i_prof, pah.dt_resolution), l_na) resolution_date,
                   pah.notes notes,
                   nvl(pk_translation.get_translation(i_lang,
                                                      'CANCEL_REASON.CODE_CANCEL_REASON.' || pah.id_cancel_reason),
                       l_na) cancel_reason,
                   pah.cancel_notes cancel_notes,
                   nvl(pk_date_utils.date_char_tsz(i_lang, pah.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) ||
                       g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, pah.id_prof_write) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pah.id_prof_write,
                                                            pah.dt_pat_allergy_tstz,
                                                            pah.id_episode),
                           l_problem_list_t069) || ')',
                       l_na) registered,
                   to_char(pah.dt_pat_allergy_tstz, 'YYYYMMDDhh24miss') create_time,
                   NULL cancel_prof,
                   NULL cancel_date,
                   NULL record_origin,
                   l_na complications,
                   NULL id_group
              FROM pat_allergy pa, allergy a, pat_allergy_hist pah
             WHERE pa.id_pat_allergy = i_pat_prob
               AND pah.id_pat_allergy = pa.id_pat_allergy
               AND a.id_allergy(+) = pa.id_allergy
               AND g_type_a = i_type
             ORDER BY create_time;
    
        -- find differences
        g_error := 'LOOP sel_problem';
        LOOP
            FETCH sel_problem
                INTO problem_record;
            EXIT WHEN sel_problem%NOTFOUND;
        
            IF first_rec = 0
            THEN
                problem_record_first.precaution_measures := problem_record.precaution_measures;
                problem_record_first.header_warning      := problem_record.header_warning;
                problem_record_first.specialty           := problem_record.specialty;
                problem_record_first.resolution_date     := problem_record.resolution_date;
                problem_record_first.status              := problem_record.status;
                problem_record_first.nature              := problem_record.nature;
                problem_record_first.onset               := problem_record.onset;
                problem_record_first.type_prob           := problem_record.type_prob;
                problem_record_first.problem             := problem_record.problem;
                problem_record_first.notes               := problem_record.notes;
                problem_record_first.cancel_notes        := problem_record.cancel_notes;
                problem_record_first.cancel_reason       := problem_record.cancel_reason;
                problem_record_first.registered          := problem_record.registered;
                problem_record_first.create_time         := problem_record.create_time;
                problem_record_first.record_origin       := problem_record.record_origin;
                first_rec                                := 1;
                i                                        := i + 1;
            ELSE
                l_flag_change := 0;
                IF problem_record_previous.precaution_measures <> problem_record.precaution_measures
                THEN
                    problem_dif_table_rec(i).precaution_measures_b := problem_record_previous.precaution_measures;
                    problem_dif_table_rec(i).precaution_measures_a := problem_record.precaution_measures;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.header_warning <> problem_record.header_warning
                THEN
                    problem_dif_table_rec(i).header_warning_b := problem_record_previous.header_warning;
                    problem_dif_table_rec(i).header_warning_a := problem_record.header_warning;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.specialty <> problem_record.specialty
                THEN
                    problem_dif_table_rec(i).specialty_b := problem_record_previous.specialty;
                    problem_dif_table_rec(i).specialty_a := problem_record.specialty;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.resolution_date <> problem_record.resolution_date
                THEN
                    problem_dif_table_rec(i).resolution_date_b := problem_record_previous.resolution_date;
                    problem_dif_table_rec(i).resolution_date_a := problem_record.resolution_date;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.status <> problem_record.status
                THEN
                    problem_dif_table_rec(i).status_b := problem_record_previous.status;
                    problem_dif_table_rec(i).status_a := problem_record.status;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.nature <> problem_record.nature
                THEN
                    problem_dif_table_rec(i).nature_b := problem_record_previous.nature;
                    problem_dif_table_rec(i).nature_a := problem_record.nature;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.onset <> problem_record.onset
                THEN
                    problem_dif_table_rec(i).onset_b := problem_record_previous.onset;
                    problem_dif_table_rec(i).onset_a := problem_record.onset;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.type_prob <> problem_record.type_prob
                THEN
                    problem_dif_table_rec(i).type_prob_b := problem_record_previous.type_prob;
                    problem_dif_table_rec(i).type_prob_a := problem_record.type_prob;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.problem <> problem_record.problem
                THEN
                    problem_dif_table_rec(i).problem_b := problem_record_previous.problem;
                    problem_dif_table_rec(i).problem_a := problem_record.problem;
                    l_flag_change := 1;
                END IF;
            
                IF (problem_record_previous.notes <> problem_record.notes)
                   OR (problem_record_previous.notes IS NOT NULL AND problem_record.notes IS NULL)
                   OR (problem_record_previous.notes IS NULL AND problem_record.notes IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).notes_b := problem_record_previous.notes;
                    problem_dif_table_rec(i).notes_a := problem_record.notes;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_notes <> problem_record.cancel_notes
                   OR (problem_record_previous.cancel_notes IS NOT NULL AND problem_record.cancel_notes IS NULL)
                   OR (problem_record_previous.cancel_notes IS NULL AND problem_record.cancel_notes IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).cancel_notes_b := problem_record_previous.cancel_notes;
                    problem_dif_table_rec(i).cancel_notes_a := problem_record.cancel_notes;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_reason <> problem_record.cancel_reason
                THEN
                    problem_dif_table_rec(i).cancel_reason_b := problem_record_previous.cancel_reason;
                    problem_dif_table_rec(i).cancel_reason_a := problem_record.cancel_reason;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.record_origin <> problem_record.record_origin
                THEN
                    problem_dif_table_rec(i).record_origin_b := problem_record_previous.record_origin;
                    problem_dif_table_rec(i).record_origin_a := problem_record.record_origin;
                    l_flag_change := 1;
                END IF;
            
                IF l_flag_change = 1
                THEN
                    problem_dif_table_rec(i).registered_b := problem_record_previous.registered;
                    problem_dif_table_rec(i).registered_a := problem_record.registered;
                    problem_dif_table_rec(i).create_time := problem_record.create_time;
                    i := i + 1;
                END IF;
            END IF;
            problem_record_previous.precaution_measures := problem_record.precaution_measures;
            problem_record_previous.header_warning      := problem_record.header_warning;
            problem_record_previous.specialty           := problem_record.specialty;
            problem_record_previous.resolution_date     := problem_record.resolution_date;
            problem_record_previous.status              := problem_record.status;
            problem_record_previous.nature              := problem_record.nature;
            problem_record_previous.onset               := problem_record.onset;
            problem_record_previous.type_prob           := problem_record.type_prob;
            problem_record_previous.problem             := problem_record.problem;
            problem_record_previous.notes               := problem_record.notes;
            problem_record_previous.cancel_notes        := problem_record.cancel_notes;
            problem_record_previous.cancel_reason       := problem_record.cancel_reason;
            problem_record_previous.registered          := problem_record.registered;
            problem_record_previous.create_time         := problem_record.create_time;
            problem_record_previous.record_origin       := problem_record.record_origin;
        END LOOP;
    
        CLOSE sel_problem;
    
        -- build first history record = creation record    
        g_error := 'OPEN o_problem';
        OPEN o_problem FOR
            SELECT table_varchar(l_type_bold, l_label_problem, problem_record_first.problem) problem,
                   table_varchar(l_type_bold,
                                 l_label_precaution,
                                 decode(problem_record_first.precaution_measures,
                                        l_na,
                                        NULL,
                                        problem_record_first.precaution_measures)) precaution_measures,
                   table_varchar(l_type_bold,
                                 l_label_header,
                                 decode(problem_record_first.header_warning,
                                        l_na,
                                        NULL,
                                        problem_record_first.header_warning)) header_warning,
                   table_varchar(l_type_bold,
                                 l_label_type,
                                 decode(problem_record_first.type_prob, l_na, NULL, problem_record_first.type_prob)) type_prob,
                   table_varchar(l_type_bold,
                                 l_label_onset,
                                 decode(problem_record_first.onset, l_na, NULL, problem_record_first.onset)) onset,
                   table_varchar(l_type_bold,
                                 l_label_nature,
                                 decode(problem_record_first.nature, l_na, NULL, problem_record_first.nature)) nature,
                   table_varchar(l_type_bold,
                                 l_label_specialty,
                                 decode(problem_record_first.specialty, l_na, NULL, problem_record_first.specialty)) specialty,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 decode(problem_record_first.status, l_na, NULL, problem_record_first.status)) status,
                   table_varchar(l_type_bold,
                                 l_label_resolution_date,
                                 decode(problem_record_first.resolution_date,
                                        l_na,
                                        NULL,
                                        problem_record_first.resolution_date)) resolution_date,
                   table_varchar(l_type_bold, l_label_notes, problem_record_first.notes) notes,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_reason,
                                 decode(problem_record_first.cancel_reason,
                                        l_na,
                                        NULL,
                                        problem_record_first.cancel_reason)) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancellation_notes, problem_record_first.cancel_notes) cancel_notes,
                   table_varchar(l_type_bold,
                                 l_record_origin,
                                 decode(problem_record_first.record_origin,
                                        NULL,
                                        decode(problem_record_first.record_origin,
                                               l_na,
                                               NULL,
                                               problem_record_first.record_origin),
                                        NULL)) record_origin,
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 decode(problem_record_first.registered, l_na, NULL, problem_record_first.registered)) registered
              FROM dual;
    
        -- build history review record
        g_error := 'open o_review_hist';
        OPEN o_review_hist FOR
            SELECT table_varchar(l_type_italic,
                                 l_label_registered_review,
                                 pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) ||
                                 g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      rd.id_professional,
                                                                      rd.dt_review,
                                                                      NULL),
                                     l_problem_list_t069) || ')',
                                 to_char(rd.dt_review, 'YYYYMMDDhh24miss')) registered_review,
                   table_varchar(l_type_bold, l_label_review_notes, rd.review_notes) review_notes
              FROM review_detail rd, pat_allergy pa
             WHERE rd.id_record_area = i_pat_prob
               AND pa.id_pat_allergy = rd.id_record_area
               AND rd.flg_context = pk_review.get_allergies_context()
             ORDER BY rd.dt_review ASC;
    
        -- build before / after problem history information     
        g_error := 'build o_problem_hist';
        IF problem_dif_table_rec.count <> 0
        THEN
            o_problem_hist := table_table_varchar();
        END IF;
        FOR k IN 1 .. problem_dif_table_rec.count
        LOOP
            IF problem_dif_table_rec(k).problem_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_problem,
                                                               problem_dif_table_rec(k).problem_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_problem_hist,
                                                               problem_dif_table_rec(k).problem_a);
            END IF;
            IF problem_dif_table_rec(k).precaution_measures_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_precaution,
                                                               problem_dif_table_rec(k).precaution_measures_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_precaution_hist,
                                                               problem_dif_table_rec(k).precaution_measures_a);
            END IF;
        
            IF problem_dif_table_rec(k).header_warning_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_header,
                                                               problem_dif_table_rec(k).header_warning_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_header_hist,
                                                               problem_dif_table_rec(k).header_warning_a);
            END IF;
            IF problem_dif_table_rec(k).type_prob_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_type,
                                                               problem_dif_table_rec(k).type_prob_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_type_hist,
                                                               problem_dif_table_rec(k).type_prob_a);
            END IF;
            IF problem_dif_table_rec(k).onset_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_onset,
                                                               problem_dif_table_rec(k).onset_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_onset_hist,
                                                               problem_dif_table_rec(k).onset_a);
            END IF;
            IF problem_dif_table_rec(k).nature_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_nature,
                                                               problem_dif_table_rec(k).nature_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_nature_hist,
                                                               problem_dif_table_rec(k).nature_a);
            END IF;
            IF problem_dif_table_rec(k).specialty_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_specialty,
                                                               problem_dif_table_rec(k).specialty_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_specialty_hist,
                                                               problem_dif_table_rec(k).specialty_a);
            END IF;
            IF problem_dif_table_rec(k).status_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_status,
                                                               problem_dif_table_rec(k).status_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_status_hist,
                                                               problem_dif_table_rec(k).status_a);
            END IF;
            IF problem_dif_table_rec(k).resolution_date_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_resolution_date,
                                                               problem_dif_table_rec(k).resolution_date_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_resolution_date_hist,
                                                               problem_dif_table_rec(k).resolution_date_a);
            END IF;
            IF problem_dif_table_rec(k).notes_b IS NOT NULL
                OR problem_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_notes,
                                                               nvl(problem_dif_table_rec(k).notes_b, l_na));
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_notes_hist,
                                                               nvl(problem_dif_table_rec(k).notes_a, l_na));
            END IF;
            IF problem_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancellation_reason,
                                                               problem_dif_table_rec(k).cancel_reason_a);
            END IF;
            IF problem_dif_table_rec(k).cancel_notes_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancellation_notes,
                                                               nvl(problem_dif_table_rec(k).cancel_notes_a, l_na));
            END IF;
            l_counter := o_problem_hist.count;
            o_problem_hist.extend(1);
            o_problem_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                           l_label_registered,
                                                           problem_dif_table_rec(k).registered_a,
                                                           problem_dif_table_rec(k).create_time);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_NEW_HIST_A');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_problem);
                pk_types.open_my_cursor(o_review_hist);
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_problem_det_new_hist_p
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        problem_dif_table_rec       problem_dif_table;
        problem_record              problem_type;
        problem_record_previous     problem_type;
        problem_record_first        problem_type;
        i                           NUMBER := 0;
        first_rec                   NUMBER := 0;
        l_label_onset               sys_message.desc_message%TYPE;
        l_label_onset_habits        sys_message.desc_message%TYPE;
        l_label_status              sys_message.desc_message%TYPE;
        l_label_nature              sys_message.desc_message%TYPE;
        l_label_type                sys_message.desc_message%TYPE;
        l_label_notes               sys_message.desc_message%TYPE;
        l_label_cancellation_reason sys_message.desc_message%TYPE;
        l_label_cancellation_notes  sys_message.desc_message%TYPE;
        l_label_precaution          sys_message.desc_message%TYPE;
        l_label_header              sys_message.desc_message%TYPE;
        l_label_specialty           sys_message.desc_message%TYPE;
        l_label_resolution_date     sys_message.desc_message%TYPE;
        l_label_problem             sys_message.desc_message%TYPE;
    
        l_label_onset_hist           sys_message.desc_message%TYPE;
        l_label_status_hist          sys_message.desc_message%TYPE;
        l_label_nature_hist          sys_message.desc_message%TYPE;
        l_label_type_hist            sys_message.desc_message%TYPE;
        l_label_notes_hist           sys_message.desc_message%TYPE;
        l_label_precaution_hist      sys_message.desc_message%TYPE;
        l_label_header_hist          sys_message.desc_message%TYPE;
        l_label_specialty_hist       sys_message.desc_message%TYPE;
        l_label_resolution_date_hist sys_message.desc_message%TYPE;
        l_label_problem_hist         sys_message.desc_message%TYPE;
        l_label_registered_review    sys_message.desc_message%TYPE;
        l_label_review_notes         sys_message.desc_message%TYPE;
        l_problem_list_t069          sys_message.desc_message%TYPE;
        l_record_origin              sys_message.desc_message%TYPE;
    
        l_label_registered sys_message.desc_message%TYPE;
        l_na               sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR);
        l_type_red    VARCHAR2(1 CHAR);
        l_type_italic VARCHAR2(1 CHAR);
        sel_problem   pk_types.cursor_type;
    
        l_counter       NUMBER;
        l_flag_change   NUMBER := 0;
        l_problems_m004 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M004');
        l_problems_m001 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M001');
        l_problems_m008 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M008');
        l_problems_m007 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M007');
        l_problems_m006 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M006');
    
    BEGIN
    
        l_problem_list_t069          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069');
        l_label_onset                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T006');
        l_label_status               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T003');
        l_label_nature               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T004');
        l_label_type                 := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T008');
        l_label_notes                := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T009');
        l_label_cancellation_reason  := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T026');
        l_label_cancellation_notes   := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T027');
        l_label_registered           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T046');
        l_label_precaution           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T047');
        l_label_header               := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T037');
        l_label_specialty            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T032');
        l_label_resolution_date      := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T033');
        l_label_problem              := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T001');
        l_label_onset_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T058');
        l_label_status_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T049');
        l_label_nature_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T059');
        l_label_type_hist            := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T057');
        l_label_notes_hist           := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T056');
        l_label_precaution_hist      := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T048');
        l_label_header_hist          := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T050');
        l_label_specialty_hist       := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T052');
        l_label_resolution_date_hist := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T051');
        l_label_problem_hist         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T055');
        l_label_registered_review    := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T062');
        l_label_review_notes         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T063');
        l_na                         := pk_message.get_message(i_lang, i_prof, 'N/A');
        l_type_bold                  := 'B';
        l_type_italic                := 'N';
        l_type_red                   := 'R';
        l_label_onset_habits         := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T084');
    
        -- query all records    
        g_error := 'OPEN sel_problem';
        OPEN sel_problem FOR
            SELECT nvl(decode(pp1.desc_pat_problem,
                              '',
                              decode(pp1.id_habit,
                                     '',
                                     decode(nvl(ed.id_epis_diagnosis, 0),
                                            0,
                                            pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                       i_id_diagnosis       => d.id_diagnosis,
                                                                       i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                       i_code               => d.code_icd,
                                                                       i_flg_other          => d.flg_other,
                                                                       i_flg_std_diag       => ad.flg_icd9),
                                            pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                       i_id_diagnosis        => d1.id_diagnosis,
                                                                       i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                       i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                       i_code                => d1.code_icd,
                                                                       i_flg_other           => d1.flg_other,
                                                                       i_flg_std_diag        => ad1.flg_icd9,
                                                                       i_epis_diag           => ed.id_epis_diagnosis)),
                                     pk_translation.get_translation(i_lang, h.code_habit)),
                              pp1.desc_pat_problem),
                       l_na) problem,
                   l_na precaution_measures,
                   l_na header_warning,
                   nvl(decode(pp1.desc_pat_problem,
                              '',
                              decode(pp1.id_habit,
                                     '',
                                     decode(nvl(ed.id_epis_diagnosis, 0),
                                            0,
                                            l_problems_m004,
                                            decode(ed.flg_type, g_epis_diag_passive, l_problems_m008, l_problems_m007)),
                                     l_problems_m006),
                              decode(pp1.id_diagnosis, NULL, l_problems_m001, l_problems_m004)),
                       l_na) type_prob,
                   nvl(get_dt_str(i_lang, i_prof, pp1.year_begin, pp1.month_begin, pp1.day_begin), l_na) onset,
                   pp1.id_habit id_habit,
                   NULL location,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp1.flg_nature, i_lang), l_na) nature,
                   nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        pp1.id_professional_ins,
                                                        pp1.dt_pat_problem_tstz,
                                                        pp1.id_episode),
                       l_na) specialty,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp1.flg_status, i_lang), l_na) status,
                   nvl(get_dt_str(i_lang, i_prof, pp1.dt_resolution), l_na) resolution_date,
                   pp1.notes notes,
                   nvl(pk_translation.get_translation(i_lang,
                                                      'CANCEL_REASON.CODE_CANCEL_REASON.' || pp1.id_cancel_reason),
                       l_na) cancel_reason,
                   pp1.cancel_notes cancel_notes,
                   nvl(pk_date_utils.date_char_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof.institution, i_prof.software) ||
                       g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, pp1.id_professional_ins) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pp1.id_professional_ins,
                                                            pp1.dt_pat_problem_tstz,
                                                            pp1.id_episode),
                           l_problem_list_t069) || ')',
                       l_na) registered,
                   to_char(pp1.dt_pat_problem_tstz, 'YYYYMMDDhh24miss') create_time,
                   NULL cancel_prof,
                   NULL cancel_date,
                   NULL record_origin,
                   l_na complications,
                   NULL id_group
              FROM pat_problem     pp1,
                   epis_diagnosis  ed,
                   habit           h,
                   alert_diagnosis ad1,
                   diagnosis       d1,
                   alert_diagnosis ad,
                   diagnosis       d
             WHERE pp1.id_pat_problem = i_pat_prob
               AND ed.id_epis_diagnosis(+) = pp1.id_epis_diagnosis
               AND pp1.id_habit = h.id_habit(+)
               AND ed.id_alert_diagnosis = ad1.id_alert_diagnosis(+)
               AND ed.id_diagnosis = d1.id_diagnosis(+)
               AND pp1.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pp1.id_diagnosis = d.id_diagnosis(+)
               AND g_type_p = i_type
               AND pp1.flg_status <> g_pat_probl_invest
            UNION ALL
            SELECT nvl(decode(pp1.desc_pat_problem,
                              '',
                              decode(pp1.id_pat_habit,
                                     '',
                                     decode(nvl(ed.id_epis_diagnosis, 0),
                                            0,
                                            pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                       i_id_diagnosis       => d.id_diagnosis,
                                                                       i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                       i_code               => d.code_icd,
                                                                       i_flg_other          => d.flg_other,
                                                                       i_flg_std_diag       => ad.flg_icd9),
                                            pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                       i_id_diagnosis        => d1.id_diagnosis,
                                                                       i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                       i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                       i_code                => d1.code_icd,
                                                                       i_flg_other           => d1.flg_other,
                                                                       i_flg_std_diag        => ad1.flg_icd9,
                                                                       i_epis_diag           => ed.id_epis_diagnosis)),
                                     pk_translation.get_translation(i_lang, h.code_habit)),
                              pp1.desc_pat_problem),
                       l_na) problem,
                   l_na precaution_measures,
                   l_na header_warning,
                   nvl(decode(pp1.desc_pat_problem,
                              '',
                              decode(pp1.id_pat_habit,
                                     '',
                                     decode(nvl(ed.id_epis_diagnosis, 0),
                                            0,
                                            l_problems_m004,
                                            decode(ed.flg_type, g_epis_diag_passive, l_problems_m008, l_problems_m007)),
                                     l_problems_m006),
                              decode(pp1.id_diagnosis, NULL, l_problems_m001, l_problems_m004)),
                       l_na) type_prob,
                   nvl(get_dt_str(i_lang, i_prof, pph1.year_begin, pph1.month_begin, pph1.day_begin), l_na) onset,
                   pp1.id_pat_habit id_habit,
                   NULL location,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pph1.flg_nature, i_lang), l_na) nature,
                   nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        pph1.id_professional_ins,
                                                        pph1.dt_pat_problem_tstz,
                                                        pph1.id_episode),
                       l_na) specialty,
                   nvl(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pph1.flg_status, i_lang), l_na) status,
                   nvl(get_dt_str(i_lang, i_prof, pph1.dt_resolution), l_na) resolution_date,
                   pph1.notes notes,
                   nvl(pk_translation.get_translation(i_lang,
                                                      'CANCEL_REASON.CODE_CANCEL_REASON.' || pph1.id_cancel_reason),
                       l_na) cancel_reason,
                   pph1.cancel_notes cancel_notes,
                   nvl(pk_date_utils.date_char_tsz(i_lang,
                                                   pph1.dt_pat_problem_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) || g_semicolon ||
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pph1.id_professional_ins) || ' (' ||
                       nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pph1.id_professional_ins,
                                                            pph1.dt_pat_problem_tstz,
                                                            pph1.id_episode),
                           l_problem_list_t069) || ')',
                       l_na) registered,
                   to_char(pph1.dt_pat_problem_tstz, 'YYYYMMDDhh24miss') create_time,
                   NULL cancel_prof,
                   NULL cancel_date,
                   NULL record_origin,
                   l_na complications,
                   NULL id_group
              FROM pat_problem      pp1,
                   pat_problem_hist pph1,
                   epis_diagnosis   ed,
                   habit            h,
                   alert_diagnosis  ad1,
                   diagnosis        d1,
                   alert_diagnosis  ad,
                   diagnosis        d
             WHERE pp1.id_pat_problem = i_pat_prob
               AND pp1.id_pat_problem = pph1.id_pat_problem
               AND ed.id_epis_diagnosis(+) = pph1.id_epis_diagnosis
               AND pp1.id_habit = h.id_habit(+)
               AND ed.id_alert_diagnosis = ad1.id_alert_diagnosis(+)
               AND ed.id_diagnosis = d1.id_diagnosis(+)
               AND pp1.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pp1.id_diagnosis = d.id_diagnosis(+)
               AND g_type_p = i_type
               AND pph1.flg_status <> g_pat_probl_invest
             ORDER BY create_time;
    
        -- find differences
        g_error := 'LOOP sel_problem';
        LOOP
            FETCH sel_problem
                INTO problem_record;
            EXIT WHEN sel_problem%NOTFOUND;
        
            IF first_rec = 0
            THEN
                problem_record_first.precaution_measures := problem_record.precaution_measures;
                problem_record_first.header_warning      := problem_record.header_warning;
                problem_record_first.specialty           := problem_record.specialty;
                problem_record_first.resolution_date     := problem_record.resolution_date;
                problem_record_first.status              := problem_record.status;
                problem_record_first.nature              := problem_record.nature;
                problem_record_first.onset               := problem_record.onset;
                problem_record_first.id_habit            := problem_record.id_habit;
                problem_record_first.type_prob           := problem_record.type_prob;
                problem_record_first.problem             := problem_record.problem;
                problem_record_first.notes               := problem_record.notes;
                problem_record_first.cancel_notes        := problem_record.cancel_notes;
                problem_record_first.cancel_reason       := problem_record.cancel_reason;
                problem_record_first.registered          := problem_record.registered;
                problem_record_first.create_time         := problem_record.create_time;
                problem_record_first.record_origin       := problem_record.record_origin;
                first_rec                                := 1;
                i                                        := i + 1;
            ELSE
                l_flag_change := 0;
                IF problem_record_previous.precaution_measures <> problem_record.precaution_measures
                THEN
                    problem_dif_table_rec(i).precaution_measures_b := problem_record_previous.precaution_measures;
                    problem_dif_table_rec(i).precaution_measures_a := problem_record.precaution_measures;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.header_warning <> problem_record.header_warning
                THEN
                    problem_dif_table_rec(i).header_warning_b := problem_record_previous.header_warning;
                    problem_dif_table_rec(i).header_warning_a := problem_record.header_warning;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.specialty <> problem_record.specialty
                THEN
                    problem_dif_table_rec(i).specialty_b := problem_record_previous.specialty;
                    problem_dif_table_rec(i).specialty_a := problem_record.specialty;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.resolution_date <> problem_record.resolution_date
                THEN
                    problem_dif_table_rec(i).resolution_date_b := problem_record_previous.resolution_date;
                    problem_dif_table_rec(i).resolution_date_a := problem_record.resolution_date;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.status <> problem_record.status
                THEN
                    problem_dif_table_rec(i).status_b := problem_record_previous.status;
                    problem_dif_table_rec(i).status_a := problem_record.status;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.nature <> problem_record.nature
                THEN
                    problem_dif_table_rec(i).nature_b := problem_record_previous.nature;
                    problem_dif_table_rec(i).nature_a := problem_record.nature;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.onset <> problem_record.onset
                THEN
                    problem_dif_table_rec(i).onset_b := problem_record_previous.onset;
                    problem_dif_table_rec(i).onset_a := problem_record.onset;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.type_prob <> problem_record.type_prob
                THEN
                    problem_dif_table_rec(i).type_prob_b := problem_record_previous.type_prob;
                    problem_dif_table_rec(i).type_prob_a := problem_record.type_prob;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.problem <> problem_record.problem
                THEN
                    problem_dif_table_rec(i).problem_b := problem_record_previous.problem;
                    problem_dif_table_rec(i).problem_a := problem_record.problem;
                    l_flag_change := 1;
                END IF;
            
                IF (problem_record_previous.notes <> problem_record.notes)
                   OR (problem_record_previous.notes IS NOT NULL AND problem_record.notes IS NULL)
                   OR (problem_record_previous.notes IS NULL AND problem_record.notes IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).notes_b := problem_record_previous.notes;
                    problem_dif_table_rec(i).notes_a := problem_record.notes;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_notes <> problem_record.cancel_notes
                   OR (problem_record_previous.cancel_notes IS NOT NULL AND problem_record.cancel_notes IS NULL)
                   OR (problem_record_previous.cancel_notes IS NULL AND problem_record.cancel_notes IS NOT NULL)
                THEN
                    problem_dif_table_rec(i).cancel_notes_b := problem_record_previous.cancel_notes;
                    problem_dif_table_rec(i).cancel_notes_a := problem_record.cancel_notes;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.cancel_reason <> problem_record.cancel_reason
                THEN
                    problem_dif_table_rec(i).cancel_reason_b := problem_record_previous.cancel_reason;
                    problem_dif_table_rec(i).cancel_reason_a := problem_record.cancel_reason;
                    l_flag_change := 1;
                END IF;
            
                IF problem_record_previous.record_origin <> problem_record.record_origin
                THEN
                    problem_dif_table_rec(i).record_origin_b := problem_record_previous.record_origin;
                    problem_dif_table_rec(i).record_origin_a := problem_record.record_origin;
                    l_flag_change := 1;
                END IF;
            
                IF l_flag_change = 1
                THEN
                    problem_dif_table_rec(i).registered_b := problem_record_previous.registered;
                    problem_dif_table_rec(i).registered_a := problem_record.registered;
                    problem_dif_table_rec(i).create_time := problem_record.create_time;
                    i := i + 1;
                END IF;
            END IF;
            problem_record_previous.precaution_measures := problem_record.precaution_measures;
            problem_record_previous.header_warning      := problem_record.header_warning;
            problem_record_previous.specialty           := problem_record.specialty;
            problem_record_previous.resolution_date     := problem_record.resolution_date;
            problem_record_previous.status              := problem_record.status;
            problem_record_previous.nature              := problem_record.nature;
            problem_record_previous.onset               := problem_record.onset;
            problem_record_previous.type_prob           := problem_record.type_prob;
            problem_record_previous.problem             := problem_record.problem;
            problem_record_previous.notes               := problem_record.notes;
            problem_record_previous.cancel_notes        := problem_record.cancel_notes;
            problem_record_previous.cancel_reason       := problem_record.cancel_reason;
            problem_record_previous.registered          := problem_record.registered;
            problem_record_previous.create_time         := problem_record.create_time;
            problem_record_previous.record_origin       := problem_record.record_origin;
        END LOOP;
    
        CLOSE sel_problem;
    
        -- build first history record = creation record 
        g_error := 'OPEN o_problem';
        OPEN o_problem FOR
            SELECT table_varchar(l_type_bold, l_label_problem, problem_record_first.problem) problem,
                   table_varchar(l_type_bold,
                                 l_label_precaution,
                                 decode(problem_record_first.precaution_measures,
                                        l_na,
                                        NULL,
                                        problem_record_first.precaution_measures)) precaution_measures,
                   table_varchar(l_type_bold,
                                 l_label_header,
                                 decode(problem_record_first.header_warning,
                                        l_na,
                                        NULL,
                                        problem_record_first.header_warning)) header_warning,
                   table_varchar(l_type_bold,
                                 l_label_type,
                                 decode(problem_record_first.type_prob, l_na, NULL, problem_record_first.type_prob)) type_prob,
                   table_varchar(l_type_bold,
                                 decode(problem_record_first.id_habit, '', l_label_onset, l_label_onset_habits),
                                 decode(problem_record_first.onset, l_na, NULL, problem_record_first.onset)) onset,
                   table_varchar(l_type_bold,
                                 l_label_nature,
                                 decode(problem_record_first.nature, l_na, NULL, problem_record_first.nature)) nature,
                   table_varchar(l_type_bold,
                                 l_label_specialty,
                                 decode(problem_record_first.specialty, l_na, NULL, problem_record_first.specialty)) specialty,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 decode(problem_record_first.status, l_na, NULL, problem_record_first.status)) status,
                   table_varchar(l_type_bold,
                                 l_label_resolution_date,
                                 decode(problem_record_first.resolution_date,
                                        l_na,
                                        NULL,
                                        problem_record_first.resolution_date)) resolution_date,
                   table_varchar(l_type_bold, l_label_notes, problem_record_first.notes) notes,
                   table_varchar(l_type_bold,
                                 l_label_cancellation_reason,
                                 decode(problem_record_first.cancel_reason,
                                        l_na,
                                        NULL,
                                        problem_record_first.cancel_reason)) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancellation_notes, problem_record_first.cancel_notes) cancel_notes,
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 decode(problem_record_first.registered, l_na, NULL, problem_record_first.registered)) registered
              FROM dual;
    
        -- build history review record
        g_error := 'open o_review_hist';
        IF problem_dif_table_rec.count <> 0
        THEN
            o_problem_hist := table_table_varchar();
        END IF;
        OPEN o_review_hist FOR
            SELECT table_varchar(l_type_italic,
                                 l_label_registered_review,
                                 pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) ||
                                 g_semicolon || pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      rd.id_professional,
                                                                      rd.dt_review,
                                                                      NULL),
                                     l_problem_list_t069) || ')',
                                 to_char(rd.dt_review, 'YYYYMMDDhh24miss')) registered_review,
                   table_varchar(l_type_bold, l_label_review_notes, rd.review_notes) review_notes
              FROM review_detail rd, pat_problem pp
             WHERE pp.id_pat_problem = i_pat_prob
               AND rd.id_record_area = decode(pp.id_pat_habit, NULL, i_pat_prob, pp.id_pat_habit)
               AND rd.flg_context =
                   decode(pp.id_pat_habit, NULL, pk_review.get_problems_context(), pk_review.get_habits_context())
             ORDER BY rd.dt_review ASC;
    
        -- build before / after problem history information
        g_error := 'build o_problem_hist';
        FOR k IN 1 .. problem_dif_table_rec.count
        LOOP
            IF problem_dif_table_rec(k).problem_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_problem,
                                                               problem_dif_table_rec(k).problem_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_problem_hist,
                                                               problem_dif_table_rec(k).problem_a);
            END IF;
            IF problem_dif_table_rec(k).precaution_measures_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_precaution,
                                                               problem_dif_table_rec(k).precaution_measures_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_precaution_hist,
                                                               problem_dif_table_rec(k).precaution_measures_a);
            END IF;
        
            IF problem_dif_table_rec(k).header_warning_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_header,
                                                               problem_dif_table_rec(k).header_warning_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_header_hist,
                                                               problem_dif_table_rec(k).header_warning_a);
            END IF;
            IF problem_dif_table_rec(k).type_prob_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_type,
                                                               problem_dif_table_rec(k).type_prob_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_type_hist,
                                                               problem_dif_table_rec(k).type_prob_a);
            END IF;
            IF problem_dif_table_rec(k).onset_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               CASE problem_record_first.id_habit
                                                                   WHEN '' THEN
                                                                    l_label_onset
                                                                   ELSE
                                                                    l_label_onset_habits
                                                               END,
                                                               problem_dif_table_rec(k).onset_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_onset_hist,
                                                               problem_dif_table_rec(k).onset_a);
            END IF;
            IF problem_dif_table_rec(k).nature_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_nature,
                                                               problem_dif_table_rec(k).nature_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_nature_hist,
                                                               problem_dif_table_rec(k).nature_a);
            END IF;
            IF problem_dif_table_rec(k).specialty_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_specialty,
                                                               problem_dif_table_rec(k).specialty_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_specialty_hist,
                                                               problem_dif_table_rec(k).specialty_a);
            END IF;
            IF problem_dif_table_rec(k).status_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_status,
                                                               problem_dif_table_rec(k).status_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_status_hist,
                                                               problem_dif_table_rec(k).status_a);
            END IF;
            IF problem_dif_table_rec(k).resolution_date_b IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_resolution_date,
                                                               problem_dif_table_rec(k).resolution_date_b);
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_resolution_date_hist,
                                                               problem_dif_table_rec(k).resolution_date_a);
            END IF;
            IF problem_dif_table_rec(k).notes_b IS NOT NULL
                OR problem_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(2);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_notes,
                                                               nvl(problem_dif_table_rec(k).notes_b, l_na));
                o_problem_hist(l_counter + 2) := table_varchar(l_type_red,
                                                               l_label_notes_hist,
                                                               nvl(problem_dif_table_rec(k).notes_a, l_na));
            END IF;
            IF problem_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancellation_reason,
                                                               problem_dif_table_rec(k).cancel_reason_a);
            END IF;
            IF problem_dif_table_rec(k).cancel_notes_a IS NOT NULL
            THEN
                l_counter := o_problem_hist.count;
                o_problem_hist.extend(1);
                o_problem_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                               l_label_cancellation_notes,
                                                               nvl(problem_dif_table_rec(k).cancel_notes_a, l_na));
            END IF;
            l_counter := o_problem_hist.count;
            o_problem_hist.extend(1);
            o_problem_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                           l_label_registered,
                                                           problem_dif_table_rec(k).registered_a,
                                                           problem_dif_table_rec(k).create_time);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_DET_NEW_HIST_P');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_problem);
                pk_types.open_my_cursor(o_review_hist);
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************
    * Returns most recent ID for that alert_diagnosis / desc_pat_history_diagnosis
    *
    * @param i_lang                   Language ID
    * @param i_alert_diag             Alert Diagnosis ID
    * @param i_desc_phd               Description for the PHD
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_canceled           Flg cancel (if canceled are to be returned or not - Y/N)
    *
    * @return                         PHD ID wanted
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/09/21
    **********************************************************************************************/

    FUNCTION get_pat_hist_diag_recent
    (
        i_lang         IN language.id_language%TYPE,
        i_alert_diag   IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_phd     IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_pat          IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_flg_canceled IN VARCHAR
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE IS
    
        l_id_phd pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    BEGIN
        l_id_phd := get_pat_hist_diag_recent(i_lang         => i_lang,
                                             i_alert_diag   => i_alert_diag,
                                             i_desc_phd     => i_desc_phd,
                                             i_pat          => i_pat,
                                             i_prof         => i_prof,
                                             i_flg_canceled => i_flg_canceled,
                                             i_flg_type     => g_flg_type_med);
        RETURN l_id_phd;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_pat_hist_diag_recent;

    FUNCTION get_pat_hist_diag_recent
    (
        i_lang         IN language.id_language%TYPE,
        i_alert_diag   IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_phd     IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_pat          IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_flg_canceled IN VARCHAR,
        i_flg_type     IN pat_history_diagnosis.flg_type%TYPE
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE IS
        l_id_phd    pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
        l_flg_other diagnosis.flg_other%TYPE;
    
        CURSOR c_alert_diag IS
            SELECT x.id_pat_history_diagnosis
              FROM (SELECT *
                      FROM (SELECT phd.dt_pat_history_diagnosis_tstz, id_pat_history_diagnosis, flg_status
                              FROM pat_history_diagnosis phd
                             WHERE phd.flg_type = i_flg_type
                               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                                   phd.id_alert_diagnosis IS NULL)
                               AND phd.id_patient = i_pat
                               AND phd.id_alert_diagnosis = i_alert_diag
                             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC)
                     WHERE rownum = 1) x
             WHERE x.flg_status <> decode(i_flg_canceled, g_available, 'DUMMY', g_flg_cancel);
    
        CURSOR c_desc_phd IS
            SELECT x.id_pat_history_diagnosis
              FROM (SELECT *
                      FROM (SELECT phd.dt_pat_history_diagnosis_tstz, id_pat_history_diagnosis, flg_status
                              FROM pat_history_diagnosis phd
                             WHERE phd.flg_type = i_flg_type
                               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                                   phd.id_alert_diagnosis IS NULL)
                               AND phd.id_patient = i_pat
                               AND lower(phd.desc_pat_history_diagnosis) = lower(i_desc_phd)
                             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC)
                     WHERE rownum = 1) x
             WHERE x.flg_status <> decode(i_flg_canceled, g_available, 'DUMMY', g_flg_cancel);
    
        CURSOR c_alert_diag_flg_oth IS
            SELECT flg_other
              FROM alert_diagnosis ad, diagnosis d
             WHERE ad.id_diagnosis = d.id_diagnosis
               AND ad.id_alert_diagnosis = i_alert_diag;
    
        CURSOR c_id_phd_desc_phd IS
            SELECT x.id_pat_history_diagnosis
              FROM (SELECT *
                      FROM (SELECT phd.dt_pat_history_diagnosis_tstz, id_pat_history_diagnosis, flg_status
                              FROM pat_history_diagnosis phd
                             WHERE phd.flg_type = i_flg_type
                               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                                   phd.id_alert_diagnosis IS NULL)
                               AND phd.id_patient = i_pat
                               AND lower(phd.desc_pat_history_diagnosis) = lower(i_desc_phd)
                               AND phd.id_alert_diagnosis = i_alert_diag
                             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC)
                     WHERE rownum = 1) x
             WHERE x.flg_status <> decode(i_flg_canceled, g_available, 'DUMMY', g_flg_cancel);
    
    BEGIN
    
        IF i_alert_diag IS NOT NULL
        THEN
        
            -- check if it is Other Diagnosis
            OPEN c_alert_diag_flg_oth;
            FETCH c_alert_diag_flg_oth
                INTO l_flg_other;
            CLOSE c_alert_diag_flg_oth;
        
            IF l_flg_other = 'Y'
            THEN
            
                OPEN c_id_phd_desc_phd;
                FETCH c_id_phd_desc_phd
                    INTO l_id_phd;
                CLOSE c_id_phd_desc_phd;
            
            ELSE
            
                OPEN c_alert_diag;
                FETCH c_alert_diag
                    INTO l_id_phd;
                CLOSE c_alert_diag;
            
            END IF;
        
        ELSIF i_desc_phd IS NOT NULL
        THEN
        
            OPEN c_desc_phd;
            FETCH c_desc_phd
                INTO l_id_phd;
            CLOSE c_desc_phd;
        
        END IF;
    
        RETURN l_id_phd;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END;

    FUNCTION get_status_string
    (
        i_flg_status  IN VARCHAR2,
        i_desc_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_shortcut      PLS_INTEGER := NULL;
        l_display_type  VARCHAR2(2) := 'TI';
        l_date          VARCHAR2(200) := NULL; -- [<year> <month> <day> <hour> <minute> <second>]
        l_text          VARCHAR2(200);
        l_icon_name     VARCHAR2(200) := 'ShortCutIcon';
        l_back_color    VARCHAR2(200); -- ["0x" <red>  <green>  <blue>]
        l_message_style VARCHAR2(200) := NULL;
        l_message_color VARCHAR2(200) := NULL;
        l_icon_color    VARCHAR2(200) := NULL;
        l_date_server   TIMESTAMP WITH TIME ZONE := current_timestamp;
    
    BEGIN
    
        l_text := i_desc_status;
    
        CASE i_flg_status
            WHEN 'A' THEN
                -- ACTIVO
                l_back_color    := g_color_red; -- VERMELHO
                l_icon_color    := g_color_red;
                l_message_style := g_font_p;
            WHEN 'P' THEN
                -- PASSIVO
                l_back_color    := g_color_orange; -- LARANJA
                l_icon_color    := g_color_orange;
                l_message_style := g_font_p;
            ELSE
                -- RESOLVIDO
                l_back_color    := g_color_beige;
                l_icon_color    := g_color_beige;
                l_message_style := g_font_o;
        END CASE;
    
        RETURN l_shortcut || '|' || l_display_type || '|' || l_date || '|' || l_text || '|' || l_icon_name || '|' || l_back_color || '|' || l_message_style || '|' || l_message_color || '|' || l_icon_color || '|' || l_date_server;
    
    END get_status_string;

    FUNCTION get_count_and_first
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        o_count              OUT NUMBER,
        o_first              OUT VARCHAR2,
        o_code               OUT VARCHAR2,
        o_date               OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_fmt                OUT VARCHAR2,
        o_id_alert_diagnosis OUT NUMBER,
        o_id_task_type       OUT NUMBER
    ) RETURN BOOLEAN IS
    
        l_list pk_types.cursor_type;
    
        l_count NUMBER := 0;
    
        l_id                 NUMBER;
        l_desc               VARCHAR2(4000); --1
        l_code               VARCHAR2(4000); --2
        l_type_first         VARCHAR2(4000); --5
        l_date               VARCHAR2(4000); --6 --TIMESTAMP WITH TIME ZONE;
        l_dt_req             VARCHAR2(4000);
        l_desc_status        VARCHAR2(4000); --7
        l_status             VARCHAR2(4000); --8
        l_rank               VARCHAR2(4000); --9
        l_rank_order         VARCHAR2(4000); --10
        l_flg_status         VARCHAR2(4000); --11
        l_flg_type           VARCHAR2(4000); --12
        l_rank2              VARCHAR2(4000); --13
        l_procedure_counter  VARCHAR2(4000); --14
        l_medication_counter VARCHAR2(4000); --15
        l_contra_indications VARCHAR2(4000); --16
        l_rank_area          NUMBER;
    
        l_task_title sys_message.desc_message%TYPE;
    
        l_fmt VARCHAR2(3) := '';
    
    BEGIN
    
        IF get_ordered_list(i_lang, i_prof, i_patient, l_list)
        THEN
            o_fmt := l_fmt;
        
            LOOP
                FETCH l_list
                    INTO l_id, --1
                         o_first, --2
                         o_code, --3
                         l_type_first, --4
                         o_fmt, --5
                         o_date, --6
                         l_dt_req, --7
                         l_rank, --8
                         l_rank_order, --9
                         l_flg_status, --10
                         l_desc_status, --11 
                         l_status, --12
                         l_flg_type, --13
                         l_rank2, --14
                         l_procedure_counter, --15
                         l_medication_counter, --16
                         l_contra_indications, --17
                         l_rank_area,
                         l_task_title, --18
                         o_id_alert_diagnosis,
                         o_id_task_type;
            
                IF (NOT l_list%NOTFOUND)
                THEN
                    l_count := l_count + 1;
                ELSE
                    l_count := 0;
                END IF;
            
                EXIT;
            END LOOP;
        
            LOOP
                FETCH l_list
                    INTO l_id, --1
                         l_desc, --2
                         l_code, --3
                         l_type_first, --4
                         l_fmt, --5
                         l_date, --6
                         l_dt_req, --7
                         l_rank, --8
                         l_rank_order, --8
                         l_flg_status, --9
                         l_desc_status, --11
                         l_status, --12
                         l_flg_type, --13
                         l_rank2, --14
                         l_procedure_counter, --15
                         l_medication_counter, --16
                         l_contra_indications, --17
                         l_rank_area,
                         l_task_title,
                         o_id_alert_diagnosis,
                         o_id_task_type;
            
                EXIT WHEN l_list%NOTFOUND;
                l_count := l_count + 1;
            END LOOP;
        
            o_count := l_count;
        
            IF o_code IS NOT NULL
            THEN
                o_first := NULL;
            END IF;
        
            RETURN TRUE;
        ELSE
              o_count := 0;
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            RETURN FALSE;
        
    END get_count_and_first;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_ordered_list OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        l_current_ts TIMESTAMP WITH TIME ZONE := current_timestamp;
    
        l_show_allergy         sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_ALLERGY_IN_PROBLEM', i_prof);
        l_show_habit           sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_HABIT_IN_PROBLEM', i_prof);
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    
        l_sc_show_surgical sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                    i_prof);
    
        l_problems_m008 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M008');
        l_problems_m007 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M007');
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T020');
    BEGIN
    
        OPEN o_ordered_list FOR
            SELECT id,
                   desc_problem AS description,
                   code_problem AS code_description,
                   problem_type AS title,
                   decode(fmt, 'DMY', 'D', 'MY', 'M', 'Y', 'Y', '') AS dt_begin_fmt,
                   year_begin AS dt_begin,
                   CASE fmt
                       WHEN 'DMY' THEN
                        pk_date_utils.dt_chr_tsz(i_lang, year_begin, i_prof)
                       WHEN 'MY' THEN
                        pk_date_utils.get_month_year(i_lang => i_lang, i_prof => i_prof, i_timestamp => year_begin)
                       WHEN 'Y' THEN
                        pk_date_utils.get_year(i_lang, i_prof, year_begin)
                   END AS dt_req,
                   rank,
                   rank_order,
                   flg_status AS flg_status,
                   pk_problems.get_status_string(flg_status, desc_status) AS desc_status,
                   desc_status AS status,
                   flg_type,
                   decode(flg_status, 'A', 1, 'P', 2, 'C', 3, 'R', 4) AS rank2,
                   procedure_counter,
                   medication_counter,
                   contra_indications,
                   rank_area,
                   l_task_title task_title,
                   id_alert_diagnosis,
                   id_task_type
              FROM (
                    --HABIT
                    SELECT pp.id_pat_problem id,
                            pk_translation.get_translation(i_lang, h.code_habit) desc_problem,
                            h.code_habit code_problem,
                            pk_sysdomain.get_domain(g_code_domain, g_problem_type_habit, i_lang) problem_type,
                            (decode(pp.day_begin, NULL, '', 'D') || decode(pp.month_begin, NULL, '', 'M') ||
                            decode(pp.year_begin, NULL, '', 'Y')) fmt,
                            pk_date_utils.get_string_tstz(i_lang,
                                                          i_prof,
                                                          nvl2(pp.year_begin,
                                                               to_char(nvl(pp.year_begin, 1), 'FM0000') ||
                                                               to_char(nvl(pp.month_begin, 1), 'FM00') ||
                                                               to_char(nvl(pp.day_begin, 1), 'FM00') || '000000',
                                                               NULL),
                                                          NULL) year_begin,
                            pp.dt_pat_problem_tstz dt_problem_reg,
                            2 rank,
                            pk_date_utils.get_timestamp_diff(l_current_ts, pp.dt_pat_problem_tstz) rank_order,
                            pp.flg_status flg_status,
                            decode(pp.desc_pat_problem,
                                   NULL,
                                   decode(pp.id_diagnosis,
                                          NULL,
                                          decode(pp.id_habit,
                                                 NULL,
                                                 ' ',
                                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang)),
                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang)),
                                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang)) desc_status,
                            decode(pp.desc_pat_problem,
                                   NULL,
                                   decode(pp.id_diagnosis,
                                          NULL,
                                          decode(pp.id_habit, NULL, ' ', g_problem_type_habit),
                                          g_problem_type_diag),
                                   'P') flg_type,
                            (SELECT COUNT(*)
                               FROM interv_pat_problem ipp
                              WHERE ipp.id_pat_problem = pp.id_pat_problem
                                AND ipp.flg_status <> g_interv_pat_prob_inactive) procedure_counter,
                            (SELECT COUNT(*)
                               FROM presc_pat_problem ppp
                              WHERE ppp.id_pat_problem = pp.id_pat_problem
                                AND ppp.flg_status <> g_cancelled
                                AND ppp.flg_type = g_med_assoc) medication_counter,
                            'N' contra_indications,
                            NULL rank_area,
                            NULL id_alert_diagnosis,
                            NULL id_task_type
                      FROM pat_problem pp, habit h
                     WHERE pp.id_habit = h.id_habit
                       AND pp.flg_status <> g_flg_cancel
                       AND pp.id_patient = i_patient
                    UNION ALL
                    -- DIFERENCIAL AND FINAL DIAGNOSIS
                    SELECT pp.id_pat_problem id,
                            CASE
                                WHEN ad1.id_alert_diagnosis IS NOT NULL THEN
                                 pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                         i_id_concept_term => ad1.id_alert_diagnosis,
                                                                         i_id_task_type    => pk_alert_constant.g_task_diagnosis)
                                ELSE
                                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                            i_id_diagnosis        => d1.id_diagnosis,
                                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                            i_id_task_type        => pk_alert_constant.g_task_problems,
                                                            i_code                => d1.code_icd,
                                                            i_flg_other           => d1.flg_other,
                                                            i_flg_std_diag        => ad1.flg_icd9,
                                                            i_epis_diag           => ed.id_epis_diagnosis)
                            END AS desc_problem,
                            ad1.code_problems AS code_problem,
                            decode(ed.flg_type, g_epis_diag_passive, l_problems_m008, l_problems_m007) problem_type,
                            'DMY' fmt,
                            pp.dt_pat_problem_tstz year_begin,
                            pp.dt_pat_problem_tstz dt_problem_reg,
                            2 rank,
                            pk_date_utils.get_timestamp_diff(l_current_ts, pp.dt_pat_problem_tstz) rank_order,
                            pp.flg_status flg_status,
                            pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang) desc_status,
                            decode(ed.flg_type, g_epis_diag_passive, 'DD', g_problem_type_diag) flg_type,
                            (SELECT COUNT(*)
                               FROM interv_pat_problem ipp
                              WHERE ipp.id_pat_problem = pp.id_pat_problem
                                AND ipp.flg_status <> g_interv_pat_prob_inactive) procedure_counter,
                            (SELECT COUNT(*)
                               FROM presc_pat_problem ppp
                              WHERE ppp.id_pat_problem = pp.id_pat_problem
                                AND ppp.flg_status <> g_cancelled
                                AND ppp.flg_type = g_med_assoc) medication_counter,
                            'N' contra_indications,
                            NULL rank_area,
                            pp.id_alert_diagnosis,
                            pk_alert_constant.g_task_diagnosis id_task_type
                      FROM pat_problem     pp,
                            diagnosis       d,
                            professional    p,
                            epis_diagnosis  ed,
                            diagnosis       d1,
                            alert_diagnosis ad1
                     WHERE pp.id_patient = i_patient
                       AND pp.id_diagnosis = d.id_diagnosis(+)
                       AND pp.id_professional_ins = p.id_professional(+)
                       AND pp.flg_status NOT IN (g_cancelled)
                       AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                       AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
                       AND d1.id_diagnosis(+) = ed.id_diagnosis
                       AND ((pp.flg_status = g_pat_probl_invest AND ed.flg_status <> 'C') OR
                           pp.flg_status <> g_pat_probl_invest)
                          -- ALERT 736: diagnosis synonyms
                       AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                       AND ( --final diagnosis 
                            (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                            OR -- differencial diagnosis only 
                            (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                            ed.id_diagnosis NOT IN
                            (SELECT ed3.id_diagnosis
                                FROM epis_diagnosis ed3
                               WHERE ed3.id_diagnosis = ed.id_diagnosis
                                 AND ed3.id_patient = pp.id_patient
                                 AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
                       AND NOT EXISTS
                     (SELECT 1
                              FROM pat_history_diagnosis phd
                              LEFT JOIN diagnosis d2
                                ON d2.id_diagnosis = phd.id_diagnosis --, alert_diagnosis ad2
                             WHERE phd.id_patient = i_patient
                               AND phd.flg_type = g_flg_type_med
                               AND phd.id_diagnosis = pp.id_diagnosis
                               AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                               AND nvl(d2.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                               AND pp.dt_pat_problem_tstz < phd.dt_pat_history_diagnosis_tstz
                               AND rownum = 1)
                    UNION ALL
                    -- ALLERGY
                    SELECT pa.id_pat_allergy id,
                            nvl2(pa.id_allergy, pk_translation.get_translation(i_lang, a.code_allergy), pa.desc_allergy) desc_problem,
                            nvl2(pa.id_allergy, a.code_allergy, NULL) code_problem,
                            pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) type_problem,
                            (decode(pa.day_begin, NULL, '', 'D') || decode(pa.month_begin, NULL, '', 'M') ||
                            decode(pa.year_begin, NULL, '', 'Y')) fmt,
                            pk_date_utils.get_string_tstz(i_lang,
                                                          i_prof,
                                                          nvl2(pa.year_begin,
                                                               to_char(nvl(pa.year_begin, 1), 'FM0000') ||
                                                               to_char(nvl(pa.month_begin, 1), 'FM00') ||
                                                               to_char(nvl(pa.day_begin, 1), 'FM00') || '000000',
                                                               NULL),
                                                          NULL) year_begin,
                            pa.dt_pat_allergy_tstz dt_problem_reg,
                            1 rank,
                            pk_date_utils.get_timestamp_diff(l_current_ts, pa.dt_pat_allergy_tstz) rank_order,
                            pa.flg_status,
                            (SELECT sd.desc_val
                               FROM sys_domain sd
                              WHERE sd.code_domain = 'PAT_PROBLEM.FLG_STATUS'
                                AND sd.domain_owner = pk_sysdomain.k_default_schema
                                AND sd.id_language = i_lang
                                AND sd.val = pa.flg_status) desc_status,
                            'A' flg_type,
                            (SELECT COUNT(*)
                               FROM interv_pat_problem ipp
                              WHERE ipp.id_pat_allergy = pa.id_pat_allergy
                                AND ipp.flg_status <> g_interv_pat_prob_inactive) procedure_counter,
                            (SELECT COUNT(*)
                               FROM presc_pat_problem ppp
                              WHERE ppp.id_pat_allergy = pa.id_pat_allergy
                                AND ppp.flg_status <> g_cancelled
                                AND ppp.flg_type = g_med_assoc) medication_counter,
                            'N' contra_indications,
                            NULL rank_area,
                            NULL id_alert_diagnosis,
                            NULL id_task_type
                      FROM pat_allergy pa, allergy a
                     WHERE pa.id_allergy = a.id_allergy(+)
                       AND pa.flg_status <> g_flg_cancel
                       AND pa.id_patient = i_patient
                    UNION ALL
                    -- OTHER DIAGNOSIS -> Coded Problems
                    SELECT phd.id_pat_history_diagnosis id,
                            decode(phd.desc_pat_history_diagnosis,
                                   NULL,
                                   decode(ad.id_alert_diagnosis,
                                          NULL,
                                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                     i_id_diagnosis       => d.id_diagnosis,
                                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                    i_flg_type => phd.flg_type),
                                                                     i_code               => d.code_icd,
                                                                     i_flg_other          => d.flg_other,
                                                                     i_flg_std_diag       => ad.flg_icd9),
                                          pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                  i_id_concept_term => ad.id_alert_diagnosis,
                                                                                  i_id_task_type    => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                              i_flg_type => phd.flg_type))),
                                   decode(phd.id_alert_diagnosis,
                                          NULL,
                                          phd.desc_pat_history_diagnosis,
                                          phd.desc_pat_history_diagnosis || ' - ' ||
                                          pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                  i_id_concept_term => ad.id_alert_diagnosis,
                                                                                  i_id_task_type    => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                              i_flg_type => phd.flg_type)))) desc_problem,
                            CASE
                                WHEN d.flg_other = pk_alert_constant.get_no THEN
                                 ad.code_problems
                                ELSE
                                 NULL
                            END AS code_problem,
                            get_problem_type_desc(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_flg_area           => phd.flg_area,
                                                  i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                  i_flg_type           => phd.flg_type) type_problem,
                            decode(phd.dt_diagnosed_precision,
                                   pk_past_history.g_date_precision_day,
                                   'DMY',
                                   pk_past_history.g_date_precision_month,
                                   'MY',
                                   pk_past_history.g_date_precision_year,
                                   pk_past_history.g_date_precision_year,
                                   '') fmt,
                            phd.dt_diagnosed year_begin,
                            phd.dt_pat_history_diagnosis_tstz dt_problem_reg,
                            3 rank,
                            pk_date_utils.get_timestamp_diff(l_current_ts, phd.dt_pat_history_diagnosis_tstz) rank_order,
                            phd.flg_status,
                            (SELECT sd.desc_val
                               FROM sys_domain sd
                              WHERE sd.code_domain = 'PAT_PROBLEM.FLG_STATUS'
                                AND sd.domain_owner = pk_sysdomain.k_default_schema
                                AND sd.id_language = i_lang
                                AND sd.val = phd.flg_status) desc_status,
                            decode(phd.flg_area,
                                   pk_alert_constant.g_diag_area_problems,
                                   g_problem_type_problem,
                                   g_problem_type_pmh) flg_type,
                            (SELECT COUNT(*)
                               FROM interv_pat_problem ipp
                              WHERE ipp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
                                AND ipp.flg_status <> g_interv_pat_prob_inactive) procedure_counter,
                            (SELECT COUNT(*)
                               FROM presc_pat_problem ppp
                              WHERE ppp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
                                AND ppp.flg_status <> g_cancelled
                                AND ppp.flg_type = g_med_assoc) medication_counter,
                            phd.flg_compl contra_indications,
                            pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', phd.flg_area) rank_area,
                            ad.id_alert_diagnosis,
                            get_flg_area_task_type(i_flg_area => phd.flg_area, i_flg_type => phd.flg_type) id_task_type
                      FROM pat_history_diagnosis phd, diagnosis d, alert_diagnosis ad
                     WHERE phd.id_diagnosis = d.id_diagnosis
                          -- ALERT 736: diagnosis synonyms
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND phd.id_patient = i_patient
                       AND nvl(phd.flg_status, '-1') <> g_flg_cancel
                       AND phd.flg_type IN
                           (pk_past_history.g_alert_diag_type_med, pk_past_history.g_alert_diag_type_surg)
                       AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
                       AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                       AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                           (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                           phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)) AND
                           ((l_sc_show_surgical = g_yes) OR phd.flg_area <> pk_alert_constant.g_diag_area_surgical_hist))
                       AND phd.id_pat_history_diagnosis_new IS NULL
                    
                    UNION ALL
                    -- Uncoded Problems
                    SELECT phd.id_pat_history_diagnosis id,
                            decode(phd.desc_pat_history_diagnosis,
                                   NULL,
                                   decode(ad.id_alert_diagnosis,
                                          NULL,
                                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                     i_id_diagnosis       => d.id_diagnosis,
                                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                    i_flg_type => phd.flg_type),
                                                                     i_code               => d.code_icd,
                                                                     i_flg_other          => d.flg_other,
                                                                     i_flg_std_diag       => ad.flg_icd9),
                                          pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                  i_id_concept_term => ad.id_alert_diagnosis,
                                                                                  i_id_task_type    => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                              i_flg_type => phd.flg_type))),
                                   decode(phd.id_alert_diagnosis,
                                          NULL,
                                          phd.desc_pat_history_diagnosis,
                                          phd.desc_pat_history_diagnosis || ' - ' ||
                                          pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                  i_id_concept_term => ad.id_alert_diagnosis,
                                                                                  i_id_task_type    => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                              i_flg_type => phd.flg_type)))) desc_probl,
                            NULL code_problem,
                            pk_sysdomain.get_domain(g_code_domain, g_problem_type_problem, i_lang) type_problem,
                            decode(phd.dt_diagnosed_precision,
                                   pk_past_history.g_date_precision_day,
                                   'DMY',
                                   pk_past_history.g_date_precision_month,
                                   'MY',
                                   pk_past_history.g_date_precision_year,
                                   pk_past_history.g_date_precision_year,
                                   '') fmt,
                            phd.dt_diagnosed year_begin,
                            phd.dt_pat_history_diagnosis_tstz dt_problem_reg,
                            3 rank,
                            pk_date_utils.get_timestamp_diff(l_current_ts, phd.dt_pat_history_diagnosis_tstz) rank_order,
                            phd.flg_status,
                            (SELECT sd.desc_val
                               FROM sys_domain sd
                              WHERE sd.code_domain = 'PAT_PROBLEM.FLG_STATUS'
                                AND sd.domain_owner = pk_sysdomain.k_default_schema
                                AND sd.id_language = i_lang
                                AND sd.val = phd.flg_status) desc_status,
                            g_problem_type_problem flg_type,
                            (SELECT COUNT(*)
                               FROM interv_pat_problem ipp
                              WHERE ipp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
                                AND ipp.flg_status <> g_interv_pat_prob_inactive) procedure_counter,
                            (SELECT COUNT(*)
                               FROM presc_pat_problem ppp
                              WHERE ppp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
                                AND ppp.flg_status <> g_cancelled
                                AND ppp.flg_type = g_med_assoc) medication_counter,
                            phd.flg_compl contra_indications,
                            pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', phd.flg_area) rank_area,
                            ad.id_alert_diagnosis,
                            get_flg_area_task_type(i_flg_area => phd.flg_area, i_flg_type => phd.flg_type) id_task_type
                      FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                     WHERE phd.id_diagnosis IS NULL
                       AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
                       AND phd.id_diagnosis = d.id_diagnosis(+)
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND phd.id_patient = i_patient
                       AND phd.flg_status <> g_flg_cancel
                       AND phd.flg_type = g_flg_type_med
                       AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                       AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                           (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                           phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
                       AND phd.id_pat_history_diagnosis_new IS NULL) t
             WHERE t.flg_type IN (g_problem_type_pmh, g_problem_type_problem, 'P')
                OR (t.flg_type = g_problem_type_allergy AND l_show_allergy = pk_alert_constant.g_yes)
                OR (t.flg_type = g_problem_type_habit AND l_show_habit = pk_alert_constant.g_yes)
                OR (t.flg_type IN (g_problem_type_diag, 'DD'))
             ORDER BY rank_area ASC, rank2 ASC, dt_problem_reg DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_ordered_list;

    FUNCTION get_software
    (
        i_epis    IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN software.id_software%TYPE IS
        l_return software.id_software%TYPE;
    BEGIN
        --try to get the software using the episode
        BEGIN
            SELECT ei.id_software
              INTO l_return
              FROM epis_info ei
             WHERE ei.id_episode = i_epis
               AND i_epis IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_return := 0;
        END;
    
        RETURN l_return;
    END;

    FUNCTION get_institution
    (
        i_epis    IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN institution.id_institution%TYPE IS
        l_return institution.id_institution%TYPE;
    BEGIN
        --try to get the institution using the episode
        BEGIN
            SELECT e.id_institution
              INTO l_return
              FROM episode e
             WHERE e.id_episode = i_epis
               AND i_epis IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                --try to get the institution using the patient if not found in the episode
                BEGIN
                    SELECT p.institution_key
                      INTO l_return
                      FROM patient p
                     WHERE p.id_patient = i_patient
                       AND i_patient IS NOT NULL;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_return := 0;
                END;
        END;
    
        RETURN l_return;
    END;

    FUNCTION get_language
    (
        i_epis    IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN language.id_language%TYPE IS
        l_return language.id_language%TYPE;
    
        l_institution institution.id_institution%TYPE;
    BEGIN
        --try to get the institution using the patient if not found in the episode
        l_institution := get_institution(i_epis, i_patient);
    
        BEGIN
            SELECT ia.id_language
              INTO l_return
              FROM institution_language ia
             WHERE ia.id_institution = l_institution
               AND ia.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_return := 2;
        END;
    
        RETURN l_return;
    END;

    PROCEDURE upd_viewer_ehr_ea IS
        l_patients table_number;
        l_error    t_error_out;
    BEGIN
    
        SELECT id_patient
          BULK COLLECT
          INTO l_patients
          FROM viewer_ehr_ea vee;
    
        IF NOT upd_viewer_ehr_ea_pat(i_lang              => pk_data_gov_admin.g_log_lang,
                                     i_table_id_patients => l_patients,
                                     i_ignore_error      => TRUE,
                                     o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
    END upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        i_ignore_error      IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_occur          table_number := table_number();
        l_desc_first         table_varchar := table_varchar();
        l_code_first         table_varchar := table_varchar();
        l_dt_first           table_varchar := table_varchar();
        l_flg_warning        table_varchar := table_varchar();
        l_flg_infective      table_varchar := table_varchar();
        l_episode            table_number := table_number();
        l_fmt                VARCHAR2(3) := '';
        l_prof               profissional;
        l_id_alert_diagnosis table_number := table_number();
        l_id_task_type       table_number := table_number();
    BEGIN
        g_error := 'START UPD_VIEWER_EHR_EA_PAT';
        l_num_occur.extend(i_table_id_patients.count);
        l_desc_first.extend(i_table_id_patients.count);
        l_code_first.extend(i_table_id_patients.count);
        l_dt_first.extend(i_table_id_patients.count);
        l_episode.extend(i_table_id_patients.count);
        l_flg_warning.extend(i_table_id_patients.count);
        l_flg_infective.extend(i_table_id_patients.count);
        l_id_alert_diagnosis.extend(i_table_id_patients.count);
        l_id_task_type.extend(i_table_id_patients.count);
    
        FOR i IN i_table_id_patients.first .. i_table_id_patients.last
        LOOP
            g_error := 'CALL GET_COUNT_AND_FIRST ' || i_table_id_patients(i);
        
            l_prof := profissional(-1,
                                   get_institution(NULL, i_table_id_patients(i)),
                                   get_software(NULL, i_table_id_patients(i)));
        
            IF NOT get_count_and_first(i_lang               => get_language(NULL, i_table_id_patients(i)),
                                       i_prof               => l_prof,
                                       i_patient            => i_table_id_patients(i),
                                       o_count              => l_num_occur(i),
                                       o_first              => l_desc_first(i),
                                       o_code               => l_code_first(i),
                                       o_date               => l_dt_first(i),
                                       o_fmt                => l_fmt,
                                       o_id_alert_diagnosis => l_id_alert_diagnosis(i),
                                       o_id_task_type       => l_id_task_type(i))
            
            THEN
                IF i_ignore_error
                THEN
                    l_flg_warning(i) := 'N';
                    l_flg_infective(i) := 'N';

                    CONTINUE;
                ELSE
                    RETURN FALSE;
                END IF;
            END IF;
        
            l_flg_warning(i) := pk_problems.get_pat_flg_warning(i_lang => i_lang,
                                                                i_pat  => i_table_id_patients(i),
                                                                i_prof => l_prof);
            l_flg_infective(i) := pk_problems.check_pat_diag_condition(i_lang => i_lang,
                                                                       i_pat  => i_table_id_patients(i),
                                                                       i_prof => l_prof);
        
        END LOOP;
    
        g_error := 'FORALL';
        FORALL i IN i_table_id_patients.first .. i_table_id_patients.last
            UPDATE viewer_ehr_ea
               SET num_problem     = l_num_occur(i),
                   desc_problem    = l_desc_first(i),
                   dt_problem      = l_dt_first(i),
                   code_problem    = l_code_first(i),
                   flg_exclamation = l_flg_warning(i),
                   flg_infective   = l_flg_infective(i),
                   id_problem      = l_id_alert_diagnosis(i),
                   id_task_type    = l_id_task_type(i)
             WHERE id_patient = i_table_id_patients(i) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject
             LIMIT unlimited;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'UPDATE VIEWER_EHR_EA',
                                              g_pk_owner,
                                              g_package_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    PROCEDURE get_nature_options
    (
        i_prof IN profissional,
        o_nat  OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_nat FOR
            SELECT nvl(pk_sysconfig.get_config(i_code_cf => 'PROBLEM_NATURE_SHOW', i_prof => i_prof),
                       pk_alert_constant.g_yes) flg_show,
                   nvl(pk_sysconfig.get_config(i_code_cf => 'PROBLEM_NATURE_MANDATORY', i_prof => i_prof),
                       pk_alert_constant.g_no) flg_mandatory
              FROM dual;
    END get_nature_options;

    FUNCTION get_problems_onset_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_onset OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_ONSET';
        OPEN o_onset FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T022') label, 'D' data, 10 rank -- Date
              FROM dual
            UNION
            SELECT pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021') label, 'U' data, 20 rank -- Unknow
              FROM dual
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PROBLEMS_ONSET_LIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- fechar os cursores
                pk_types.open_my_cursor(o_onset);
                -- return failure   
                RETURN FALSE;
            END;
    END get_problems_onset_list;

    FUNCTION get_pat_problem_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_problem.id_patient%TYPE,
        i_id_problem  IN NUMBER,
        i_type        IN VARCHAR2,
        o_pat_problem OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --sys_messages used
        l_problems_m001 sys_message.desc_message%TYPE;
        l_problems_m004 sys_message.desc_message%TYPE;
    BEGIN
        l_problems_m001 := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M001');
        l_problems_m004 := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_M004');
        g_error         := 'OPEN O_PAT_PROBLEM';
    
        IF (i_type = g_type_d)
        THEN
            -------------------
            -- Relevant diseases
            -------------------  
            OPEN o_pat_problem FOR
                SELECT ad.id_diagnosis id,
                       phd.id_pat_history_diagnosis id_problem,
                       g_type_d TYPE,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   phd.dt_pat_history_diagnosis_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_problem2,
                       pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_date      => phd.dt_diagnosed,
                                                               i_precision => phd.dt_diagnosed_precision) dt_problem_to_print,
                       decode(phd.dt_diagnosed_precision,
                              g_unknown,
                              g_unknown,
                              pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) dt_problem,
                       phd.dt_diagnosed_precision dt_problem_precision,
                       decode(phd.desc_pat_history_diagnosis,
                              NULL,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                         i_id_diagnosis       => d.id_diagnosis,
                                                         i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                        i_flg_type => phd.flg_type),
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => ad.flg_icd9),
                              decode(phd.id_alert_diagnosis,
                                     NULL,
                                     phd.desc_pat_history_diagnosis,
                                     phd.desc_pat_history_diagnosis || ' - ' ||
                                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                i_id_diagnosis       => d.id_diagnosis,
                                                                i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                               i_flg_type => phd.flg_type),
                                                                i_code               => d.code_icd,
                                                                i_flg_other          => d.flg_other,
                                                                i_flg_std_diag       => ad.flg_icd9))) desc_probl,
                       phd.id_location id_location,
                       nvl2(phd.id_location,
                            pk_diagnosis.std_diag_desc(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_id_diagnosis          => pk_diagnosis_core.get_term_diagnosis_id(phd.id_location,
                                                                                                                          i_prof.institution,
                                                                                                                          i_prof.software),
                                                       i_id_alert_diagnosis    => phd.id_location,
                                                       i_code                  => pk_diagnosis_core.get_term_diagnosis_code(phd.id_location,
                                                                                                                            i_prof.institution,
                                                                                                                            i_prof.software),
                                                       i_flg_other             => pk_alert_constant.g_no,
                                                       i_flg_std_diag          => pk_alert_constant.g_yes,
                                                       i_epis_diag             => NULL,
                                                       i_show_aditional_info   => pk_alert_constant.g_no,
                                                       i_flg_show_ae_diag_info => pk_alert_constant.g_no),
                            '') desc_location,
                       decode(phd.id_alert_diagnosis, NULL, l_problems_m001, l_problems_m004) title,
                       decode(phd.id_alert_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh) flg_source,
                       pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_order,
                       phd.flg_status,
                       pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', phd.flg_status) rank_type,
                       decode(phd.flg_status, g_cancelled, 1, 0) rank_cancelled,
                       pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', phd.flg_area) rank_area,
                       decode(phd.flg_status, 'C', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel,
                       pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                       pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                       pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', phd.flg_status) rank_status,
                       nvl(pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_NATURE', phd.flg_nature), -1) rank_nature,
                       phd.flg_nature,
                       phd.notes notes,
                       phd.id_pat_history_diagnosis id_prob,
                       pk_problems.get_pat_precaution_list_cod(i_lang, i_prof, i_id_problem) id_precaution_measures,
                       pk_problems.get_pat_precaution_list_desc(i_lang, i_prof, i_id_problem) precaution_measures_str,
                       phd.flg_warning header_warning,
                       pk_sysdomain.get_domain(pk_list.g_yes_no, phd.flg_warning, i_lang) header_warning_str,
                       pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_date      => phd.dt_resolved,
                                                               i_precision => phd.dt_resolved_precision) resolution_date_str,
                       decode(phd.dt_resolved_precision,
                              g_unknown,
                              g_unknown,
                              pk_date_utils.date_send_tsz(i_lang, phd.dt_resolved, i_prof)) resolution_date,
                       phd.dt_resolved_precision resolution_precision,
                       get_flg_area(i_flg_area => phd.flg_area, i_flg_type => phd.flg_type) flg_area,
                       pk_sysdomain.get_domain(i_code_dom => g_area_sys_domain,
                                               i_val      => get_flg_area(i_flg_area => phd.flg_area,
                                                                          i_flg_type => phd.flg_type),
                                               i_lang     => i_lang) flg_area_desc,
                       phd.flg_compl complications,
                       pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) complications_desc,
                       get_prob_group(ep.id_episode, ep.id_epis_prob_group) prob_group,
                       ep.rank seq_num,
                       get_max_prob_group_internal(i_lang, i_prof, ep.id_episode) max_group
                  FROM pat_history_diagnosis phd, diagnosis d, alert_diagnosis ad, epis_prob ep
                 WHERE phd.id_patient = i_pat
                   AND phd.id_pat_history_diagnosis = i_id_problem
                   AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                   AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                   AND phd.id_episode = ep.id_episode(+)
                   AND phd.id_pat_history_diagnosis = ep.id_problem(+)
                   AND (ep.flg_type IS NULL OR (ep.flg_type IS NOT NULL AND ep.flg_type = 'D'))
                      -- ALERT-736 synonyms diagnosis
                   AND phd.id_diagnosis = d.id_diagnosis(+);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_INFO');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                --open cursors
                pk_types.open_my_cursor(o_pat_problem);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END get_pat_problem_info;

    FUNCTION cancel_pat_problem
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN pat_problem.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_problem       IN NUMBER,
        i_type             IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_type             OUT table_varchar,
        o_ids              OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat_prob_unaware pat_prob_unaware.id_pat_prob_unaware%TYPE;
    BEGIN
    
        IF i_id_problem IS NULL
           AND i_type IS NULL
        THEN
            IF NOT cancel_pat_prob_unaware_nc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_patient          => i_pat,
                                              i_id_episode          => i_id_episode,
                                              i_notes               => NULL,
                                              i_id_cancel_reason    => i_id_cancel_reason,
                                              i_cancel_notes        => i_cancel_notes,
                                              i_flg_status          => table_varchar(g_active),
                                              o_id_pat_prob_unaware => l_id_pat_prob_unaware,
                                              o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT cancel_pat_problem_nc(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_pat              => i_pat,
                                         i_id_episode       => i_id_episode,
                                         i_id_problem       => i_id_problem,
                                         i_type             => i_type,
                                         i_id_cancel_reason => i_id_cancel_reason,
                                         i_cancel_notes     => i_cancel_notes,
                                         i_prof_cat_type    => i_prof_cat_type,
                                         i_dt_register      => current_timestamp,
                                         o_type             => o_type,
                                         o_ids              => o_ids,
                                         o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'CANCEL_PAT_PROBLEM',
                                              o_error);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            -- undo changes quando aplic?l-> s?z ROLLBACK 
            pk_utils.undo_changes;
            -- return failure   
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'CANCEL_PAT_PROBLEM');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END cancel_pat_problem;

    FUNCTION cancel_pat_problem_nc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN pat_problem.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_problem       IN NUMBER,
        i_type             IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_dt_register      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_type             OUT table_varchar,
        o_ids              OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_seq_phd          table_number := table_number();
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
        v_pat_allergy_hist pat_allergy_hist%ROWTYPE;
    
        --ID da epis_diagnosis
        l_epis_diagnosis pat_problem.id_epis_diagnosis%TYPE;
        --ID do diagn?co
        l_diagnosis pat_problem.id_diagnosis%TYPE;
    
        l_id_habit          pat_problem.id_habit%TYPE;
        l_id_epis_diagnosis pat_problem.id_epis_diagnosis%TYPE;
        l_id_epis_anamnesis pat_problem.id_epis_anamnesis%TYPE;
    
        l_ret BOOLEAN;
    
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   flg_nature,
                   id_diagnosis,
                   id_cancel_reason,
                   cancel_notes,
                   dt_resolution
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    
        CURSOR c_allergy IS
            SELECT pa.notes, pa.flg_nature, pa.year_begin
              FROM pat_allergy pa
             WHERE pa.id_pat_allergy = i_id_problem;
    
        CURSOR c_epis_prob IS
            SELECT ep.id_problem, ep.id_epis_prob_group, ep.rank seq_num
              FROM epis_prob ep
             WHERE ep.id_problem = i_id_problem
               AND ep.id_episode = i_id_episode;
    
        --procura o diagn?co correspondente
        CURSOR c_epis_d(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT pp.id_epis_diagnosis, pp.id_diagnosis
              FROM pat_problem pp
             WHERE pp.id_pat_problem = l_id;
    
        l_id_alert_diagnosis          table_number;
        l_dt_pat_history_diagnosis_tz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_desc_phd                    VARCHAR2(2000);
        l_desc_phd_arr                table_varchar;
    
        l_flg_nature     pat_problem.flg_nature%TYPE;
        l_notes          pat_problem.notes%TYPE;
        l_notes_arr      table_varchar;
        l_flg_nature_arr table_varchar;
    
        l_flg_status_arr    table_varchar;
        l_cancel_reason_arr table_number;
    
        l_id_alert_diagnosis_num     pat_history_diagnosis.id_alert_diagnosis%TYPE;
        l_desc_pat_history_diagnosis pat_history_diagnosis.desc_pat_history_diagnosis%TYPE;
    
        CURSOR c_pp IS
            SELECT id_habit, id_epis_diagnosis, id_epis_anamnesis
              FROM pat_problem
             WHERE id_pat_problem = i_id_problem;
    
        CURSOR c_dt_phd IS
            SELECT phd.dt_pat_history_diagnosis_tstz,
                   phd.desc_pat_history_diagnosis,
                   phd.id_alert_diagnosis,
                   phd.desc_pat_history_diagnosis,
                   phd.notes,
                   phd.flg_nature,
                   phd.id_diagnosis
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_problem; -- only changes a phd at once
    
        l_rowids     table_varchar;
        l_rowids_aux table_varchar;
    
        l_notes_aux pat_problem.notes%TYPE;
    
        l_rec_diag        pk_edis_types.rec_in_diagnosis;
        l_rec_epis_diag   pk_edis_types.rec_in_epis_diagnoses;
        l_diag_out_params pk_edis_types.table_out_epis_diags;
        l_flg_area        pat_history_diagnosis.flg_area%TYPE;
        l_id_diagnosis    pat_history_diagnosis.id_diagnosis%TYPE;
        l_rowids2         table_varchar;
    
        l_id_problem         NUMBER(24);
        l_prob_group         NUMBER(24);
        l_id_epis_prob_group NUMBER(24); --CEMR-6
        l_seq_num            NUMBER(24);
    
        l_has_group sys_config.value%TYPE := pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof);
    BEGIN
        g_sysdate_tstz := nvl(i_dt_register, current_timestamp);
    
        g_error            := 'GET TYPE / STATUS';
        v_pat_problem_hist := NULL;
    
        -- get the problem details (just to check if it's a habit)
        g_error := 'GET L_ID_DIAGNOSIS';
        OPEN c_pp;
        FETCH c_pp
            INTO l_id_habit, l_id_epis_diagnosis, l_id_epis_anamnesis;
        CLOSE c_pp;
    
        g_error := 'IF ALLERGIES/HABITS..';
        IF i_type = g_pat_prob_allrg
           OR (i_type = g_pat_prob_prob AND
           (l_id_habit IS NOT NULL OR l_id_epis_diagnosis IS NOT NULL OR l_id_epis_anamnesis IS NOT NULL))
        THEN
            IF i_type = g_pat_prob_allrg
            THEN
            
                OPEN c_allergy;
                FETCH c_allergy
                    INTO v_pat_allergy_hist.notes, v_pat_allergy_hist.flg_nature, v_pat_allergy_hist.year_begin;
                g_found := c_allergy%NOTFOUND;
                CLOSE c_allergy;
            
                g_error := 'CANCEL PAT ALLERGY';
                IF (NOT pk_allergy.cancel_allergy(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_pat_allergy   => i_id_problem,
                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                  i_cancel_notes     => i_cancel_notes,
                                                  o_error            => o_error))
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSIF i_type = g_pat_prob_prob
            THEN
                g_error := 'OPEN CURSOR C_PROB';
                OPEN c_prob(i_id_problem);
                FETCH c_prob
                    INTO v_pat_problem_hist.id_pat_problem,
                         v_pat_problem_hist.id_patient,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_alert_diagnosis,
                         v_pat_problem_hist.id_professional_ins,
                         v_pat_problem_hist.dt_pat_problem_tstz,
                         v_pat_problem_hist.desc_pat_problem,
                         v_pat_problem_hist.notes,
                         v_pat_problem_hist.flg_age,
                         v_pat_problem_hist.year_begin,
                         v_pat_problem_hist.month_begin,
                         v_pat_problem_hist.day_begin,
                         v_pat_problem_hist.year_end,
                         v_pat_problem_hist.month_end,
                         v_pat_problem_hist.day_end,
                         v_pat_problem_hist.pct_incapacity,
                         v_pat_problem_hist.flg_surgery,
                         v_pat_problem_hist.notes_support,
                         v_pat_problem_hist.dt_confirm_tstz,
                         v_pat_problem_hist.rank,
                         v_pat_problem_hist.flg_status,
                         v_pat_problem_hist.id_epis_diagnosis,
                         v_pat_problem_hist.flg_aproved,
                         v_pat_problem_hist.id_institution,
                         v_pat_problem_hist.id_pat_habit,
                         v_pat_problem_hist.id_episode,
                         v_pat_problem_hist.id_epis_anamnesis,
                         v_pat_problem_hist.flg_nature,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_cancel_reason,
                         v_pat_problem_hist.cancel_notes,
                         v_pat_problem_hist.dt_resolution;
                g_found := c_prob%NOTFOUND;
                CLOSE c_prob;
            
                IF v_pat_problem_hist.id_pat_habit IS NOT NULL
                   OR v_pat_problem_hist.id_diagnosis IS NOT NULL
                THEN
                    ts_pat_problem_hist.ins(id_pat_problem_hist_in => ts_pat_problem_hist.next_key,
                                            id_pat_problem_in      => v_pat_problem_hist.id_pat_problem,
                                            id_patient_in          => v_pat_problem_hist.id_patient,
                                            id_diagnosis_in        => v_pat_problem_hist.id_diagnosis,
                                            id_professional_ins_in => v_pat_problem_hist.id_professional_ins,
                                            dt_pat_problem_tstz_in => v_pat_problem_hist.dt_pat_problem_tstz,
                                            desc_pat_problem_in    => v_pat_problem_hist.desc_pat_problem,
                                            notes_in               => v_pat_problem_hist.notes,
                                            flg_age_in             => v_pat_problem_hist.flg_age,
                                            year_begin_in          => v_pat_problem_hist.year_begin,
                                            month_begin_in         => v_pat_problem_hist.month_begin,
                                            day_begin_in           => v_pat_problem_hist.day_begin,
                                            year_end_in            => v_pat_problem_hist.year_end,
                                            month_end_in           => v_pat_problem_hist.month_end,
                                            day_end_in             => v_pat_problem_hist.day_end,
                                            pct_incapacity_in      => v_pat_problem_hist.pct_incapacity,
                                            flg_surgery_in         => v_pat_problem_hist.flg_surgery,
                                            notes_support_in       => v_pat_problem_hist.notes_support,
                                            dt_confirm_tstz_in     => v_pat_problem_hist.dt_confirm_tstz,
                                            rank_in                => v_pat_problem_hist.rank,
                                            flg_status_in          => v_pat_problem_hist.flg_status,
                                            id_epis_diagnosis_in   => v_pat_problem_hist.id_epis_diagnosis,
                                            flg_aproved_in         => v_pat_problem_hist.flg_aproved,
                                            id_institution_in      => v_pat_problem_hist.id_institution,
                                            id_pat_habit_in        => v_pat_problem_hist.id_pat_habit,
                                            id_episode_in          => v_pat_problem_hist.id_episode,
                                            id_epis_anamnesis_in   => v_pat_problem_hist.id_epis_anamnesis,
                                            flg_nature_in          => v_pat_problem_hist.flg_nature,
                                            id_alert_diagnosis_in  => v_pat_problem_hist.id_alert_diagnosis,
                                            id_cancel_reason_in    => v_pat_problem_hist.id_cancel_reason,
                                            cancel_notes_in        => v_pat_problem_hist.cancel_notes,
                                            dt_resolution_in       => v_pat_problem_hist.dt_resolution,
                                            rows_out               => l_rowids);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_PROBLEM_HIST',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                END IF;
            
                g_error := 'UPDATE PAT_PROBLEM';
                SELECT notes
                  INTO l_notes_aux
                  FROM pat_problem
                 WHERE id_pat_problem = i_id_problem;
            
                ts_pat_problem.upd(id_pat_problem_in       => i_id_problem,
                                   flg_status_in           => g_cancelled,
                                   dt_pat_problem_tstz_in  => g_sysdate_tstz,
                                   dt_pat_problem_tstz_nin => FALSE,
                                   id_professional_ins_in  => i_prof.id,
                                   id_professional_ins_nin => FALSE,
                                   id_institution_in       => i_prof.institution,
                                   id_institution_nin      => FALSE,
                                   notes_in                => v_pat_problem_hist.notes,
                                   notes_nin               => FALSE,
                                   id_episode_in           => i_id_episode,
                                   id_episode_nin          => FALSE,
                                   flg_nature_in           => v_pat_problem_hist.flg_nature,
                                   flg_nature_nin          => FALSE,
                                   id_cancel_reason_in     => i_id_cancel_reason,
                                   cancel_notes_in         => i_cancel_notes,
                                   cancel_notes_nin        => FALSE,
                                   rows_out                => l_rowids_aux);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids_aux,
                                              o_error      => o_error);
            
                IF v_pat_problem_hist.id_pat_habit IS NOT NULL
                THEN
                    g_error := 'PAT_HABIT P';
                    pk_alertlog.log_debug(g_error);
                    l_rowids_aux := table_varchar();
                    ts_pat_habit.upd(id_pat_habit_in   => v_pat_problem_hist.id_pat_habit,
                                     flg_status_in     => g_cancelled,
                                     dt_cancel_tstz_in => g_sysdate_tstz,
                                     id_prof_cancel_in => i_prof.id,
                                     note_cancel_in    => i_cancel_notes,
                                     id_episode_in     => i_id_episode,
                                     rows_out          => l_rowids_aux);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HABIT',
                                                  i_rowids     => l_rowids_aux,
                                                  o_error      => o_error);
                END IF;
            
                --get epis_diagnosys
                g_error := 'OPEN EPIS_DIAGNOSIS';
                OPEN c_epis_d(i_id_problem);
                FETCH c_epis_d
                    INTO l_epis_diagnosis, l_diagnosis;
                CLOSE c_epis_d;
            
                IF l_epis_diagnosis IS NOT NULL
                THEN
                    g_error                 := 'CALL TO PK_DIAGNOSIS.SET_EPIS_DIAG_STATUS';
                    l_rec_diag.flg_status   := g_cancelled;
                    l_rec_diag.id_diagnosis := l_diagnosis;
                
                    l_rec_epis_diag.epis_diagnosis.id_episode        := i_id_episode;
                    l_rec_epis_diag.epis_diagnosis.id_epis_diagnosis := l_epis_diagnosis;
                    l_rec_epis_diag.epis_diagnosis.cancel_notes      := i_cancel_notes;
                    l_rec_epis_diag.epis_diagnosis.id_cancel_reason  := i_id_cancel_reason;
                    l_rec_epis_diag.epis_diagnosis.flg_type          := i_type;
                    l_rec_epis_diag.epis_diagnosis.tbl_diagnosis     := pk_edis_types.table_in_diagnosis(l_rec_diag);
                
                    g_error := 'CALL SET_EPIS_DIAGNOSIS';
                    IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_epis_diagnoses => l_rec_epis_diag,
                                                           o_params         => l_diag_out_params,
                                                           o_error          => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
        
            o_ids := table_number();
            o_ids.extend(1);
            o_ids(1) := i_id_problem;
        
            o_type := table_varchar();
            o_type.extend(1);
            o_type(1) := i_type;
        
        ELSE
            --PROBLEMAS E DIAGNOSTICOS
        
            -- gets the date associated with this phd
            g_error := 'GET DT_PAT_HISTORY_DIAGNOSIS';
            OPEN c_dt_phd;
            FETCH c_dt_phd
                INTO l_dt_pat_history_diagnosis_tz,
                     l_desc_phd,
                     l_id_alert_diagnosis_num,
                     l_desc_pat_history_diagnosis,
                     l_notes,
                     l_flg_nature,
                     l_id_diagnosis;
            CLOSE c_dt_phd;
        
            l_desc_phd_arr := table_varchar();
            l_desc_phd_arr.extend;
            l_desc_phd_arr(1) := l_desc_phd;
        
            IF l_id_alert_diagnosis_num IS NULL
               AND l_id_diagnosis IS NOT NULL
            THEN
                l_id_alert_diagnosis_num := pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => l_id_diagnosis,
                                                                                               i_task_type       => pk_alert_constant.g_task_problems);
                IF l_id_alert_diagnosis_num IS NOT NULL
                THEN
                    ts_pat_history_diagnosis.upd(id_pat_history_diagnosis_in => i_id_problem,
                                                 id_alert_diagnosis_in       => l_id_alert_diagnosis_num,
                                                 rows_out                    => l_rowids2);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                  i_rowids     => l_rowids2,
                                                  o_error      => o_error);
                END IF;
            END IF;
        
            l_id_alert_diagnosis := table_number();
            l_id_alert_diagnosis.extend;
            l_id_alert_diagnosis(1) := l_id_alert_diagnosis_num;
        
            l_notes_arr := table_varchar();
            l_notes_arr.extend;
            l_notes_arr(1) := i_cancel_notes;
        
            l_flg_nature_arr := table_varchar();
            l_flg_nature_arr.extend;
            l_flg_nature_arr(1) := l_flg_nature;
        
            l_flg_status_arr := table_varchar();
            l_flg_status_arr.extend;
            l_flg_status_arr(1) := g_cancelled;
        
            l_cancel_reason_arr := table_number();
            l_cancel_reason_arr.extend;
            l_cancel_reason_arr(1) := i_id_cancel_reason;
        
            g_error := 'GET flg_area. id_pat_history_diagnosis: ' || i_id_problem;
            pk_alertlog.log_debug(g_error);
            SELECT phd.flg_area
              INTO l_flg_area
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_problem
               AND rownum = 1;
        
            g_error := 'cancel_past_history';
            IF NOT pk_past_history.cancel_past_history(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_doc_area              => 45,
                                                       i_id_episode            => i_id_episode,
                                                       i_id_patient            => i_pat,
                                                       i_record_id             => i_id_problem,
                                                       i_id_cancel_reason      => i_id_cancel_reason,
                                                       i_cancel_notes          => i_cancel_notes,
                                                       i_id_epis_documentation => NULL,
                                                       i_screen                => pk_alert_constant.g_diag_area_problems,
                                                       o_error                 => o_error)
            
            THEN
                RAISE g_exception;
            END IF;
        
            l_seq_phd.extend(1);
            SELECT phd.id_pat_history_diagnosis_new
              INTO l_seq_phd(1)
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_problem;
        
            o_ids  := l_seq_phd;
            o_type := table_varchar();
            FOR i IN 1 .. l_seq_phd.count
            LOOP
                o_type.extend(1);
                o_type(o_type.count) := i_type;
            END LOOP;
        
            -- BEGIN -- hammer
            g_error := 'hammer';
            pk_alertlog.log_debug(g_error);
        
            UPDATE pat_history_diagnosis phd
               SET phd.flg_recent_diag = 'Y', phd.id_pat_history_diagnosis_new = NULL
             WHERE phd.id_pat_history_diagnosis = (SELECT phd.id_pat_history_diagnosis
                                                     FROM pat_history_diagnosis phd
                                                    WHERE phd.id_pat_history_diagnosis_new IN
                                                          (SELECT phd.id_pat_history_diagnosis_new
                                                             FROM pat_history_diagnosis phd
                                                            WHERE phd.id_pat_history_diagnosis = i_id_problem)
                                                      AND phd.id_pat_history_diagnosis != i_id_problem
                                                      AND rownum = 1);
            -- /END -- hammer
        
            g_error := 'call set_problem_history';
            IF NOT pk_problems.set_problem_history(i_lang           => i_lang,
                                                   i_pat            => i_pat,
                                                   i_prof           => i_prof,
                                                   i_id_pat_problem => i_id_problem,
                                                   o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROBLEM',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'HANDLE EPIS_PROBLEM_GROUP';
        OPEN c_epis_prob;
        FETCH c_epis_prob
            INTO l_id_problem, l_id_epis_prob_group, l_seq_num;
        g_found := c_epis_prob%NOTFOUND;
        CLOSE c_epis_prob;
    
        IF l_has_group = pk_alert_constant.g_yes
        THEN
            l_prob_group := pk_problems.get_prob_group(i_episode         => i_id_episode,
                                                       i_epis_prob_group => l_id_epis_prob_group);
        END IF;
    
        IF l_id_problem IS NOT NULL
        THEN
            IF NOT set_epis_problem_group_array(i_lang            => i_lang,
                                                i_episode         => i_id_episode,
                                                i_prof            => i_prof,
                                                i_id_problem      => o_ids,
                                                i_prev_id_problem => table_number(l_id_problem),
                                                i_flg_status      => table_varchar(g_cancelled),
                                                i_prob_group      => table_number(l_prob_group),
                                                i_seq_num         => table_number(l_seq_num),
                                                i_flg_type        => o_type,
                                                o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'cancel_pat_problem_nc',
                                              o_error);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            -- return failure   
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'cancel_pat_problem_nc');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END cancel_pat_problem_nc;

    FUNCTION get_pat_problem_epis_stat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        
        o_problem_allergy OUT NOCOPY pk_types.cursor_type,
        o_problem_habit   OUT NOCOPY pk_types.cursor_type,
        o_problem_relev   OUT NOCOPY pk_types.cursor_type,
        o_problem_diag    OUT NOCOPY pk_types.cursor_type,
        o_problem_problem OUT NOCOPY pk_types.cursor_type,
        
        o_new_problem    OUT VARCHAR2,
        o_edited_problem OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        dataset1 pk_types.cursor_type;
        dataset2 pk_types.cursor_type;
    
        l_problem_list      t_coll_epis_problem;
        l_problem_list_hist t_coll_epis_problem;
    
        l_problem_list_all t_coll_epis_problem_list;
    
        l_problem_list_edition problem_rec_status_edition;
    
        --Messages used
        l_msg_unknown sys_message.desc_message%TYPE;
    
        --Patient ID
        l_id_patient episode.id_patient%TYPE;
    
        l_show_allergy         sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_ALLERGY_IN_PROBLEM', i_prof);
        l_show_habit           sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_HABIT_IN_PROBLEM', i_prof);
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    BEGIN
    
        --Get the sys_messages
        g_error       := 'GET MESSAGES';
        l_msg_unknown := pk_message.get_message(i_lang, i_prof, 'PROBLEMS_T015');
    
        --Get the patient ID
        g_error := 'GET ID_PATIENT';
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        -------------------
        -- Alergies
        -------------------
        g_error := 'OPEN DATASET 1';
        OPEN dataset1 FOR
            SELECT t_rec_epis_problem(pa.id_pat_allergy,
                                      'A',
                                      NULL,
                                      pa.id_episode,
                                      pk_translation.get_translation(i_lang, a.code_allergy),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof),
                                      pa.flg_status,
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  pa.dt_pat_allergy_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                      to_char(pa.year_begin),
                                      to_char(pa.year_begin))
              FROM pat_allergy pa
              JOIN professional p
                ON p.id_professional = pa.id_prof_write
              JOIN allergy a
                ON a.id_allergy = pa.id_allergy
             WHERE pa.id_episode = i_id_episode
               AND pa.flg_status != g_cancelled
               AND nvl(instr(a.flg_without, pk_alert_constant.g_yes), 0) <> 1
               AND l_show_allergy = pk_alert_constant.g_yes
            UNION ALL
            SELECT t_rec_epis_problem(pah.id_pat_allergy,
                                      'A',
                                      NULL,
                                      pah.id_episode,
                                      pk_translation.get_translation(i_lang, a.code_allergy),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pah.dt_pat_allergy_tstz, i_prof),
                                      pah.flg_status,
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  pah.dt_pat_allergy_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                      to_char(pah.year_begin),
                                      to_char(pah.year_begin))
              FROM pat_allergy_hist pah
              JOIN professional p
                ON p.id_professional = pah.id_prof_write
              JOIN allergy a
                ON a.id_allergy = pah.id_allergy
             WHERE pah.id_episode = i_id_episode
               AND nvl(instr(a.flg_without, pk_alert_constant.g_yes), 0) <> 1
               AND pah.id_pat_allergy_hist IN
                   (SELECT MAX(pa2.id_pat_allergy_hist)
                      FROM pat_allergy_hist pa2
                     WHERE pa2.id_episode = i_id_episode
                       AND pa2.id_pat_allergy = pah.id_pat_allergy)
               AND NOT EXISTS (SELECT 'X'
                      FROM pat_allergy pa3
                     WHERE pa3.id_episode = i_id_episode
                       AND pa3.id_allergy = pah.id_allergy
                       AND pa3.flg_status != g_cancelled
                       AND nvl(instr(a.flg_without, pk_alert_constant.g_yes), 0) <> 1)
               AND l_show_allergy = pk_alert_constant.g_yes;
    
        g_error := 'FETCH FROM RESULTS CURSOR 1';
        FETCH dataset1 BULK COLLECT
            INTO l_problem_list;
        CLOSE dataset1;
    
        g_error := 'OPEN DATASET 2';
        OPEN dataset2 FOR
            SELECT t_rec_epis_problem(pa.id_pat_allergy,
                                      'A',
                                      NULL,
                                      pa.id_episode,
                                      pk_translation.get_translation(i_lang, a.code_allergy),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof),
                                      pa.flg_status,
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  pa.dt_pat_allergy_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                      to_char(pa.year_begin),
                                      to_char(pa.year_begin))
              FROM pat_allergy_hist pa
              JOIN professional p
                ON p.id_professional = pa.id_prof_write
              JOIN allergy a
                ON a.id_allergy = pa.id_allergy
             WHERE nvl(instr(a.flg_without, pk_alert_constant.g_yes), 0) <> 1
               AND pa.id_pat_allergy IN (SELECT pa2.id_pat_allergy
                                           FROM pat_allergy_hist pa2
                                          WHERE pa2.id_episode = i_id_episode
                                            AND pa2.id_pat_allergy = pa.id_pat_allergy)
               AND l_show_allergy = pk_alert_constant.g_yes
             ORDER BY pa.dt_pat_allergy_tstz DESC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 2';
        FETCH dataset2 BULK COLLECT
            INTO l_problem_list_hist;
        CLOSE dataset2;
    
        l_problem_list_edition := tf_pat_problem_epis_stat(i_lang, i_id_episode, l_problem_list, l_problem_list_hist);
    
        --Process the array in order to have a new array with the state transitions
        l_problem_list_all := l_problem_list_edition.problem_status_list;
        o_new_problem := CASE
                             WHEN o_new_problem = pk_alert_constant.g_no
                                  OR o_new_problem IS NULL THEN
                              l_problem_list_edition.new_problem
                             ELSE
                              pk_alert_constant.g_yes
                         END;
        o_edited_problem := CASE
                                WHEN o_edited_problem = pk_alert_constant.g_no
                                     OR o_edited_problem IS NULL THEN
                                 l_problem_list_edition.edit_problem
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
    
        OPEN o_problem_allergy FOR
            SELECT *
              FROM TABLE(l_problem_list_all);
    
        -------------------
        -- Habits
        -------------------   
        g_error := 'OPEN DATASET 3';
        OPEN dataset1 FOR
            SELECT t_rec_epis_problem(pp.id_pat_problem,
                                      'P',
                                      pp.id_diagnosis,
                                      pp.id_episode,
                                      pk_translation.get_translation(i_lang, h.code_habit),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof),
                                      pp.flg_status,
                                      NULL,
                                      NULL, --dt_problem
                                      decode(decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof)))),
                                             '',
                                             lower(l_msg_unknown),
                                             decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof))))))
              FROM pat_problem pp, professional p, habit h
             WHERE pp.id_episode = i_id_episode
               AND pp.id_professional_ins = p.id_professional(+)
               AND pp.id_habit = h.id_habit
               AND pp.flg_status != g_cancelled
               AND l_show_habit = pk_alert_constant.g_yes
            UNION ALL
            SELECT t_rec_epis_problem(pph.id_pat_problem,
                                      'P',
                                      pph.id_diagnosis,
                                      pph.id_episode,
                                      pk_translation.get_translation(i_lang, h.code_habit),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pph.dt_pat_problem_tstz, i_prof),
                                      pph.flg_status,
                                      NULL,
                                      NULL, --dt_problem
                                      decode(decode(pph.year_begin,
                                                    '',
                                                    '',
                                                    decode(pph.month_begin,
                                                           '',
                                                           to_char(pph.year_begin),
                                                           decode(pph.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pph.year_begin ||
                                                                                                       lpad(pph.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pph.year_begin ||
                                                                                               lpad(pph.month_begin, 2, '0') ||
                                                                                               lpad(pph.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof)))),
                                             '',
                                             lower(l_msg_unknown),
                                             decode(pph.year_begin,
                                                    '',
                                                    '',
                                                    decode(pph.month_begin,
                                                           '',
                                                           to_char(pph.year_begin),
                                                           decode(pph.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pph.year_begin ||
                                                                                                       lpad(pph.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pph.year_begin ||
                                                                                               lpad(pph.month_begin, 2, '0') ||
                                                                                               lpad(pph.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof))))))
              FROM pat_problem_hist pph, professional p, habit h
             WHERE pph.id_professional_ins = p.id_professional(+)
               AND pph.id_pat_habit = h.id_habit(+)
               AND pph.id_episode = i_id_episode
               AND pph.id_pat_problem_hist IN (SELECT MAX(pa2.id_pat_problem_hist)
                                                 FROM pat_problem_hist pa2
                                                WHERE pa2.id_episode = i_id_episode
                                                  AND pa2.id_pat_habit = pph.id_pat_habit)
               AND NOT EXISTS (SELECT 'X'
                      FROM pat_problem pp3
                     WHERE pp3.id_episode = i_id_episode
                       AND pp3.id_pat_habit = pph.id_pat_habit
                       AND pp3.flg_status != g_cancelled)
               AND l_show_habit = pk_alert_constant.g_yes;
    
        g_error := 'FETCH FROM RESULTS CURSOR 3';
        FETCH dataset1 BULK COLLECT
            INTO l_problem_list;
        CLOSE dataset1;
    
        g_error := 'OPEN DATASET 4';
        OPEN dataset2 FOR
            SELECT t_rec_epis_problem(pp.id_pat_problem,
                                      'P',
                                      pp.id_diagnosis,
                                      pp.id_episode,
                                      pk_translation.get_translation(i_lang, h.code_habit),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof),
                                      pp.flg_status,
                                      NULL,
                                      NULL, --dt_problem
                                      decode(decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof)))),
                                             '',
                                             lower(l_msg_unknown),
                                             decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof))))))
              FROM pat_problem_hist pp, professional p, habit h
             WHERE pp.id_professional_ins = p.id_professional(+)
               AND pp.id_pat_habit = h.id_habit(+)
               AND pp.id_pat_problem IN (SELECT pp2.id_pat_problem
                                           FROM pat_problem_hist pp2
                                          WHERE pp2.id_episode = i_id_episode
                                            AND pp2.id_pat_problem = pp.id_pat_problem)
               AND l_show_habit = pk_alert_constant.g_yes
             ORDER BY pp.dt_pat_problem_tstz DESC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 3';
        FETCH dataset2 BULK COLLECT
            INTO l_problem_list_hist;
        CLOSE dataset2;
    
        l_problem_list_edition := tf_pat_problem_epis_stat(i_lang, i_id_episode, l_problem_list, l_problem_list_hist);
    
        --Process the array in order to have a new array with the state transitions
        l_problem_list_all := l_problem_list_edition.problem_status_list;
        o_new_problem := CASE
                             WHEN o_new_problem = pk_alert_constant.g_no
                                  OR o_new_problem IS NULL THEN
                              l_problem_list_edition.new_problem
                             ELSE
                              pk_alert_constant.g_yes
                         END;
        o_edited_problem := CASE
                                WHEN o_edited_problem = pk_alert_constant.g_no
                                     OR o_edited_problem IS NULL THEN
                                 l_problem_list_edition.edit_problem
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
    
        OPEN o_problem_habit FOR
            SELECT *
              FROM TABLE(l_problem_list_all);
    
        -------------------
        -- DIAGNOSIS
        -------------------   
        g_error := 'OPEN DATASET 3';
        OPEN dataset1 FOR
            SELECT t_rec_epis_problem(pp.id_pat_problem,
                                      decode(ed.flg_type, pk_diagnosis.g_diag_type_d, 'DF', 'DD'),
                                      pp.id_epis_diagnosis,
                                      pp.id_episode,
                                      decode(nvl(ed.id_epis_diagnosis, 0),
                                             0,
                                             pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                        i_id_diagnosis       => d.id_diagnosis,
                                                                        i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                        i_code               => d.code_icd,
                                                                        i_flg_other          => d.flg_other,
                                                                        i_flg_std_diag       => ad.flg_icd9),
                                             pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                        i_id_diagnosis        => d1.id_diagnosis,
                                                                        i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                        i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                        i_code                => d1.code_icd,
                                                                        i_flg_other           => d1.flg_other,
                                                                        i_flg_std_diag        => ad1.flg_icd9,
                                                                        i_epis_diag           => ed.id_epis_diagnosis)),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof),
                                      pp.flg_status,
                                      NULL,
                                      NULL, --dt_problem
                                      decode(decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof)))),
                                             '',
                                             lower(l_msg_unknown),
                                             decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof))))))
              FROM pat_problem     pp,
                   diagnosis       d,
                   alert_diagnosis ad,
                   professional    p,
                   epis_diagnosis  ed,
                   diagnosis       d1,
                   alert_diagnosis ad1
             WHERE pp.id_episode = i_id_episode
               AND pp.id_diagnosis = d.id_diagnosis(+)
               AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pp.id_professional_ins = p.id_professional(+)
               AND pp.flg_status NOT IN (g_cancelled, g_pat_probl_invest)
               AND d1.id_diagnosis(+) = ed.id_diagnosis
               AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                  -- RdSN To exclude relev.diseases and problems
               AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
               AND ( --final diagnosis 
                    (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                    OR -- differencial diagnosis only 
                    (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                    ed.id_diagnosis NOT IN (SELECT ed3.id_diagnosis
                                               FROM epis_diagnosis ed3
                                              WHERE ed3.id_diagnosis = ed.id_diagnosis
                                                AND ed3.id_patient = pp.id_episode
                                                AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
            UNION ALL
            SELECT t_rec_epis_problem(pph.id_pat_problem,
                                      decode(ed.flg_type, pk_diagnosis.g_diag_type_d, 'DF', 'DD'),
                                      pph.id_epis_diagnosis,
                                      pph.id_episode,
                                      decode(nvl(ed.id_epis_diagnosis, 0),
                                             0,
                                             pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                        i_id_diagnosis       => d.id_diagnosis,
                                                                        i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                        i_code               => d.code_icd,
                                                                        i_flg_other          => d.flg_other,
                                                                        i_flg_std_diag       => ad.flg_icd9),
                                             pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                        i_id_diagnosis        => d1.id_diagnosis,
                                                                        i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                        i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                        i_code                => d1.code_icd,
                                                                        i_flg_other           => d1.flg_other,
                                                                        i_flg_std_diag        => ad1.flg_icd9,
                                                                        i_epis_diag           => ed.id_epis_diagnosis)),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pph.dt_pat_problem_tstz, i_prof),
                                      pph.flg_status,
                                      NULL,
                                      NULL, --dt_problem
                                      decode(decode(pph.year_begin,
                                                    '',
                                                    '',
                                                    decode(pph.month_begin,
                                                           '',
                                                           to_char(pph.year_begin),
                                                           decode(pph.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pph.year_begin ||
                                                                                                       lpad(pph.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pph.year_begin ||
                                                                                               lpad(pph.month_begin, 2, '0') ||
                                                                                               lpad(pph.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof)))),
                                             '',
                                             lower(l_msg_unknown),
                                             decode(pph.year_begin,
                                                    '',
                                                    '',
                                                    decode(pph.month_begin,
                                                           '',
                                                           to_char(pph.year_begin),
                                                           decode(pph.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pph.year_begin ||
                                                                                                       lpad(pph.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pph.year_begin ||
                                                                                               lpad(pph.month_begin, 2, '0') ||
                                                                                               lpad(pph.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof))))))
              FROM pat_problem_hist pph,
                   diagnosis        d,
                   alert_diagnosis  ad,
                   professional     p,
                   epis_diagnosis   ed,
                   diagnosis        d1,
                   alert_diagnosis  ad1
             WHERE pph.id_diagnosis = d.id_diagnosis(+)
               AND pph.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pph.id_professional_ins = p.id_professional(+)
               AND d1.id_diagnosis(+) = ed.id_diagnosis
               AND pph.flg_status <> g_pat_probl_invest
               AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                  -- RdSN To exclude relev.diseases and problems
               AND ed.id_epis_diagnosis = pph.id_epis_diagnosis
               AND ( --final diagnosis 
                    (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                    OR -- differencial diagnosis only 
                    (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                    ed.id_diagnosis NOT IN (SELECT ed3.id_diagnosis
                                               FROM epis_diagnosis ed3
                                              WHERE ed3.id_diagnosis = ed.id_diagnosis
                                                AND ed3.id_patient = pph.id_episode
                                                AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
               AND pph.id_pat_problem IN (SELECT pp2.id_pat_problem
                                            FROM pat_problem_hist pp2
                                           WHERE pp2.id_episode = i_id_episode
                                             AND pp2.id_pat_problem = pph.id_pat_problem)
               AND pph.id_episode = i_id_episode
               AND pph.id_pat_problem_hist IN (SELECT MAX(pa2.id_pat_problem_hist)
                                                 FROM pat_problem_hist pa2
                                                WHERE pa2.id_episode = i_id_episode
                                                  AND pa2.id_diagnosis = pph.id_diagnosis)
               AND NOT EXISTS (SELECT 'X'
                      FROM pat_problem pp3
                     WHERE pp3.id_episode = i_id_episode
                       AND pp3.id_diagnosis = pph.id_diagnosis
                       AND pp3.flg_status != g_cancelled);
    
        g_error := 'FETCH FROM RESULTS CURSOR 3';
        FETCH dataset1 BULK COLLECT
            INTO l_problem_list;
        CLOSE dataset1;
    
        g_error := 'OPEN DATASET 4';
        OPEN dataset2 FOR
            SELECT t_rec_epis_problem(pp.id_pat_problem,
                                      decode(ed.flg_type, pk_diagnosis.g_diag_type_d, 'DF', 'DD'),
                                      pp.id_epis_diagnosis,
                                      pp.id_episode,
                                      decode(nvl(ed.id_epis_diagnosis, 0),
                                             0,
                                             pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                        i_id_diagnosis       => d.id_diagnosis,
                                                                        i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                        i_code               => d.code_icd,
                                                                        i_flg_other          => d.flg_other,
                                                                        i_flg_std_diag       => ad.flg_icd9),
                                             pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                        i_id_diagnosis        => d1.id_diagnosis,
                                                                        i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                        i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                        i_code                => d1.code_icd,
                                                                        i_flg_other           => d1.flg_other,
                                                                        i_flg_std_diag        => ad1.flg_icd9,
                                                                        i_epis_diag           => ed.id_epis_diagnosis)),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof),
                                      pp.flg_status,
                                      NULL,
                                      NULL, --dt_problem
                                      decode(decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof)))),
                                             '',
                                             lower(l_msg_unknown),
                                             decode(pp.year_begin,
                                                    '',
                                                    '',
                                                    decode(pp.month_begin,
                                                           '',
                                                           to_char(pp.year_begin),
                                                           decode(pp.day_begin,
                                                                  '',
                                                                  pk_date_utils.get_month_year(i_lang,
                                                                                               i_prof,
                                                                                               to_date(pp.year_begin ||
                                                                                                       lpad(pp.month_begin,
                                                                                                            2,
                                                                                                            '0'),
                                                                                                       'YYYYMM')),
                                                                  pk_date_utils.dt_chr(i_lang,
                                                                                       to_date(pp.year_begin ||
                                                                                               lpad(pp.month_begin, 2, '0') ||
                                                                                               lpad(pp.day_begin, 2, '0'),
                                                                                               'YYYYMMDD'),
                                                                                       i_prof))))))
              FROM pat_problem_hist pp,
                   diagnosis        d,
                   alert_diagnosis  ad,
                   professional     p,
                   epis_diagnosis   ed,
                   diagnosis        d1,
                   alert_diagnosis  ad1
             WHERE pp.id_diagnosis = d.id_diagnosis(+)
               AND pp.flg_status <> g_pat_probl_invest
               AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pp.id_professional_ins = p.id_professional(+)
               AND d1.id_diagnosis(+) = ed.id_diagnosis
               AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                  -- RdSN To exclude relev.diseases and problems
               AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
               AND ( --final diagnosis 
                    (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                    OR -- differencial diagnosis only 
                    (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                    ed.id_diagnosis NOT IN (SELECT ed3.id_diagnosis
                                               FROM epis_diagnosis ed3
                                              WHERE ed3.id_diagnosis = ed.id_diagnosis
                                                AND ed3.id_patient = pp.id_episode
                                                AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
               AND pp.id_pat_problem IN (SELECT pp2.id_pat_problem
                                           FROM pat_problem_hist pp2
                                          WHERE pp2.id_episode = i_id_episode
                                            AND pp2.id_pat_problem = pp.id_pat_problem)
             ORDER BY pp.dt_pat_problem_tstz DESC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 3';
        FETCH dataset2 BULK COLLECT
            INTO l_problem_list_hist;
        CLOSE dataset2;
    
        l_problem_list_edition := tf_pat_problem_epis_stat(i_lang, i_id_episode, l_problem_list, l_problem_list_hist);
    
        --Process the array in order to have a new array with the state transitions
        l_problem_list_all := l_problem_list_edition.problem_status_list;
        o_new_problem := CASE
                             WHEN o_new_problem = pk_alert_constant.g_no
                                  OR o_new_problem IS NULL THEN
                              l_problem_list_edition.new_problem
                             ELSE
                              pk_alert_constant.g_yes
                         END;
        o_edited_problem := CASE
                                WHEN o_edited_problem = pk_alert_constant.g_no
                                     OR o_edited_problem IS NULL THEN
                                 l_problem_list_edition.edit_problem
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
    
        OPEN o_problem_diag FOR
            SELECT *
              FROM TABLE(l_problem_list_all);
    
        -------------------
        -- PROBLEMS
        -------------------   
        g_error := 'OPEN DATASET 5';
        OPEN dataset1 FOR
            SELECT t_rec_epis_problem(phd.desc_pat_history_diagnosis,
                                      'P',
                                      NULL,
                                      phd.id_episode,
                                      phd.desc_pat_history_diagnosis,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof),
                                      phd.flg_status,
                                      phd.dt_pat_history_diagnosis_tstz,
                                      NULL, --dt_problem
                                      pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_date      => phd.dt_diagnosed,
                                                                              i_precision => phd.dt_diagnosed_precision))
            
              FROM pat_history_diagnosis phd, professional p
             WHERE phd.id_episode = i_id_episode
               AND phd.id_professional = p.id_professional(+)
               AND phd.id_alert_diagnosis IS NULL
               AND phd.flg_status NOT IN (g_flg_status_none, g_flg_status_unk, g_cancelled)
               AND phd.id_pat_history_diagnosis IN
                   (SELECT MAX(phd2.id_pat_history_diagnosis)
                      FROM pat_history_diagnosis phd2
                     WHERE phd2.desc_pat_history_diagnosis = phd.desc_pat_history_diagnosis
                       AND phd2.id_episode = i_id_episode)
               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                   phd.flg_area IN
                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
             ORDER BY phd.dt_pat_history_diagnosis_tstz ASC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 4';
        FETCH dataset1 BULK COLLECT
            INTO l_problem_list;
        CLOSE dataset1;
    
        g_error := 'OPEN DATASET 6';
        OPEN dataset2 FOR
            SELECT t_rec_epis_problem(phd.desc_pat_history_diagnosis,
                                      'P',
                                      NULL,
                                      phd.id_episode,
                                      phd.desc_pat_history_diagnosis,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof),
                                      phd.flg_status,
                                      phd.dt_pat_history_diagnosis_tstz,
                                      NULL, --dt_problem
                                      pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_date      => phd.dt_diagnosed,
                                                                              i_precision => phd.dt_diagnosed_precision))
            
              FROM pat_history_diagnosis phd, professional p
             WHERE phd.id_professional = p.id_professional(+)
               AND phd.id_patient = l_id_patient
               AND phd.id_alert_diagnosis IS NULL
               AND phd.id_pat_history_diagnosis NOT IN
                   (SELECT MAX(phd2.id_pat_history_diagnosis)
                      FROM pat_history_diagnosis phd2
                     WHERE phd2.desc_pat_history_diagnosis = phd.desc_pat_history_diagnosis
                       AND phd2.id_episode = i_id_episode)
               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                   phd.flg_area IN
                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 5';
        FETCH dataset2 BULK COLLECT
            INTO l_problem_list_hist;
        CLOSE dataset2;
    
        l_problem_list_edition := tf_pat_problem_epis_stat(i_lang, i_id_episode, l_problem_list, l_problem_list_hist);
    
        --Process the array in order to have a new array with the state transitions
        l_problem_list_all := l_problem_list_edition.problem_status_list;
    
        dbms_output.put_line('PROB');
        dbms_output.put_line(l_problem_list_edition.new_problem);
        dbms_output.put_line(l_problem_list_edition.edit_problem);
        o_new_problem := CASE
                             WHEN o_new_problem = pk_alert_constant.g_no
                                  OR o_new_problem IS NULL THEN
                              l_problem_list_edition.new_problem
                             ELSE
                              pk_alert_constant.g_yes
                         END;
        o_edited_problem := CASE
                                WHEN o_edited_problem = pk_alert_constant.g_no
                                     OR o_edited_problem IS NULL THEN
                                 l_problem_list_edition.edit_problem
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
    
        OPEN o_problem_problem FOR
            SELECT *
              FROM TABLE(l_problem_list_all);
    
        -------------------
        -- Past History
        -------------------   
        g_error := 'OPEN DATASET 6';
        OPEN dataset1 FOR
            SELECT t_rec_epis_problem(phd.id_alert_diagnosis,
                                      'DR',
                                      NULL,
                                      phd.id_episode,
                                      decode(phd.desc_pat_history_diagnosis,
                                             NULL,
                                             pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                        i_id_diagnosis       => d.id_diagnosis,
                                                                        i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                       i_flg_type => phd.flg_type),
                                                                        i_code               => d.code_icd,
                                                                        i_flg_other          => d.flg_other,
                                                                        i_flg_std_diag       => ad.flg_icd9),
                                             decode(phd.id_alert_diagnosis,
                                                    NULL,
                                                    phd.desc_pat_history_diagnosis,
                                                    phd.desc_pat_history_diagnosis || ' - ' ||
                                                    pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                               i_prof               => i_prof,
                                                                               i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                               i_id_diagnosis       => d.id_diagnosis,
                                                                               i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                              i_flg_type => phd.flg_type),
                                                                               i_code               => d.code_icd,
                                                                               i_flg_other          => d.flg_other,
                                                                               i_flg_std_diag       => ad.flg_icd9))),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof),
                                      phd.flg_status,
                                      phd.dt_pat_history_diagnosis_tstz,
                                      NULL, --dt_problem
                                      pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_date      => phd.dt_diagnosed,
                                                                              i_precision => phd.dt_diagnosed_precision))
              FROM pat_history_diagnosis phd, professional p, diagnosis d, alert_diagnosis ad
             WHERE phd.id_episode = i_id_episode
               AND phd.id_professional = p.id_professional(+)
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis
                  -- ALERT-736 synonyms diagnosis
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_patient = l_id_patient
               AND phd.flg_type = g_flg_type_med
               AND phd.id_pat_history_diagnosis =
                   get_most_recent_phd_id(phd.id_pat_history_diagnosis, pk_alert_constant.g_diag_area_past_history)
               AND phd.flg_status != g_cancelled
               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                   phd.flg_area IN
                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
             ORDER BY phd.dt_pat_history_diagnosis_tstz ASC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 6';
        FETCH dataset1 BULK COLLECT
            INTO l_problem_list;
        CLOSE dataset1;
    
        g_error := 'OPEN DATASET 8';
        OPEN dataset2 FOR
            SELECT t_rec_epis_problem(phd.id_alert_diagnosis,
                                      'DR',
                                      NULL,
                                      phd.id_episode,
                                      decode(phd.desc_pat_history_diagnosis,
                                             NULL,
                                             pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                        i_id_diagnosis       => d.id_diagnosis,
                                                                        i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                       i_flg_type => phd.flg_type),
                                                                        i_code               => d.code_icd,
                                                                        i_flg_other          => d.flg_other,
                                                                        i_flg_std_diag       => ad.flg_icd9),
                                             decode(phd.id_alert_diagnosis,
                                                    NULL,
                                                    phd.desc_pat_history_diagnosis,
                                                    phd.desc_pat_history_diagnosis || ' - ' ||
                                                    pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                               i_prof               => i_prof,
                                                                               i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                               i_id_diagnosis       => d.id_diagnosis,
                                                                               i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                              i_flg_type => phd.flg_type),
                                                                               i_code               => d.code_icd,
                                                                               i_flg_other          => d.flg_other,
                                                                               i_flg_std_diag       => ad.flg_icd9))),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof),
                                      phd.flg_status,
                                      phd.dt_pat_history_diagnosis_tstz,
                                      NULL, --dt_problem
                                      pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_date      => phd.dt_diagnosed,
                                                                              i_precision => phd.dt_diagnosed_precision))
              FROM pat_history_diagnosis phd, professional p, diagnosis d, alert_diagnosis ad
             WHERE phd.id_professional = p.id_professional(+)
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis
                  -- ALERT-736 synonyms diagnosis
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_patient = l_id_patient
               AND phd.id_pat_history_diagnosis NOT IN
                   (SELECT MAX(phd2.id_pat_history_diagnosis)
                      FROM pat_history_diagnosis phd2
                     WHERE phd2.id_alert_diagnosis = phd.id_alert_diagnosis
                       AND phd2.id_episode = i_id_episode)
               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                   phd.flg_area IN
                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC;
    
        g_error := 'FETCH FROM RESULTS CURSOR 7';
        FETCH dataset2 BULK COLLECT
            INTO l_problem_list_hist;
        CLOSE dataset2;
    
        l_problem_list_edition := tf_pat_problem_epis_stat(i_lang, i_id_episode, l_problem_list, l_problem_list_hist);
    
        --Process the array in order to have a new array with the state transitions
        l_problem_list_all := l_problem_list_edition.problem_status_list;
        o_new_problem := CASE
                             WHEN o_new_problem = pk_alert_constant.g_no
                                  OR o_new_problem IS NULL THEN
                              l_problem_list_edition.new_problem
                             ELSE
                              pk_alert_constant.g_yes
                         END;
        o_edited_problem := CASE
                                WHEN o_edited_problem = pk_alert_constant.g_no
                                     OR o_edited_problem IS NULL THEN
                                 l_problem_list_edition.edit_problem
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
    
        OPEN o_problem_relev FOR
            SELECT *
              FROM TABLE(l_problem_list_all);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_EPIS_STAT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                --Open cursors
                pk_types.open_my_cursor(o_problem_allergy);
                pk_types.open_my_cursor(o_problem_diag);
                pk_types.open_my_cursor(o_problem_habit);
                pk_types.open_my_cursor(o_problem_problem);
                pk_types.open_my_cursor(o_problem_relev);
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION tf_pat_problem_epis_stat
    (
        i_lang              IN language.id_language%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_problem_list      IN t_coll_epis_problem,
        i_problem_list_hist IN t_coll_epis_problem
    ) RETURN problem_rec_status_edition IS
        l_problem_list_all t_coll_epis_problem_list;
    
        l_hist_found BOOLEAN;
        l_first_run  BOOLEAN;
        l_done_once  BOOLEAN;
        l_index      NUMBER := 1;
    
        --Result record
        l_result problem_rec_status_edition;
    
        --Messages used
        l_msg_since   sys_message.desc_message%TYPE;
        l_msg_actual  sys_message.desc_message%TYPE;
        l_msg_changed sys_message.desc_message%TYPE;
        l_msg_to      sys_message.desc_message%TYPE;
        l_2points     sys_message.desc_message%TYPE;
        l_break       sys_message.desc_message%TYPE;
    
        --Auxiliary variables to store temp data
        l_current_state  VARCHAR2(4000);
        l_old_state      VARCHAR2(4000);
        l_status_message VARCHAR2(4000);
    
        --Variables that will provided information if there are problems that were editet or created (overall in the episode)
        l_new_problem    VARCHAR(1) := pk_alert_constant.g_no;
        l_edited_problem VARCHAR(1) := pk_alert_constant.g_no;
    
        l_flg_prev_index NUMBER;
    BEGIN
        --Get the sys_messages
        g_error       := 'GET MESSAGES';
        l_msg_since   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEMS_T011') || ' ';
        l_msg_actual  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEMS_T012') || ' ';
        l_msg_changed := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEMS_T013') || ' ';
        l_msg_to      := ' ' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEMS_T014') || ' ';
        l_2points     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEMS_T018');
        l_break       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEMS_T019');
    
        --Init the collection
        l_problem_list_all := t_coll_epis_problem_list();
    
        FOR i IN 1 .. i_problem_list.count
        LOOP
            l_hist_found := FALSE;
            l_first_run  := TRUE;
            l_done_once  := FALSE;
        
            FOR j IN 1 .. i_problem_list_hist.count
            LOOP
                IF (i_problem_list(i).id_pat_problem = i_problem_list_hist(j).id_pat_problem)
                   AND (i_problem_list(i).type = i_problem_list_hist(j).type)
                THEN
                    IF i_problem_list(i).id_episode = i_id_episode
                        AND (i_problem_list_hist(j).id_episode = i_id_episode OR NOT l_done_once)
                    THEN
                    
                        IF i_problem_list_hist(j).id_episode <> i_id_episode
                        THEN
                            l_done_once := TRUE;
                        END IF;
                    
                        IF l_first_run
                        THEN
                            l_first_run := FALSE;
                        
                            IF i_problem_list(i).flg_status <> i_problem_list_hist(j).flg_status
                            THEN
                                l_hist_found     := TRUE;
                                l_edited_problem := pk_alert_constant.g_yes;
                                l_current_state  := lower(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                                  i_problem_list(i).flg_status,
                                                                                  i_lang));
                                l_old_state      := lower(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                                  i_problem_list_hist(j).flg_status,
                                                                                  i_lang));
                                l_status_message := i_problem_list(i)
                                                    .desc_problem || l_2points || l_msg_changed || l_old_state ||
                                                     l_msg_to || l_current_state || g_dot;
                            
                                l_problem_list_all.extend;
                                l_problem_list_all(l_index) := t_rec_epis_problem_list(id_pat_problem      => i_problem_list(i).id_pat_problem,
                                                                                       TYPE                => i_problem_list(i).type,
                                                                                       id_diagnosis        => NULL,
                                                                                       id_episode          => i_problem_list(i).id_episode,
                                                                                       problem_desc        => i_problem_list(i).desc_problem,
                                                                                       flg_status          => i_problem_list(i).flg_status,
                                                                                       dt_problem_to_print => i_problem_list(i).dt_problem_to_print,
                                                                                       nick_name           => i_problem_list(i).nick_name,
                                                                                       current_state_desc  => l_current_state,
                                                                                       old_state_desc      => l_old_state,
                                                                                       full_desc           => l_status_message);
                                l_index := l_index + 1;
                            END IF;
                        ELSE
                            IF i_problem_list_hist(j).flg_status <> i_problem_list_hist(l_flg_prev_index).flg_status
                            THEN
                                l_hist_found     := TRUE;
                                l_edited_problem := pk_alert_constant.g_yes;
                                l_current_state  := lower(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                                  i_problem_list_hist(l_flg_prev_index).flg_status,
                                                                                  i_lang));
                                l_old_state      := lower(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                                  i_problem_list_hist(j).flg_status,
                                                                                  i_lang));
                                l_status_message := i_problem_list(i)
                                                    .desc_problem || l_2points || l_msg_changed || l_old_state ||
                                                     l_msg_to || l_current_state || g_dot;
                            
                                l_problem_list_all.extend;
                                l_problem_list_all(l_index) := t_rec_epis_problem_list(id_pat_problem      => i_problem_list_hist(j).id_pat_problem,
                                                                                       TYPE                => i_problem_list_hist(j).type,
                                                                                       id_diagnosis        => NULL,
                                                                                       id_episode          => i_problem_list_hist(j).id_episode,
                                                                                       problem_desc        => i_problem_list(i).desc_problem || ' ',
                                                                                       flg_status          => i_problem_list_hist(j).flg_status,
                                                                                       dt_problem_to_print => i_problem_list_hist(j).dt_problem_to_print,
                                                                                       nick_name           => i_problem_list_hist(j).nick_name,
                                                                                       current_state_desc  => l_current_state,
                                                                                       old_state_desc      => l_old_state,
                                                                                       full_desc           => l_status_message);
                            
                                l_index := l_index + 1;
                            END IF;
                        END IF;
                    
                        l_flg_prev_index := j;
                    END IF;
                
                END IF;
            END LOOP;
        
            IF NOT l_hist_found
            THEN
                l_new_problem   := pk_alert_constant.g_yes;
                l_current_state := lower(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                 i_problem_list(i).flg_status,
                                                                 i_lang));
                -- ALERT-260808 -- when no text no label   
            
                -- l_status_message := i_problem_list(i).desc_problem || l_msg_since || i_problem_list(i).dt_problem_to_print || l_msg_actual || l_current_state || g_dot;            
                IF i_problem_list(i).dt_problem_to_print IS NOT NULL
                THEN
                    l_status_message := i_problem_list(i).desc_problem || l_2points || l_msg_since || i_problem_list(i).dt_problem_to_print ||
                                         l_break || l_msg_actual || l_current_state || g_dot;
                ELSE
                    l_status_message := i_problem_list(i)
                                        .desc_problem || l_2points || l_msg_actual || l_current_state || g_dot;
                END IF;
            
                l_problem_list_all.extend;
                l_problem_list_all(l_index) := t_rec_epis_problem_list(id_pat_problem      => i_problem_list(i).id_pat_problem,
                                                                       TYPE                => i_problem_list(i).type,
                                                                       id_diagnosis        => NULL,
                                                                       id_episode          => i_problem_list(i).id_episode,
                                                                       problem_desc        => i_problem_list(i).desc_problem,
                                                                       flg_status          => i_problem_list(i).flg_status,
                                                                       dt_problem_to_print => i_problem_list(i).dt_problem_to_print,
                                                                       nick_name           => i_problem_list(i).nick_name,
                                                                       current_state_desc  => l_current_state,
                                                                       old_state_desc      => NULL,
                                                                       full_desc           => l_status_message);
                l_index := l_index + 1;
            END IF;
        END LOOP;
    
        l_result.problem_status_list := l_problem_list_all;
        l_result.new_problem         := l_new_problem;
        l_result.edit_problem        := l_edited_problem;
    
        RETURN l_result;
    END;

    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN pat_problem.id_pat_problem%TYPE,
        i_flg_source     IN VARCHAR2,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT set_pat_problem_review(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_pat_problem => table_number(i_id_pat_problem),
                                      i_flg_source     => table_varchar(i_flg_source),
                                      i_review_notes   => i_review_notes,
                                      i_episode        => NULL,
                                      i_flg_auto       => 'N',
                                      o_error          => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              'set_pat_problem_review',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_pat_problem_review;

    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN pat_problem.id_pat_problem%TYPE,
        i_flg_source     IN VARCHAR2,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT set_pat_problem_review(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_pat_problem => table_number(i_id_pat_problem),
                                      i_flg_source     => table_varchar(i_flg_source),
                                      i_review_notes   => i_review_notes,
                                      i_episode        => i_episode,
                                      i_flg_auto       => i_flg_auto,
                                      o_error          => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              'set_pat_problem_review',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_pat_problem_review;

    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_source     IN table_varchar,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count          NUMBER;
        l_flg_context    review_detail.flg_context%TYPE;
        l_id_record_area review_detail.id_record_area%TYPE;
        l_revision       review_detail.revision%TYPE;
        l_rowids         table_varchar;
        l_category       category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_pat_problem.count <> i_flg_source.count
        THEN
            RAISE g_exception;
        END IF;
    
        FOR i IN 1 .. i_id_pat_problem.count
        LOOP
            IF (i_flg_source(i) = g_problem_type_allergy)
            THEN
                -- allergies
                l_flg_context    := pk_review.get_allergies_context();
                l_id_record_area := i_id_pat_problem(i);
                SELECT pa.revision
                  INTO l_revision
                  FROM pat_allergy pa
                 WHERE pa.id_pat_allergy = i_id_pat_problem(i);
            
            ELSIF (i_flg_source(i) = g_problem_type_habit)
            THEN
                -- habits (in this case id_pat_habit is registered instead of id_pat_problem)
                l_flg_context := pk_review.get_habits_context();
                SELECT id_pat_habit
                  INTO l_id_record_area
                  FROM pat_problem
                 WHERE id_pat_problem = i_id_pat_problem(i);
            ELSIF (i_flg_source(i) = pk_review.get_past_history_context())
            THEN
                l_id_record_area := i_id_pat_problem(i);
                l_flg_context    := pk_review.get_past_history_context();
            ELSE
                l_id_record_area := i_id_pat_problem(i);
                l_flg_context    := pk_review.get_problems_context();
            END IF;
        
            IF l_category = g_doctor
               OR i_flg_auto = pk_alert_constant.g_no
            THEN
                g_error := 'set set_pat_problem_review';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_review.set_review(i_lang,
                                            i_prof,
                                            l_id_record_area,
                                            l_flg_context,
                                            g_sysdate_tstz,
                                            i_review_notes,
                                            i_episode,
                                            i_flg_auto,
                                            l_revision,
                                            o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                SELECT COUNT(1)
                  INTO l_count
                  FROM review_detail rd
                 WHERE rd.id_record_area = l_id_record_area
                   AND rd.id_episode = i_episode
                   AND rd.flg_context = l_flg_context;
            
                IF l_count > 0
                THEN
                    IF i_episode IS NOT NULL
                    THEN
                        ts_review_detail.upd(flg_problem_review_in => pk_alert_constant.g_no,
                                             where_in              => 'id_record_area = ' || l_id_record_area ||
                                                                      ' and id_episode = ' || i_episode ||
                                                                      ' and flg_context = ''' || l_flg_context || '''',
                                             rows_out              => l_rowids);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'REVIEW_DETAIL',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    END IF;
                END IF;
            END IF;
        
            -- Call the function set_register_by_me_nc
            IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_episode  => i_episode,
                                                i_pat         => NULL,
                                                i_id_problem  => i_id_pat_problem(i),
                                                i_flg_type    => CASE
                                                                     WHEN l_flg_context = pk_review.get_habits_context() THEN
                                                                      'P'
                                                                     WHEN l_flg_context = pk_review.get_allergies_context() THEN
                                                                      'A'
                                                                     WHEN l_flg_context = pk_review.get_past_history_context() THEN
                                                                      'D'
                                                                     ELSE
                                                                      'P'
                                                                 END,
                                                i_flag_active => pk_alert_constant.g_yes,
                                                o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'set_pat_problem_review',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_pat_problem_review;

    FUNCTION get_precaution_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_precautions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- returns all precaution ids and descriptions
        g_error := 'OPEN o_precautions';
        OPEN o_precautions FOR
            SELECT DISTINCT p.rank,
                            p.id_precaution,
                            pk_translation.get_translation(i_lang, p.code_precaution) precaution_desc
              FROM precaution p, precaution_inst pi
             WHERE p.id_precaution = pi.id_precaution
               AND p.flg_available = pk_alert_constant.g_yes
               AND pi.id_institution IN (i_prof.institution, 0)
             ORDER BY rank, precaution_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PRECAUTION_LIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_precautions);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure   
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_precaution_list_cod
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE
    ) RETURN table_number IS
    
        l_id_precaution table_number;
    
    BEGIN
        -- returns precaution ids of a given problem
        SELECT id_precaution
          BULK COLLECT
          INTO l_id_precaution
          FROM pat_hist_diag_precaution phdp
         WHERE phdp.id_pat_history_diagnosis = i_pat_history_diagnosis
         ORDER BY id_precaution;
        RETURN l_id_precaution;
    END;

    FUNCTION get_pat_precaution_list_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE
    ) RETURN table_varchar IS
        l_desc_precaution table_varchar;
    BEGIN
        -- returns precaution descriptions of a given problem
        SELECT pk_translation.get_translation(i_lang, p.code_precaution)
          BULK COLLECT
          INTO l_desc_precaution
          FROM pat_hist_diag_precaution phdp, precaution p
         WHERE phdp.id_precaution = p.id_precaution
           AND phdp.id_pat_history_diagnosis = i_pat_history_diagnosis
         ORDER BY p.id_precaution;
        RETURN l_desc_precaution;
    END;

    FUNCTION set_registered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name     VARCHAR2(32 CHAR) := 'SET_REGISTERED_BY_ME';
        l_prof_cat_type category.flg_type%TYPE;
    
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => g_package_name, --g_package_name
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_problem: ' || i_id_problem || ' | i_flg_type: ' || i_flg_type);
    
        -- Call the function set_register_by_me_nc
        IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_episode  => i_id_episode,
                                                 i_pat         => i_pat,
                                                 i_id_problem  => i_id_problem,
                                                 i_flg_type    => i_flg_type,
                                                 i_flag_active => pk_alert_constant.g_yes,
                                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_sysdate_tstz  := current_timestamp;
        g_error         := 'CALL TO GET_CATEGORY';
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
        g_error         := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => l_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_pk_owner, --g_pk_owner,
                                              g_package_name, --g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_unregistered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name     VARCHAR2(32 CHAR) := 'SET_UNREGISTERED_BY_ME';
        l_prof_cat_type category.flg_type%TYPE;
    
    BEGIN
    
        -- Call the function set_register_by_me_nc
        IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_episode  => i_id_episode,
                                                 i_pat         => i_pat,
                                                 i_id_problem  => i_id_problem,
                                                 i_flg_type    => i_flg_type,
                                                 i_flag_active => pk_alert_constant.g_no,
                                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_sysdate_tstz  := current_timestamp;
        g_error         := 'CALL TO GET_CATEGORY';
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
        g_error         := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => l_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_pk_owner, --g_pk_owner,
                                              g_package_name, --g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_register_by_me_nc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_info.id_episode%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_id_problem  IN NUMBER,
        i_flg_type    IN VARCHAR2,
        i_flag_active IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32 CHAR) := 'SET_REGISTER_BY_ME_NC';
        l_count     NUMBER := NULL;
        l_rowids    table_varchar;
    
    BEGIN
    
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_id_problem IS NULL
           OR i_flg_type IS NULL
           OR i_flag_active IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- check type of operation insert/update
        g_error := 'ERROR IN COUNT OF PROFESSIONAL_RECORD';
        SELECT COUNT(1)
          INTO l_count
          FROM professional_record pr
         WHERE pr.id_professional = i_prof.id
           AND pr.id_record = i_id_problem
           AND pr.flg_type = i_flg_type;
    
        IF l_count = 0
        THEN
        
            IF i_flag_active = pk_alert_constant.g_yes
            THEN
                g_error := 'UPDATE PROFESSIONAL_RECORD';
                ts_professional_record.upd(flg_active_in => pk_alert_constant.g_no,
                                           where_in      => ' ID_RECORD = ' || i_id_problem || ' AND FLG_TYPE = ''' ||
                                                            i_flg_type || '''',
                                           rows_out      => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang, i_prof, 'PROFESSIONAL_RECORD', l_rowids, o_error);
            END IF;
        
            g_error := 'INSERT PROFESSIONAL_RECORD';
            ts_professional_record.ins(id_professional_in => i_prof.id,
                                       id_record_in       => i_id_problem,
                                       flg_type_in        => i_flg_type,
                                       flg_active_in      => i_flag_active,
                                       rows_out           => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PROFESSIONAL_RECORD',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            IF i_flag_active = pk_alert_constant.g_yes
            THEN
                g_error := 'UPDATE PROFESSIONAL_RECORD';
                ts_professional_record.upd(flg_active_in => pk_alert_constant.g_no,
                                           where_in      => ' ID_RECORD = ' || i_id_problem || ' AND FLG_TYPE = ''' ||
                                                            i_flg_type || '''',
                                           rows_out      => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang, i_prof, 'PROFESSIONAL_RECORD', l_rowids, o_error);
            END IF;
        
            g_error := 'UPDATE PROFESSIONAL_RECORD';
            ts_professional_record.upd(flg_active_in => i_flag_active,
                                       where_in      => ' ID_PROFESSIONAL = ' || i_prof.id || ' AND ID_RECORD = ' ||
                                                        i_id_problem || ' AND FLG_TYPE = ''' || i_flg_type || '''',
                                       rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'PROFESSIONAL_RECORD', l_rowids, o_error);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_registered_by_me
    (
        i_prof       IN profissional,
        i_id_problem IN professional_record.id_record%TYPE,
        i_flg_type   IN professional_record.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name  VARCHAR2(32 CHAR) := 'GET_REGISTERED_BY_ME';
        l_flg_active professional_record.flg_active%TYPE;
    
    BEGIN
    
        g_error := 'get flg_active';
        -- returns flg_active from professional_record table for the input parameters
        SELECT flg_active
          INTO l_flg_active
          FROM professional_record
         WHERE id_professional = i_prof.id
           AND id_record = i_id_problem
           AND flg_type = i_flg_type;
    
        RETURN l_flg_active;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION set_pat_hist_diag_precau_nc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN epis_info.id_episode%TYPE,
        i_pat                   IN patient.id_patient%TYPE,
        i_pat_history_diagnosis IN pat_hist_diag_precaution.id_pat_history_diagnosis%TYPE,
        i_precaution            IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'SET_PAT_HIST_DIAG_PRECAU_NC';
        l_rowids    table_varchar;
    
    BEGIN
    
        IF i_precaution.exists(1)
        THEN
        
            <<lup_thru_precautions>>
            FOR i IN 1 .. i_precaution.count
            LOOP
                pk_alertlog.log_info(text            => 'Begin execution of:',
                                     object_name     => g_package_name,
                                     sub_object_name => l_func_name);
            
                pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                                     ' | i_pat_history_diagnosis: ' || i_pat_history_diagnosis || ' | i_precaution: ' ||
                                     i_precaution(i));
            
                -- check input parameters
                IF i_precaution(i) IS NOT NULL
                THEN
                    g_error := 'INVALID INPUT PARAMETERS';
                    IF i_lang IS NULL
                       OR i_prof IS NULL
                       OR i_pat_history_diagnosis IS NULL
                       OR i_precaution(i) IS NULL
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error  := 'INSERT PAT_HIST_DIAG_PRECAUTION';
                    l_rowids := table_varchar();
                    ts_pat_hist_diag_precaution.ins(id_pat_history_diagnosis_in => i_pat_history_diagnosis,
                                                    id_precaution_in            => i_precaution(i),
                                                    rows_out                    => l_rowids);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HIST_DIAG_PRECAUTION',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            END LOOP lup_thru_precautions;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_pat_hist_diag_precaution(i_pat_history_diagnosis IN pat_hist_diag_precaution.id_pat_history_diagnosis%TYPE)
        RETURN table_number IS
        l_func_name  VARCHAR2(32) := 'get_pat_hist_diag_precaution';
        l_precaution table_number;
    
    BEGIN
    
        g_error := 'get precaution table_number';
        -- returns table_number of id_precaution field of PAT_HIST_DIAG_PRECAUTION
        SELECT phdp.id_precaution
          BULK COLLECT
          INTO l_precaution
          FROM pat_hist_diag_precaution phdp
         WHERE phdp.id_pat_history_diagnosis = i_pat_history_diagnosis;
    
        RETURN l_precaution;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_pat_flg_warning
    (
        i_lang IN language.id_language%TYPE,
        i_pat  IN pat_problem.id_patient%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        l_flg_warning pat_history_diagnosis.flg_warning%TYPE;
    BEGIN
    
        -- returns yes if the patient has at least one problem with "yes" in the flag warning field and doesn't have a virus
        g_error       := 'CALL get_pat_flg_warning';
        l_flg_warning := pk_alert_constant.g_no;
        SELECT flg_warning
          INTO l_flg_warning
          FROM (SELECT DISTINCT flg_warning
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_patient = i_pat
                   AND phd.flg_type IN (g_flg_type_med, g_ph_surgical_hist)
                   AND pk_alert_constant.g_yes = nvl((SELECT DISTINCT pk_alert_constant.g_no
                                                       FROM diag_diag_condition ddc
                                                      WHERE ddc.id_diagnosis = phd.id_diagnosis
                                                        AND ddc.id_software IN (0, i_prof.software)
                                                        AND ddc.id_institution IN (0, i_prof.institution)),
                                                     pk_alert_constant.g_yes)
                   AND pk_alert_constant.g_yes = nvl((SELECT DISTINCT pk_alert_constant.g_no
                                                       FROM diag_diag_condition ddc, alert_diagnosis ad1
                                                      WHERE ddc.id_diagnosis = ad1.id_diagnosis
                                                        AND ad1.id_alert_diagnosis = phd.id_alert_diagnosis
                                                        AND ddc.id_software IN (0, i_prof.software)
                                                        AND ddc.id_institution IN (0, i_prof.institution)),
                                                     pk_alert_constant.g_yes)
                   AND phd.flg_status = g_pat_probl_active
                   AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                   AND phd.id_pat_history_diagnosis_new IS NULL)
         WHERE flg_warning = pk_alert_constant.g_yes;
    
        RETURN l_flg_warning;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_flg_warning;
    END;

    FUNCTION check_pat_diag_condition
    (
        i_lang IN language.id_language%TYPE,
        i_pat  IN pat_problem.id_patient%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        l_diag_condition pat_history_diagnosis.flg_warning%TYPE;
    BEGIN
    
        -- returns yes if the patient has a problem with virus alert precaution, if 
        g_error          := 'CALL check_pat_diag_condition';
        l_diag_condition := pk_alert_constant.g_no;
    
        SELECT DISTINCT pk_alert_constant.g_yes
          INTO l_diag_condition
          FROM pat_history_diagnosis phd, diag_diag_condition ddc
         WHERE phd.id_patient = i_pat
           AND phd.flg_warning = pk_alert_constant.g_yes
           AND phd.flg_type IN (g_flg_type_med, g_ph_surgical_hist)
           AND phd.flg_status = g_pat_probl_active
           AND ddc.id_software IN (0, i_prof.software)
           AND ddc.id_institution IN (0, i_prof.institution)
           AND ddc.id_diagnosis IN (phd.id_diagnosis,
                                    (SELECT ad1.id_diagnosis
                                       FROM alert_diagnosis ad1
                                      WHERE ad1.id_alert_diagnosis = phd.id_alert_diagnosis))
           AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
           AND phd.id_pat_history_diagnosis_new IS NULL;
    
        RETURN l_diag_condition;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_diag_condition;
    END;

    FUNCTION check_pat_precaution
    (
        i_lang IN language.id_language%TYPE,
        i_pat  IN pat_problem.id_patient%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        l_precaution VARCHAR2(1 CHAR);
    BEGIN
    
        -- returns yes if the patient has active problems with precautions
        g_error      := 'CALL check_pat_precaution';
        l_precaution := pk_alert_constant.g_no;
        SELECT DISTINCT pk_alert_constant.g_yes
          INTO l_precaution
          FROM pat_history_diagnosis phd, pat_hist_diag_precaution phdp
         WHERE id_patient = i_pat
           AND phdp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
           AND phdp.id_precaution > 0
           AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
           AND phd.flg_type = g_flg_type_med
           AND phd.flg_status = g_pat_probl_active
           AND phd.id_pat_history_diagnosis_new IS NULL
           AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis);
    
        RETURN l_precaution;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_precaution;
    END;

    FUNCTION get_pat_precaution
    (
        i_lang              IN language.id_language%TYPE,
        i_pat               IN pat_problem.id_patient%TYPE,
        i_prof              IN profissional,
        o_precaution_list   OUT VARCHAR2,
        o_precaution_number OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- select the list and number of precautions with active problems 
        g_error := 'OPEN o_list';
        SELECT COUNT(precaution_list) precaution_number,
               substr(concatenate(precaution_list || g_semicolon),
                      1,
                      length(concatenate(precaution_list || g_semicolon)) - length(g_semicolon)) precaution_list
          INTO o_precaution_number, o_precaution_list
          FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, p.code_precaution) precaution_list
                  FROM pat_history_diagnosis phd, pat_hist_diag_precaution phdp, precaution p
                 WHERE id_patient = i_pat
                   AND phdp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
                   AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
                   AND phdp.id_precaution = p.id_precaution
                   AND phdp.id_precaution > 0
                   AND phd.flg_type = g_flg_type_med
                   AND phd.flg_status = g_pat_probl_active
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PAT_PRECAUTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            -- return failure   
            RETURN FALSE;
    END;

    FUNCTION get_pat_precaution_problem
    (
        i_lang           IN language.id_language%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        o_problem_list   OUT VARCHAR2,
        o_problem_number OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- select the list and number of active problems with precautions
        g_error := 'OPEN o_list';
        SELECT COUNT(problem_list) problem_number,
               substr(concatenate(problem_list || g_semicolon),
                      1,
                      length(concatenate(problem_list || g_semicolon)) - length(g_semicolon)) problem_list
          INTO o_problem_number, o_problem_list
          FROM (SELECT DISTINCT decode(phd.desc_pat_history_diagnosis,
                                       NULL,
                                       pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                  i_id_diagnosis       => d.id_diagnosis,
                                                                  i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                 i_flg_type => phd.flg_type),
                                                                  i_code               => d.code_icd,
                                                                  i_flg_other          => d.flg_other,
                                                                  i_flg_std_diag       => ad.flg_icd9),
                                       decode(phd.id_alert_diagnosis,
                                              NULL,
                                              phd.desc_pat_history_diagnosis,
                                              phd.desc_pat_history_diagnosis || ' - ' ||
                                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                         i_prof               => i_prof,
                                                                         i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                         i_id_diagnosis       => d.id_diagnosis,
                                                                         i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                        i_flg_type => phd.flg_type),
                                                                         i_code               => d.code_icd,
                                                                         i_flg_other          => d.flg_other,
                                                                         i_flg_std_diag       => ad.flg_icd9))) problem_list
                  FROM pat_history_diagnosis    phd,
                       pat_hist_diag_precaution phdp,
                       precaution               p,
                       alert_diagnosis          ad,
                       diagnosis                d
                 WHERE id_patient = i_pat
                   AND phdp.id_pat_history_diagnosis = phd.id_pat_history_diagnosis
                   AND phdp.id_precaution = p.id_precaution
                   AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                   AND phd.id_diagnosis = d.id_diagnosis(+)
                   AND phdp.id_precaution > 0
                   AND phd.flg_status = g_pat_probl_active
                   AND phd.flg_type = g_flg_type_med
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PAT_PRECAUTION',
                                              o_error);
            -- return failure   
            RETURN FALSE;
    END;

    FUNCTION set_problem_history
    (
        i_lang           IN language.id_language%TYPE,
        i_pat            IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'SET_PROBLEM_HISTORY',
                                              o_error);
        
            RETURN FALSE;
    END;

    FUNCTION get_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN review_detail.id_record_area%TYPE,
        i_flg_source     IN VARCHAR2,
        i_episode        IN review_detail.id_episode%TYPE,
        i_status         IN VARCHAR2
    ) RETURN table_varchar IS
    
        l_reviewed      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T074');
        l_last_reviewed sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T075');
        l_return        table_varchar;
    
    BEGIN
        g_error := 'get_review CASE';
        CASE
            WHEN i_flg_source = g_problem_type_habit
                 AND i_status IN (g_passive, g_active) THEN
                SELECT table_varchar(pk_alert_constant.g_yes,
                                     l_reviewed,
                                     pk_date_utils.date_send_tsz(i_lang, dt_review, i_prof),
                                     l_last_reviewed || ' ' ||
                                     pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || g_bar ||
                                     pk_date_utils.date_char_tsz(i_lang, dt_review, i_prof.institution, i_prof.software))
                  INTO l_return
                  FROM (SELECT rd.dt_review dt_review, rd.id_professional id_professional
                          FROM pat_problem pp
                          JOIN review_detail rd
                            ON rd.id_record_area = pp.id_pat_habit
                         WHERE pp.id_pat_problem = i_id_pat_problem
                           AND rd.flg_context = pk_review.get_habits_context()
                           AND rd.id_episode = i_episode
                         ORDER BY rd.dt_review DESC)
                 WHERE rownum = 1;
            
            WHEN i_flg_source = g_problem_type_allergy
                 AND i_status IN (g_passive, g_active) THEN
                SELECT table_varchar(pk_alert_constant.g_yes,
                                     l_reviewed,
                                     pk_date_utils.date_send_tsz(i_lang, dt_review, i_prof),
                                     l_last_reviewed || ' ' ||
                                     pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || g_bar ||
                                     pk_date_utils.date_char_tsz(i_lang, dt_review, i_prof.institution, i_prof.software))
                  INTO l_return
                  FROM (SELECT rd.dt_review dt_review, rd.id_professional id_professional
                          FROM review_detail rd
                         WHERE rd.id_record_area = i_id_pat_problem
                           AND rd.flg_context = pk_review.get_allergies_context()
                           AND rd.id_episode = i_episode
                         ORDER BY rd.dt_review DESC)
                 WHERE rownum = 1;
            
            WHEN i_flg_source IN (g_problem_type_diag, g_problem_type_pmh, g_problem_type_problem)
                 AND i_status IN (g_passive, g_active) THEN
                SELECT table_varchar(pk_alert_constant.g_yes,
                                     l_reviewed,
                                     pk_date_utils.date_send_tsz(i_lang, dt_review, i_prof),
                                     l_last_reviewed || ' ' ||
                                     pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || g_bar ||
                                     pk_date_utils.date_char_tsz(i_lang, dt_review, i_prof.institution, i_prof.software))
                  INTO l_return
                  FROM (SELECT rd.dt_review dt_review, rd.id_professional id_professional
                          FROM review_detail rd
                         WHERE rd.id_record_area = i_id_pat_problem
                           AND rd.flg_context IN
                               (pk_review.get_problems_context(), pk_review.get_past_history_context())
                           AND rd.id_episode = i_episode
                           AND pk_prof_utils.get_category(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_prof_id   => rd.id_professional,
                                                          i_prof_inst => i_prof.institution) =
                               pk_alert_constant.g_cat_type_doc
                         ORDER BY rd.dt_review DESC)
                 WHERE rownum = 1;
            
            ELSE
                l_return := table_varchar(NULL, NULL, NULL, NULL);
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN table_varchar(pk_alert_constant.g_no, NULL, NULL, NULL);
        WHEN OTHERS THEN
            RETURN table_varchar(NULL, NULL, NULL, NULL);
    END get_review;

    FUNCTION get_pat_problem_report
    (
        i_lang                 IN language.id_language%TYPE,
        i_pat                  IN pat_problem.id_patient%TYPE,
        i_prof                 IN profissional,
        i_episode              IN pat_problem.id_episode%TYPE,
        i_report               IN VARCHAR2,
        i_dt_ini               IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_show_hist            IN VARCHAR2,
        o_pat_problem          OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_detail_common_m005   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'DETAIL_COMMON_M005');
        l_label_edited         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'PROBLEM_LIST_T023');
        l_label_created        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'PROBLEM_LIST_T024');
        l_label_cancelled      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'PROBLEM_LIST_T028');
        l_episode              table_number := table_number();
        l_list                 table_table_number;
        l_phd_list             table_number;
        l_headerviolenceicon   sys_message.desc_message%TYPE := 'HeaderViolenceIcon';
        l_headervirusicon      sys_message.desc_message%TYPE := 'HeaderVirusIcon';
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    
    BEGIN
        --find list of episodes
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_pat,
                                                 i_id_episode        => i_episode,
                                                 i_flg_visit_or_epis => i_report);
    
        IF NOT pk_problems.build_unique_problem_id(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_pat      => i_pat,
                                                   i_list     => l_list,
                                                   i_phd_list => l_phd_list)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_pat_problem FOR
        -------------------
        -- Past History
        -------------------           
            SELECT get_unique_problem_id(phd.id_pat_history_diagnosis, l_list) unique_id,
                   NULL r_id_record_area,
                   NULL r_id_episode,
                   NULL r_flg_context,
                   NULL r_dt_review_send,
                   NULL r_name_prof,
                   NULL r_desc_speciality,
                   NULL r_dt_review_char,
                   NULL r_review_notes,
                   NULL r_dt_review,
                   phd.id_pat_history_diagnosis id_problem,
                   phd.id_pat_history_diagnosis_new id_problem_new,
                   phd.flg_status,
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type)))) desc_probl_complete,
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type)))) desc_probl_cod,
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type),
                                                            i_flg_show_term_code => pk_alert_constant.g_no))) desc_probl_syn,
                   
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type),
                                                            i_flg_show_term_code => pk_alert_constant.g_no))) desc_probl_short,
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => phd.flg_area,
                                         i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                         i_flg_type           => phd.flg_type) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) desc_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    phd.id_professional,
                                                    phd.dt_pat_history_diagnosis_tstz,
                                                    phd.id_episode) desc_speciality,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || phd.id_cancel_reason) cancel_reason,
                   phd.cancel_notes cancel_notes,
                   pk_date_utils.date_char_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_pat_problem,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_diagnosed,
                                                           i_precision => phd.dt_diagnosed_precision) dt_problem_to_print,
                   decode(phd.dt_diagnosed_precision,
                          pk_past_history.g_date_unknown,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) dt_problem_to_print2,
                   phd.notes prob_notes,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                   NULL desc_location,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                   decode(phd.flg_status,
                          g_pat_probl_cancel,
                          l_label_cancelled,
                          decode(pk_utils.search_table_number(pk_problems.get_phd_ids(phd.id_pat_history_diagnosis),
                                                              phd.id_pat_history_diagnosis),
                                 1,
                                 l_label_created,
                                 l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(phd.id_professional, phd.id_institution, NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   phd.id_episode id_episode,
                   phd.dt_pat_history_diagnosis_tstz dt_order_tstz,
                   pk_utils.concat_table(pk_problems.get_pat_precaution_list_desc(i_lang,
                                                                                  i_prof,
                                                                                  phd.id_pat_history_diagnosis),
                                         ', ',
                                         1,
                                         -1) precaution_measures_str,
                   phd.flg_warning header_warning_flg,
                   pk_sysdomain.get_domain(pk_list.g_yes_no, phd.flg_warning, i_lang) header_warning_str,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_resolved,
                                                           i_precision => phd.dt_resolved_precision) resolution_date_str,
                   decode(phd.dt_resolved_precision,
                          g_unknown,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, phd.dt_resolved, i_prof)) resolution_date_str2,
                   decode((SELECT DISTINCT pk_alert_constant.g_yes
                            FROM diag_diag_condition ddc
                           WHERE ddc.id_software IN (0, i_prof.software)
                             AND ddc.id_institution IN (0, i_prof.institution)
                             AND ddc.id_diagnosis IN
                                 (phd.id_diagnosis,
                                  (SELECT ad1.id_diagnosis
                                     FROM alert_diagnosis ad1
                                    WHERE ad1.id_alert_diagnosis = phd.id_alert_diagnosis))),
                          pk_alert_constant.g_yes,
                          l_headervirusicon,
                          decode(phd.flg_warning, pk_alert_constant.g_yes, l_headerviolenceicon, NULL)) warning_icon,
                   pk_diagnosis_core.get_terminology_abbreviation(i_lang => i_lang, id_diagnosis => phd.id_diagnosis) icd_desc,
                   d.code_icd icd_code,
                   d.flg_type diag_flg_type,
                   decode(get_most_recent_phd_id(phd.id_pat_history_diagnosis, phd.flg_area),
                          phd.id_pat_history_diagnosis,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) most_recent,
                   coalesce(d.id_content, ad.id_content) id_content,
                   pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', phd.flg_area) rank_area,
                   get_flg_area(i_flg_area => phd.flg_area, i_flg_type => phd.flg_type) flg_area
              FROM pat_history_diagnosis phd
              LEFT JOIN alert_diagnosis ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON phd.id_diagnosis = d.id_diagnosis
             WHERE phd.id_patient = i_pat
               AND phd.id_pat_history_diagnosis IN (SELECT /*+opt_estimate (table e rows=0.00000000001)*/
                                                     e.column_value
                                                      FROM TABLE(l_phd_list) e)
               AND phd.flg_type IN (pk_past_history.g_alert_diag_type_med, pk_past_history.g_alert_diag_type_surg)
               AND (phd.id_alert_diagnosis IS NOT NULL OR phd.desc_pat_history_diagnosis IS NOT NULL OR
                   (d.flg_other = 'Y'))
               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
               AND (nvl(i_report, g_report_p) = g_report_p OR
                   phd.id_episode IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                        d.column_value
                                         FROM TABLE(l_episode) d))
               AND phd.dt_pat_history_diagnosis_tstz BETWEEN
                   nvl(pk_date_utils.trunc_insttimezone(i_prof,
                                                        pk_date_utils.get_string_tstz(i_lang,
                                                                                      i_prof,
                                                                                      i_dt_ini,
                                                                                      NULL,
                                                                                      'YYYYMMDD')),
                       phd.dt_pat_history_diagnosis_tstz) AND
                   nvl(pk_date_utils.trunc_insttimezone(i_prof,
                                                        pk_date_utils.get_string_tstz(i_lang,
                                                                                      i_prof,
                                                                                      i_dt_end,
                                                                                      NULL,
                                                                                      'YYYYMMDD')),
                       current_timestamp)
               AND (i_show_hist = pk_alert_constant.g_yes OR
                   get_most_recent_phd_id(phd.id_pat_history_diagnosis, phd.flg_area) = phd.id_pat_history_diagnosis)
               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                   phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                      pk_alert_constant.g_diag_area_surgical_hist,
                                      pk_alert_constant.g_diag_area_not_defined)))
            UNION ALL
            SELECT get_unique_problem_id(phd.id_pat_history_diagnosis, l_list) unique_id,
                   rd.id_record_area r_id_record_area,
                   rd.id_episode r_id_episode,
                   rd.flg_context r_flg_context,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) r_dt_review_send,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) r_name_prof,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, rd.id_episode) r_desc_speciality,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) r_dt_review_char,
                   rd.review_notes r_review_notes,
                   rd.dt_review r_dt_review,
                   phd.id_pat_history_diagnosis id_problem,
                   phd.id_pat_history_diagnosis_new id_problem_new,
                   phd.flg_status,
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type)))) desc_probl_complete,
                   
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type)))) desc_probl_cod,
                   
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type),
                                                            i_flg_show_term_code => pk_alert_constant.g_no))) desc_probl_syn,
                   
                   decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type),
                                                            i_flg_show_term_code => pk_alert_constant.g_no))) desc_probl_short,
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => phd.flg_area,
                                         i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                         i_flg_type           => phd.flg_type) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) desc_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    phd.id_professional,
                                                    phd.dt_pat_history_diagnosis_tstz,
                                                    phd.id_episode) desc_speciality,
                   pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || phd.id_cancel_reason) cancel_reason,
                   phd.cancel_notes cancel_notes,
                   pk_date_utils.date_char_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_pat_problem,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_diagnosed,
                                                           i_precision => phd.dt_diagnosed_precision) dt_problem_to_print,
                   decode(phd.dt_diagnosed_precision,
                          pk_past_history.g_date_unknown,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) dt_problem_to_print2,
                   phd.notes prob_notes,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                   nvl2(phd.id_location,
                        pk_diagnosis.std_diag_desc(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_id_diagnosis          => pk_diagnosis_core.get_term_diagnosis_id(phd.id_location,
                                                                                                                      i_prof.institution,
                                                                                                                      i_prof.software),
                                                   i_id_alert_diagnosis    => phd.id_location,
                                                   i_code                  => pk_diagnosis_core.get_term_diagnosis_code(phd.id_location,
                                                                                                                        i_prof.institution,
                                                                                                                        i_prof.software),
                                                   i_flg_other             => pk_alert_constant.g_no,
                                                   i_flg_std_diag          => pk_alert_constant.g_yes,
                                                   i_epis_diag             => NULL,
                                                   i_show_aditional_info   => pk_alert_constant.g_no,
                                                   i_flg_show_ae_diag_info => pk_alert_constant.g_no),
                        '') desc_location,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                   decode(phd.flg_status,
                          g_pat_probl_cancel,
                          l_label_cancelled,
                          decode(pk_utils.search_table_number(pk_problems.get_phd_ids(phd.id_pat_history_diagnosis),
                                                              phd.id_pat_history_diagnosis),
                                 1,
                                 l_label_created,
                                 l_label_edited) ||
                          decode(pk_prof_utils.get_category(i_lang,
                                                            profissional(phd.id_professional, phd.id_institution, NULL)),
                                 g_doctor,
                                 g_bar2 || l_detail_common_m005,
                                 '')) desc_edit,
                   phd.id_episode id_episode,
                   phd.dt_pat_history_diagnosis_tstz dt_order_tstz,
                   
                   pk_utils.concat_table(pk_problems.get_pat_precaution_list_desc(i_lang,
                                                                                  i_prof,
                                                                                  phd.id_pat_history_diagnosis),
                                         ', ',
                                         1,
                                         -1) precaution_measures_str,
                   phd.flg_warning header_warning_flg,
                   pk_sysdomain.get_domain(pk_list.g_yes_no, phd.flg_warning, i_lang) header_warning_str,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_resolved,
                                                           i_precision => phd.dt_resolved_precision) resolution_date_str,
                   decode(phd.dt_resolved_precision,
                          g_unknown,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, phd.dt_resolved, i_prof)) resolution_date_str2,
                   decode((SELECT DISTINCT pk_alert_constant.g_yes
                            FROM diag_diag_condition ddc
                           WHERE ddc.id_software IN (0, i_prof.software)
                             AND ddc.id_institution IN (0, i_prof.institution)
                             AND ddc.id_diagnosis IN
                                 (phd.id_diagnosis,
                                  (SELECT ad1.id_diagnosis
                                     FROM alert_diagnosis ad1
                                    WHERE ad1.id_alert_diagnosis = phd.id_alert_diagnosis))),
                          pk_alert_constant.g_yes,
                          l_headervirusicon,
                          decode(phd.flg_warning, pk_alert_constant.g_yes, l_headerviolenceicon, NULL)) warning_icon,
                   pk_diagnosis_core.get_terminology_abbreviation(i_lang => i_lang, id_diagnosis => phd.id_diagnosis) icd_desc,
                   d.code_icd icd_code,
                   d.flg_type diag_flg_type,
                   pk_alert_constant.g_no most_recent,
                   coalesce(d.id_content, ad.id_content) id_content,
                   pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', phd.flg_area) rank_area,
                   get_flg_area(i_flg_area => phd.flg_area, i_flg_type => phd.flg_type) flg_area
              FROM review_detail rd
              JOIN pat_history_diagnosis phd
                ON phd.id_pat_history_diagnosis = rd.id_record_area
              LEFT JOIN alert_diagnosis ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON phd.id_diagnosis = d.id_diagnosis
             WHERE rd.flg_context IN (pk_review.get_problems_context(), pk_review.get_past_history_context())
               AND phd.id_patient = i_pat
               AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR phd.id_alert_diagnosis IS NULL)
               AND phd.id_pat_history_diagnosis IN (SELECT /*+opt_estimate (table e rows=0.00000000001)*/
                                                     e.column_value
                                                      FROM TABLE(l_phd_list) e)
               AND phd.flg_type IN (pk_past_history.g_alert_diag_type_med, pk_past_history.g_alert_diag_type_surg)
               AND (phd.id_alert_diagnosis IS NOT NULL OR phd.desc_pat_history_diagnosis IS NOT NULL OR
                   (d.flg_other = 'Y'))
               AND (nvl(i_report, g_report_p) = g_report_p OR
                   rd.id_episode IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                       t.column_value
                                        FROM TABLE(l_episode) t))
               AND ((nvl(rd.flg_auto, pk_alert_constant.g_no) = pk_alert_constant.g_no) OR phd.id_episode = i_episode)
               AND ((rd.dt_review BETWEEN nvl(pk_date_utils.trunc_insttimezone(i_prof,
                                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             i_dt_ini,
                                                                                                             NULL,
                                                                                                             'YYYYMMDD')),
                                              rd.dt_review) AND
                   nvl(pk_date_utils.trunc_insttimezone(i_prof,
                                                          pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_prof,
                                                                                        i_dt_end,
                                                                                        NULL,
                                                                                        'YYYYMMDD')),
                         current_timestamp)) OR (i_dt_ini IS NULL OR i_dt_end IS NULL))
               AND (i_show_hist = pk_alert_constant.g_yes OR
                   get_most_recent_phd_id(phd.id_pat_history_diagnosis) = phd.id_pat_history_diagnosis)
               AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                   (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                   phd.flg_area IN
                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
             ORDER BY r_id_record_area DESC, rank_area ASC, id_problem_new DESC;
    
        IF NOT get_pat_prob_unaware_active(i_lang                    => i_lang,
                                           i_prof                    => i_prof,
                                           i_patient                 => i_pat,
                                           i_episode                 => i_episode,
                                           o_pat_prob_unaware_active => o_unawareness_active,
                                           o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT get_pat_prob_unaware_outdated(i_lang                      => i_lang,
                                             i_prof                      => i_prof,
                                             i_patient                   => i_pat,
                                             i_episode                   => i_episode,
                                             o_pat_prob_unaware_outdated => o_unawareness_outdated,
                                             o_error                     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_PAT_PROBLEM_REPORT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure   
                pk_types.open_my_cursor(o_pat_problem);
                pk_types.open_my_cursor(o_unawareness_active);
                pk_types.open_my_cursor(o_unawareness_outdated);
                RETURN FALSE;
            END;
    END;

    FUNCTION build_unique_problem_id
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN pat_problem.id_patient%TYPE,
        i_list     OUT table_table_number,
        i_phd_list OUT table_number
    ) RETURN BOOLEAN IS
        l_parents        table_number;
        l_unique_id_aux1 table_table_number := table_table_number();
        l_unique_id_aux2 table_table_number := table_table_number();
        l_unique_id      table_table_number := table_table_number();
        l_phd_list_aux1  table_number := table_number();
        l_phd_list_aux2  table_number := table_number();
        l_phd_list       table_number := table_number();
        l_pat_prob       table_number := table_number();
    BEGIN
    
        -- gather parents collection id's
        SELECT id_problem
          BULK COLLECT
          INTO l_parents
          FROM TABLE(pk_problems.get_phd(i_lang, i_prof, i_pat, table_varchar(), NULL, NULL, NULL, NULL, NULL));
    
        --for each parent gather all child and parent ids and give one unique id for each problem
        FOR i IN 1 .. l_parents.count
        LOOP
            l_pat_prob := pk_problems.get_phd_ids(l_parents(i));
            SELECT table_number(phd.id_pat_history_diagnosis, i), phd.id_pat_history_diagnosis
              BULK COLLECT
              INTO l_unique_id_aux1, l_phd_list_aux1
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis IN
                   (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                     column_value
                      FROM TABLE(CAST(l_pat_prob AS table_number)) d);
        
            --join with previous iteration
            l_unique_id      := l_unique_id_aux1 MULTISET UNION l_unique_id_aux2;
            l_unique_id_aux2 := SET(l_unique_id);
        
            l_phd_list      := l_phd_list_aux1 MULTISET UNION l_phd_list_aux2;
            l_phd_list_aux2 := SET(l_phd_list);
        END LOOP;
    
        i_list     := SET(l_unique_id);
        i_phd_list := SET(l_phd_list);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END build_unique_problem_id;

    FUNCTION get_unique_problem_id
    (
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_list       IN table_table_number
    ) RETURN NUMBER IS
    BEGIN
    
        -- search original id in position 1 and returns unique id in position 2
        FOR i IN 1 .. i_list.count
        LOOP
            IF i_list(i) (1) = i_id_problem
            THEN
                RETURN i_list(i)(2);
            END IF;
        END LOOP;
    
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_unique_problem_id;

    FUNCTION get_dt_str
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dt   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_desc_dt         sys_message.desc_message%TYPE;
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
    BEGIN
        SELECT decode(i_dt,
                      g_unknown,
                      l_message_unknown,
                      decode(nvl(substr(i_dt, 1, 4), ''),
                             '',
                             '',
                             decode(nvl(substr(i_dt, 5, 2), ''),
                                    '',
                                    to_char(nvl(substr(i_dt, 1, 4), '')),
                                    decode(nvl(substr(i_dt, 7, 2), ''),
                                           '',
                                           pk_date_utils.get_month_year(i_lang,
                                                                        i_prof,
                                                                        to_date(nvl(substr(i_dt, 1, 4), '') ||
                                                                                lpad(nvl(substr(i_dt, 5, 2), ''), 2, '0'),
                                                                                'YYYYMM')),
                                           pk_date_utils.dt_chr(i_lang,
                                                                to_date(nvl(substr(i_dt, 1, 4), '') ||
                                                                        lpad(nvl(substr(i_dt, 5, 2), ''), 2, '0') ||
                                                                        lpad(nvl(substr(i_dt, 7, 2), ''), 2, '0'),
                                                                        'YYYYMMDD'),
                                                                i_prof))))) desc_dt
          INTO l_desc_dt
          FROM dual;
    
        RETURN l_desc_dt;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_str;

    FUNCTION get_dt_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_year_begin  IN NUMBER,
        i_month_begin IN NUMBER,
        i_day_begin   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_desc_dt         sys_message.desc_message%TYPE;
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
    BEGIN
        SELECT decode(i_year_begin,
                      g_year_unknown,
                      l_message_unknown,
                      decode(i_year_begin,
                             '',
                             '',
                             decode(i_month_begin,
                                    '',
                                    to_char(i_year_begin),
                                    decode(i_day_begin,
                                           '',
                                           pk_date_utils.get_month_year(i_lang,
                                                                        i_prof,
                                                                        to_date(i_year_begin || lpad(i_month_begin, 2, '0'),
                                                                                'YYYYMM')),
                                           pk_date_utils.dt_chr(i_lang,
                                                                to_date(i_year_begin || lpad(i_month_begin, 2, '0') ||
                                                                        lpad(i_day_begin, 2, '0'),
                                                                        'YYYYMMDD'),
                                                                i_prof))))) desc_dt
          INTO l_desc_dt
          FROM dual;
    
        RETURN l_desc_dt;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_str;

    FUNCTION get_add_problems
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_add_problems';
        l_count     NUMBER;
    BEGIN
    
        g_error := 'get_add_problems OPEN o_list';
        OPEN o_list FOR
            SELECT id_action,
                   id_parent,
                   LEVEL,
                   to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                   icon,
                   flg_default action_type,
                   flg_status AS action_statement,
                   internal_name,
                   -- ALERT-193094 - MᲩo Mineiro - Just for the NO_KNOWN_PROBLEMS if theres problems hides button
                   CASE
                        WHEN a.internal_name = 'NO_KNOWN_PROBLEMS' THEN
                         get_validate_add_button(i_lang, i_prof, i_patient, i_episode)
                        ELSE
                         CASE
                             WHEN i_episode IS NULL THEN
                              pk_alert_constant.g_no
                             ELSE
                              pk_alert_constant.g_yes
                         END
                    END flg_enable
            
              FROM action a
             WHERE subject = 'PROBLEMS.PLUS_BUTTON'
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_add_problems;

    FUNCTION send_pat_prob_unaware_to_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat_prob_unaware IN pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SEND_PAT_PROB_UNAWARE_TO_HIST';
    
        l_rowids_hist      table_varchar;
        v_pat_prob_unaware pat_prob_unaware%ROWTYPE;
    
        CURSOR c_pat_prob_unaware(l_id pat_prob_unaware.id_pat_prob_unaware%TYPE) IS
            SELECT ppu.id_prob_unaware,
                   ppu.id_patient,
                   ppu.id_episode,
                   ppu.notes,
                   ppu.flg_status,
                   ppu.id_prof_last_update,
                   ppu.dt_last_update,
                   ppu.id_cancel_reason,
                   ppu.cancel_notes
              FROM pat_prob_unaware ppu
             WHERE ppu.id_pat_prob_unaware = l_id;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_pat_prob_unaware';
        OPEN c_pat_prob_unaware(i_pat_prob_unaware);
        FETCH c_pat_prob_unaware
            INTO v_pat_prob_unaware.id_prob_unaware,
                 v_pat_prob_unaware.id_patient,
                 v_pat_prob_unaware.id_episode,
                 v_pat_prob_unaware.notes,
                 v_pat_prob_unaware.flg_status,
                 v_pat_prob_unaware.id_prof_last_update,
                 v_pat_prob_unaware.dt_last_update,
                 v_pat_prob_unaware.id_cancel_reason,
                 v_pat_prob_unaware.cancel_notes;
        g_found := c_pat_prob_unaware%NOTFOUND;
        CLOSE c_pat_prob_unaware;
    
        g_error := 'TS_pat_prob_unaware_HIST.INS';
    
        ts_pat_prob_unaware_hist.ins(id_pat_prob_unaware_hist_in => ts_pat_prob_unaware_hist.next_key,
                                     id_pat_prob_unaware_in      => i_pat_prob_unaware,
                                     id_prob_unaware_in          => v_pat_prob_unaware.id_prob_unaware,
                                     id_patient_in               => v_pat_prob_unaware.id_patient,
                                     id_episode_in               => v_pat_prob_unaware.id_episode,
                                     notes_in                    => v_pat_prob_unaware.notes,
                                     flg_status_in               => v_pat_prob_unaware.flg_status,
                                     id_prof_last_update_in      => v_pat_prob_unaware.id_prof_last_update,
                                     dt_last_update_in           => v_pat_prob_unaware.dt_last_update,
                                     id_cancel_reason_in         => v_pat_prob_unaware.id_cancel_reason,
                                     cancel_notes_in             => v_pat_prob_unaware.cancel_notes,
                                     rows_out                    => l_rowids_hist);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROB_UNAWARE_HIST',
                                      i_rowids     => l_rowids_hist,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END send_pat_prob_unaware_to_hist;
    FUNCTION ins_pat_prob_unaware_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prob_unaware     IN pat_prob_unaware.id_prob_unaware%TYPE,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_flg_status          IN pat_prob_unaware.flg_status%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(60 CHAR) := 'INS_PAT_PROB_UNAWARE_NC';
        l_rowids              table_varchar;
        l_id_pat_prob_unaware pat_prob_unaware.id_pat_prob_unaware%TYPE;
    BEGIN
    
        BEGIN
            SELECT ppu.id_pat_prob_unaware
              INTO l_id_pat_prob_unaware
              FROM pat_prob_unaware ppu
             WHERE ppu.id_patient = i_id_patient
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_pat_prob_unaware := NULL;
        END;
    
        IF l_id_pat_prob_unaware IS NULL
        THEN
        
            g_error               := 'TS_PAT_PROB_UNAWARE.INS';
            o_id_pat_prob_unaware := ts_pat_prob_unaware.next_key;
            ts_pat_prob_unaware.ins(id_pat_prob_unaware_in => o_id_pat_prob_unaware,
                                    id_prob_unaware_in     => i_id_prob_unaware,
                                    id_patient_in          => i_id_patient,
                                    id_episode_in          => i_id_episode,
                                    notes_in               => i_notes,
                                    flg_status_in          => i_flg_status,
                                    id_prof_last_update_in => i_prof.id,
                                    dt_last_update_in      => current_timestamp,
                                    rows_out               => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PROB_UNAWARE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            g_error := 'CALL SEND_PAT_PROB_UNAWARE_TO_HIST';
            IF NOT send_pat_prob_unaware_to_hist(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_pat_prob_unaware => l_id_pat_prob_unaware,
                                                 o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            o_id_pat_prob_unaware := l_id_pat_prob_unaware;
        
            g_error := 'TS_PAT_PROB_UNAWARE.UPD';
            ts_pat_prob_unaware.upd(id_pat_prob_unaware_in => l_id_pat_prob_unaware,
                                    id_prob_unaware_in     => i_id_prob_unaware,
                                    id_episode_in          => i_id_episode,
                                    id_episode_nin         => FALSE,
                                    notes_in               => i_notes,
                                    notes_nin              => FALSE,
                                    flg_status_in          => i_flg_status,
                                    id_prof_last_update_in => i_prof.id,
                                    dt_last_update_in      => current_timestamp,
                                    id_cancel_reason_in    => i_id_cancel_reason,
                                    id_cancel_reason_nin   => FALSE,
                                    cancel_notes_in        => i_cancel_notes,
                                    cancel_notes_nin       => FALSE,
                                    rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PROB_UNAWARE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_pat_prob_unaware_nc;

    FUNCTION ins_pat_prob_unaware
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prob_unaware     IN pat_prob_unaware.id_prob_unaware%TYPE,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_flg_status          IN pat_prob_unaware.flg_status%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'INS_PAT_PROB_UNAWARE';
    BEGIN
    
        g_error := 'CALL INS_PAT_PROB_UNAWARE_NC';
        IF NOT ins_pat_prob_unaware_nc(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_prob_unaware     => i_id_prob_unaware,
                                       i_id_patient          => i_id_patient,
                                       i_id_episode          => i_id_episode,
                                       i_notes               => i_notes,
                                       i_flg_status          => i_flg_status,
                                       i_id_cancel_reason    => i_id_cancel_reason,
                                       i_cancel_notes        => i_cancel_notes,
                                       o_id_pat_prob_unaware => o_id_pat_prob_unaware,
                                       o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_pat_prob_unaware;

    FUNCTION get_pat_prob_unaware_choices
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_choices  OUT pk_types.cursor_type,
        o_notes    OUT pat_prob_unaware.notes%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(60 CHAR) := 'GET_PAT_PROB_UNAWARE_CHOICES';
        l_id_prob_unaware pat_prob_unaware.id_prob_unaware%TYPE;
    BEGIN
    
        BEGIN
            SELECT ppu.id_prob_unaware,
                   CASE
                        WHEN i_flg_type = 'E'
                             AND ppu.flg_status = g_status_ppu_active THEN
                         ppu.notes
                        ELSE
                         NULL
                    END notes
              INTO l_id_prob_unaware, o_notes
              FROM pat_prob_unaware ppu
             WHERE ppu.id_patient = i_patient
               AND ppu.flg_status = g_status_ppu_active
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_prob_unaware := NULL;
                o_notes           := NULL;
        END;
    
        g_error := 'get_pat_prob_unaware_choices OPEN o_choices';
        OPEN o_choices FOR
            SELECT pu.id_prob_unaware id_prob_unaware,
                   pk_translation.get_translation(i_lang, pu.code_prob_unaware) desc_prob_unaware,
                   CASE
                        WHEN i_flg_type = 'E'
                             AND pu.id_prob_unaware <> l_id_prob_unaware THEN
                         pk_alert_constant.g_no
                        WHEN i_flg_type = 'A'
                             AND pu.id_prob_unaware = l_id_prob_unaware
                             AND pu.id_prob_unaware = g_no_known_prob THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END flg_enabled,
                   
                   CASE
                        WHEN i_flg_type = 'E'
                             AND pu.id_prob_unaware = l_id_prob_unaware THEN
                         pk_alert_constant.g_yes
                        WHEN i_flg_type = 'E'
                             AND pu.id_prob_unaware <> l_id_prob_unaware THEN
                         pk_alert_constant.g_no
                        WHEN i_flg_type = 'A'
                             AND pu.id_prob_unaware = l_id_prob_unaware
                             AND pu.id_prob_unaware = g_no_known_prob THEN
                         pk_alert_constant.g_no
                        WHEN i_flg_type = 'A'
                             AND pu.id_prob_unaware = l_id_prob_unaware THEN
                         pk_alert_constant.g_no
                        WHEN l_id_prob_unaware IS NULL THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END flg_selected
              FROM prob_unaware pu;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_choices);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_prob_unaware_choices;

    FUNCTION cancel_pat_prob_unaware_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        i_flg_status          IN table_varchar,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name       VARCHAR2(60 CHAR) := 'CANCEL_PAT_PROB_UNAWARE_NC';
        l_id_prob_unaware pat_prob_unaware.id_prob_unaware%TYPE;
        l_flg_status      table_varchar;
    
    BEGIN
        l_flg_status := i_flg_status;
        IF l_flg_status IS NULL
        THEN
            l_flg_status.extend(1);
            l_flg_status(1) := g_passive;
        END IF;
    
        g_error := 'CANCEL PROBLEM UNAWARENESS';
        BEGIN
            SELECT ppu.id_prob_unaware
              INTO l_id_prob_unaware
              FROM pat_prob_unaware ppu
             WHERE ppu.id_patient = i_id_patient
               AND ppu.flg_status = g_status_ppu_active
               AND rownum = 1
               AND g_active IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                 d.column_value
                                  FROM TABLE(l_flg_status) d);
        EXCEPTION
            WHEN OTHERS THEN
                l_id_prob_unaware := NULL;
        END;
    
        IF l_id_prob_unaware IS NOT NULL
        THEN
            IF NOT pk_problems.ins_pat_prob_unaware_nc(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_prob_unaware     => l_id_prob_unaware,
                                                       i_id_patient          => i_id_patient,
                                                       i_id_episode          => i_id_episode,
                                                       i_notes               => i_notes,
                                                       i_flg_status          => g_status_ppu_outdated,
                                                       i_id_cancel_reason    => i_id_cancel_reason,
                                                       i_cancel_notes        => i_cancel_notes,
                                                       o_id_pat_prob_unaware => o_id_pat_prob_unaware,
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_pat_prob_unaware_nc;

    FUNCTION validate_unawareness
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_prob_unaware IN pat_prob_unaware.id_prob_unaware%TYPE,
        o_title           OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_show            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(60 CHAR) := 'validate_unawareness';
        l_problem_list_t085 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T085');
        l_problem_list_t086 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T086');
        l_problem_list_t087 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T087');
        l_problem_list_t088 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T088');
        l_problem_list_t089 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T089');
        l_show_allergy      sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_ALLERGY_IN_PROBLEM', i_prof);
        l_show_habit        sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_HABIT_IN_PROBLEM', i_prof);
        l_count             NUMBER;
        l_id_prob_unaware   pat_prob_unaware.id_prob_unaware%TYPE;
    BEGIN
        o_show := pk_alert_constant.g_no;
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT phd.flg_status, flg_source
                  FROM TABLE(get_phd(i_lang,
                                     i_prof,
                                     i_patient,
                                     table_varchar(g_active),
                                     NULL,
                                     i_episode,
                                     g_report_p,
                                     NULL,
                                     NULL)) phd
                UNION ALL
                SELECT pp.flg_status, flg_source
                  FROM TABLE(get_pp(i_lang,
                                    i_prof,
                                    i_patient,
                                    table_varchar(g_active),
                                    NULL,
                                    NULL,
                                    i_episode,
                                    g_report_p,
                                    NULL,
                                    NULL)) pp
                UNION ALL
                SELECT pa.flg_status, flg_source
                  FROM TABLE(get_pa(i_lang,
                                    i_prof,
                                    i_patient,
                                    table_varchar(g_active),
                                    NULL,
                                    i_episode,
                                    g_report_p,
                                    NULL,
                                    NULL)) pa) t
         WHERE t.flg_source IN (g_problem_type_pmh, g_problem_type_problem)
            OR (t.flg_source = g_problem_type_allergy AND l_show_allergy = pk_alert_constant.g_yes)
            OR (t.flg_source = g_problem_type_habit AND l_show_habit = pk_alert_constant.g_yes)
            OR (t.flg_source = g_problem_type_diag);
    
        IF l_count > 0
        THEN
            o_msg  := l_problem_list_t085;
            o_show := pk_alert_constant.g_yes;
        END IF;
    
        BEGIN
            SELECT ppu.id_prob_unaware
              INTO l_id_prob_unaware
              FROM pat_prob_unaware ppu
             WHERE ppu.id_patient = i_patient
               AND ppu.flg_status = g_status_ppu_active;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_prob_unaware := NULL;
        END;
    
        IF l_id_prob_unaware = g_no_known_prob
           AND i_id_prob_unaware = g_unable_to_access_prob
        THEN
            CASE o_show
                WHEN pk_alert_constant.g_yes THEN
                    o_msg := o_msg || chr(13) || l_problem_list_t087;
                ELSE
                    o_msg := l_problem_list_t087;
            END CASE;
            o_show := pk_alert_constant.g_yes;
        END IF;
    
        IF l_id_prob_unaware = g_unable_to_access_prob
           AND i_id_prob_unaware = g_unable_to_access_prob
        THEN
            CASE o_show
                WHEN pk_alert_constant.g_yes THEN
                    o_msg := o_msg || chr(13) || l_problem_list_t088;
                ELSE
                    o_msg := l_problem_list_t088;
            END CASE;
            o_show := pk_alert_constant.g_yes;
        END IF;
    
        IF o_show = pk_alert_constant.g_yes
        THEN
            o_title := l_problem_list_t089;
            o_msg   := o_msg || chr(13) || chr(13) || l_problem_list_t086;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_unawareness;

    FUNCTION validate_trials
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN table_number,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_shortcut  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diagnosis IS
            SELECT d.flg_type, d.code_icd
              FROM diagnosis d
             WHERE d.id_diagnosis = i_diagnosis(1);
    
        l_diag_type diagnosis.flg_type%TYPE;
        l_diag_code diagnosis.code_icd%TYPE;
        l_profile   profile_template.id_profile_template%TYPE;
        l_num       NUMBER;
    
    BEGIN
    
        o_flg_show := pk_alert_constant.g_no;
        g_error    := 'OPEN c_diagnosis';
        OPEN c_diagnosis;
        FETCH c_diagnosis
            INTO l_diag_type, l_diag_code;
        CLOSE c_diagnosis;
        g_error   := 'CALL pk_prof_utils.get_prof_profile_template';
        l_profile := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'VERIFY shortcut';
        SELECT COUNT(1)
          INTO l_num
          FROM profile_templ_access pta
         WHERE pta.id_software = i_prof.software
           AND pta.id_profile_template IN (SELECT id_parent
                                             FROM profile_template pt
                                            WHERE pt.id_profile_template = l_profile
                                              AND id_parent IS NOT NULL
                                           UNION
                                           SELECT l_profile
                                             FROM dual)
           AND id_sys_shortcut = pk_trials.g_trial_shortcut;
    
        IF l_num > 0
        THEN
            o_shortcut := pk_trials.g_trial_shortcut;
        END IF;
        g_error := 'VERIFY diagnosis';
        IF ((l_diag_code = 'V70.7' AND l_diag_type IN ('C', 'I', 'N', 'U')) OR
           (l_diag_code = 'Z00.6' AND l_diag_type IN ('B', 'E', 'F', 'G', 'H', 'J', 'M', 'N')) OR
           ((l_diag_code = '428024001' OR l_diag_code = '185923000') AND l_diag_type = 'S'))
           AND l_num > 0
        THEN
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'TRIALS_T077');
            o_msg       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T078') || '<BR><BR>' ||
                           pk_message.get_message(i_lang, i_prof, 'TRIALS_T079');
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'VALIDATE_TRIALS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_trials;

    FUNCTION get_phd_ids
    (
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_flg_area              VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems
    ) RETURN table_number IS
        l_return                     table_number := table_number();
        l_id_pat_history_diagnosis   pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
        l_id_diagnosis               pat_history_diagnosis.id_diagnosis%TYPE;
        l_id_alert_diagnosis         pat_history_diagnosis.id_alert_diagnosis%TYPE;
        l_desc_pat_history_diagnosis pat_history_diagnosis.desc_pat_history_diagnosis%TYPE;
        l_id_patient                 pat_history_diagnosis.id_patient%TYPE;
        l_flg_other                  diagnosis.flg_type%TYPE;
        l_flg_status                 pat_history_diagnosis.flg_status%TYPE;
    BEGIN
    
        IF i_pat_history_diagnosis IS NOT NULL
        THEN
            SELECT phd.id_pat_history_diagnosis,
                   phd.id_diagnosis,
                   phd.id_alert_diagnosis,
                   phd.desc_pat_history_diagnosis,
                   phd.id_patient,
                   d.flg_other,
                   phd.flg_status
              INTO l_id_pat_history_diagnosis,
                   l_id_diagnosis,
                   l_id_alert_diagnosis,
                   l_desc_pat_history_diagnosis,
                   l_id_patient,
                   l_flg_other,
                   l_flg_status
              FROM pat_history_diagnosis phd
              LEFT JOIN diagnosis d
                ON d.id_diagnosis = phd.id_diagnosis
             WHERE phd.id_pat_history_diagnosis = i_pat_history_diagnosis
               AND phd.flg_area IN (i_flg_area, pk_alert_constant.g_diag_area_not_defined);
        
            IF l_flg_status IN (g_flg_status_none, g_flg_status_unk)
            THEN
                RETURN table_number();
            END IF;
        END IF;
    
        IF (l_id_diagnosis IS NOT NULL OR l_id_alert_diagnosis IS NOT NULL)
           AND l_flg_other <> pk_alert_constant.g_yes
        THEN
            SELECT k.id_pat_history_diagnosis
              BULK COLLECT
              INTO l_return
              FROM (SELECT phd.id_pat_history_diagnosis, phd.dt_pat_history_diagnosis_tstz
                      FROM pat_history_diagnosis phd
                     WHERE (phd.id_diagnosis = l_id_diagnosis OR phd.id_alert_diagnosis = l_id_alert_diagnosis)
                       AND phd.id_patient = l_id_patient
                    CONNECT BY PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new
                     START WITH phd.id_pat_history_diagnosis = l_id_pat_history_diagnosis) k
             ORDER BY k.dt_pat_history_diagnosis_tstz ASC;
        
        ELSIF l_desc_pat_history_diagnosis IS NOT NULL
        THEN
            FOR i IN (SELECT phd.id_pat_history_diagnosis_new, phd.id_pat_history_diagnosis
                        FROM pat_history_diagnosis phd
                       WHERE lower(phd.desc_pat_history_diagnosis) = lower(l_desc_pat_history_diagnosis)
                         AND phd.id_patient = l_id_patient
                         AND nvl(to_char(phd.id_alert_diagnosis), pk_alert_constant.g_yes) =
                             nvl(to_char(l_id_alert_diagnosis), pk_alert_constant.g_yes)
                         AND phd.flg_area IN (i_flg_area, pk_alert_constant.g_diag_area_not_defined)
                         AND phd.id_pat_history_diagnosis >= i_pat_history_diagnosis
                       ORDER BY phd.dt_pat_history_diagnosis_tstz ASC)
            LOOP
            
                l_return.extend;
                l_return(l_return.count + 1) := i.id_pat_history_diagnosis;
            
                IF i.id_pat_history_diagnosis_new IS NULL
                THEN
                    EXIT;
                END IF;
            
            END LOOP;
        
        ELSE
            l_return.extend(1);
            l_return(l_return.count) := i_pat_history_diagnosis;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_return := table_number();
            l_return.extend(1);
            l_return(l_return.count) := i_pat_history_diagnosis;
            RETURN l_return;
        
    END get_phd_ids;

    FUNCTION get_most_recent_phd_id
    (
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_flg_area              VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems
    ) RETURN NUMBER IS
        l_phd_ids table_number;
    BEGIN
        l_phd_ids := get_phd_ids(i_pat_history_diagnosis => i_pat_history_diagnosis, i_flg_area => i_flg_area);
        RETURN l_phd_ids(l_phd_ids.last);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_most_recent_phd_id;

    FUNCTION check_diagnosis_in_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_cdr_api_out IS
        l_ret t_coll_cdr_api_out;
    BEGIN
    
        SELECT t_rec_cdr_api_out(id_record  => t.id_problem,
                                 id_element => t.id_diagnosis,
                                 dt_record  => t.dt_problem,
                                 flg_source => t.flg_source,
                                 code_icd   => t.code_icd)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT v.id_problem   id_problem,
                       v.flg_source   flg_source,
                       v.dt_problem   dt_problem,
                       v.id_diagnosis id_diagnosis,
                       v.code_icd
                  FROM v_check_diagnosis_in_ehr v
                 WHERE v.id_patient = i_patient) t
         WHERE t.flg_source NOT IN (g_problem_type_allergy, g_problem_type_habit);
    
        RETURN l_ret;
    END check_diagnosis_in_ehr;

    FUNCTION check_synonym_diag_in_ehr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_alert_diag IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_is_present OUT VARCHAR2,
        o_diag_list  OUT table_number,
        o_diag_type  OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    BEGIN
        g_error := 'GET DIAG RECORDS';
        SELECT t.id_problem, decode(t.flg_source, g_problem_type_pmh, 'PMH', g_problem_type_diag, 'DIAG')
          BULK COLLECT
          INTO o_diag_list, o_diag_type
          FROM (
                --PAST_MEDICAL_HISTORY SECTION
                SELECT phd.id_pat_history_diagnosis id_problem,
                        decode(phd.id_alert_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh) flg_source,
                        phd.dt_pat_history_diagnosis_tstz dt_problem_tstz
                  FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
                 WHERE phd.id_alert_diagnosis = i_alert_diag
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_diagnosis = d.id_diagnosis
                      --AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                   AND phd.id_patient = i_patient
                   AND phd.flg_type = g_flg_type_med
                   AND phd.flg_status IN (pk_problems.g_pat_probl_active, pk_problems.g_pat_probl_passive)
                   AND phd.dt_pat_history_diagnosis_tstz >= nvl(i_start_date, phd.dt_pat_history_diagnosis_tstz)
                   AND phd.id_pat_history_diagnosis =
                       get_most_recent_phd_id(phd.id_pat_history_diagnosis, pk_alert_constant.g_diag_area_past_history)
                   AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                       (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                       phd.flg_area IN
                       (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)))
                   AND NOT EXISTS (SELECT 1
                          FROM pat_problem pp, epis_diagnosis ed, diagnosis d1
                         WHERE pp.id_diagnosis = d.id_diagnosis
                           AND pp.id_patient = phd.id_patient
                           AND pp.id_habit IS NULL
                           AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                           AND pp.id_diagnosis = d1.id_diagnosis(+)
                           AND ( --final diagnosis 
                                (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                                OR -- differencial diagnosis only 
                                (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                ed.id_diagnosis NOT IN
                                (SELECT ed3.id_diagnosis
                                    FROM epis_diagnosis ed3
                                   WHERE ed3.id_diagnosis = ed.id_diagnosis
                                     AND ed3.id_patient = pp.id_patient
                                     AND ed3.flg_type = pk_diagnosis.g_diag_type_d)) --
                                OR (pp.id_habit IS NOT NULL))
                           AND pp.flg_status <> g_pat_probl_invest
                           AND pp.dt_pat_problem_tstz > phd.dt_pat_history_diagnosis_tstz
                              --time filter
                           AND pp.dt_pat_problem_tstz >= nvl(i_start_date, pp.dt_pat_problem_tstz)
                           AND rownum = 1)
                UNION ALL
                -- PAT_PROBLEM SECTION
                SELECT pp.id_pat_problem id_problem,
                        decode(pp.desc_pat_problem,
                               '',
                               decode(pp.id_habit,
                                      '',
                                      decode(nvl(ed.id_epis_diagnosis, 0), 0, g_problem_type_pmh, g_problem_type_diag),
                                      g_problem_type_habit),
                               decode(pp.id_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh)) flg_source,
                        pp.dt_pat_problem_tstz dt_problem_tstz
                  FROM pat_problem     pp,
                        diagnosis       d,
                        alert_diagnosis ad,
                        epis_diagnosis  ed,
                        diagnosis       d1,
                        alert_diagnosis ad1
                 WHERE pp.id_alert_diagnosis = i_alert_diag
                   AND pp.id_patient = i_patient
                   AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+) -- ALERT 736: diagnosis synonyms
                   AND pp.flg_status IN (pk_problems.g_pat_probl_active, pk_problems.g_pat_probl_passive)
                   AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                   AND ed.id_diagnosis = d1.id_diagnosis(+)
                   AND ed.id_alert_diagnosis = ad1.id_alert_diagnosis(+) -- ALERT 736: diagnosis synonyms
                   AND pp.id_habit IS NULL
                   AND pp.id_diagnosis = d.id_diagnosis
                      -- RdSN To exclude relev.diseases and problems
                   AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
                   AND ( --final diagnosis 
                        (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                        OR -- differencial diagnosis only 
                        (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                        ed.id_diagnosis NOT IN (SELECT ed3.id_diagnosis
                                                   FROM epis_diagnosis ed3
                                                  WHERE ed3.id_diagnosis = ed.id_diagnosis
                                                    AND ed3.id_patient = pp.id_patient
                                                    AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
                   AND pp.flg_status <> g_pat_probl_invest
                      --Time filter
                   AND pp.dt_pat_problem_tstz >= nvl(i_start_date, pp.dt_pat_problem_tstz)
                   AND NOT EXISTS
                 (SELECT 1
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_patient = i_patient
                           AND phd.flg_type = g_flg_type_med
                           AND phd.id_diagnosis = pp.id_diagnosis
                           AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                           AND pp.dt_pat_problem_tstz < phd.dt_pat_history_diagnosis_tstz
                           AND pp.dt_pat_problem_tstz >= nvl(i_start_date, pp.dt_pat_problem_tstz)
                           AND rownum = 1)) t
         WHERE t.flg_source IN (g_problem_type_pmh, g_problem_type_diag);
    
        g_error := 'CHECK PROBLEM PRESENCE';
        IF o_diag_list.count >= 1
        THEN
            o_is_present := pk_alert_constant.g_yes;
        ELSE
            o_is_present := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_pk_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CHECK_DIAGNOSIS_IN_EHR',
                                                     o_error    => o_error);
    END check_synonym_diag_in_ehr;

    FUNCTION check_dup_icd_problem
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count                   NUMBER := 0;
        l_allow_problems_same_icd sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_PROBLEMS_SAME_ICD', i_prof);
        l_n_distinct_diagnoses    NUMBER := 0;
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
        o_msg      := NULL;
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT phd.id_diagnosis, phd.id_alert_diagnosis, phd.flg_status
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_episode = i_episode
                   AND phd.id_diagnosis IN (SELECT *
                                              FROM TABLE(i_id_diagnosis_list))
                   AND phd.id_alert_diagnosis NOT IN (SELECT *
                                                        FROM TABLE(i_id_alert_diag_list))
                   AND phd.flg_status != pk_diagnosis.g_ed_flg_status_ca
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND (l_allow_problems_same_icd = pk_alert_constant.g_no OR
                       nvl(pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                           i_id_concept_term    => phd.id_alert_diagnosis,
                                                           i_id_concept_version => phd.id_diagnosis,
                                                           i_id_task_type       => pk_alert_constant.g_task_problems,
                                                           i_id_institution     => i_prof.institution,
                                                           i_id_software        => i_prof.software),
                            pk_alert_constant.g_yes) = pk_alert_constant.g_no)
                
                UNION
                
                SELECT pp.id_diagnosis, pp.id_alert_diagnosis, pp.flg_status
                  FROM pat_problem pp
                  LEFT JOIN epis_diagnosis ed
                    ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                 WHERE pp.id_episode = i_episode
                   AND pp.id_diagnosis IN (SELECT *
                                             FROM TABLE(i_id_diagnosis_list))
                   AND pp.id_alert_diagnosis NOT IN (SELECT *
                                                       FROM TABLE(i_id_alert_diag_list))
                   AND pp.flg_status != pk_diagnosis.g_ed_flg_status_ca
                   AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca
                   AND (l_allow_problems_same_icd = pk_alert_constant.g_no OR
                       nvl(pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                           i_id_concept_term    => pp.id_alert_diagnosis,
                                                           i_id_concept_version => pp.id_diagnosis,
                                                           i_id_task_type       => pk_alert_constant.g_task_problems,
                                                           i_id_institution     => i_prof.institution,
                                                           i_id_software        => i_prof.software),
                            pk_alert_constant.g_yes) = pk_alert_constant.g_no));
    
        IF l_count > 0
        THEN
            o_flg_show := 'YW';
            o_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEM_LIST_T118');
        
        ELSE
            --CHECK IF FROM THE SELECTED PROBLEMS (WHICH HAVE NOT YET BEEN SAVED ON THE DB) 
            --THERE ARE RECORDS WITH THE SAME CODE AND IF THE CONFIGURATIONS (SYS_CONFIG AND CONTENT)
            --ALLOW SUCH SELECTION
            SELECT COUNT(*)
              INTO l_n_distinct_diagnoses
              FROM (SELECT DISTINCT column_value
                      FROM TABLE(i_id_diagnosis_list));
        
            IF l_n_distinct_diagnoses < i_id_diagnosis_list.count()
            THEN
                DECLARE
                    l_aux NUMBER := 0;
                BEGIN
                    SELECT COUNT(*)
                      INTO l_aux
                      FROM TABLE(i_id_diagnosis_list) t
                     WHERE pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                          i_id_concept_term    => NULL,
                                                          i_id_concept_version => t.column_value,
                                                          i_id_task_type       => pk_alert_constant.g_task_problems,
                                                          i_id_institution     => i_prof.institution,
                                                          i_id_software        => i_prof.software) =
                           pk_alert_constant.g_no;
                
                    IF l_aux > 0
                       OR l_allow_problems_same_icd = pk_alert_constant.g_no
                    THEN
                        o_flg_show := 'YW';
                        o_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROBLEM_LIST_T119');
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_aux := 0;
                END;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PROBLEMS',
                                              'CHECK_DUP_ICD_PROBLEM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_dup_icd_problem;

    FUNCTION get_desc_probl
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_id   IN NUMBER,
        i_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000 CHAR);
    BEGIN
    
        IF i_type = g_type_d
        THEN
            SELECT decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type),
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9))) desc_probl
              INTO l_return
              FROM pat_history_diagnosis phd
              LEFT JOIN diagnosis d
                ON phd.id_diagnosis = d.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
             WHERE phd.id_pat_history_diagnosis = i_id;
        
        ELSIF i_type = g_type_a
        THEN
            SELECT nvl2(pa.id_allergy, pk_translation.get_translation(i_lang, a.code_allergy), pa.desc_allergy) desc_probl
              INTO l_return
              FROM pat_allergy pa
              LEFT JOIN allergy a
                ON a.id_allergy = pa.id_allergy
             WHERE pa.id_pat_allergy = i_id;
        
        ELSIF i_type = g_type_p
        THEN
            SELECT decode(pp.desc_pat_problem,
                          '',
                          decode(pp.id_habit,
                                 '',
                                 decode(nvl(ed.id_epis_diagnosis, 0),
                                        0,
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                   i_id_diagnosis       => d.id_diagnosis,
                                                                   i_id_task_type       => pk_alert_constant.g_task_problems,
                                                                   i_code               => d.code_icd,
                                                                   i_flg_other          => d.flg_other,
                                                                   i_flg_std_diag       => ad.flg_icd9),
                                        pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                                   i_id_diagnosis        => d1.id_diagnosis,
                                                                   i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                   i_id_task_type        => pk_alert_constant.g_task_problems,
                                                                   i_code                => d1.code_icd,
                                                                   i_flg_other           => d1.flg_other,
                                                                   i_flg_std_diag        => ad1.flg_icd9,
                                                                   i_epis_diag           => ed.id_epis_diagnosis)),
                                 pk_translation.get_translation(i_lang, h.code_habit)),
                          pp.desc_pat_problem) desc_probl
              INTO l_return
              FROM pat_problem pp
              LEFT JOIN diagnosis d
                ON pp.id_diagnosis = d.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON pp.id_alert_diagnosis = ad.id_alert_diagnosis
              LEFT JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
              LEFT JOIN diagnosis d1
                ON ed.id_diagnosis = d1.id_diagnosis
              LEFT JOIN alert_diagnosis ad1
                ON ed.id_alert_diagnosis = ad1.id_alert_diagnosis
              LEFT JOIN habit h
                ON pp.id_habit = h.id_habit
             WHERE pp.id_pat_problem = i_id;
        ELSE
            l_return := NULL;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_probl;

    FUNCTION get_problem_types
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name            VARCHAR2(32 CHAR) := 'GET_PROBLEM_TYPES';
        l_problem_type_problem sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'EHR_VIEWER_T006');
        l_problem_type_pmh     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'RELEVANT_DISEASES_T001');
        l_problem_type_habit   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'EHR_HIST_T005');
        l_problem_type_diag    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'EHR_VIEWER_T007');
        l_problem_type_allergy sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'EHR_VIEWER_T024');
    BEGIN
        g_error := g_package_name || '.' || l_func_name || ' open o_list';
        OPEN o_list FOR
            SELECT aux.desc_val, aux.val, aux.img_name, aux.rank
              FROM (SELECT l_problem_type_allergy desc_val, g_problem_type_allergy val, NULL img_name, NULL rank
                      FROM dual
                    UNION ALL
                    SELECT l_problem_type_diag desc_val, g_problem_type_diag val, NULL img_name, NULL rank
                      FROM dual
                    UNION ALL
                    SELECT l_problem_type_habit desc_val, g_problem_type_habit val, NULL img_name, NULL rank
                      FROM dual
                    UNION ALL
                    SELECT l_problem_type_problem desc_val, g_problem_type_problem val, NULL img_name, NULL rank
                      FROM dual
                    UNION ALL
                    SELECT l_problem_type_pmh desc_val, g_problem_type_pmh val, NULL img_name, NULL rank
                      FROM dual) aux
             ORDER BY aux.desc_val ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_problem_types;

    FUNCTION get_flg_area
    (
        i_flg_area pat_history_diagnosis.flg_area%TYPE,
        i_flg_type pat_history_diagnosis.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(1 CHAR);
    
    BEGIN
        CASE i_flg_type
            WHEN pk_past_history.g_alert_diag_type_surg THEN
                l_ret := pk_alert_constant.g_diag_area_surgical_hist;
            WHEN pk_past_history.g_alert_diag_type_med THEN
                CASE i_flg_area
                    WHEN pk_alert_constant.g_diag_area_past_history THEN
                        l_ret := pk_alert_constant.g_diag_area_past_history;
                    ELSE
                        l_ret := pk_alert_constant.g_diag_area_problems;
                END CASE;
            ELSE
                l_ret := pk_alert_constant.g_diag_area_problems;
        END CASE;
    
        RETURN l_ret;
    END get_flg_area;

    FUNCTION get_areas_domain
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_record         IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        id_tl_task_timeline IN tl_task.id_tl_task%TYPE DEFAULT NULL,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(16 CHAR) := 'GET_AREAS_DOMAIN';
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_sc_show_surgical     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                        i_prof);
        l_excluded_areas       table_varchar;
        l_possible_areas       table_varchar;
        l_id_diagnosis         pat_history_diagnosis.id_diagnosis%TYPE;
        l_id_alert_diagnosis   pat_history_diagnosis.id_alert_diagnosis%TYPE;
        l_id_patient           pat_history_diagnosis.id_patient%TYPE;
        l_tbl_diags            t_coll_diagnosis_config;
        l_val                  VARCHAR2(1 CHAR);
        l_flg_type             pat_history_diagnosis.flg_type%TYPE;
        l_flg_area             pat_history_diagnosis.flg_area%TYPE;
        l_current_flg_area     pat_history_diagnosis.flg_area%TYPE;
    BEGIN
        -- when creating, only excludes not_defined type
        l_excluded_areas := table_varchar(pk_alert_constant.g_diag_area_not_defined);
    
        IF i_id_record IS NOT NULL
        THEN
            g_error := 'CHECK PAT_HISTORY_DIAGNOSIS DATA';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            -- when editing, checks to see which types should not be available
            SELECT phd.id_diagnosis, phd.id_alert_diagnosis, phd.id_patient, phd.flg_type, phd.flg_area
              INTO l_id_diagnosis, l_id_alert_diagnosis, l_id_patient, l_flg_type, l_flg_area
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_record;
        
            l_current_flg_area := get_flg_area(i_flg_area => l_flg_area, i_flg_type => l_flg_type);
        
            IF l_id_diagnosis IS NOT NULL
            THEN
                -- only validate if a id_diagnosis was used, or else it was a free text record and can be changed to any type
                -- loads current possibilities to be displayed in problems "type" field
                l_possible_areas := table_varchar(pk_alert_constant.g_diag_area_past_history,
                                                  pk_alert_constant.g_diag_area_problems,
                                                  pk_alert_constant.g_diag_area_surgical_hist);
            
                FOR i IN l_possible_areas.first .. l_possible_areas.last
                LOOP
                    IF l_current_flg_area <> l_possible_areas(i)
                    THEN
                        g_error := 'CHECK CONTENT AVAILABILITY';
                        pk_alertlog.log_info(text            => g_error,
                                             object_name     => g_package_name,
                                             sub_object_name => l_func_name);
                        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                               i_prof                     => i_prof,
                                                                               i_patient                  => l_id_patient,
                                                                               i_terminologies_task_types => table_number(get_flg_area_task_type(i_flg_area => l_possible_areas(i))),
                                                                               i_term_task_type           => get_flg_area_task_type(l_possible_areas(i)),
                                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                               i_tbl_diagnosis            => table_number(l_id_diagnosis),
                                                                               i_tbl_alert_diagnosis      => table_number(l_id_alert_diagnosis));
                        IF l_tbl_diags.count <= 0
                        THEN
                            -- if the current type does not have the same content configured, removes the type from the possibilities
                            l_excluded_areas.extend;
                            l_excluded_areas(l_excluded_areas.count) := l_possible_areas(i);
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        IF id_tl_task_timeline IS NOT NULL
        THEN
        
            IF id_tl_task_timeline = pk_prog_notes_constants.g_task_ph_medical_hist
            THEN
                l_val := g_ph_medical_hist;
            ELSIF id_tl_task_timeline = pk_prog_notes_constants.g_task_ph_surgical_hist
            THEN
                l_val := g_ph_surgical_hist;
            ELSIF id_tl_task_timeline = pk_prog_notes_constants.g_task_problems
            THEN
                l_val := g_prob;
            END IF;
        
            OPEN o_list FOR
                SELECT *
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                      i_prof          => i_prof,
                                                                      i_code_dom      => g_area_sys_domain,
                                                                      i_dep_clin_serv => NULL)) t
                 WHERE t.val = l_val;
        ELSE
        
            g_error := ' open o_list';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF l_sc_show_surgical = g_no
            THEN
                -- if the current type does not have the same content configured, removes the type from the possibilities
                l_excluded_areas.extend;
                l_excluded_areas(l_excluded_areas.count) := pk_alert_constant.g_diag_area_surgical_hist;
            
            END IF;
            IF l_sys_config_show_diag = pk_alert_constant.g_diag_area_config_show_own
            THEN
                -- if the current type does not have the same content configured, removes the type from the possibilities
                l_excluded_areas.extend;
                l_excluded_areas(l_excluded_areas.count) := pk_alert_constant.g_diag_area_past_history;
            
            END IF;
        
            OPEN o_list FOR
                SELECT d.*
                  FROM (SELECT *
                          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                              i_prof          => i_prof,
                                                                              i_code_dom      => g_area_sys_domain,
                                                                              i_dep_clin_serv => NULL)) t
                         WHERE t.val NOT IN (SELECT *
                                               FROM TABLE(l_excluded_areas))) d
                 ORDER BY d.rank;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_areas_domain;

    FUNCTION get_problem_type_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_area           IN pat_history_diagnosis.flg_area%TYPE,
        i_id_alert_diagnosis IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_flg_type           IN pat_history_diagnosis.flg_type%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_func_name VARCHAR2(21 CHAR) := 'GET_PROBLEM_TYPE_DESC';
        l_flg_area  pat_history_diagnosis.flg_area%TYPE := i_flg_area;
    BEGIN
    
        l_flg_area := get_flg_area(i_flg_area => i_flg_area, i_flg_type => i_flg_type);
    
        RETURN pk_sysdomain.get_domain(i_code_dom => g_area_sys_domain, i_val => l_flg_area, i_lang => i_lang);
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR on get_problem_type_desc. i_flg_area: ' || i_flg_area || ' i_id_alert_diagnosis: ' ||
                       i_id_alert_diagnosis;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            RETURN NULL;
    END get_problem_type_desc;

    FUNCTION get_description_phd
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_phd    IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_desc_type IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
        l_ret            CLOB;
        desc_problem_all CLOB;
        desc_status      sys_domain.desc_val%TYPE;
        prob_notes       pat_history_diagnosis.notes%TYPE;
    
        CURSOR c_desc IS
            SELECT decode(phd.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                    i_flg_type => phd.flg_type),
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(phd.id_alert_diagnosis,
                                 NULL,
                                 phd.desc_pat_history_diagnosis,
                                 phd.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                           i_flg_type => phd.flg_type),
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9))) ||
                   decode(i_desc_type,
                          pk_prog_notes_constants.g_desc_type_s,
                          '',
                          ', ' || get_problem_type_desc(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_flg_area           => phd.flg_area,
                                                        i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                        i_flg_type           => phd.flg_type)) desc_probl,
                   decode(i_desc_type,
                          pk_prog_notes_constants.g_desc_type_s,
                          '',
                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang)) desc_status,
                   decode(phd.flg_status, 'C', phd.cancel_notes, phd.notes) prob_notes
              FROM pat_history_diagnosis phd
              LEFT JOIN diagnosis d
                ON phd.id_diagnosis = d.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
             WHERE phd.id_pat_history_diagnosis = i_id_phd;
    
    BEGIN
        alertlog.pk_alertlog.log_info(text            => 'i_desc_type:' || i_desc_type || ' i_id_phd :' || i_id_phd,
                                      object_name     => g_package_name,
                                      sub_object_name => 'get_description_phd');
        OPEN c_desc;
        FETCH c_desc
            INTO desc_problem_all, desc_status, prob_notes;
        CLOSE c_desc;
    
        l_ret := pk_prog_notes_dblock.get_format_string_problems(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_problem_desc   => desc_problem_all,
                                                                 i_problem_status => desc_status,
                                                                 i_problem_notes  => prob_notes);
    
        l_ret := pk_string_utils.trim_empty_lines(i_text => l_ret);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_description_phd;

    FUNCTION get_description_pp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_pp     IN pat_problem.id_pat_problem%TYPE,
        i_desc_type IN VARCHAR2
    ) RETURN CLOB IS
        l_ret            CLOB;
        desc_problem_all CLOB;
        desc_status      sys_domain.desc_val%TYPE;
        prob_notes       pat_history_diagnosis.notes%TYPE;
    
        CURSOR c_desc IS
            SELECT decode(pp.desc_pat_problem,
                          '',
                          decode(nvl(ed.id_epis_diagnosis, 0),
                                 0,
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_id_task_type       => pk_alert_constant.g_task_problems,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9),
                                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_alert_diagnosis  => ad1.id_alert_diagnosis,
                                                            i_id_diagnosis        => d1.id_diagnosis,
                                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                            i_id_task_type        => pk_alert_constant.g_task_problems,
                                                            i_code                => d1.code_icd,
                                                            i_flg_other           => d1.flg_other,
                                                            i_flg_std_diag        => ad1.flg_icd9,
                                                            i_epis_diag           => ed.id_epis_diagnosis)),
                          
                          pp.desc_pat_problem) desc_probl,
                   decode(nvl(ed.id_epis_diagnosis, 0),
                          0,
                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang),
                          decode(ed.flg_status,
                                 'C',
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', ed.flg_status, i_lang),
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang))) desc_status,
                   decode(pp.flg_status, 'C', pp.cancel_notes, pp.notes) prob_notes
              FROM pat_problem pp
              LEFT JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
              LEFT JOIN alert_diagnosis ad1
                ON ed.id_alert_diagnosis = ad1.id_alert_diagnosis
              LEFT JOIN diagnosis d1
                ON ed.id_diagnosis = d1.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON pp.id_alert_diagnosis = ad.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON pp.id_diagnosis = d.id_diagnosis
             WHERE pp.id_pat_problem = i_id_pp;
    
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO desc_problem_all, desc_status, prob_notes;
        CLOSE c_desc;
    
        l_ret := pk_prog_notes_dblock.get_format_string_problems(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_problem_desc   => desc_problem_all,
                                                                 i_problem_status => desc_status,
                                                                 i_problem_notes  => prob_notes);
    
        l_ret := pk_string_utils.trim_empty_lines(i_text => l_ret);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_description_pp;

    FUNCTION get_desc_prob_unaware
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_pat_prob_unaware IN pat_prob_unaware.id_pat_prob_unaware%TYPE,
        i_desc_type           IN VARCHAR2
    ) RETURN CLOB IS
        l_ret       CLOB;
        l_desc_prob CLOB;
        l_notes     pat_history_diagnosis.notes%TYPE;
        CURSOR c_desc IS
            SELECT pk_translation.get_translation(i_lang, pu.code_prob_unaware) l_desc_prob,
                   decode(ppu.flg_status, pk_problems.g_status_ppu_cancel, ppu.cancel_notes, ppu.notes) l_notes
              FROM pat_prob_unaware ppu
              LEFT JOIN prob_unaware pu
                ON pu.id_prob_unaware = ppu.id_prob_unaware
             WHERE ppu.id_pat_prob_unaware = i_id_pat_prob_unaware;
    
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_desc_prob, l_notes;
        CLOSE c_desc;
    
        l_ret := l_desc_prob || --
                 CASE
                     WHEN l_notes IS NOT NULL THEN
                      pk_prog_notes_constants.g_comma || l_notes
                     ELSE
                      NULL
                 END;
    
        l_ret := pk_string_utils.trim_empty_lines(i_text => l_ret);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_prob_unaware;

    FUNCTION get_flg_area_task_type
    (
        i_flg_area pat_history_diagnosis.flg_area%TYPE,
        i_flg_type pat_history_diagnosis.flg_type%TYPE DEFAULT NULL
    ) RETURN task_type.id_task_type%TYPE IS
    
        l_flg_type pat_history_diagnosis.flg_type%TYPE;
    
    BEGIN
        IF i_flg_type IS NOT NULL
        THEN
            l_flg_type := i_flg_type;
        ELSE
            -- if the flg_type is not received, calculates it based on flg_area
            SELECT decode(i_flg_area,
                          pk_past_history.g_alert_diag_type_surg,
                          pk_past_history.g_alert_diag_type_surg,
                          pk_past_history.g_alert_diag_type_med)
              INTO l_flg_type
              FROM dual;
        END IF;
    
        CASE l_flg_type
            WHEN pk_past_history.g_alert_diag_type_surg THEN
                RETURN pk_alert_constant.g_task_surgical_history;
            WHEN pk_past_history.g_alert_diag_type_med THEN
                CASE i_flg_area
                    WHEN pk_alert_constant.g_diag_area_past_history THEN
                        RETURN pk_alert_constant.g_task_medical_history;
                    ELSE
                        RETURN pk_alert_constant.g_task_problems;
                END CASE;
            WHEN pk_past_history.g_alert_diag_type_cong_anom THEN
                RETURN pk_alert_constant.g_task_congenital_anomalies;
            ELSE
                RETURN pk_alert_constant.g_task_problems;
        END CASE;
    END get_flg_area_task_type;

    FUNCTION get_flg_info_button
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diag IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_other               diagnosis.flg_other%TYPE;
        l_code_icd                diagnosis.code_icd%TYPE;
        l_term_international_code diagnosis.term_international_code%TYPE;
    
    BEGIN
    
        -- Get Overall permissions, and if url is configured.       
        IF pk_info_button.get_show_info_button(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_task_type => pk_alert_constant.g_task_diagnosis) =
           pk_alert_constant.g_no
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        IF (i_diag IS NULL)
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        SELECT d.flg_other, d.code_icd, d.term_international_code
          INTO l_flg_other, l_code_icd, l_term_international_code
          FROM diagnosis d
         WHERE d.id_diagnosis = i_diag;
    
        IF (l_flg_other = pk_alert_constant.g_no AND l_code_icd IS NOT NULL AND l_term_international_code IS NOT NULL)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END get_flg_info_button;

    FUNCTION validate_diagnosis_selection
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_area           IN pat_history_diagnosis.flg_area%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        o_id_diagnosis       OUT table_number,
        o_id_alert_diagnosis OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'VALIDATE_DIAGNOSIS_SELECTION';
        l_task_type task_type.id_task_type%TYPE;
        l_tbl_diags t_coll_diagnosis_config;
    
    BEGIN
        -- validate arrays
        g_error := 'VALIDATE ARRAYS';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT i_id_diagnosis.exists(1)
           OR NOT i_id_alert_diagnosis.exists(1)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_id_diagnosis.count <> i_id_alert_diagnosis.count
        THEN
            RAISE g_exception;
        END IF;
    
        o_id_diagnosis       := table_number();
        o_id_alert_diagnosis := table_number();
    
        g_error := 'CALCULATE TASK TYPE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_task_type := get_flg_area_task_type(i_flg_area => i_flg_area);
    
        g_error := 'LOOP DIAGNOSES ARRAYS';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        FOR i IN i_id_diagnosis.first .. i_id_diagnosis.last
        LOOP
            g_error := 'CHECK CONTENT AVAILABILITY';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                   i_prof                     => i_prof,
                                                                   i_patient                  => i_id_patient,
                                                                   i_terminologies_task_types => table_number(l_task_type),
                                                                   i_term_task_type           => l_task_type,
                                                                   i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                   i_tbl_diagnosis            => table_number(i_id_diagnosis(i)),
                                                                   i_tbl_alert_diagnosis      => table_number(i_id_alert_diagnosis(i)));
            IF l_tbl_diags.count > 0
            THEN
                -- if the diagnosis exists in the new type add it to the return array
                o_id_diagnosis.extend;
                o_id_diagnosis(o_id_diagnosis.count) := i_id_diagnosis(i);
            
                o_id_alert_diagnosis.extend;
                o_id_alert_diagnosis(o_id_diagnosis.count) := i_id_alert_diagnosis(i);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_diagnosis_selection;

    FUNCTION get_validate_button_areas
    (
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
        IF i_id_tl_task = pk_prog_notes_constants.g_task_problems
        THEN
            RETURN g_yes;
        ELSIF i_id_tl_task = pk_prog_notes_constants.g_task_ph_surgical_hist
        THEN
            RETURN pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, i_prof);
        ELSIF i_id_tl_task = pk_prog_notes_constants.g_task_ph_medical_hist
        THEN
            IF pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, i_prof) = g_active
            THEN
                RETURN g_yes;
            ELSE
                RETURN g_no;
            END IF;
        ELSE
            RETURN g_no;
        END IF;
    
    END get_validate_button_areas;

    FUNCTION get_validate_add_button
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM TABLE(get_pat_problem_tf(i_lang,
                                        i_prof,
                                        i_patient,
                                        table_varchar(g_active, g_passive, g_inactive),
                                        NULL,
                                        NULL,
                                        i_episode,
                                        NULL,
                                        NULL,
                                        NULL));
    
        SELECT l_count + COUNT(*)
          INTO l_count
          FROM pat_prob_unaware
         WHERE id_patient = i_patient
           AND flg_status = g_active;
    
        IF l_count != 0
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
    END get_validate_add_button;

    FUNCTION get_pat_problem_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN pat_history_diagnosis.id_patient%TYPE,
        i_type        IN VARCHAR2,
        i_id          IN NUMBER,
        i_id_episode  IN pat_problem.id_episode%TYPE,
        o_pat_problem OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL get_phd';
        IF i_type IN ('PH', 'PP')
        THEN
        
            OPEN o_pat_problem FOR
                SELECT dt_problem2 dateregister,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.viewer_id_prof) professionalname,
                       origin_specialty speciality,
                       desc_status flgstatusdescription,
                       0 procedurecounter,
                       resolution_date_str datebegin,
                       flg_source flgsourcedescription,
                       0 medicationcounter,
                       pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', flg_nature, i_lang) flgnaturedescription,
                       NULL flgsource,
                       NULL description,
                       flg_status flgstatus,
                       NULL institution
                  FROM (SELECT *
                          FROM TABLE(get_phd(i_lang,
                                             i_prof,
                                             i_id_patient,
                                             table_varchar(),
                                             NULL,
                                             i_id_episode,
                                             NULL,
                                             NULL,
                                             NULL)) phd
                        UNION ALL
                        SELECT *
                          FROM TABLE(get_pp(i_lang,
                                            i_prof,
                                            i_id_patient,
                                            table_varchar(),
                                            NULL,
                                            NULL,
                                            i_id_episode,
                                            NULL,
                                            NULL,
                                            NULL)) pp
                        UNION ALL
                        SELECT *
                          FROM TABLE(get_pa(i_lang,
                                            i_prof,
                                            i_id_patient,
                                            table_varchar(),
                                            NULL,
                                            i_id_episode,
                                            NULL,
                                            NULL,
                                            NULL)) pa) t
                 WHERE t.id_problem = i_id;
        ELSE
        
            OPEN o_pat_problem FOR
                SELECT *
                  FROM (SELECT *
                          FROM TABLE(get_phd(i_lang,
                                             i_prof,
                                             i_id_patient,
                                             table_varchar(),
                                             NULL,
                                             i_id_episode,
                                             g_report_p,
                                             NULL,
                                             NULL)) phd
                        UNION ALL
                        SELECT *
                          FROM TABLE(get_pp(i_lang,
                                            i_prof,
                                            i_id_patient,
                                            table_varchar(),
                                            NULL,
                                            NULL,
                                            i_id_episode,
                                            g_report_p,
                                            NULL,
                                            NULL)) pp
                        UNION ALL
                        SELECT *
                          FROM TABLE(get_pa(i_lang,
                                            i_prof,
                                            i_id_patient,
                                            table_varchar(),
                                            NULL,
                                            i_id_episode,
                                            g_report_p,
                                            NULL,
                                            NULL)) pa) t;
        END IF;
    
        RETURN TRUE;
    END get_pat_problem_detail;

    FUNCTION get_diag_flg_warning_value
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diag IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
    
        l_warning VARCHAR2(1 CHAR);
    
    BEGIN
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_warning
              FROM diag_diag_condition ddc
             WHERE ddc.id_software IN (0, i_prof.software)
               AND ddc.id_institution IN (0, i_prof.institution)
               AND ddc.id_diagnosis = i_diag
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_warning := pk_alert_constant.g_no;
        END;
        RETURN l_warning;
    
    END;

    FUNCTION get_diag_flg_warning
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag         IN table_number,
        o_diag_warning OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30 CHAR) := 'GET_DIAG_FLG_WARNING';
    
    BEGIN
    
        g_error := 'CALL pk_problems.get_diag_flg_warning';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_diag_warning FOR
            SELECT val data, pk_sysdomain.get_domain(pk_list.g_yes_no, val, i_lang) label, id_diagnosis
              FROM (SELECT get_diag_flg_warning_value(i_lang, i_prof, d.id_diagnosis) val, d.id_diagnosis
                      FROM diagnosis d
                     WHERE d.id_diagnosis IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                               column_value
                                                FROM TABLE(i_diag)));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_id_location IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_infection NUMBER;
        l_func_name VARCHAR2(30 CHAR) := 'GET_PLACE_OF_OCCURENCE';
    BEGIN
        --      checks  if it is an infection 
        SELECT COUNT(1)
          INTO l_infection
          FROM diag_diag_condition ddc
         WHERE ddc.id_software IN (0, i_prof.software)
           AND ddc.id_institution IN (0, i_prof.institution)
           AND ddc.id_diagnosis = i_diagnosis;
    
        IF l_infection > 0 -- this diagnosis is an infection 
        THEN
            -- gets the place of occurrence configured
            IF NOT pk_diagnosis_form.get_place_of_occurence(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_diagnosis   => i_diagnosis,
                                                            i_id_location => i_id_location,
                                                            o_location    => o_location,
                                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_location);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_location);
            RETURN FALSE;
    END get_place_of_occurence;

    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN table_number,
        i_id_location IN table_number DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_infection NUMBER;
        l_func_name VARCHAR2(30 CHAR) := 'GET_PLACE_OF_OCCURENCE';
    BEGIN
        --Checks if the input diagnoses are infections
        SELECT COUNT(1)
          INTO l_infection
          FROM diag_diag_condition ddc
         WHERE ddc.id_software IN (0, i_prof.software)
           AND ddc.id_institution IN (0, i_prof.institution)
           AND ddc.id_diagnosis IN (SELECT /*+opt_estimate(table d rows=1)*/
                                     d.*
                                      FROM TABLE(i_diagnosis) d);
    
        IF l_infection > 0
           AND l_infection = i_diagnosis.count
        THEN
            -- gets the places of occurrence configured
            IF NOT pk_diagnosis_form.get_place_of_occurence(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_diagnosis   => i_diagnosis,
                                                            i_id_location => i_id_location,
                                                            o_location    => o_location,
                                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_location);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_location);
            RETURN FALSE;
    END get_place_of_occurence;

    FUNCTION get_count_prob_unaware(i_tbl_episode IN table_number) RETURN NUMBER IS
        l_count NUMBER;
        k_cancel CONSTANT VARCHAR2(0001 CHAR) := 'C';
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM pat_prob_unaware p
          JOIN (SELECT /*+ opt_estimate(table t rows=1)*/
                 column_value id_episode
                  FROM TABLE(i_tbl_episode) t) e
            ON e.id_episode = p.id_episode
         WHERE flg_status NOT IN (g_status_ppu_outdated, g_status_ppu_cancel);
    
        RETURN l_count;
    
    END get_count_prob_unaware;

    FUNCTION get_vwr_past_history_ph
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status      VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_id_visit    NUMBER;
        l_count       NUMBER;
        l_scope       NUMBER;
        l_tbl_episode table_number := table_number();
        k_vwr_flg_cancelled CONSTANT VARCHAR2(0001 CHAR) := 'C';
    BEGIN
    
        SELECT id_visit
          INTO l_id_visit
          FROM episode
         WHERE id_episode = i_episode;
    
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                l_scope := i_episode;
            WHEN pk_alert_constant.g_scope_type_visit THEN
                l_scope := l_id_visit;
            ELSE
                l_scope := i_episode;
        END CASE;
    
        SELECT COUNT(*)
          INTO l_count
          FROM TABLE(pk_problems.get_phd(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_pat         => i_patient,
                                         i_status      => NULL,
                                         i_problem     => NULL,
                                         i_id_scope    => l_scope,
                                         i_scope       => i_scope_type,
                                         i_dt_ini      => NULL,
                                         i_dt_end      => NULL,
                                         i_show_ph     => 'Y',
                                         i_show_review => 'Y')) xx
         WHERE xx.flg_status != k_vwr_flg_cancelled;
    
        IF l_count = 0
        THEN
        
            l_tbl_episode := pk_episode.get_scope(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_patient    => i_patient,
                                                  i_episode    => i_episode,
                                                  i_flg_filter => i_scope_type);
        
            l_count := get_count_prob_unaware(i_tbl_episode => l_tbl_episode);
        
        END IF;
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_vwr_past_history_ph;

    FUNCTION get_problems_precautions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_precautions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(30 CHAR) := 'GET_PROBLEMS_PRECAUTIONS';
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_sc_show_surgical     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                        i_prof);
        l_show_all             sys_config.value%TYPE := pk_sysconfig.get_config('SUMMARY_VIEW_ALL', i_prof);
        l_problem              table_varchar;
        l_precaution           table_varchar;
        l_count                NUMBER;
        l_precaution_list      VARCHAR2(4000 CHAR);
    BEGIN
    
        IF NOT get_pat_precaution(i_lang              => i_lang,
                                  i_pat               => i_patient,
                                  i_prof              => i_prof,
                                  o_precaution_list   => l_precaution_list,
                                  o_precaution_number => l_count,
                                  o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_precautions);
            RETURN FALSE;
        END IF;
    
        OPEN o_precautions FOR
            SELECT decode(l_count, 0, '', upper(pk_message.get_message(i_lang, 'PROBLEM_LIST_T031')) || ':') title,
                   l_precaution_list VALUE
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_precautions);
            RETURN FALSE;
        
    END get_problems_precautions;

    FUNCTION get_count_prob_in_group
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_problem      IN epis_prob.id_problem%TYPE,
        o_epis_prob_group OUT epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN NUMBER IS
        l_ret             NUMBER(24) := 0;
        l_epis_prob_group epis_prob_group.id_epis_prob_group%TYPE;
    BEGIN
    
        BEGIN
            SELECT ep.id_epis_prob_group
              INTO l_epis_prob_group
              FROM epis_prob ep
             WHERE ep.id_problem = i_id_problem
               AND ep.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                o_epis_prob_group := 0;
        END;
    
        IF l_epis_prob_group > 0
        THEN
            SELECT COUNT(1)
              INTO l_ret
              FROM epis_prob ep
             WHERE ep.id_episode = i_episode
               AND ep.id_epis_prob_group = l_epis_prob_group
               AND ep.id_problem_new IS NULL
               AND ep.flg_status IN (g_active, g_passive);
        
        END IF;
        o_epis_prob_group := l_epis_prob_group;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_epis_prob_group := 0;
            RETURN l_ret;
    END get_count_prob_in_group;

    FUNCTION set_epis_prob_to_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_problem IN epis_prob.id_epis_problem%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SET_EPIS_PROB_TO_HIST';
    
        l_rowids_hist table_varchar;
        v_epis_prob   epis_prob_hist%ROWTYPE;
    
        CURSOR c_epis_prob(l_id epis_prob.id_epis_problem%TYPE) IS
            SELECT ep.id_epis_problem,
                   ep.id_problem,
                   ep.id_epis_prob_group,
                   ep.id_episode,
                   ep.flg_type,
                   ep.flg_status,
                   ep.rank,
                   ep.id_cancel_reason,
                   ep.cancel_notes,
                   ep.id_prof_cancel,
                   ep.dt_cancel,
                   ep.id_problem_new,
                   ep.id_professional,
                   ep.dt_epis_prob_tstz
              FROM epis_prob ep
             WHERE ep.id_epis_problem = l_id;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_EPIS_PROB';
        OPEN c_epis_prob(i_id_epis_problem);
        FETCH c_epis_prob
            INTO v_epis_prob.id_epis_problem,
                 v_epis_prob.id_problem,
                 v_epis_prob.id_epis_prob_group,
                 v_epis_prob.id_episode,
                 v_epis_prob.flg_type,
                 v_epis_prob.flg_status,
                 v_epis_prob.rank,
                 v_epis_prob.id_cancel_reason,
                 v_epis_prob.cancel_notes,
                 v_epis_prob.id_prof_cancel,
                 v_epis_prob.dt_cancel,
                 v_epis_prob.id_problem_new,
                 v_epis_prob.id_professional,
                 v_epis_prob.dt_epis_prob_tstz;
        g_found := c_epis_prob%NOTFOUND;
        CLOSE c_epis_prob;
    
        g_error := 'TS_EPIS_PROB_HIST.INS';
    
        ts_epis_prob_hist.ins(id_epis_problem_hist_in => ts_epis_prob_hist.next_key,
                              dt_epis_prob_hist_in    => current_timestamp,
                              id_epis_problem_in      => v_epis_prob.id_epis_problem,
                              id_problem_in           => v_epis_prob.id_problem,
                              id_epis_prob_group_in   => v_epis_prob.id_epis_prob_group,
                              id_episode_in           => v_epis_prob.id_episode,
                              flg_type_in             => v_epis_prob.flg_type,
                              flg_status_in           => v_epis_prob.flg_status,
                              rank_in                 => v_epis_prob.rank,
                              id_cancel_reason_in     => v_epis_prob.id_cancel_reason,
                              cancel_notes_in         => v_epis_prob.cancel_notes,
                              id_prof_cancel_in       => v_epis_prob.id_prof_cancel,
                              dt_cancel_in            => v_epis_prob.dt_cancel,
                              id_problem_new_in       => v_epis_prob.id_problem_new,
                              id_professional_in      => v_epis_prob.id_professional,
                              dt_epis_prob_tstz_in    => v_epis_prob.dt_epis_prob_tstz);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_prob_to_hist;

    FUNCTION set_epis_prob_group_to_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SET_EPIS_PROB_GROUP_TO_HIST';
    
        l_rowids_hist     table_varchar;
        v_epis_prob_group epis_prob_group_hist%ROWTYPE;
    
        CURSOR c_epis_prob_group(l_id epis_prob_group.id_epis_prob_group%TYPE) IS
            SELECT epg.id_epis_prob_group,
                   epg.id_episode,
                   epg.prob_group,
                   epg.id_professional,
                   epg.dt_epis_prob_group_tstz
              FROM epis_prob_group epg
             WHERE epg.id_epis_prob_group = l_id;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_EPIS_PROB_GROUP';
        OPEN c_epis_prob_group(i_id_epis_prob_group);
        FETCH c_epis_prob_group
            INTO v_epis_prob_group.id_epis_prob_group,
                 v_epis_prob_group.id_episode,
                 v_epis_prob_group.prob_group,
                 v_epis_prob_group.id_professional,
                 v_epis_prob_group.dt_epis_prob_group_tstz;
        g_found := c_epis_prob_group%NOTFOUND;
        CLOSE c_epis_prob_group;
    
        g_error := 'TS_EPIS_PROB_GROUP_HIST.INS';
    
        ts_epis_prob_group_hist.ins(id_epis_prob_group_hist_in => ts_epis_prob_group_hist.next_key,
                                    dt_epis_prob_group_hist_in => current_timestamp,
                                    id_epis_prob_group_in      => v_epis_prob_group.id_epis_prob_group,
                                    id_episode_in              => v_epis_prob_group.id_episode,
                                    prob_group_in              => v_epis_prob_group.prob_group,
                                    id_professional_in         => v_epis_prob_group.id_professional,
                                    dt_epis_prob_group_tstz_in => v_epis_prob_group.dt_epis_prob_group_tstz);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_prob_group_to_hist;

    FUNCTION set_epis_problem_group_array
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_prof            IN profissional,
        i_id_problem      IN table_number,
        i_prev_id_problem IN table_number,
        i_flg_status      IN table_varchar,
        i_prob_group      IN table_number,
        i_seq_num         IN table_number,
        i_flg_type        IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_has_group sys_config.value%TYPE := pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof);
    
        l_id_epis_prob_group  epis_prob_group.id_epis_prob_group%TYPE;
        l_pre_epis_prob_group epis_prob_group.id_epis_prob_group%TYPE;
        l_prob_group          epis_prob_group.prob_group%TYPE;
        l_seq_num             epis_prob.rank%TYPE;
        l_id_epis_problem     epis_prob.id_epis_problem%TYPE;
        l_prev_epis_problem   epis_prob.id_epis_problem%TYPE;
        l_cnt_problem         NUMBER(24);
    
        l_rows table_varchar;
    
        l_id_problem      NUMBER(24);
        l_group_exception EXCEPTION;
    
        CURSOR c_next_seq_num IS
            SELECT nvl(MAX(ep.rank), 0) + 1
              FROM epis_prob ep
             WHERE ep.id_episode = i_episode;
    
        CURSOR c_epis_prob_group(l_prob_group epis_prob_group.prob_group%TYPE) IS
            SELECT epg.id_epis_prob_group
              FROM epis_prob_group epg
             WHERE epg.prob_group = l_prob_group
               AND epg.id_episode = i_episode;
    
        CURSOR c_epis_prob(l_id_problem epis_prob.id_problem%TYPE) IS
            SELECT ep.id_epis_problem
              FROM epis_prob ep
             WHERE ep.id_problem = l_id_problem
               AND ep.id_episode = i_episode;
    
    BEGIN
    
        g_error := 'START SET_EPIS_PROBLEM_GROUP_ARRAY';
        FOR i IN 1 .. i_id_problem.count
        LOOP
        
            IF l_has_group = pk_alert_constant.get_yes
            THEN
                IF i_prob_group IS NOT NULL
                   AND i_prob_group.count > 0
                THEN
                    l_prob_group := i_prob_group(i);
                    IF i_flg_status(i) <> g_cancelled
                    THEN
                        -- Check if the other problems with different status has the same group id
                        g_error := 'CHECK PROBLEM GROUP';
                        BEGIN
                            SELECT t.id_problem
                              INTO l_id_problem
                              FROM (SELECT ep.id_episode, ep.id_problem, ep.flg_status, epg.prob_group
                                      FROM epis_prob ep
                                      JOIN epis_prob_group epg
                                        ON epg.id_epis_prob_group = ep.id_epis_prob_group
                                      JOIN pat_history_diagnosis phd
                                        ON (phd.id_pat_history_diagnosis = ep.id_problem AND
                                           phd.id_episode = ep.id_episode AND ep.flg_type = g_type_d)
                                     WHERE phd.id_pat_history_diagnosis_new IS NULL) t
                             WHERE t.id_episode = i_episode
                               AND t.prob_group = l_prob_group
                               AND t.flg_status <> i_flg_status(i)
                               AND t.flg_status <> g_cancelled
                               AND rownum = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_problem := 0;
                        END;
                        IF l_id_problem > 0
                        THEN
                            RAISE l_group_exception;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
            IF i_seq_num IS NOT NULL
               AND i_seq_num.count > 0
            THEN
                l_seq_num := i_seq_num(i);
            END IF;
        
            IF l_seq_num IS NULL
            THEN
                g_error := 'GET L_SEQ_NUM_START';
                OPEN c_next_seq_num;
                FETCH c_next_seq_num
                    INTO l_seq_num;
                g_found := c_next_seq_num%NOTFOUND;
                CLOSE c_next_seq_num;
            END IF;
        
            g_error := 'INSERT EPISODE PROBLEM GROUP DATA';
            OPEN c_epis_prob_group(l_prob_group);
            FETCH c_epis_prob_group
                INTO l_id_epis_prob_group;
            g_found := c_epis_prob_group%NOTFOUND;
            CLOSE c_epis_prob_group;
        
            IF l_has_group = pk_alert_constant.get_no
            THEN
                l_id_epis_prob_group := -1;
            END IF;
        
            -- get id_epis_prob_group
            IF l_id_epis_prob_group IS NULL
            THEN
                ts_epis_prob_group.ins(id_episode_in              => i_episode,
                                       prob_group_in              => l_prob_group,
                                       id_professional_in         => i_prof.id,
                                       dt_epis_prob_group_tstz_in => current_timestamp,
                                       id_epis_prob_group_out     => l_id_epis_prob_group,
                                       rows_out                   => l_rows);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_PROB_GROUP',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
                l_rows := table_varchar();
            END IF;
        
            -- process epis_prob
            IF i_prev_id_problem IS NULL
               OR i_prev_id_problem(i) IS NULL
            THEN
                -- add new epis prob
                ts_epis_prob.ins(id_problem_in         => i_id_problem(i),
                                 id_epis_prob_group_in => l_id_epis_prob_group,
                                 id_episode_in         => i_episode,
                                 flg_type_in           => i_flg_type(i),
                                 flg_status_in         => i_flg_status(i),
                                 rank_in               => l_seq_num,
                                 id_professional_in    => i_prof.id,
                                 dt_epis_prob_tstz_in  => current_timestamp,
                                 rows_out              => l_rows);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_PROB',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
                l_rows := table_varchar();
            ELSE
                g_error := 'GET L_ID_EPIS_PROBLEM';
                OPEN c_epis_prob(i_id_problem(i));
                FETCH c_epis_prob
                    INTO l_id_epis_problem;
                g_found := c_epis_prob%NOTFOUND;
                CLOSE c_epis_prob;
            
                IF l_id_epis_problem IS NOT NULL
                THEN
                    IF NOT set_epis_prob_to_hist(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_epis_problem => l_id_epis_problem,
                                                 o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_prev_epis_problem := l_id_epis_problem;
                ELSE
                    OPEN c_epis_prob(i_prev_id_problem(i));
                    FETCH c_epis_prob
                        INTO l_prev_epis_problem;
                    g_found := c_epis_prob%NOTFOUND;
                    CLOSE c_epis_prob;
                END IF;
            
                -- update new id_problem to previous problem 
                IF l_prev_epis_problem IS NOT NULL
                THEN
                    ts_epis_prob.upd(id_epis_problem_in    => l_prev_epis_problem,
                                     id_problem_in         => i_id_problem(i),
                                     id_epis_prob_group_in => l_id_epis_prob_group,
                                     id_episode_in         => i_episode,
                                     flg_type_in           => i_flg_type(i),
                                     flg_status_in         => i_flg_status(i),
                                     rank_in               => l_seq_num,
                                     id_professional_in    => i_prof.id,
                                     dt_epis_prob_tstz_in  => current_timestamp,
                                     rows_out              => l_rows);
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_PROB',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                    l_rows := table_varchar();
                END IF;
            
                -- remove epis_prob_group note if no other problem belongs to the previous group
                IF l_has_group = pk_alert_constant.get_yes
                THEN
                    l_cnt_problem := get_count_prob_in_group(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_episode         => i_episode,
                                                             i_id_problem      => i_prev_id_problem(i),
                                                             o_epis_prob_group => l_pre_epis_prob_group);
                    IF l_cnt_problem = 0
                    THEN
                        -- update to history first
                        IF NOT set_epis_prob_group_to_hist(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_epis_prob_group => l_pre_epis_prob_group,
                                                           o_error              => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        --set_epis_prob_group_to_hist
                        l_rows := table_varchar();
                        ts_epis_prob_group.upd(id_epis_prob_group_in => l_pre_epis_prob_group, rows_out => l_rows);
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'EPIS_PROB_GROUP',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    END IF;
                END IF;
            END IF;
        
            l_seq_num            := NULL;
            l_id_epis_prob_group := NULL;
            l_id_epis_problem    := NULL;
            l_prev_epis_problem  := NULL;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_group_exception THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   g_error_group_code,
                                   pk_message.get_message(i_lang, 'PROBLEM_LIST_T105'),
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'set_epis_problem_group_array',
                                   pk_message.get_message(i_lang, 'PROBLEM_LIST_T106'),
                                   'U',
                                   pk_message.get_message(i_lang, 'PROBLEM_LIST_T104'),
                                   'E');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'set_epis_problem_group_array',
                                              o_error);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            -- undo changes
            pk_utils.undo_changes;
            -- return failure
            RETURN FALSE;
    END set_epis_problem_group_array;

    FUNCTION set_prob_group_ass_hist
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SET_PROB_GROUP_ASS_HIST';
    
        l_rowids_hist         table_varchar;
        v_epis_prob_group_ass epis_prob_group_assess%ROWTYPE;
    
        CURSOR c_epis_prob_group_ass IS
            SELECT pga.id_epis_prob_group_ass,
                   pga.id_epis_prob_group,
                   pga.id_prof_create,
                   pga.dt_create,
                   pga.flg_status,
                   pga.id_prof_last_update,
                   pga.dt_last_update,
                   pga.assessment_note,
                   pga.plan_note,
                   pga.id_prof_cancel,
                   pga.id_cancel_reason,
                   pga.cancel_notes,
                   pga.dt_cancel
              FROM epis_prob_group_assess pga
             WHERE pga.id_epis_prob_group_ass = i_id_epis_prob_group_ass;
        l_id epis_prob_grp_ass_hist.id_epis_prob_grp_ass_hist%TYPE;
    BEGIN
    
        g_error := 'OPEN CURSOR c_epis_prob_group_ass';
        OPEN c_epis_prob_group_ass;
        FETCH c_epis_prob_group_ass
            INTO v_epis_prob_group_ass.id_epis_prob_group_ass,
                 v_epis_prob_group_ass.id_epis_prob_group,
                 v_epis_prob_group_ass.id_prof_create,
                 v_epis_prob_group_ass.dt_create,
                 v_epis_prob_group_ass.flg_status,
                 v_epis_prob_group_ass.id_prof_last_update,
                 v_epis_prob_group_ass.dt_last_update,
                 v_epis_prob_group_ass.assessment_note,
                 v_epis_prob_group_ass.plan_note,
                 v_epis_prob_group_ass.id_prof_cancel,
                 v_epis_prob_group_ass.id_cancel_reason,
                 v_epis_prob_group_ass.cancel_notes,
                 v_epis_prob_group_ass.dt_cancel;
        g_found := c_epis_prob_group_ass%NOTFOUND;
        CLOSE c_epis_prob_group_ass;
    
        g_error := 'TS_EPIS_PROB_GROUP_HIST.INS';
    
        ts_epis_prob_grp_ass_hist.ins(id_epis_prob_grp_ass_hist_in => seq_epis_prob_grp_ass_hist.nextval,
                                      id_epis_prob_group_ass_in    => v_epis_prob_group_ass.id_epis_prob_group_ass,
                                      id_epis_prob_group_in        => v_epis_prob_group_ass.id_epis_prob_group,
                                      id_prof_create_in            => v_epis_prob_group_ass.id_prof_create,
                                      dt_create_in                 => v_epis_prob_group_ass.dt_create,
                                      flg_status_in                => v_epis_prob_group_ass.flg_status,
                                      id_prof_last_update_in       => v_epis_prob_group_ass.id_prof_last_update,
                                      dt_last_update_in            => v_epis_prob_group_ass.dt_last_update,
                                      assessment_note_in           => v_epis_prob_group_ass.assessment_note,
                                      plan_note_in                 => v_epis_prob_group_ass.plan_note,
                                      id_prof_cancel_in            => v_epis_prob_group_ass.id_prof_cancel,
                                      id_cancel_reason_in          => v_epis_prob_group_ass.id_cancel_reason,
                                      cancel_notes_in              => v_epis_prob_group_ass.cancel_notes,
                                      dt_cancel_in                 => v_epis_prob_group_ass.dt_cancel);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_prob_group_ass_hist;

    FUNCTION set_epis_prob_group_note
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_epis_prob_grp_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_epis_prob_group   IN epis_prob_group.id_epis_prob_group%TYPE,
        i_assessment_note      IN CLOB,
        i_plan_note            IN CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_prob_group   epis_prob_group.id_epis_prob_group%TYPE;
        l_rows                 table_varchar;
        l_id_epis_prob_grp_ass epis_prob_group_assess.id_epis_prob_group_ass%TYPE;
        l_current_date         TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_current_date := current_timestamp;
    
        IF i_id_epis_prob_grp_ass IS NOT NULL
        THEN
            IF NOT set_prob_group_ass_hist(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_id_epis_prob_group_ass => i_id_epis_prob_grp_ass,
                                           o_error                  => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            ts_epis_prob_group_assess.upd(id_epis_prob_group_ass_in => i_id_epis_prob_grp_ass,
                                          id_epis_prob_group_in     => i_id_epis_prob_group,
                                          id_prof_last_update_in    => i_prof.id,
                                          dt_last_update_in         => current_timestamp,
                                          assessment_note_in        => i_assessment_note,
                                          plan_note_in              => i_plan_note,
                                          rows_out                  => l_rows);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_PROB_GROUP_ASSESS',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        ELSE
            l_id_epis_prob_grp_ass := ts_epis_prob_group_assess.next_key;
        
            ts_epis_prob_group_assess.ins(id_epis_prob_group_ass_in => l_id_epis_prob_grp_ass,
                                          id_epis_prob_group_in     => i_id_epis_prob_group,
                                          id_prof_create_in         => i_prof.id,
                                          dt_create_in              => l_current_date,
                                          flg_status_in             => pk_problems.g_status_prog_group_ass_a,
                                          id_prof_last_update_in    => i_prof.id,
                                          dt_last_update_in         => l_current_date,
                                          assessment_note_in        => i_assessment_note,
                                          plan_note_in              => i_plan_note,
                                          rows_out                  => l_rows);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_PROB_GROUP_ASSESS',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'set_epis_prob_group_note',
                                              o_error);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            -- undo changes
            pk_utils.undo_changes;
            -- return failure
            RETURN FALSE;
    END set_epis_prob_group_note;

    FUNCTION get_max_problem_group
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_group OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_max_group NUMBER(3, 0);
    
    BEGIN
        o_group := get_max_prob_group_internal(i_lang => i_lang, i_prof => i_prof, i_epis => i_epis);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_max_problem_group;

    FUNCTION get_max_prob_group_internal
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
    
        l_max_group NUMBER(3, 0);
    
    BEGIN
    
        BEGIN
            SELECT MAX(epg.prob_group)
              INTO l_max_group
              FROM epis_prob_group epg
             WHERE epg.id_episode = i_epis;
        EXCEPTION
            WHEN no_data_found THEN
                l_max_group := 0;
        END;
    
        IF l_max_group IS NULL
        THEN
            l_max_group := 0;
        END IF;
    
        RETURN l_max_group;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_max_prob_group_internal;

    FUNCTION get_prob_group
    (
        i_episode         IN episode.id_episode%TYPE,
        i_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN NUMBER IS
    
        l_prob_group NUMBER(3, 0);
    
    BEGIN
        SELECT epg.prob_group
          INTO l_prob_group
          FROM epis_prob_group epg
         WHERE epg.id_episode = i_episode
           AND epg.id_epis_prob_group = i_epis_prob_group;
    
        RETURN l_prob_group;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prob_group;

    FUNCTION get_epis_problem_internal
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pat        IN pat_history_diagnosis.id_patient%TYPE,
        i_status     IN table_varchar,
        i_type       IN VARCHAR2,
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_dt_ini     IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end     IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_problem    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
        l_headerviolenceicon   sys_message.desc_message%TYPE := 'HeaderViolenceIcon';
        l_headervirusicon      sys_message.desc_message%TYPE := 'HeaderVirusIcon';
        l_problem_list_t069    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'PROBLEM_LIST_T069');
        l_common_m008          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M008');
        l_common_m028          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
        l_show_all             sys_config.value%TYPE := pk_sysconfig.get_config('SUMMARY_VIEW_ALL', i_prof);
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_sc_show_surgical     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist,
                                                                                        i_prof);
    
    BEGIN
        IF i_status IS NULL
        THEN
            l_count := 0;
        ELSE
            l_count := i_status.count;
        END IF;
    
        g_error := 'CALL get_epis_problem_internal';
        -------------------
        -- Relevant diseases
        -------------------
        OPEN o_problem FOR
            SELECT k.id_diagnosis id,
                   k.id_pat_history_diagnosis id_problem,
                   g_type_d TYPE,
                   pk_date_utils.date_char_tsz(i_lang,
                                               k.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_problem2,
                   decode(k.dt_diagnosed_precision,
                          g_unknown,
                          g_unknown,
                          pk_date_utils.date_send_tsz(i_lang, k.dt_diagnosed, i_prof)) dt_problem,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => k.dt_diagnosed,
                                                           i_precision => k.dt_diagnosed_precision) dt_problem_to_print,
                   decode(k.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => k.id_alert_diagnosis,
                                                     i_id_diagnosis       => k.id_diagnosis,
                                                     i_id_task_type       => get_flg_area_task_type(i_flg_area => k.flg_area,
                                                                                                    i_flg_type => k.flg_type),
                                                     i_code               => k.code_icd,
                                                     i_flg_other          => k.flg_other,
                                                     i_flg_std_diag       => k.flg_icd9),
                          decode(k.id_alert_diagnosis,
                                 NULL,
                                 k.desc_pat_history_diagnosis,
                                 k.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => k.id_alert_diagnosis,
                                                            i_id_diagnosis       => k.id_diagnosis,
                                                            i_id_task_type       => get_flg_area_task_type(i_flg_area => k.flg_area,
                                                                                                           i_flg_type => k.flg_type),
                                                            i_code               => k.code_icd,
                                                            i_flg_other          => k.flg_other,
                                                            i_flg_std_diag       => k.flg_icd9))) desc_probl,
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => k.flg_area,
                                         i_id_alert_diagnosis => k.id_alert_diagnosis,
                                         i_flg_type           => k.flg_type) title,
                   decode(k.id_alert_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh) flg_source,
                   pk_date_utils.date_send_tsz(i_lang, k.dt_pat_history_diagnosis_tstz, i_prof) dt_order,
                   flg_status,
                   pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', k.flg_status) rank_type,
                   decode(k.flg_status, g_cancelled, 1, 0) rank_cancelled,
                   pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_AREA', k.flg_area) rank_area,
                   decode(k.flg_status, 'C', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', k.flg_status, i_lang) desc_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', k.flg_nature, i_lang) desc_nature,
                   pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', k.flg_status) rank_status,
                   nvl(pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_NATURE', k.flg_nature), -1) rank_nature,
                   k.flg_nature flg_nature,
                   decode(k.flg_status,
                          'C',
                          decode(k.cancel_notes, NULL, '', '(' || l_common_m008 || ')'),
                          decode(k.notes, NULL, '', '(' || l_common_m008 || ')')) title_notes,
                   decode(k.flg_status, 'C', k.cancel_notes, k.notes) prob_notes,
                   decode(k.flg_status, 'C', l_common_m028, '') title_canceled,
                   k.id_pat_history_diagnosis id_prob,
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => k.flg_area,
                                         i_id_alert_diagnosis => k.id_alert_diagnosis,
                                         i_flg_type           => k.flg_type) viewer_category,
                   
                   get_problem_type_desc(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_area           => k.flg_area,
                                         i_id_alert_diagnosis => k.id_alert_diagnosis,
                                         i_flg_type           => k.flg_type) viewer_category_desc,
                   k.id_professional viewer_id_prof,
                   k.id_episode viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, k.dt_pat_history_diagnosis_tstz, i_prof) viewer_date,
                   pk_problems.get_registered_by_me(i_prof, k.id_pat_history_diagnosis, g_type_d) registered_by_me,
                   nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        k.id_professional,
                                                        k.dt_pat_history_diagnosis_tstz,
                                                        k.id_episode),
                       l_problem_list_t069) origin_specialty,
                   pk_prof_utils.get_prof_speciality_id(i_lang,
                                                        profissional(k.id_professional,
                                                                     i_prof.institution,
                                                                     i_prof.software)) id_origin_specialty,
                   pk_problems.get_pat_precaution_list_desc(i_lang, i_prof, k.id_pat_history_diagnosis) precaution_measures_str,
                   pk_problems.get_pat_precaution_list_cod(i_lang, i_prof, k.id_pat_history_diagnosis) id_precaution_measures,
                   k.flg_warning header_warning,
                   pk_sysdomain.get_domain(pk_list.g_yes_no, k.flg_warning, i_lang) header_warning_str,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => k.dt_resolved,
                                                           i_precision => k.dt_resolved_precision) resolution_date_str,
                   decode(k.dt_resolved_precision,
                          pk_past_history.g_date_unknown,
                          pk_past_history.g_date_unknown,
                          pk_date_utils.date_send_tsz(i_lang, k.dt_resolved, i_prof)) resolution_date,
                   k.dt_resolved_precision dt_resolved_precision,
                   decode((SELECT pk_alert_constant.g_yes
                            FROM diag_diag_condition ddc
                           WHERE ddc.id_software IN (0, i_prof.software)
                             AND ddc.id_institution IN (0, i_prof.institution)
                             AND ddc.id_diagnosis IN
                                 (k.id_diagnosis,
                                  (SELECT ad1.id_diagnosis
                                     FROM alert_diagnosis ad1
                                    WHERE ad1.id_alert_diagnosis = k.id_alert_diagnosis))
                             AND rownum = 1),
                          pk_alert_constant.g_yes,
                          l_headervirusicon,
                          decode(k.flg_warning, pk_alert_constant.g_yes, l_headerviolenceicon, NULL)) warning_icon,
                   get_review(i_lang,
                              i_prof,
                              k.id_pat_history_diagnosis,
                              decode(k.id_alert_diagnosis, NULL, g_problem_type_problem, g_problem_type_pmh),
                              i_episode,
                              k.flg_status) review_info,
                   NULL,
                   get_flg_area(i_flg_area => k.flg_area, i_flg_type => k.flg_type) flg_area,
                   id_terminology_version,
                   id_content,
                   code_icd,
                   term_international_code,
                   get_flg_info_button(i_lang, i_prof, k.id_diagnosis) flg_info_button,
                   k.dt_pat_history_diagnosis_tstz update_time,
                   pk_past_history.get_partial_date_format_serial(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_date      => k.dt_diagnosed,
                                                                  i_precision => k.dt_diagnosed_precision) dt_problem_serial,
                   flg_epis_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', flg_epis_status, i_lang) desc_epis_status,
                   decode(k.id_epis_prob_group, -1, NULL, get_prob_group(i_episode, k.id_epis_prob_group)) prob_group,
                   k.rank seq_num,
                   nvl(get_max_prob_group_internal(i_lang, i_prof, i_episode), 0) max_group
              FROM (SELECT --p.id_professional,
                     d.id_diagnosis,
                     phd.id_pat_history_diagnosis,
                     phd.dt_pat_history_diagnosis_tstz,
                     phd.dt_diagnosed_precision,
                     phd.dt_diagnosed,
                     phd.desc_pat_history_diagnosis,
                     ad.id_alert_diagnosis,
                     phd.flg_area,
                     phd.flg_type,
                     d.code_icd,
                     d.flg_other,
                     ad.flg_icd9,
                     phd.flg_status                    flg_status,
                     phd.flg_nature,
                     phd.cancel_notes,
                     phd.notes,
                     phd.id_professional,
                     phd.id_episode,
                     phd.flg_warning,
                     phd.dt_resolved,
                     phd.dt_resolved_precision,
                     d.id_terminology_version,
                     d.id_content,
                     d.term_international_code,
                     ep.flg_status                     flg_epis_status,
                     ep.id_epis_prob_group,
                     ep.rank
                      FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d, epis_prob ep
                     WHERE phd.id_pat_history_diagnosis = nvl(i_id_problem, phd.id_pat_history_diagnosis)
                       AND phd.id_diagnosis = d.id_diagnosis(+)
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND phd.id_patient = i_pat
                       AND (ep.flg_type(+) = g_type_d AND phd.id_pat_history_diagnosis = ep.id_problem(+))
                       AND phd.id_episode = ep.id_episode(+)
                       AND ep.id_problem_new(+) IS NULL
                       AND phd.dt_pat_history_diagnosis_tstz BETWEEN nvl(i_dt_ini, phd.dt_pat_history_diagnosis_tstz) AND
                           nvl(i_dt_end, current_timestamp)
                       AND phd.flg_type IN
                           (pk_past_history.g_alert_diag_type_med, pk_past_history.g_alert_diag_type_surg)
                       AND (l_count = 0 OR
                           phd.flg_status IN (SELECT /*+ opt_estimate (table d rows=1) */
                                                column_value
                                                 FROM TABLE(i_status) d))
                       AND phd.id_pat_history_diagnosis = get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                       AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                           (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                           phd.flg_area IN
                           (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)))
                       AND ((l_sc_show_surgical = g_yes) OR phd.flg_area <> pk_alert_constant.g_diag_area_surgical_hist)
                          --eliminate outdated records due to editions
                       AND (phd.id_alert_diagnosis NOT IN (g_diag_unknown, g_diag_none) OR
                           phd.id_alert_diagnosis IS NULL)
                       AND NOT EXISTS
                     (SELECT 1
                              FROM pat_problem pp, epis_diagnosis ed, diagnosis d1
                             WHERE pp.id_diagnosis = d.id_diagnosis
                               AND pp.id_patient = phd.id_patient
                               AND pp.id_habit IS NULL
                               AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
                               AND pp.id_diagnosis = d1.id_diagnosis(+)
                               AND nvl(d1.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                               AND (nvl(d1.flg_type, 'Y') <> pk_diagnosis.g_diag_type_x OR
                                   (d1.flg_type = pk_diagnosis.g_diag_type_x AND l_show_all = pk_alert_constant.g_yes))
                               AND ( --final diagnosis
                                    (ed.flg_type = pk_diagnosis.g_diag_type_d) --
                                    OR -- differencial diagnosis only
                                    (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                    ed.id_diagnosis NOT IN
                                    (SELECT ed3.id_diagnosis
                                        FROM epis_diagnosis ed3
                                       WHERE ed3.id_diagnosis = ed.id_diagnosis
                                         AND ed3.id_patient = pp.id_patient
                                         AND ed3.flg_type = pk_diagnosis.g_diag_type_d)) --
                                    OR -- nao e um diagnostico
                                    (pp.id_habit IS NOT NULL))
                               AND pp.flg_status <> g_pat_probl_invest
                               AND pp.dt_pat_problem_tstz > phd.dt_pat_history_diagnosis_tstz
                               AND rownum = 1
                               AND pp.dt_pat_problem_tstz BETWEEN nvl(i_dt_ini, pp.dt_pat_problem_tstz) AND
                                   nvl(i_dt_end, current_timestamp))) k
             WHERE k.id_episode = i_episode
             ORDER BY seq_num, rank_status, dt_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'GET_EPIS_PROBLEM_INTERNAL');
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_problem);
                -- return failure
                RETURN FALSE;
            END;
    END get_epis_problem_internal;

    FUNCTION get_epis_problem
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pat        IN pat_history_diagnosis.id_patient%TYPE,
        i_status     IN table_varchar,
        i_type       IN VARCHAR2,
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        o_problem    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EPIS_PROBLEM_INTERNAL';
        IF NOT pk_problems.get_epis_problem_internal(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_episode    => i_episode,
                                                     i_pat        => i_pat,
                                                     i_status     => i_status,
                                                     i_type       => i_type,
                                                     i_id_problem => i_id_problem,
                                                     i_dt_ini     => NULL,
                                                     i_dt_end     => NULL,
                                                     o_problem    => o_problem,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_pk_owner, g_package_name, 'GET_EPIS_PROBLEM');
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_problem);
                -- return failure
                RETURN FALSE;
            END;
    END get_epis_problem;

    FUNCTION validate_epis_prob_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_problem        IN epis_prob.id_problem%TYPE,
        i_prob_group        IN epis_prob_group.prob_group%TYPE,
        o_prob_in_epis_prob OUT VARCHAR2,
        o_prob_in_gorup     OUT VARCHAR2,
        o_prob_in_prev_epis OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prob_group       epis_prob_group.prob_group%TYPE := i_prob_group;
        l_cnt_epis_problem NUMBER(24);
        l_cnt_prob         NUMBER(24);
        l_epis_prob_group  epis_prob_group.id_epis_prob_group%TYPE;
        l_id_prev_episode  episode.id_episode%TYPE;
    
    BEGIN
        g_error := 'CHECK EPIS PROB GROUP';
    
        o_prob_in_epis_prob := g_no;
        o_prob_in_gorup     := g_no;
        o_prob_in_prev_epis := g_no;
    
        SELECT COUNT(1)
          INTO l_cnt_epis_problem
          FROM epis_prob ep
         WHERE ep.id_problem = i_id_problem
           AND ep.id_episode = i_episode
           AND ep.flg_status <> g_cancelled;
    
        IF l_cnt_epis_problem > 0
        THEN
            o_prob_in_epis_prob := g_yes;
        
            -- Check if other problems in the same group
            l_cnt_prob := get_count_prob_in_group(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_id_problem      => i_id_problem,
                                                  o_epis_prob_group => l_epis_prob_group);
            IF l_cnt_prob > 1
               AND l_epis_prob_group <> 0
            THEN
                o_prob_in_gorup := g_yes;
            END IF;
        
            -- Check if this problem belongs previous episode
            BEGIN
                SELECT phd.id_episode
                  INTO l_id_prev_episode
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_pat_history_diagnosis_new =
                       (SELECT id_problem
                          FROM (SELECT ep.id_problem,
                                       row_number() over(PARTITION BY ep.id_episode ORDER BY ep.id_problem ASC) rn
                                  FROM epis_prob ep
                                  JOIN pat_history_diagnosis phd1
                                    ON phd1.id_pat_history_diagnosis = ep.id_problem
                                 WHERE ep.id_episode = i_episode
                                   AND phd1.id_diagnosis =
                                       (SELECT phd2.id_diagnosis
                                          FROM pat_history_diagnosis phd2
                                         WHERE phd2.id_pat_history_diagnosis = i_id_problem)) t
                         WHERE t.rn = 1);
            EXCEPTION
                WHEN no_data_found THEN
                    o_prob_in_prev_epis := g_no;
            END;
            IF l_id_prev_episode IS NOT NULL
               AND l_id_prev_episode <> i_episode
            THEN
                o_prob_in_prev_epis := g_yes;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'VALIDATE_EPIS_PROB_GROUP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_epis_prob_group;

    FUNCTION cancel_epis_problem
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat                 IN pat_problem.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_problem          IN NUMBER,
        i_type                IN VARCHAR2,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_prob.cancel_notes%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_flg_cancel_pat_prob IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_type                OUT table_varchar,
        o_ids                 OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_has_group sys_config.value%TYPE := pk_sysconfig.get_config('EPIS_PROB_SHOW_GROUP', i_prof);
    
        l_id_epis_problem    epis_prob.id_epis_problem%TYPE;
        l_id_problem_new     epis_prob.id_problem_new%TYPE;
        l_id_epis_prob_group epis_prob.id_epis_prob_group%TYPE;
        l_flg_type           epis_prob.flg_type%TYPE;
        l_seq_num            epis_prob.rank%TYPE;
    
        l_cnt_problem NUMBER(24);
        l_rows        table_varchar;
    
        CURSOR c_epis_prob IS
            SELECT ep.id_epis_problem, ep.id_epis_prob_group, ep.flg_type, ep.rank, ep.id_problem_new
              FROM epis_prob ep
             WHERE ep.id_problem = i_id_problem
               AND ep.id_episode = i_id_episode;
    BEGIN
    
        IF i_flg_cancel_pat_prob IS NOT NULL
           AND i_flg_cancel_pat_prob = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL PK_PROBLEMS.CANCEL_PAT_PROBLEM_NC';
            IF NOT cancel_pat_problem_nc(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_pat              => i_pat,
                                         i_id_episode       => i_id_episode,
                                         i_id_problem       => i_id_problem,
                                         i_type             => i_type,
                                         i_id_cancel_reason => i_id_cancel_reason,
                                         i_cancel_notes     => i_cancel_notes,
                                         i_prof_cat_type    => i_prof_cat_type,
                                         i_dt_register      => current_timestamp,
                                         o_type             => o_type,
                                         o_ids              => o_ids,
                                         o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'CANCEL EPIS PROBLEM';
            OPEN c_epis_prob;
            FETCH c_epis_prob
                INTO l_id_epis_problem, l_id_epis_prob_group, l_flg_type, l_seq_num, l_id_problem_new;
            g_found := c_epis_prob%NOTFOUND;
            CLOSE c_epis_prob;
        
            IF l_id_epis_problem IS NOT NULL
            THEN
                IF NOT set_epis_prob_to_hist(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_epis_problem => l_id_epis_problem,
                                             o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                ts_epis_prob.upd(id_epis_problem_in    => l_id_epis_problem,
                                 id_problem_in         => i_id_problem,
                                 id_epis_prob_group_in => l_id_epis_prob_group,
                                 id_episode_in         => i_id_episode,
                                 flg_type_in           => l_flg_type,
                                 flg_status_in         => g_cancelled,
                                 rank_in               => l_seq_num,
                                 id_cancel_reason_in   => i_id_cancel_reason,
                                 cancel_notes_in       => i_cancel_notes,
                                 id_prof_cancel_in     => i_prof.id,
                                 dt_cancel_in          => current_timestamp,
                                 id_problem_new_in     => l_id_problem_new,
                                 id_professional_in    => i_prof.id,
                                 dt_epis_prob_tstz_in  => current_timestamp,
                                 rows_out              => l_rows);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_PROB',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                IF l_has_group = pk_alert_constant.get_yes
                THEN
                    g_error       := 'CLEAR PRBLEM GROUP NOTES';
                    l_cnt_problem := get_count_prob_in_group(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_episode         => i_id_episode,
                                                             i_id_problem      => i_id_problem,
                                                             o_epis_prob_group => l_id_epis_prob_group);
                    IF l_cnt_problem = 0
                    THEN
                        IF NOT set_epis_prob_group_to_hist(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_epis_prob_group => l_id_epis_prob_group,
                                                           o_error              => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        l_rows := table_varchar();
                        ts_epis_prob_group.upd(id_epis_prob_group_in => l_id_epis_prob_group, rows_out => l_rows);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'EPIS_PROB_GROUP',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_PROBLEM',
                                              o_error);
            -- function called by Flash layer, reseting error state
            pk_alert_exceptions.reset_error_state;
            -- undo changes quando aplicavel-> so faz ROLLBACK
            pk_utils.undo_changes;
            -- return failure
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_pk_owner,
                                   g_package_name,
                                   'CANCEL_EPIS_PROBLEM');
            
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END cancel_epis_problem;

    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_subject CONSTANT VARCHAR2(20 CHAR) := 'PROBLEMS_VIEW';
    BEGIN
    
        g_error := 'OPEN o_list FOR';
        OPEN o_actions FOR
            SELECT *
              FROM (SELECT /*+opt_estimate (table t rows=1)*/
                     actp.id_action,
                     actp.id_parent,
                     actp.level_nr AS "LEVEL",
                     actp.from_state,
                     actp.to_state,
                     actp.desc_action,
                     actp.icon,
                     actp.flg_default,
                     decode(actp.flg_active,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.g_active,
                            pk_alert_constant.g_inactive) flg_active,
                     actp.action
                      FROM TABLE(pk_action.tf_get_actions_permissions(i_lang, i_prof, l_subject, NULL)) actp
                    UNION ALL
                    SELECT /*+opt_estimate(table act rows=1)*/
                     act.id_action,
                     act.id_parent,
                     act.level_nr AS "LEVEL", --used to manage the shown' items by Flash
                      act.from_state,
                      act.to_state, --destination state flag
                      act.desc_action, --action's description
                     act.icon, --action's icon
                      act.flg_default, --default action
                      act.flg_active, --action's state
                     act.action
                      FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, l_subject, i_from_state)) act);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    FUNCTION get_prob_group_description
    
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_group_ass          IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_flg_desc_for_dblock   IN VARCHAR2,
        i_flg_description       IN VARCHAR2,
        i_description_condition IN VARCHAR2
    ) RETURN CLOB IS
        l_prob_list     table_varchar;
        l_group_problem VARCHAR2(2000 CHAR);
        l_group         epis_prob_group.prob_group%TYPE;
        l_assessment    epis_prob_group_assess.assessment_note%TYPE;
        l_plan          epis_prob_group_assess.plan_note%TYPE;
        l_ret           CLOB;
        l_id_group      epis_prob_group.id_epis_prob_group%TYPE;
    BEGIN
    
        SELECT epg.id_epis_prob_group, epg.prob_group, pga.assessment_note, pga.plan_note
          INTO l_id_group, l_group, l_assessment, l_plan
          FROM epis_prob_group_assess pga
          JOIN epis_prob_group epg
            ON epg.id_epis_prob_group = pga.id_epis_prob_group
         WHERE pga.id_epis_prob_group_ass = i_id_group_ass;
    
        l_group_problem := get_epis_group_problem(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  i_id_epis_prob_group     => l_id_group,
                                                  i_id_epis_prob_group_ass => NULL);
    
        l_ret := pk_message.get_message(i_lang, 'PROBLEM_LIST_T101') || ' ' || l_group || chr(10);
        IF l_group_problem IS NOT NULL
        THEN
            l_ret := l_ret || l_group_problem || chr(10);
        END IF;
        IF l_assessment IS NOT NULL
        THEN
            l_ret := l_ret || ' ' || pk_message.get_message(i_lang, 'PROBLEMS_T024') || chr(10);
            l_ret := l_ret || '   ' || l_assessment;
        END IF;
        IF l_plan IS NOT NULL
        THEN
            l_ret := l_ret || chr(10) || ' ' || pk_message.get_message(i_lang, 'PROBLEMS_T025') || chr(10);
            l_ret := l_ret || '   ' || l_plan;
        END IF;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prob_group_description;

    FUNCTION get_epis_prob_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_problems           IN epis_prob.id_epis_problem%TYPE,
        i_flg_desc_for_dblock   IN VARCHAR2,
        i_flg_description       IN VARCHAR2,
        i_description_condition IN VARCHAR2
    ) RETURN CLOB IS
        l_ret               CLOB;
        l_rank              epis_prob_group.prob_group%TYPE;
        l_id_problem        epis_prob.id_problem%TYPE;
        l_type              epis_prob.flg_type%TYPE;
        l_description       VARCHAR2(2000 CHAR);
        l_status            sys_domain.desc_val%TYPE;
        l_complications     sys_domain.desc_val%TYPE;
        l_nature            sys_domain.desc_val%TYPE;
        l_dt_diagnosis      VARCHAR2(200 CHAR);
        l_description_split table_varchar;
        l_token_list        table_varchar;
        l_id                NUMBER;
    BEGIN
        SELECT ep.rank, ep.id_problem, ep.flg_type
          INTO l_rank, l_id_problem, l_type
          FROM epis_prob ep
          JOIN epis_prob_group epg
            ON ep.id_epis_prob_group = epg.id_epis_prob_group
         WHERE ep.id_epis_problem = i_id_problems;
    
        IF NOT pk_past_history.get_past_history_desc(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_pat_hist_diag => l_id_problem,
                                                     o_description   => l_description,
                                                     o_status        => l_status,
                                                     o_complications => l_complications,
                                                     o_nature        => l_nature,
                                                     o_dt_diagnosis  => l_dt_diagnosis)
        THEN
            RETURN NULL;
        END IF;
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
        
            l_description_split := pk_string_utils.str_split(i_list => i_description_condition, i_delim => ';');
            IF i_flg_desc_for_dblock = pk_prog_notes_constants.g_yes
            THEN
                l_id := 1;
            ELSE
                l_id := 2;
            END IF;
            l_token_list := pk_string_utils.str_split(i_list => l_description_split(l_id), i_delim => '|');
        
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'NUMBER'
                THEN
                    IF l_ret IS NOT NULL
                       AND l_rank IS NOT NULL
                    THEN
                        l_ret := l_ret || ' ';
                    END IF;
                    l_ret := l_ret || '[' || l_rank || ']';
                
                ELSIF l_token_list(i) = 'DESCRIPTION'
                THEN
                    IF l_ret IS NOT NULL
                       AND l_description IS NOT NULL
                    THEN
                        l_ret := l_ret || ', ';
                    END IF;
                    l_ret := l_ret || l_description;
                
                ELSIF l_token_list(i) = 'STATUS'
                THEN
                    IF l_ret IS NOT NULL
                       AND l_status IS NOT NULL
                    THEN
                        l_ret := l_ret || ', ';
                    END IF;
                    l_ret := l_ret || l_status;
                END IF;
            END LOOP;
        
        ELSIF i_flg_description = pk_prog_notes_constants.g_desc_type_s
        THEN
            l_ret := '[' || l_rank || '] ' || l_description;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_prob_description;

    FUNCTION get_epis_group_problem
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_epis_prob_group     IN epis_prob_group.id_epis_prob_group%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE
    ) RETURN VARCHAR2 IS
        l_prob_list          table_varchar;
        l_description        VARCHAR2(2000 CHAR);
        l_id_epis_prob_group epis_prob_group.id_epis_prob_group%TYPE;
    BEGIN
    
        l_id_epis_prob_group := i_id_epis_prob_group;
        IF i_id_epis_prob_group IS NULL
           AND i_id_epis_prob_group_ass IS NOT NULL
        THEN
            SELECT pga.id_epis_prob_group
              INTO l_id_epis_prob_group
              FROM epis_prob_group_assess pga
             WHERE pga.id_epis_prob_group_ass = i_id_epis_prob_group_ass;
        END IF;
    
        SELECT '[' || ep.rank || '] ' || decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                           i_prof               => i_prof,
                                                                           i_id_alert_diagnosis => phd.id_alert_diagnosis,
                                                                           i_id_diagnosis       => phd.id_diagnosis,
                                                                           i_id_task_type       => get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                                                          i_flg_type => phd.flg_type),
                                                                           i_code               => NULL,
                                                                           i_flg_other          => d.flg_other,
                                                                           i_flg_std_diag       => NULL),
                                                phd.desc_pat_history_diagnosis)
          BULK COLLECT
          INTO l_prob_list
          FROM epis_prob ep
          JOIN pat_history_diagnosis phd
            ON ep.id_problem = phd.id_pat_history_diagnosis
          JOIN alert_diagnosis ad
            ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
          JOIN diagnosis d
            ON phd.id_diagnosis = d.id_diagnosis
         WHERE ep.id_epis_prob_group = i_id_epis_prob_group
           AND ep.flg_type = 'D'
           AND ep.id_problem_new IS NULL
           AND ep.flg_status <> pk_problems.g_flg_cancel
           AND phd.id_pat_history_diagnosis_new IS NULL;
    
        l_description := pk_utils.concat_table(i_tab => l_prob_list, i_delim => '; ');
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_group_problem;

    FUNCTION get_epis_prob_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_status IN VARCHAR2,
        o_prob_group OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_description sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEM_LIST_T101') || ' ';
        l_list        table_number;
    BEGIN
    
        IF i_id_epis_pn IS NOT NULL
        THEN
            IF NOT pk_prog_notes_out.get_note_tasks_by_task_type(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_epis_pn => i_id_epis_pn,
                                                                 i_id_tl_task => pk_prog_notes_constants.g_task_problems_group_ass,
                                                                 o_tasks      => l_list,
                                                                 o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'OPEN o_prob_group';
        OPEN o_prob_group FOR
            SELECT id_epis_prob_group val,
                   prob_group rank,
                   l_description || prob_group || chr(10) ||
                   get_epis_group_problem(i_lang, i_prof, id_epis_prob_group, NULL) desc_val,
                   get_prev_group_assessment(i_lang, i_prof, i_episode, id_epis_prob_group) assessment,
                   get_prev_group_plan(i_lang, i_prof, i_episode, id_epis_prob_group) plan
              FROM (SELECT epg.id_epis_prob_group,
                           epg.prob_group,
                           (SELECT flg_status
                              FROM epis_prob ep
                             WHERE ep.id_epis_prob_group = epg.id_epis_prob_group
                               AND ep.flg_status <> 'C'
                               AND ep.id_problem_new IS NULL
                               AND rownum = 1) flg_status
                      FROM epis_prob_group epg
                     WHERE epg.id_episode = i_episode)
             WHERE flg_status = nvl(i_flg_status, pk_problems.g_pat_probl_active)
               AND id_epis_prob_group NOT IN
                   (SELECT id_epis_prob_group
                      FROM epis_prob_group_assess pga
                     WHERE pga.id_epis_prob_group_ass IN (SELECT /*+opt_estimate (table d rows=0.00000000001)*/
                                                           column_value
                                                            FROM TABLE(l_list) d))
             ORDER BY prob_group ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prob_group);
            RETURN FALSE;
        
    END get_epis_prob_group;

    FUNCTION get_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group     IN epis_prob_group.id_epis_prob_group%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        o_assessement            OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name              VARCHAR2(200 CHAR) := 'GET_PROB_GROUP_ASSESSMENT';
        l_id_epis_prob_group_ass epis_prob_group_assess.id_epis_prob_group_ass%TYPE;
        l_description            sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROBLEM_LIST_T101') || ' ';
    
    BEGIN
    
        IF i_id_epis_prob_group_ass IS NULL
        THEN
            OPEN o_assessement FOR
                SELECT NULL id_epis_prob_group_ass, id_epis_prob_group, assessment_note, plan_note
                  FROM (SELECT pga.assessment_note,
                               pga.plan_note,
                               pga.id_epis_prob_group,
                               row_number() over(PARTITION BY pga.id_epis_prob_group ORDER BY pga.dt_last_update DESC, pga.dt_create DESC) rn
                          FROM epis_prob_group_assess pga
                          JOIN epis_prob_group epg
                            ON pga.id_epis_prob_group = epg.id_epis_prob_group
                         WHERE pga.id_epis_prob_group = i_id_epis_prob_group
                           AND epg.id_episode = i_episode)
                 WHERE rn = 1;
        ELSE
            OPEN o_assessement FOR
                SELECT pga.id_epis_prob_group_ass,
                       pga.id_epis_prob_group,
                       l_description || prob_group || chr(10) ||
                       get_epis_group_problem(i_lang, i_prof, pga.id_epis_prob_group, NULL) group_desc,
                       pga.assessment_note,
                       pga.plan_note
                  FROM epis_prob_group_assess pga
                  JOIN epis_prob_group epg
                    ON pga.id_epis_prob_group = epg.id_epis_prob_group
                 WHERE pga.id_epis_prob_group_ass = i_id_epis_prob_group_ass
                   AND epg.id_episode = i_episode;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_assessement);
            RETURN FALSE;
    END get_prob_group_assessment;

    FUNCTION cancel_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel           IN CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(200 CHAR) := 'CANCEL_PROB_GROUP_ASSESSMENT';
        l_rows      table_varchar;
    
    BEGIN
        IF NOT set_prob_group_ass_hist(i_lang                   => i_lang,
                                       i_prof                   => i_prof,
                                       i_id_epis_prob_group_ass => i_id_epis_prob_group_ass,
                                       o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ts_epis_prob_group_assess.upd(id_epis_prob_group_ass_in => i_id_epis_prob_group_ass,
                                      flg_status_in             => pk_problems.g_status_prog_group_ass_c,
                                      id_cancel_reason_in       => i_id_cancel_reason,
                                      id_prof_cancel_in         => i_prof.id,
                                      cancel_notes_in           => i_notes_cancel,
                                      dt_cancel_in              => current_timestamp,
                                      rows_out                  => l_rows);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_PROB_GROUP_ASSESS',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_prob_group_assessment;

    FUNCTION get_prev_group_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN CLOB IS
        l_assessment epis_prob_group_assess.assessment_note%TYPE;
    BEGIN
        SELECT assessment_note
          INTO l_assessment
          FROM (SELECT pga.assessment_note,
                       pga.plan_note,
                       row_number() over(PARTITION BY pga.id_epis_prob_group ORDER BY pga.dt_last_update DESC, pga.dt_create DESC) rn
                  FROM epis_prob_group_assess pga
                  JOIN epis_prob_group epg
                    ON pga.id_epis_prob_group = epg.id_epis_prob_group
                 WHERE pga.id_epis_prob_group = i_id_epis_prob_group
                   AND epg.id_episode = i_episode
                   AND pga.flg_status = pk_problems.g_status_prog_group_ass_a)
         WHERE rn = 1;
    
        RETURN l_assessment;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prev_group_assessment;

    FUNCTION get_prev_group_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN CLOB IS
    
        l_plan epis_prob_group_assess.plan_note%TYPE;
    
    BEGIN
        SELECT plan_note
          INTO l_plan
          FROM (SELECT pga.assessment_note,
                       pga.plan_note,
                       row_number() over(PARTITION BY pga.id_epis_prob_group ORDER BY pga.dt_last_update DESC, pga.dt_create DESC) rn
                  FROM epis_prob_group_assess pga
                  JOIN epis_prob_group epg
                    ON pga.id_epis_prob_group = epg.id_epis_prob_group
                 WHERE pga.id_epis_prob_group = i_id_epis_prob_group
                   AND epg.id_episode = i_episode
                   AND pga.flg_status = pk_problems.g_status_prog_group_ass_a)
         WHERE rn = 1;
    
        RETURN l_plan;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prev_group_plan;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
    g_diag_select := 'Y';

    g_available := 'Y';

    g_patient_active           := 'A';
    g_pat_hplan_active         := 'A';
    g_pat_hplan_flg_default_no := 'N';
    g_pat_job_active           := 'A';
    g_clin_rec_active          := 'A';

    g_pat_allergy_active   := 'A';
    g_pat_allergy_passive  := 'P';
    g_pat_allergy_cancel   := 'C';
    g_pat_allergy_resolved := 'R';

    g_pat_allergy_all  := 'A';
    g_pat_allergy_reac := 'I';

    g_pat_allergy_doc := 'M';
    g_pat_allergy_pat := 'U';

    g_pat_probl_active   := 'A';
    g_pat_probl_passive  := 'P';
    g_pat_probl_cancel   := 'C';
    g_pat_probl_resolved := 'R';
    g_pat_probl_invest   := 'E';

    g_epis_diag_passive := 'P';

    g_pat_note_flg_active := 'A';
    g_pat_note_flg_cancel := 'C';

    g_pat_hplan_default := 'Y';
    g_doc_avail         := 'Y';
    g_hplan_avail       := 'Y';
    g_pat_doc_active    := 'A';

    g_pat_habit_canc        := 'C';
    g_pat_habit_active      := 'A';
    g_pat_fam_soc_hist_canc := 'C';
    g_pat_fam_soc_hist_act  := 'A';

    g_pat_medicat_active := 'A';

    g_pat_blood_active := 'A';
    g_pat_blood_cancel := 'I';

    g_pat_prob_allrg := 'A';
    g_pat_prob_prob  := 'P';

    g_error_msg_code       := 'COMMON_M001';
    g_date_convert_pattern := 'YYYYMMDD';

    g_patient_row.flg_migration := 'A';

    g_medical_diagnosis_type := 'M';

END;
/
